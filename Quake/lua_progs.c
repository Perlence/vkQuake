/*
Copyright (C) 2026 vkQuake contributors

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License.
*/

#include "quakedef.h"

#include <limits.h>
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>

#define LP_ENTITY_META "vkquake.entity"
#define LP_VECTOR_META "vkquake.vec3"

static const char *const lp_boolean_globals[] = {
	"coop", "trace_allsolid", "trace_inopen", "trace_inwater", "trace_startsolid",
};

static const char *const lp_boolean_fields[] = {
	"button0",
	"button1",
	"button2",
};

typedef struct
{
	float  owned[3];
	float *value;
} lp_vector_t;

typedef struct
{
	int number;
} lp_entity_t;

typedef struct
{
	char	*name;
	etype_t	 type;
	qboolean boolean;
} lp_def_t;

typedef struct
{
	etype_t	 type;
	qboolean boolean;
	qboolean field;
} lp_builtin_value_t;

typedef struct
{
	int				   number;
	int				   argc;
	lp_builtin_value_t parameters[MAX_PARMS];
	lp_builtin_value_t result;
} lp_builtin_t;

static lua_State *lp_state;
static int		  lp_spawns_ref = LUA_NOREF;
static int		  lp_boolean_defs_ref = LUA_NOREF;
// Registered functions are mapped in both directions: lp_functions_ref maps
// names to func_t values, lp_function_names_ref maps Lua functions to names,
// and the Lua registry maps the negated func_t values to Lua functions. Valid
// QuakeC function indexes are below the signed dprograms_t.numfunctions, so
// negated positive Lua references cannot collide with them.
static int		  lp_functions_ref = LUA_NOREF;
static int		  lp_function_names_ref = LUA_NOREF;
static qboolean	  lp_active;
static lp_def_t	 *lp_global_defs;
static size_t	  lp_num_global_defs;
static lp_def_t	 *lp_field_defs;
static size_t	  lp_num_field_defs;

static int		LP_CallQC (lua_State *L);
static void		LP_ClearDefs (void);
static int		LP_CompareDefs (const void *left, const void *right);
static qboolean LP_IsBooleanDef (lua_State *L, const ddef_t *definition);
static void		LP_ReadDefsTable (lua_State *L, int index, const char *description, lp_def_t **defs, size_t *numdefs);
static etype_t	LP_ReadDefType (const char *name, const char *type, qboolean *boolean);
static ddef_t  *LP_FindFileDef (dprograms_t *progs, int lumpofs, int count, const char *name);
static qboolean LP_HasDef (const lp_def_t *definitions, size_t count, const char *name);
static int		LP_AppendString (dprograms_t *progs, const char *name);

// Reports the Lua error at the top of the global state and does not return.
static void LP_Error (const char *context)
{
	const char *message = lua_tostring (lp_state, -1);
	Host_Error ("Lua progs %s: %s", context, message ? message : "unknown error");
}

// Adds a traceback to an error while its Lua call stack is still available.
// [-0, +1]
static int LP_Traceback (lua_State *L)
{
	const char *message = lua_tostring (L, 1);

	if (!message)
		message = "unknown error";
	luaL_traceback (L, L, message, 1);
	return 1;
}

// Calls a Lua function in protected mode with a traceback-producing message
// handler.
// [-(nargs + 1), +(nresults|1)]
static int LP_PCall (lua_State *L, int arguments, int results)
{
	const int function = lua_gettop (L) - arguments;
	int		  status;

	lua_pushcfunction (L, LP_Traceback);
	lua_insert (L, function);
	status = lua_pcall (L, arguments, results, function);
	lua_remove (L, function);
	return status;
}

// Returns the function's registered name, or NULL if none was found.
// [-0, +0]
static const char *LP_GetRegisteredFunctionName (lua_State *L, int index)
{
	const char *name;
	index = lua_absindex (L, index);
	lua_rawgeti (L, LUA_REGISTRYINDEX, lp_function_names_ref);
	lua_pushvalue (L, index);
	lua_gettable (L, -2);
	name = lua_isstring (L, -1) ? lua_tostring (L, -1) : NULL;
	lua_pop (L, 2);
	return name;
}

// Looks up the function's stable reference, returning it or 0.
// [-0, +0]
static func_t LP_GetRegisteredFunctionRef (lua_State *L, int index)
{
	const char *name = LP_GetRegisteredFunctionName (L, index);
	func_t		function = 0;
	if (!name)
		return 0;
	lua_rawgeti (L, LUA_REGISTRYINDEX, lp_functions_ref);
	lua_getfield (L, -1, name);
	if (lua_isinteger (L, -1))
		function = lua_tointeger (L, -1);
	lua_pop (L, 2);
	return function;
}

// Registers a named Lua function, pushes it onto the stack.
// [-0, +1]
static int LP_RegisterFunction (lua_State *L)
{
	const char *identifier = luaL_checkstring (L, 1);
	char		name[1024];
	func_t		function;
	luaL_checktype (L, 2, LUA_TFUNCTION);
	q_snprintf (name, sizeof (name), "lua:%s", identifier);

	lua_rawgeti (L, LUA_REGISTRYINDEX, lp_functions_ref);
	lua_getfield (L, -1, name);
	if (!lua_isnil (L, -1))
		return luaL_error (L, "function '%s' is already registered", identifier);
	lua_pop (L, 1);

	function = LP_GetRegisteredFunctionRef (L, 2);
	if (!function)
	{
		lua_pushvalue (L, 2);
		function = -luaL_ref (L, LUA_REGISTRYINDEX);
	}
	lua_pushstring (L, name);
	lua_pushinteger (L, function);
	lua_settable (L, -3);
	lua_pop (L, 1);

	lua_rawgeti (L, LUA_REGISTRYINDEX, lp_function_names_ref);
	lua_pushvalue (L, 2);
	lua_pushstring (L, name);
	lua_settable (L, -3);
	lua_pop (L, 1);
	lua_pushvalue (L, 2);
	return 1;
}

// Looks up a Lua function by the reference, returning its name or NULL.
const char *LP_GetFunctionName (func_t function)
{
	const char *name;
	if (!lp_active || (int)function >= 0)
		return NULL;
	lua_rawgeti (lp_state, LUA_REGISTRYINDEX, -(int)function);
	name = lua_isfunction (lp_state, -1) ? LP_GetRegisteredFunctionName (lp_state, -1) : NULL;
	lua_pop (lp_state, 1);
	return name;
}

// Looks up a named Lua function, returning its reference or 0.
func_t LP_FindFunction (const char *name)
{
	func_t function = 0;
	if (!lp_active || strncmp (name, "lua:", 4))
		return 0;
	lua_rawgeti (lp_state, LUA_REGISTRYINDEX, lp_functions_ref);
	lua_getfield (lp_state, -1, name);
	if (lua_isinteger (lp_state, -1))
		function = lua_tointeger (lp_state, -1);
	lua_pop (lp_state, 2);
	return function;
}

// Pushes the numbered entity userdata or nil.
// [-0, +1]
static void LP_PushEntityNumber (lua_State *L, int number, qboolean allow_world)
{
	lp_entity_t *value;

	if (number == 0 && !allow_world)
	{
		lua_pushnil (L);
		return;
	}
	if (number < 0 || number >= qcvm->num_edicts)
		Host_Error ("LP_PushEntityNumber: bad entity number %d", number);

	value = lua_newuserdatauv (L, sizeof (*value), 0);
	value->number = number;
	luaL_setmetatable (L, LP_ENTITY_META);
}

// Pushes entity userdata or nil.
// [-0, +1]
static void LP_PushEntity (lua_State *L, edict_t *entity, qboolean allow_world)
{
	LP_PushEntityNumber (L, NUM_FOR_EDICT (entity), allow_world);
}

// Checks and returns the entity at index.
// [-0, +0]
static edict_t *LP_CheckEntity (lua_State *L, int index)
{
	lp_entity_t *value = luaL_checkudata (L, index, LP_ENTITY_META);
	if (value->number < 0 || value->number >= qcvm->num_edicts)
		luaL_error (L, "invalid entity %d", value->number);
	return EDICT_NUM (value->number);
}

// Pushes vector userdata referencing existing storage.
// [-0, +1]
static void LP_PushVector (lua_State *L, float *value)
{
	lp_vector_t *vector = lua_newuserdatauv (L, sizeof (*vector), 0);
	vector->value = value;
	luaL_setmetatable (L, LP_VECTOR_META);
}

// Pushes vector userdata owning the given components.
// [-0, +1]
static void LP_PushOwnedVector (lua_State *L, float x, float y, float z)
{
	lp_vector_t *vector = lua_newuserdatauv (L, sizeof (*vector), 0);
	vector->owned[0] = x;
	vector->owned[1] = y;
	vector->owned[2] = z;
	vector->value = vector->owned;
	luaL_setmetatable (L, LP_VECTOR_META);
}

// Checks and returns the vector userdata at index.
// [-0, +0]
static lp_vector_t *LP_CheckVector (lua_State *L, int index)
{
	return luaL_checkudata (L, index, LP_VECTOR_META);
}

// Copies the vector at index into native storage.
// [-0, +0]
static void LP_CopyVector (lua_State *L, int index, float *destination)
{
	lp_vector_t *vector = LP_CheckVector (L, index);
	VectorCopy (vector->value, destination);
}

// Looks up a vector component or method, pushes it.
// [-0, +1]
static int LP_VectorIndex (lua_State *L)
{
	lp_vector_t *vector = LP_CheckVector (L, 1);
	const char	*key = luaL_checkstring (L, 2);

	if (!strcmp (key, "x"))
		lua_pushnumber (L, vector->value[0]);
	else if (!strcmp (key, "y"))
		lua_pushnumber (L, vector->value[1]);
	else if (!strcmp (key, "z"))
		lua_pushnumber (L, vector->value[2]);
	else
	{
		luaL_getmetatable (L, LP_VECTOR_META);
		lua_getfield (L, -1, key);
		lua_remove (L, -2);
	}
	return 1;
}

// Sets a vector component, pushes nothing.
// [-0, +0]
static int LP_VectorNewIndex (lua_State *L)
{
	lp_vector_t *vector = LP_CheckVector (L, 1);
	const char	*key = luaL_checkstring (L, 2);
	const float	 value = luaL_checknumber (L, 3);

	if (!strcmp (key, "x"))
		vector->value[0] = value;
	else if (!strcmp (key, "y"))
		vector->value[1] = value;
	else if (!strcmp (key, "z"))
		vector->value[2] = value;
	else
		return luaL_error (L, "unknown vec3 member '%s'", key);
	return 0;
}

// Adds or subtracts two vectors, pushes the resulting vector.
// [-0, +1]
static int LP_VectorBinary (lua_State *L, int operation)
{
	lp_vector_t *a = LP_CheckVector (L, 1);
	lp_vector_t *b = LP_CheckVector (L, 2);
	if (operation == 0)
		LP_PushOwnedVector (L, a->value[0] + b->value[0], a->value[1] + b->value[1], a->value[2] + b->value[2]);
	else
		LP_PushOwnedVector (L, a->value[0] - b->value[0], a->value[1] - b->value[1], a->value[2] - b->value[2]);
	return 1;
}

// Adds two vectors, pushes the resulting vector.
// [-0, +1]
static int LP_VectorAdd (lua_State *L)
{
	return LP_VectorBinary (L, 0);
}
// Subtracts two vectors, pushes the resulting vector.
// [-0, +1]
static int LP_VectorSub (lua_State *L)
{
	return LP_VectorBinary (L, 1);
}

// Scales a vector, pushes the resulting vector.
// [-0, +1]
static int LP_VectorMul (lua_State *L)
{
	lp_vector_t *vector;
	float		 scale;
	if (lua_isnumber (L, 1))
	{
		scale = lua_tonumber (L, 1);
		vector = LP_CheckVector (L, 2);
	}
	else
	{
		vector = LP_CheckVector (L, 1);
		scale = luaL_checknumber (L, 2);
	}
	LP_PushOwnedVector (L, vector->value[0] * scale, vector->value[1] * scale, vector->value[2] * scale);
	return 1;
}

// Negates a vector, pushes the resulting vector.
// [-0, +1]
static int LP_VectorUnm (lua_State *L)
{
	lp_vector_t *vector = LP_CheckVector (L, 1);
	LP_PushOwnedVector (L, -vector->value[0], -vector->value[1], -vector->value[2]);
	return 1;
}

// Compares two vectors, pushes their equality.
// [-0, +1]
static int LP_VectorEq (lua_State *L)
{
	lp_vector_t *a = LP_CheckVector (L, 1), *b = LP_CheckVector (L, 2);
	lua_pushboolean (L, VectorCompare (a->value, b->value));
	return 1;
}

// Computes a vector length, pushes it.
// [-0, +1]
static int LP_VectorLength (lua_State *L)
{
	lua_pushnumber (L, VectorLength (LP_CheckVector (L, 1)->value));
	return 1;
}

// Normalizes a vector, pushes the resulting vector.
// [-0, +1]
static int LP_VectorNormalized (lua_State *L)
{
	vec3_t value;
	VectorCopy (LP_CheckVector (L, 1)->value, value);
	VectorNormalize (value);
	LP_PushOwnedVector (L, value[0], value[1], value[2]);
	return 1;
}

// Computes a vector dot product, pushes it.
// [-0, +1]
static int LP_VectorDot (lua_State *L)
{
	lp_vector_t *a = LP_CheckVector (L, 1), *b = LP_CheckVector (L, 2);
	lua_pushnumber (L, DotProduct (a->value, b->value));
	return 1;
}

// Formats a vector, pushes the string.
// [-0, +1]
static int LP_VectorToString (lua_State *L)
{
	lp_vector_t *vector = LP_CheckVector (L, 1);
	lua_pushfstring (L, "'%f %f %f'", vector->value[0], vector->value[1], vector->value[2]);
	return 1;
}

// Compares two entities, pushes their equality.
// [-0, +1]
static int LP_EntityEq (lua_State *L)
{
	lp_entity_t *a = luaL_checkudata (L, 1, LP_ENTITY_META), *b = luaL_checkudata (L, 2, LP_ENTITY_META);
	lua_pushboolean (L, a->number == b->number);
	return 1;
}

// Formats an entity, pushes the string.
// [-0, +1]
static int LP_EntityToString (lua_State *L)
{
	lp_entity_t *entity = luaL_checkudata (L, 1, LP_ENTITY_META);
	lua_pushfstring (L, "entity %d", entity->number);
	return 1;
}

// Pushes nil, a stored Lua function, or a QuakeC closure.
// [-0, +1]
static void LP_PushFunction (lua_State *L, func_t function)
{
	if (!function)
		lua_pushnil (L);
	else if ((int)function < 0)
		lua_rawgeti (L, LUA_REGISTRYINDEX, -(int)function);
	else
	{
		lua_pushinteger (L, function);
		lua_pushcclosure (L, LP_CallQC, 1);
	}
}

// Converts a QuakeC value, pushes its Lua representation.
// [-0, +1]
static void LP_PushValue (lua_State *L, int type, eval_t *value, qboolean boolean, qboolean allow_world)
{
	if (boolean)
	{
		assert ((type & ~DEF_SAVEGLOBAL) == ev_float);
		lua_pushboolean (L, value->_float != 0);
		return;
	}
	switch (type & ~DEF_SAVEGLOBAL)
	{
	case ev_string:
		lua_pushstring (L, PR_GetString (value->string));
		break;
	case ev_float:
		lua_pushnumber (L, value->_float);
		break;
	case ev_vector:
		LP_PushVector (L, value->vector);
		break;
	case ev_entity:
		LP_PushEntity (L, PROG_TO_EDICT (value->edict), allow_world);
		break;
	case ev_function:
		LP_PushFunction (L, value->function);
		break;
	default:
		lua_pushnil (L);
		break;
	}
}

// Copies the string at index into QuakeC storage, returning its offset.
// [-0, +0]
static int LP_CopyString (lua_State *L, int index)
{
	const char *source = luaL_checkstring (L, index);
	char	   *destination;
	int			result = PR_AllocString ((int)strlen (source) + 1, &destination);
	q_strlcpy (destination, source, strlen (source) + 1);
	return result;
}

// Copies the value at index into QuakeC storage.
// [-0, +0]
static void LP_SetValue (lua_State *L, int index, int type, eval_t *value, qboolean boolean)
{
	if (boolean)
	{
		assert ((type & ~DEF_SAVEGLOBAL) == ev_float);
		luaL_checktype (L, index, LUA_TBOOLEAN);
		value->_float = lua_toboolean (L, index);
		return;
	}
	switch (type & ~DEF_SAVEGLOBAL)
	{
	case ev_string:
		value->string = LP_CopyString (L, index);
		break;
	case ev_float:
		value->_float = luaL_checknumber (L, index);
		break;
	case ev_vector:
		LP_CopyVector (L, index, value->vector);
		break;
	case ev_entity:
		value->edict = lua_isnil (L, index) ? 0 : EDICT_TO_PROG (LP_CheckEntity (L, index));
		break;
	case ev_function:
		if (lua_isnil (L, index))
		{
			value->function = 0;
			break;
		}

		luaL_checktype (L, index, LUA_TFUNCTION);
		if (lua_iscfunction (L, index) && lua_tocfunction (L, index) == LP_CallQC)
		{
			lua_getupvalue (L, index, 1);
			value->function = lua_tointeger (L, -1);
			lua_pop (L, 1);
			break;
		}

		value->function = LP_GetRegisteredFunctionRef (L, index);
		if (!value->function)
			luaL_error (L, "cannot store an unregistered Lua function");
		break;
	default:
		luaL_error (L, "unsupported QuakeC value type %d", type);
		break;
	}
}

// Copies Lua arguments into QuakeC parameters, executes the closure target.
// [-0, +0]
static int LP_CallQC (lua_State *L)
{
	const func_t function = lua_tointeger (L, lua_upvalueindex (1));
	const int	 count = q_min (lua_gettop (L), MAX_PARMS);
	int			 i;

	for (i = 0; i < count; ++i)
	{
		const int index = i + 1;
		const int offset = OFS_PARM0 + i * 3;
		if (luaL_testudata (L, index, LP_ENTITY_META))
			G_INT (offset) = EDICT_TO_PROG (LP_CheckEntity (L, index));
		else if (luaL_testudata (L, index, LP_VECTOR_META))
			LP_CopyVector (L, index, G_VECTOR (offset));
		else if (lua_isnumber (L, index))
			G_FLOAT (offset) = lua_tonumber (L, index);
		else if (lua_isstring (L, index))
			G_INT (offset) = LP_CopyString (L, index);
	}
	PR_ExecuteProgram (function);
	return 0;
}

// Looks up an entity field, pushes its value.
// [-0, +1]
static int LP_EntityIndex (lua_State *L)
{
	edict_t	   *entity = LP_CheckEntity (L, 1);
	const char *name = luaL_checkstring (L, 2);
	ddef_t	   *field = ED_FindField (name);
	if (!field)
		return luaL_error (L, "unknown entity field '%s'", name);
	LP_PushValue (L, field->type, (eval_t *)((float *)&entity->v + field->ofs), LP_IsBooleanDef (L, field), false);
	return 1;
}

// Sets an entity field.
// [-0, +0]
static int LP_EntityNewIndex (lua_State *L)
{
	edict_t	   *entity = LP_CheckEntity (L, 1);
	const char *name = luaL_checkstring (L, 2);
	ddef_t	   *field = ED_FindField (name);
	if (!field)
		return luaL_error (L, "unknown entity field '%s'", name);
	LP_SetValue (L, 3, field->type, (eval_t *)((float *)&entity->v + field->ofs), LP_IsBooleanDef (L, field));
	return 0;
}

// Looks up a global, pushes its value.
// [-0, +1]
static int LP_GlobalsIndex (lua_State *L)
{
	const char *name = luaL_checkstring (L, 2);
	ddef_t	   *global = ED_FindGlobal (name);
	if (!global)
		return luaL_error (L, "unknown global '%s'", name);
	LP_PushValue (L, global->type, (eval_t *)&qcvm->globals[global->ofs], LP_IsBooleanDef (L, global), false);
	return 1;
}

// Sets a global.
// [-0, +0]
static int LP_GlobalsNewIndex (lua_State *L)
{
	const char *name = luaL_checkstring (L, 2);
	ddef_t	   *global = ED_FindGlobal (name);
	if (!global)
		return luaL_error (L, "unknown global '%s'", name);
	LP_SetValue (L, 3, global->type, (eval_t *)&qcvm->globals[global->ofs], LP_IsBooleanDef (L, global));
	return 0;
}

// Parses the builtin type at index.
// [-0, +0]
static lp_builtin_value_t LP_CheckBuiltinType (lua_State *L, int index, qboolean allow_void)
{
	const char		  *original = luaL_checkstring (L, index);
	const char		  *name = original;
	lp_builtin_value_t value = {ev_bad, false, false};

	if (name[0] == '.')
	{
		value.field = true;
		name++;
	}
	if (allow_void && !value.field && !strcmp (name, "void"))
		value.type = ev_void;
	else if (!value.field && !strcmp (name, "bool"))
	{
		value.type = ev_float;
		value.boolean = true;
	}
	else if (!strcmp (name, "float"))
		value.type = ev_float;
	else if (!strcmp (name, "string"))
		value.type = ev_string;
	else if (!strcmp (name, "vector"))
		value.type = ev_vector;
	else if (!strcmp (name, "entity"))
		value.type = ev_entity;
	else if (!strcmp (name, "function"))
		value.type = ev_function;
	else
		luaL_error (L, "unknown builtin type '%s'", original);
	return value;
}

// Copies the Lua value at index into its corresponding QuakeC parameter.
// [-0, +0]
static void LP_SetBuiltinParm (lua_State *L, int index, lp_builtin_value_t value)
{
	eval_t *destination = (eval_t *)&qcvm->globals[OFS_PARM0 + (index - 1) * 3];

	if (value.field)
	{
		const char *name = luaL_checkstring (L, index);
		ddef_t	   *field = ED_FindField (name);
		if (!field)
			luaL_error (L, "unknown entity field '%s'", name);
		if ((field->type & ~DEF_SAVEGLOBAL) != value.type)
			luaL_error (L, "entity field '%s' has the wrong type", name);
		destination->_int = field->ofs;
		return;
	}
	LP_SetValue (L, index, value.type, destination, value.boolean);
}

// Pushes the typed QuakeC return value, unless the builtin returns void.
// [-0, +(0|1)]
static int LP_PushBuiltinResult (lua_State *L, lp_builtin_value_t result)
{
	eval_t *value = (eval_t *)&qcvm->globals[OFS_RETURN];

	if (result.type == ev_void)
		return 0;
	if (result.boolean)
		lua_pushboolean (L, value->_float != 0);
	else
	{
		switch (result.type)
		{
		case ev_float:
			lua_pushnumber (L, value->_float);
			break;
		case ev_string:
			lua_pushstring (L, PR_GetString (value->string));
			break;
		case ev_vector:
			LP_PushOwnedVector (L, value->vector[0], value->vector[1], value->vector[2]);
			break;
		case ev_entity:
			LP_PushEntity (L, PROG_TO_EDICT (value->edict), false);
			break;
		case ev_function:
			LP_PushFunction (L, value->function);
			break;
		default:
			return luaL_error (L, "unsupported builtin result type %d", result.type);
		}
	}
	return 1;
}

// Copies the Lua arguments into QuakeC parameters and calls the bound builtin.
// [-0, +(0|1)]
static int LP_CallBuiltin (lua_State *L)
{
	lp_builtin_t *builtin = lua_touserdata (L, lua_upvalueindex (1));
	const int	  previous_argc = qcvm->argc;
	int			  i;

	if (lua_gettop (L) != builtin->argc)
		return luaL_error (L, "builtin #%d expects %d arguments, got %d", builtin->number, builtin->argc, lua_gettop (L));

	for (i = 1; i <= builtin->argc; ++i)
		LP_SetBuiltinParm (L, i, builtin->parameters[i - 1]);

	qcvm->argc = builtin->argc;
	qcvm->builtins[builtin->number]();
	qcvm->argc = previous_argc;

	return LP_PushBuiltinResult (L, builtin->result);
}

// Binds a QuakeC builtin to a typed Lua closure.
// [-0, +1]
static int LP_BindBuiltin (lua_State *L)
{
	const int	  number = luaL_checkinteger (L, 1);
	int			  argc;
	lp_builtin_t *builtin;
	int			  i;

	luaL_checktype (L, 2, LUA_TTABLE);
	argc = luaL_len (L, 2);
	if (number < 0 || number >= qcvm->numbuiltins || !qcvm->builtins[number])
		return luaL_error (L, "builtin #%d is unavailable", number);
	if (argc > MAX_PARMS)
		return luaL_error (L, "builtin #%d has too many parameters", number);
	builtin = lua_newuserdatauv (L, sizeof (*builtin), 0);
	builtin->number = number;
	builtin->argc = argc;
	for (i = 0; i < argc; ++i)
	{
		lua_rawgeti (L, 2, i + 1);
		builtin->parameters[i] = LP_CheckBuiltinType (L, -1, false);
		lua_pop (L, 1);
	}
	builtin->result = LP_CheckBuiltinType (L, 3, true);
	if (builtin->result.field)
		return luaL_error (L, "a builtin cannot return a field reference");
	lua_pushcclosure (L, LP_CallBuiltin, 1);
	return 1;
}

static int LP_Time (lua_State *L)
{
	lua_pushnumber (L, qcvm->time);
	return 1;
}

static int LP_Vec3 (lua_State *L)
{
	LP_PushOwnedVector (L, luaL_checknumber (L, 1), luaL_checknumber (L, 2), luaL_checknumber (L, 3));
	return 1;
}

// Registers an entity spawn function.
// [-0, +0]
static int LP_RegisterEntity (lua_State *L)
{
	const char *name = luaL_checkstring (L, 1);
	luaL_checktype (L, 2, LUA_TFUNCTION);
	lua_rawgeti (L, LUA_REGISTRYINDEX, lp_spawns_ref);
	lua_getfield (L, -1, name);
	if (!lua_isnil (L, -1))
		return luaL_error (L, "entity '%s' is already registered", name);
	lua_pop (L, 1);

	lua_pushvalue (L, 2);
	lua_setfield (L, -2, name);
	lua_pop (L, 1);
	return 0;
}

// Raises an object error without returning or changing the stack first.
// [-0, +0]
static int LP_ObjectError (lua_State *L)
{
	const char *message = luaL_checkstring (L, -1);
	return luaL_error (L, "%s", message);
}

static const luaL_Reg lp_quake_functions[] = {
	{"bind_builtin", LP_BindBuiltin},
	{"object_error", LP_ObjectError},
	{"register_function", LP_RegisterFunction},
	{"register_entity", LP_RegisterEntity},
	{"time", LP_Time},
	{"vec3", LP_Vec3},
	{NULL, NULL}};

// Creates and pushes the quake module.
// [-0, +1]
static int LP_OpenQuake (lua_State *L)
{
	luaL_newlib (L, lp_quake_functions);

	lua_newtable (L);
	lua_newtable (L);
	lua_pushcfunction (L, LP_GlobalsIndex);
	lua_setfield (L, -2, "__index");
	lua_pushcfunction (L, LP_GlobalsNewIndex);
	lua_setfield (L, -2, "__newindex");
	lua_setmetatable (L, -2);
	lua_setfield (L, -2, "globals");

	LP_PushEntityNumber (L, 0, true);
	lua_setfield (L, -2, "world");
	return 1;
}

// Loads a game module, pushes its chunk or an error message.
// [-0, +1]
static int LP_ModuleSearcher (lua_State *L)
{
	const char *module = luaL_checkstring (L, 1);
	char		path[MAX_OSPATH];
	byte	   *source;
	int			status;
	size_t		i, prefix = !strncmp (module, "game.", 5) ? 5 : 0;

	q_snprintf (path, sizeof (path), "lua/%s.lua", module + prefix);
	for (i = 4; i < strlen (path) - 4; ++i)
		if (path[i] == '.')
			path[i] = '/';
	source = COM_LoadFile (path, NULL);
	if (!source)
	{
		lua_pushfstring (L, "\n\tno game module '%s'", path);
		return 1;
	}
	status = luaL_loadbuffer (L, (const char *)source, com_filesize, path);
	Mem_Free (source);
	if (status != LUA_OK)
		return lua_error (L);
	return 1;
}

// Creates the entity and vector metatables.
// [-0, +0]
static void LP_CreateMetatables (lua_State *L)
{
	luaL_newmetatable (L, LP_ENTITY_META);
	lua_pushcfunction (L, LP_EntityIndex);
	lua_setfield (L, -2, "__index");
	lua_pushcfunction (L, LP_EntityNewIndex);
	lua_setfield (L, -2, "__newindex");
	lua_pushcfunction (L, LP_EntityEq);
	lua_setfield (L, -2, "__eq");
	lua_pushcfunction (L, LP_EntityToString);
	lua_setfield (L, -2, "__tostring");
	lua_pop (L, 1);

	luaL_newmetatable (L, LP_VECTOR_META);
	lua_pushcfunction (L, LP_VectorIndex);
	lua_setfield (L, -2, "__index");
	lua_pushcfunction (L, LP_VectorNewIndex);
	lua_setfield (L, -2, "__newindex");
	lua_pushcfunction (L, LP_VectorAdd);
	lua_setfield (L, -2, "__add");
	lua_pushcfunction (L, LP_VectorSub);
	lua_setfield (L, -2, "__sub");
	lua_pushcfunction (L, LP_VectorMul);
	lua_setfield (L, -2, "__mul");
	lua_pushcfunction (L, LP_VectorUnm);
	lua_setfield (L, -2, "__unm");
	lua_pushcfunction (L, LP_VectorEq);
	lua_setfield (L, -2, "__eq");
	lua_pushcfunction (L, LP_VectorToString);
	lua_setfield (L, -2, "__tostring");
	lua_pushcfunction (L, LP_VectorLength);
	lua_setfield (L, -2, "length");
	lua_pushcfunction (L, LP_VectorNormalized);
	lua_setfield (L, -2, "normalized");
	lua_pushcfunction (L, LP_VectorDot);
	lua_setfield (L, -2, "dot");
	lua_pop (L, 1);
}

// Loads the game definition schema, returning whether one exists.
qboolean LP_LoadDefs (void)
{
	static const char path[] = "lua/defs.lua";
	lua_State		 *L;
	byte			 *source;
	int				  status;

	LP_ClearDefs ();
	source = COM_LoadFile (path, NULL);
	if (!source)
		return false;

	L = luaL_newstate ();
	if (!L)
		Host_Error ("Could not create Lua state for %s", path);
	status = luaL_loadbuffer (L, (const char *)source, com_filesize, path);
	Mem_Free (source);
	if (status == LUA_OK)
		status = lua_pcall (L, 0, 2, 0);
	if (status != LUA_OK)
		Host_Error ("Lua progs loading %s: %s", path, lua_tostring (L, -1));
	if (!lua_istable (L, 1) || !lua_istable (L, 2))
		Host_Error ("Lua progs %s must return global and entity field tables", path);

	LP_ReadDefsTable (L, 1, "global", &lp_global_defs, &lp_num_global_defs);
	LP_ReadDefsTable (L, 2, "entity field", &lp_field_defs, &lp_num_field_defs);
	lua_close (L);

	// Lua does not specify table iteration order. Sort for stable VM offsets.
	if (lp_num_global_defs > 1)
		qsort (lp_global_defs, lp_num_global_defs, sizeof (*lp_global_defs), LP_CompareDefs);
	if (lp_num_field_defs > 1)
		qsort (lp_field_defs, lp_num_field_defs, sizeof (*lp_field_defs), LP_CompareDefs);
	Con_DPrintf ("Loaded %s (%u globals, %u entity fields)\n", path, (unsigned)lp_num_global_defs, (unsigned)lp_num_field_defs);
	return true;
}

static void LP_ClearDefs (void)
{
	size_t i;
	for (i = 0; i < lp_num_global_defs; ++i)
		Mem_Free (lp_global_defs[i].name);
	for (i = 0; i < lp_num_field_defs; ++i)
		Mem_Free (lp_field_defs[i].name);
	Mem_Free (lp_global_defs);
	Mem_Free (lp_field_defs);
	lp_global_defs = NULL;
	lp_num_global_defs = 0;
	lp_field_defs = NULL;
	lp_num_field_defs = 0;
}

static int LP_CompareDefs (const void *left, const void *right)
{
	const lp_def_t *a = left, *b = right;
	return strcmp (a->name, b->name);
}

static qboolean LP_IsBooleanDef (lua_State *L, const ddef_t *definition)
{
	qboolean boolean;
	lua_rawgeti (L, LUA_REGISTRYINDEX, lp_boolean_defs_ref);
	lua_pushlightuserdata (L, (void *)definition);
	lua_rawget (L, -2);
	boolean = lua_toboolean (L, -1);
	lua_pop (L, 2);
	return boolean;
}

static void LP_ReadDefsTable (lua_State *L, int index, const char *description, lp_def_t **defs, size_t *numdefs)
{
	index = lua_absindex (L, index);
	lua_pushnil (L);
	while (lua_next (L, index))
	{
		const char *name, *type;
		qboolean	boolean;
		if (lua_type (L, -2) != LUA_TSTRING || lua_type (L, -1) != LUA_TSTRING)
			Host_Error ("Lua progs %s definitions must map names to type strings", description);
		name = lua_tostring (L, -2);
		type = lua_tostring (L, -1);
		if (!name[0])
			Host_Error ("Lua progs %s definition has an empty name", description);
		*defs = Mem_Realloc (*defs, (*numdefs + 1) * sizeof (**defs));
		(*defs)[*numdefs].name = q_strdup (name);
		(*defs)[*numdefs].type = LP_ReadDefType (name, type, &boolean);
		(*defs)[*numdefs].boolean = boolean;
		(*numdefs)++;
		lua_pop (L, 1);
	}
}

static etype_t LP_ReadDefType (const char *name, const char *type, qboolean *boolean)
{
	*boolean = false;
	if (!strcmp (type, "bool"))
	{
		*boolean = true;
		return ev_float;
	}
	if (!strcmp (type, "float"))
		return ev_float;
	if (!strcmp (type, "string"))
		return ev_string;
	if (!strcmp (type, "vector"))
		return ev_vector;
	if (!strcmp (type, "entity"))
		return ev_entity;
	if (!strcmp (type, "function"))
		return ev_function;
	Host_Error ("Lua progs definition '%s' has unknown type '%s'", name, type);
	return ev_bad;
}

static void LP_ResolveBooleanDefs (lua_State *L)
{
	size_t i;
	lua_newtable (L);
	for (i = 0; i < countof (lp_boolean_globals); ++i)
	{
		ddef_t *definition = ED_FindGlobal (lp_boolean_globals[i]);
		if (!definition || (definition->type & ~DEF_SAVEGLOBAL) != ev_float)
			Host_Error ("Lua progs global '%s' is not a float", lp_boolean_globals[i]);
		lua_pushlightuserdata (L, definition);
		lua_pushboolean (L, true);
		lua_rawset (L, -3);
	}
	for (i = 0; i < countof (lp_boolean_fields); ++i)
	{
		ddef_t *definition = ED_FindField (lp_boolean_fields[i]);
		if (!definition || (definition->type & ~DEF_SAVEGLOBAL) != ev_float)
			Host_Error ("Lua progs entity field '%s' is not a float", lp_boolean_fields[i]);
		lua_pushlightuserdata (L, definition);
		lua_pushboolean (L, true);
		lua_rawset (L, -3);
	}
	for (i = 0; i < lp_num_global_defs; ++i)
	{
		ddef_t *definition;
		if (!lp_global_defs[i].boolean)
			continue;
		definition = ED_FindGlobal (lp_global_defs[i].name);
		if (!definition)
			Host_Error ("Lua progs global '%s' was not added to progs.dat", lp_global_defs[i].name);
		lua_pushlightuserdata (L, definition);
		lua_pushboolean (L, true);
		lua_rawset (L, -3);
	}
	for (i = 0; i < lp_num_field_defs; ++i)
	{
		ddef_t *definition;
		if (!lp_field_defs[i].boolean)
			continue;
		definition = ED_FindField (lp_field_defs[i].name);
		if (!definition)
			Host_Error ("Lua progs entity field '%s' was not added to progs.dat", lp_field_defs[i].name);
		lua_pushlightuserdata (L, definition);
		lua_pushboolean (L, true);
		lua_rawset (L, -3);
	}
	lp_boolean_defs_ref = luaL_ref (L, LUA_REGISTRYINDEX);
}

// Rewrites the loaded progs.dat image to include the Lua definitions, leaving
// it indistinguishable from an image compiled with them. Runs before the engine
// byte-swaps the lumps or derives any state from them, so appended records are
// written in file (little-endian) byte order.
void LP_SupplementProgs (void)
{
	dprograms_t *oldprogs = qcvm->progs, *progs;
	ddef_t		*newglobaldefs, *newfielddefs, *definition;
	int			 ofs_globaldefs, ofs_fielddefs, ofs_strings, ofs_globals, size;
	int			 addedglobaldefs = 0, addedglobals = 0, addedfielddefs = 0, addedfields = 0, addedstrings = 0;
	size_t		 i;

	if (qcvm != &sv.qcvm || (!lp_num_global_defs && !lp_num_field_defs))
		return;

	// Validate the definitions against the original image, mark pre-existing
	// globals for saving, and count the records to append.
	for (i = 0; i < lp_num_global_defs; ++i)
	{
		definition = LP_FindFileDef (oldprogs, oldprogs->ofs_globaldefs, oldprogs->numglobaldefs, lp_global_defs[i].name);
		if (definition)
		{
			if (((unsigned short)LittleShort (definition->type) & ~DEF_SAVEGLOBAL) != lp_global_defs[i].type)
				Host_Error ("Global '%s' is already defined with a different type", lp_global_defs[i].name);
			definition->type = LittleShort ((unsigned short)LittleShort (definition->type) | DEF_SAVEGLOBAL);
			continue;
		}
		addedglobaldefs++;
		addedglobals += type_size[lp_global_defs[i].type];
		addedstrings += strlen (lp_global_defs[i].name) + 1;
	}
	for (i = 0; i < lp_num_field_defs; ++i)
	{
		unsigned int component;
		definition = LP_FindFileDef (oldprogs, oldprogs->ofs_fielddefs, oldprogs->numfielddefs, lp_field_defs[i].name);
		if (definition)
		{
			if (((unsigned short)LittleShort (definition->type) & ~DEF_SAVEGLOBAL) != lp_field_defs[i].type)
				Host_Error ("Entity field '%s' is already defined with a different type", lp_field_defs[i].name);
			continue;
		}
		addedfielddefs++;
		addedfields += type_size[lp_field_defs[i].type];
		addedstrings += strlen (lp_field_defs[i].name) + 1;
		if (lp_field_defs[i].type == ev_vector)
		{
			for (component = 0; component < 3; ++component)
			{
				const char *name = va ("%s_%c", lp_field_defs[i].name, 'x' + component);
				if (LP_FindFileDef (oldprogs, oldprogs->ofs_fielddefs, oldprogs->numfielddefs, name) || LP_HasDef (lp_field_defs, lp_num_field_defs, name))
					Host_Error ("Entity field '%s' conflicts with vector '%s'", name, lp_field_defs[i].name);
				addedfielddefs++;
				addedstrings += strlen (name) + 1;
			}
		}
	}
	if (!addedglobaldefs && !addedfielddefs)
		return;
	if (addedglobals > USHRT_MAX + 1 - oldprogs->numglobals || addedfields > USHRT_MAX + 1 - oldprogs->entityfields)
		Host_Error ("Lua progs definitions exceed progs.dat limits");

	// Extended copies of the affected lumps go after the original image, whose
	// stale lump bytes become dead space. The globals lump comes last so that
	// the strings lump ends strictly inside the image.
	ofs_globaldefs = (qcvm->progssize + 3) & ~3;
	ofs_fielddefs = ofs_globaldefs + (oldprogs->numglobaldefs + addedglobaldefs) * sizeof (ddef_t);
	ofs_strings = ofs_fielddefs + (oldprogs->numfielddefs + addedfielddefs) * sizeof (ddef_t);
	ofs_globals = (ofs_strings + oldprogs->numstrings + addedstrings + 3) & ~3;
	size = ofs_globals + (oldprogs->numglobals + addedglobals) * sizeof (float);

	progs = Mem_Alloc (size); // zero-initialized: the appended globals read as zero
	memcpy (progs, oldprogs, qcvm->progssize);
	memcpy ((byte *)progs + ofs_globaldefs, (byte *)oldprogs + oldprogs->ofs_globaldefs, oldprogs->numglobaldefs * sizeof (ddef_t));
	memcpy ((byte *)progs + ofs_fielddefs, (byte *)oldprogs + oldprogs->ofs_fielddefs, oldprogs->numfielddefs * sizeof (ddef_t));
	memcpy ((byte *)progs + ofs_strings, (byte *)oldprogs + oldprogs->ofs_strings, oldprogs->numstrings);
	memcpy ((byte *)progs + ofs_globals, (byte *)oldprogs + oldprogs->ofs_globals, oldprogs->numglobals * sizeof (float));
	progs->ofs_globaldefs = ofs_globaldefs;
	progs->ofs_fielddefs = ofs_fielddefs;
	progs->ofs_strings = ofs_strings;
	progs->ofs_globals = ofs_globals;

	newglobaldefs = (ddef_t *)((byte *)progs + ofs_globaldefs);
	for (i = 0; i < lp_num_global_defs; ++i)
	{
		if (LP_FindFileDef (progs, ofs_globaldefs, progs->numglobaldefs, lp_global_defs[i].name))
			continue;
		definition = &newglobaldefs[progs->numglobaldefs++];
		definition->type = LittleShort (lp_global_defs[i].type | DEF_SAVEGLOBAL);
		definition->ofs = LittleShort (progs->numglobals);
		definition->s_name = LittleLong (LP_AppendString (progs, lp_global_defs[i].name));
		progs->numglobals += type_size[lp_global_defs[i].type];
	}

	newfielddefs = (ddef_t *)((byte *)progs + ofs_fielddefs);
	for (i = 0; i < lp_num_field_defs; ++i)
	{
		unsigned int component;
		const int	 offset = progs->entityfields;
		if (LP_FindFileDef (progs, ofs_fielddefs, progs->numfielddefs, lp_field_defs[i].name))
			continue;
		definition = &newfielddefs[progs->numfielddefs++];
		definition->type = LittleShort (lp_field_defs[i].type);
		definition->ofs = LittleShort (offset);
		definition->s_name = LittleLong (LP_AppendString (progs, lp_field_defs[i].name));
		progs->entityfields += type_size[lp_field_defs[i].type];
		for (component = 0; lp_field_defs[i].type == ev_vector && component < 3; ++component)
		{
			definition = &newfielddefs[progs->numfielddefs++];
			definition->type = LittleShort (ev_float);
			definition->ofs = LittleShort (offset + component);
			definition->s_name = LittleLong (LP_AppendString (progs, va ("%s_%c", lp_field_defs[i].name, 'x' + component)));
		}
	}

	Mem_Free (oldprogs);
	qcvm->progs = progs;
	qcvm->progssize = size;
	Con_DPrintf ("Lua progs extended progs.dat (%d globals, %d entity fields)\n", addedglobaldefs, addedfielddefs);
}

// Finds a definition by name in a file-endian lump of the progs image.
static ddef_t *LP_FindFileDef (dprograms_t *progs, int lumpofs, int count, const char *name)
{
	ddef_t	   *definitions = (ddef_t *)((byte *)progs + lumpofs);
	const char *strings = (const char *)progs + progs->ofs_strings;
	int			i;
	for (i = 0; i < count; ++i)
		if (!strcmp (strings + LittleLong (definitions[i].s_name), name))
			return &definitions[i];
	return NULL;
}

static qboolean LP_HasDef (const lp_def_t *definitions, size_t count, const char *name)
{
	size_t i;
	for (i = 0; i < count; ++i)
		if (!strcmp (definitions[i].name, name))
			return true;
	return false;
}

// Appends a name to the strings lump of the extended image, returning its offset.
static int LP_AppendString (dprograms_t *progs, const char *name)
{
	const int ofs = progs->numstrings;
	const int length = strlen (name) + 1;
	memcpy ((byte *)progs + progs->ofs_strings + ofs, name, length);
	progs->numstrings += length;
	return ofs;
}

// Creates and initializes the global Lua state, returning success with its stack unchanged.
qboolean LP_Init (void)
{
	int searchers;
	if (lp_state)
		LP_Shutdown ();
	if (!COM_FileExists ("lua/init.lua", NULL))
		return false;
	lp_state = luaL_newstate ();
	if (!lp_state)
		Host_Error ("Could not create Lua state");
	luaL_openlibs (lp_state);
	LP_CreateMetatables (lp_state);
	LP_ResolveBooleanDefs (lp_state);
	luaL_requiref (lp_state, "quake", LP_OpenQuake, 1);
	lua_pop (lp_state, 1);

	lua_getglobal (lp_state, "package");
	lua_getfield (lp_state, -1, "searchers");
	searchers = lua_gettop (lp_state);
	lua_pushcfunction (lp_state, LP_ModuleSearcher);
	lua_rawseti (lp_state, searchers, (lua_Integer)lua_rawlen (lp_state, searchers) + 1);
	lua_pop (lp_state, 2);

	lua_newtable (lp_state);
	lp_spawns_ref = luaL_ref (lp_state, LUA_REGISTRYINDEX);
	lua_newtable (lp_state);
	lp_functions_ref = luaL_ref (lp_state, LUA_REGISTRYINDEX);
	lua_newtable (lp_state);
	lp_function_names_ref = luaL_ref (lp_state, LUA_REGISTRYINDEX);
	lua_getglobal (lp_state, "require");
	lua_pushstring (lp_state, "game.init");
	if (LP_PCall (lp_state, 1, 1) != LUA_OK)
		LP_Error ("loading game.init");

	lua_pop (lp_state, 1);
	lp_active = true;
	Con_Printf ("Lua progs initialized\n");
	return true;
}

// Closes the global Lua state.
void LP_Shutdown (void)
{
	if (lp_state)
		lua_close (lp_state);
	lp_state = NULL;
	lp_spawns_ref = LUA_NOREF;
	lp_boolean_defs_ref = LUA_NOREF;
	lp_functions_ref = LUA_NOREF;
	lp_function_names_ref = LUA_NOREF;
	lp_active = false;
	LP_ClearDefs ();
}

// Calls a stored Lua function, returning whether it handled the function with
// the global stack unchanged.
qboolean LP_ExecuteProgram (func_t function)
{
	if (!lp_active || (int)function >= 0)
		return false;
	lua_rawgeti (lp_state, LUA_REGISTRYINDEX, -(int)function);
	LP_PushEntity (lp_state, PROG_TO_EDICT (pr_global_struct->self), true);
	LP_PushEntity (lp_state, PROG_TO_EDICT (pr_global_struct->other), true);
	if (LP_PCall (lp_state, 2, 0) != LUA_OK)
		LP_Error ("executing function");
	return true;
}

// Calls a registered Lua spawn function, returning whether one was found with
// the global stack unchanged.
qboolean LP_CallSpawn (const char *classname, edict_t *entity)
{
	if (!lp_active)
		return false;
	lua_rawgeti (lp_state, LUA_REGISTRYINDEX, lp_spawns_ref);
	lua_getfield (lp_state, -1, classname);
	lua_remove (lp_state, -2);
	if (!lua_isfunction (lp_state, -1))
	{
		lua_pop (lp_state, 1);
		return false;
	}
	LP_PushEntity (lp_state, entity, true);
	if (LP_PCall (lp_state, 1, 0) != LUA_OK)
		LP_Error ("spawning entity");
	return true;
}
