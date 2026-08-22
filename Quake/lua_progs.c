/*
Copyright (C) 2026 vkQuake contributors

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License.
*/

#include "quakedef.h"

#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>

#define LP_ENTITY_META "vkquake.entity"
#define LP_VECTOR_META "vkquake.vec3"

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
	char (*names)[16];
	int		 count;
	qboolean loaded;
} lp_frame_names_t;

static lua_State	   *lp_state;
static int				lp_spawns_ref = LUA_NOREF;
static int				lp_entity_values_ref = LUA_NOREF;
static int				lp_global_values_ref = LUA_NOREF;
static lp_frame_names_t lp_frame_names[MAX_MODELS];
static qboolean			lp_active;

static int	LP_EntityIndex (lua_State *L);
static int	LP_EntityNewIndex (lua_State *L);
static int	LP_CallQC (lua_State *L);
static int	LP_GlobalsIndex (lua_State *L);
static int	LP_GlobalsNewIndex (lua_State *L);
static void LP_SetParmFloat (int parm, float value);
static void LP_SetParmString (lua_State *L, int parm, int index);
static void LP_RunBuiltin (int number, int argc);

static void LP_Error (const char *context)
{
	const char *message = lua_tostring (lp_state, -1);
	Host_Error ("Lua progs %s: %s", context, message ? message : "unknown error");
}

static int LP_StoreFunction (lua_State *L, int index)
{
	lua_pushvalue (L, index);
	return -luaL_ref (L, LUA_REGISTRYINDEX);
}

static void LP_PushEntityNumber (lua_State *L, int number, qboolean allow_world)
{
	lp_entity_t *value;

	if (number == 0 && !allow_world)
	{
		lua_pushnil (L);
		return;
	}
	if (number < 0 || number >= qcvm->num_edicts)
	{
		lua_pushnil (L);
		return;
	}

	value = lua_newuserdatauv (L, sizeof (*value), 0);
	value->number = number;
	luaL_setmetatable (L, LP_ENTITY_META);
}

static void LP_PushEntity (lua_State *L, edict_t *entity, qboolean allow_world)
{
	LP_PushEntityNumber (L, NUM_FOR_EDICT (entity), allow_world);
}

static edict_t *LP_CheckEntity (lua_State *L, int index)
{
	lp_entity_t *value = luaL_checkudata (L, index, LP_ENTITY_META);
	if (value->number < 0 || value->number >= qcvm->num_edicts)
		luaL_error (L, "invalid entity %d", value->number);
	return EDICT_NUM (value->number);
}

static void LP_PushVector (lua_State *L, float *value)
{
	lp_vector_t *vector = lua_newuserdatauv (L, sizeof (*vector), 0);
	vector->value = value;
	luaL_setmetatable (L, LP_VECTOR_META);
}

static void LP_PushOwnedVector (lua_State *L, float x, float y, float z)
{
	lp_vector_t *vector = lua_newuserdatauv (L, sizeof (*vector), 0);
	vector->owned[0] = x;
	vector->owned[1] = y;
	vector->owned[2] = z;
	vector->value = vector->owned;
	luaL_setmetatable (L, LP_VECTOR_META);
}

static lp_vector_t *LP_CheckVector (lua_State *L, int index)
{
	return luaL_checkudata (L, index, LP_VECTOR_META);
}

static void LP_CopyVector (lua_State *L, int index, float *destination)
{
	lp_vector_t *vector = LP_CheckVector (L, index);
	VectorCopy (vector->value, destination);
}

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

static int LP_VectorAdd (lua_State *L)
{
	return LP_VectorBinary (L, 0);
}
static int LP_VectorSub (lua_State *L)
{
	return LP_VectorBinary (L, 1);
}

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

static int LP_VectorUnm (lua_State *L)
{
	lp_vector_t *vector = LP_CheckVector (L, 1);
	LP_PushOwnedVector (L, -vector->value[0], -vector->value[1], -vector->value[2]);
	return 1;
}

static int LP_VectorEq (lua_State *L)
{
	lp_vector_t *a = LP_CheckVector (L, 1), *b = LP_CheckVector (L, 2);
	lua_pushboolean (L, VectorCompare (a->value, b->value));
	return 1;
}

static int LP_VectorLength (lua_State *L)
{
	lua_pushnumber (L, VectorLength (LP_CheckVector (L, 1)->value));
	return 1;
}

static int LP_VectorNormalized (lua_State *L)
{
	vec3_t value;
	VectorCopy (LP_CheckVector (L, 1)->value, value);
	VectorNormalize (value);
	LP_PushOwnedVector (L, value[0], value[1], value[2]);
	return 1;
}

static int LP_VectorDot (lua_State *L)
{
	lp_vector_t *a = LP_CheckVector (L, 1), *b = LP_CheckVector (L, 2);
	lua_pushnumber (L, DotProduct (a->value, b->value));
	return 1;
}

static int LP_VectorToString (lua_State *L)
{
	lp_vector_t *vector = LP_CheckVector (L, 1);
	lua_pushfstring (L, "'%f %f %f'", vector->value[0], vector->value[1], vector->value[2]);
	return 1;
}

static int LP_EntityEq (lua_State *L)
{
	lp_entity_t *a = luaL_checkudata (L, 1, LP_ENTITY_META), *b = luaL_checkudata (L, 2, LP_ENTITY_META);
	lua_pushboolean (L, a->number == b->number);
	return 1;
}

static int LP_EntityToString (lua_State *L)
{
	lp_entity_t *entity = luaL_checkudata (L, 1, LP_ENTITY_META);
	lua_pushfstring (L, "entity %d", entity->number);
	return 1;
}

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

static void LP_PushValue (lua_State *L, int type, eval_t *value, qboolean allow_world)
{
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

static int LP_CopyString (lua_State *L, int index)
{
	const char *source = luaL_checkstring (L, index);
	char	   *destination;
	int			result = PR_AllocString ((int)strlen (source) + 1, &destination);
	q_strlcpy (destination, source, strlen (source) + 1);
	return result;
}

static void LP_SetValue (lua_State *L, int index, int type, eval_t *value)
{
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
			value->function = 0;
		else
		{
			luaL_checktype (L, index, LUA_TFUNCTION);
			value->function = LP_StoreFunction (L, index);
		}
		break;
	default:
		luaL_error (L, "unsupported QuakeC value type %d", type);
		break;
	}
}

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

static void LP_PushEntityValues (lua_State *L, int number)
{
	lua_rawgeti (L, LUA_REGISTRYINDEX, lp_entity_values_ref);
	lua_rawgeti (L, -1, number + 1);
	if (lua_isnil (L, -1))
	{
		lua_pop (L, 1);
		lua_newtable (L);
		lua_pushvalue (L, -1);
		lua_rawseti (L, -3, number + 1);
	}
	lua_remove (L, -2);
}

static int LP_EntityIndex (lua_State *L)
{
	edict_t	   *entity = LP_CheckEntity (L, 1);
	const char *name = luaL_checkstring (L, 2);
	ddef_t	   *field = ED_FindField (name);
	if (!field)
	{
		LP_PushEntityValues (L, NUM_FOR_EDICT (entity));
		lua_getfield (L, -1, name);
		lua_remove (L, -2);
		return 1;
	}
	LP_PushValue (L, field->type, (eval_t *)((float *)&entity->v + field->ofs), false);
	return 1;
}

static void LP_LoadFrameNames (int modelindex, qmodel_t *model)
{
	lp_frame_names_t *cache = &lp_frame_names[modelindex];
	byte			 *data, *cursor;
	mdl_t			 *header;
	int				  numskins, skinwidth, skinheight, numverts, numtris, numframes;
	int				  i;

	cache->loaded = true;
	data = COM_LoadFile (model->name, NULL);
	if (!data)
		return;
	header = (mdl_t *)data;
	if (LittleLong (header->ident) != IDPOLYHEADER || LittleLong (header->version) != ALIAS_VERSION)
	{
		Mem_Free (data);
		return;
	}

	numskins = LittleLong (header->numskins);
	skinwidth = LittleLong (header->skinwidth);
	skinheight = LittleLong (header->skinheight);
	numverts = LittleLong (header->numverts);
	numtris = LittleLong (header->numtris);
	numframes = LittleLong (header->numframes);
	if (numskins < 0 || skinwidth < 1 || skinheight < 1 || numverts < 1 || numtris < 0 || numframes < 1 || numframes > MAXALIASFRAMES)
	{
		Mem_Free (data);
		return;
	}

	cursor = data + sizeof (*header);
	for (i = 0; i < numskins; ++i)
	{
		const int type = LittleLong (((daliasskintype_t *)cursor)->type);
		cursor += sizeof (daliasskintype_t);
		if (type == ALIAS_SKIN_SINGLE)
			cursor += skinwidth * skinheight;
		else
		{
			const int count = LittleLong (((daliasskingroup_t *)cursor)->numskins);
			cursor += sizeof (daliasskingroup_t) + count * sizeof (daliasskininterval_t) + count * skinwidth * skinheight;
		}
	}
	cursor += numverts * sizeof (stvert_t) + numtris * sizeof (dtriangle_t);

	cache->names = Mem_Alloc (numframes * sizeof (*cache->names));
	cache->count = numframes;
	for (i = 0; i < numframes; ++i)
	{
		const int type = LittleLong (((daliasframetype_t *)cursor)->type);
		cursor += sizeof (daliasframetype_t);
		if (type == ALIAS_SINGLE)
		{
			daliasframe_t *frame = (daliasframe_t *)cursor;
			memcpy (cache->names[i], frame->name, sizeof (cache->names[i]));
			cache->names[i][sizeof (cache->names[i]) - 1] = '\0';
			cursor = (byte *)(frame + 1) + numverts * sizeof (trivertx_t);
		}
		else
		{
			daliasgroup_t *group = (daliasgroup_t *)cursor;
			const int	   count = LittleLong (group->numframes);
			daliasframe_t *frame = (daliasframe_t *)((byte *)(group + 1) + count * sizeof (daliasinterval_t));
			int			   j;
			memcpy (cache->names[i], frame->name, sizeof (cache->names[i]));
			cache->names[i][sizeof (cache->names[i]) - 1] = '\0';
			for (j = 0; j < count; ++j)
				frame = (daliasframe_t *)((byte *)(frame + 1) + numverts * sizeof (trivertx_t));
			cursor = (byte *)frame;
		}
	}
	Mem_Free (data);
}

static int LP_FrameForName (edict_t *entity, const char *name)
{
	const int	modelindex = entity->v.modelindex;
	qmodel_t   *model = qcvm->GetModel (modelindex);
	aliashdr_t *alias;
	int			i;

	if (!model || model->type != mod_alias || !(alias = Mod_Extradata (model)))
		return -1;
	for (i = 0; i < alias->numframes; ++i)
		if (!strcmp (alias->frames[i].name, name))
			return i;

	/* Replacement MD5 animations have frame numbers but no MDL frame names. */
	if (modelindex > 0 && modelindex < MAX_MODELS)
	{
		lp_frame_names_t *cache = &lp_frame_names[modelindex];
		if (!cache->loaded)
			LP_LoadFrameNames (modelindex, model);
		for (i = 0; i < cache->count; ++i)
			if (!strcmp (cache->names[i], name))
				return i;
	}
	return -1;
}

static int LP_EntityNewIndex (lua_State *L)
{
	edict_t	   *entity = LP_CheckEntity (L, 1);
	const char *name = luaL_checkstring (L, 2);
	ddef_t	   *field = ED_FindField (name);
	if (!field)
	{
		LP_PushEntityValues (L, NUM_FOR_EDICT (entity));
		lua_pushvalue (L, 3);
		lua_setfield (L, -2, name);
		return 0;
	}
	if (!strcmp (name, "frame") && lua_type (L, 3) == LUA_TSTRING)
	{
		const char *frame = lua_tostring (L, 3);
		const int	number = LP_FrameForName (entity, frame);
		if (number < 0)
			return luaL_error (L, "model '%s' has no frame '%s'", PR_GetString (entity->v.model), frame);
		((eval_t *)((float *)&entity->v + field->ofs))->_float = number;
	}
	else
		LP_SetValue (L, 3, field->type, (eval_t *)((float *)&entity->v + field->ofs));
	return 0;
}

static int LP_GlobalsIndex (lua_State *L)
{
	const char *name = luaL_checkstring (L, 2);
	ddef_t	   *global;

	lua_rawgeti (L, LUA_REGISTRYINDEX, lp_global_values_ref);
	lua_getfield (L, -1, name);
	if (!lua_isnil (L, -1))
	{
		lua_remove (L, -2);
		return 1;
	}
	lua_pop (L, 2);

	global = ED_FindGlobal (name);
	if (!global)
		return 0;
	LP_PushValue (L, global->type, (eval_t *)&qcvm->globals[global->ofs], false);
	return 1;
}

static int LP_GlobalsNewIndex (lua_State *L)
{
	const char *name = luaL_checkstring (L, 2);
	ddef_t	   *global = ED_FindGlobal (name);
	if (!global)
	{
		lua_rawgeti (L, LUA_REGISTRYINDEX, lp_global_values_ref);
		lua_pushvalue (L, 3);
		lua_setfield (L, -2, name);
		return 0;
	}
	{
		const int	   type = global->type & ~DEF_SAVEGLOBAL;
		lp_entity_t	  *entity = type == ev_entity ? luaL_testudata (L, 3, LP_ENTITY_META) : NULL;
		const qboolean shadow = (type == ev_float && lua_isboolean (L, 3)) || (entity && entity->number == 0);

		if (type == ev_float && lua_isboolean (L, 3))
			qcvm->globals[global->ofs] = lua_toboolean (L, 3);
		else
			LP_SetValue (L, 3, global->type, (eval_t *)&qcvm->globals[global->ofs]);

		lua_rawgeti (L, LUA_REGISTRYINDEX, lp_global_values_ref);
		if (shadow)
			lua_pushvalue (L, 3);
		else
			lua_pushnil (L);
		lua_setfield (L, -2, name);
	}
	return 0;
}

static void LP_SetParmEntity (int parm, edict_t *entity)
{
	G_INT (OFS_PARM0 + parm * 3) = EDICT_TO_PROG (entity);
}
static void LP_SetParmFloat (int parm, float value)
{
	G_FLOAT (OFS_PARM0 + parm * 3) = value;
}
static void LP_SetParmString (lua_State *L, int parm, int index)
{
	G_INT (OFS_PARM0 + parm * 3) = LP_CopyString (L, index);
}
static void LP_SetParmVector (lua_State *L, int parm, int index)
{
	LP_CopyVector (L, index, G_VECTOR (OFS_PARM0 + parm * 3));
}
static void LP_RunBuiltin (int number, int argc)
{
	const int previous_argc = qcvm->argc;
	if (number >= qcvm->numbuiltins || !qcvm->builtins[number])
		Host_Error ("Lua progs: builtin #%d is unavailable", number);
	qcvm->argc = argc;
	qcvm->builtins[number]();
	qcvm->argc = previous_argc;
}

static int LP_Time (lua_State *L)
{
	lua_pushnumber (L, qcvm->time);
	return 1;
}
static int LP_Random (lua_State *L)
{
	LP_RunBuiltin (7, 0);
	lua_pushnumber (L, G_FLOAT (OFS_RETURN));
	return 1;
}
static int LP_CRandom (lua_State *L)
{
	LP_RunBuiltin (7, 0);
	lua_pushnumber (L, G_FLOAT (OFS_RETURN) * 2 - 1);
	return 1;
}

static int LP_Vec3 (lua_State *L)
{
	LP_PushOwnedVector (L, luaL_checknumber (L, 1), luaL_checknumber (L, 2), luaL_checknumber (L, 3));
	return 1;
}

static int LP_SetOrigin (lua_State *L)
{
	LP_SetParmEntity (0, LP_CheckEntity (L, 1));
	LP_SetParmVector (L, 1, 2);
	LP_RunBuiltin (2, 2);
	return 0;
}
static int LP_SetModel (lua_State *L)
{
	LP_SetParmEntity (0, LP_CheckEntity (L, 1));
	LP_SetParmString (L, 1, 2);
	LP_RunBuiltin (3, 2);
	return 0;
}
static int LP_SetSize (lua_State *L)
{
	LP_SetParmEntity (0, LP_CheckEntity (L, 1));
	LP_SetParmVector (L, 1, 2);
	LP_SetParmVector (L, 2, 3);
	LP_RunBuiltin (4, 3);
	return 0;
}

static int LP_Sound (lua_State *L)
{
	LP_SetParmEntity (0, LP_CheckEntity (L, 1));
	LP_SetParmFloat (1, luaL_checknumber (L, 2));
	LP_SetParmString (L, 2, 3);
	LP_SetParmFloat (3, luaL_checknumber (L, 4));
	LP_SetParmFloat (4, luaL_checknumber (L, 5));
	LP_RunBuiltin (8, 5);
	return 0;
}

static int LP_Spawn (lua_State *L)
{
	LP_RunBuiltin (14, 0);
	LP_PushEntity (L, G_EDICT (OFS_RETURN), false);
	return 1;
}
static int LP_Remove (lua_State *L)
{
	LP_SetParmEntity (0, LP_CheckEntity (L, 1));
	LP_RunBuiltin (15, 1);
	return 0;
}
static int LP_CheckClient (lua_State *L)
{
	LP_RunBuiltin (17, 0);
	LP_PushEntity (L, G_EDICT (OFS_RETURN), false);
	return 1;
}

static int LP_TraceLine (lua_State *L)
{
	LP_SetParmVector (L, 0, 1);
	LP_SetParmVector (L, 1, 2);
	LP_SetParmFloat (2, lua_toboolean (L, 3));
	LP_SetParmEntity (3, LP_CheckEntity (L, 4));
	LP_RunBuiltin (16, 4);
	lua_createtable (L, 0, 8);
	lua_pushnumber (L, pr_global_struct->trace_fraction);
	lua_setfield (L, -2, "fraction");
	lua_pushboolean (L, pr_global_struct->trace_inopen);
	lua_setfield (L, -2, "in_open");
	lua_pushboolean (L, pr_global_struct->trace_inwater);
	lua_setfield (L, -2, "in_water");
	LP_PushEntity (L, PROG_TO_EDICT (pr_global_struct->trace_ent), true);
	lua_setfield (L, -2, "entity");
	LP_PushVector (L, pr_global_struct->trace_endpos);
	lua_setfield (L, -2, "endpos");
	LP_PushVector (L, pr_global_struct->trace_plane_normal);
	lua_setfield (L, -2, "plane_normal");
	return 1;
}

static int LP_Find (lua_State *L)
{
	ddef_t	*field;
	edict_t *cursor = lua_isnil (L, 1) ? qcvm->edicts : LP_CheckEntity (L, 1);

	/* QuakeC permits find() to continue from an entity removed in the loop body. */
	G_INT (OFS_PARM0) = (int)((byte *)cursor - (byte *)qcvm->edicts);
	field = ED_FindField (luaL_checkstring (L, 2));
	if (!field)
		return luaL_error (L, "unknown find field");
	G_INT (OFS_PARM1) = field->ofs;
	LP_SetParmString (L, 2, 3);
	LP_RunBuiltin (18, 3);
	LP_PushEntity (L, G_EDICT (OFS_RETURN), false);
	return 1;
}

static int LP_StringBuiltin (lua_State *L, int number)
{
	LP_SetParmString (L, 0, 1);
	LP_RunBuiltin (number, 1);
	lua_pushstring (L, G_STRING (OFS_RETURN));
	return 1;
}
static int LP_PrecacheSound (lua_State *L)
{
	return LP_StringBuiltin (L, 19);
}
static int LP_PrecacheModel (lua_State *L)
{
	return LP_StringBuiltin (L, 20);
}
static int LP_PrecacheFile (lua_State *L)
{
	return LP_StringBuiltin (L, 68);
}
static int LP_PrecacheModel2 (lua_State *L)
{
	return LP_StringBuiltin (L, 75);
}
static int LP_PrecacheSound2 (lua_State *L)
{
	return LP_StringBuiltin (L, 76);
}
static int LP_PrecacheFile2 (lua_State *L)
{
	return LP_StringBuiltin (L, 77);
}

static int LP_EntityStringBuiltin (lua_State *L, int number)
{
	LP_SetParmEntity (0, LP_CheckEntity (L, 1));
	LP_SetParmString (L, 1, 2);
	LP_RunBuiltin (number, 2);
	return 0;
}
static int LP_StuffCmd (lua_State *L)
{
	return LP_EntityStringBuiltin (L, 21);
}
static int LP_SPrint (lua_State *L)
{
	return LP_EntityStringBuiltin (L, 24);
}
static int LP_CenterPrint (lua_State *L)
{
	return LP_EntityStringBuiltin (L, 73);
}

static int LP_PrintBuiltin (lua_State *L, int number)
{
	int i;
	for (i = 1; i <= lua_gettop (L); ++i)
	{
		luaL_tolstring (L, i, NULL);
		LP_SetParmString (L, 0, -1);
		LP_RunBuiltin (number, 1);
		lua_pop (L, 1);
	}
	return 0;
}
static int LP_BPrint (lua_State *L)
{
	return LP_PrintBuiltin (L, 23);
}
static int LP_DPrint (lua_State *L)
{
	return LP_PrintBuiltin (L, 25);
}

static int LP_FindRadius (lua_State *L)
{
	LP_SetParmVector (L, 0, 1);
	LP_SetParmFloat (1, luaL_checknumber (L, 2));
	LP_RunBuiltin (22, 2);
	LP_PushEntity (L, G_EDICT (OFS_RETURN), false);
	return 1;
}
static int LP_FloatToString (lua_State *L)
{
	LP_SetParmFloat (0, luaL_checknumber (L, 1));
	LP_RunBuiltin (26, 1);
	lua_pushstring (L, G_STRING (OFS_RETURN));
	return 1;
}
static int LP_VectorToStringBuiltin (lua_State *L)
{
	LP_SetParmVector (L, 0, 1);
	LP_RunBuiltin (27, 1);
	lua_pushstring (L, G_STRING (OFS_RETURN));
	return 1;
}

static int LP_SelfBuiltin (lua_State *L, int number, int has_float)
{
	int previous = pr_global_struct->self;
	pr_global_struct->self = EDICT_TO_PROG (LP_CheckEntity (L, 1));
	if (has_float)
		LP_SetParmFloat (0, luaL_checknumber (L, 2));
	LP_RunBuiltin (number, has_float);
	pr_global_struct->self = previous;
	return 0;
}
static int LP_ChangeYaw (lua_State *L)
{
	return LP_SelfBuiltin (L, 49, 0);
}
static int LP_MoveToGoal (lua_State *L)
{
	return LP_SelfBuiltin (L, 67, 1);
}
static int LP_DropToFloor (lua_State *L)
{
	LP_SelfBuiltin (L, 34, 0);
	lua_pushboolean (L, G_FLOAT (OFS_RETURN));
	return 1;
}
static int LP_WalkMove (lua_State *L)
{
	int old = pr_global_struct->self;
	pr_global_struct->self = EDICT_TO_PROG (LP_CheckEntity (L, 1));
	LP_SetParmFloat (0, luaL_checknumber (L, 2));
	LP_SetParmFloat (1, luaL_checknumber (L, 3));
	LP_RunBuiltin (32, 2);
	pr_global_struct->self = old;
	lua_pushboolean (L, G_FLOAT (OFS_RETURN));
	return 1;
}

static int LP_CheckBottom (lua_State *L)
{
	LP_SetParmEntity (0, LP_CheckEntity (L, 1));
	LP_RunBuiltin (40, 1);
	lua_pushboolean (L, G_FLOAT (OFS_RETURN));
	return 1;
}
static int LP_PointContents (lua_State *L)
{
	LP_SetParmVector (L, 0, 1);
	LP_RunBuiltin (41, 1);
	lua_pushnumber (L, G_FLOAT (OFS_RETURN));
	return 1;
}
static int LP_Aim (lua_State *L)
{
	LP_SetParmEntity (0, LP_CheckEntity (L, 1));
	LP_SetParmFloat (1, luaL_checknumber (L, 2));
	LP_RunBuiltin (44, 2);
	LP_PushOwnedVector (L, G_VECTOR (OFS_RETURN)[0], G_VECTOR (OFS_RETURN)[1], G_VECTOR (OFS_RETURN)[2]);
	return 1;
}
static int LP_Cvar (lua_State *L)
{
	LP_SetParmString (L, 0, 1);
	LP_RunBuiltin (45, 1);
	lua_pushnumber (L, G_FLOAT (OFS_RETURN));
	return 1;
}
static int LP_LocalCmd (lua_State *L)
{
	LP_SetParmString (L, 0, 1);
	LP_RunBuiltin (46, 1);
	return 0;
}

static int LP_Particle (lua_State *L)
{
	LP_SetParmVector (L, 0, 1);
	LP_SetParmVector (L, 1, 2);
	LP_SetParmFloat (2, luaL_checknumber (L, 3));
	LP_SetParmFloat (3, luaL_checknumber (L, 4));
	LP_RunBuiltin (48, 4);
	return 0;
}
static int LP_VectorToAngles (lua_State *L)
{
	LP_SetParmVector (L, 0, 1);
	LP_RunBuiltin (51, 1);
	LP_PushOwnedVector (L, G_VECTOR (OFS_RETURN)[0], G_VECTOR (OFS_RETURN)[1], G_VECTOR (OFS_RETURN)[2]);
	return 1;
}
static int LP_VectorToYaw (lua_State *L)
{
	LP_SetParmVector (L, 0, 1);
	LP_RunBuiltin (13, 1);
	lua_pushnumber (L, G_FLOAT (OFS_RETURN));
	return 1;
}

static int LP_WriteFloatBuiltin (lua_State *L, int number)
{
	LP_SetParmFloat (0, luaL_checknumber (L, 1));
	LP_SetParmFloat (1, luaL_checknumber (L, 2));
	LP_RunBuiltin (number, 2);
	return 0;
}
static int LP_WriteByte (lua_State *L)
{
	return LP_WriteFloatBuiltin (L, 52);
}
static int LP_WriteCoord (lua_State *L)
{
	return LP_WriteFloatBuiltin (L, 56);
}
static int LP_WriteString (lua_State *L)
{
	LP_SetParmFloat (0, luaL_checknumber (L, 1));
	LP_SetParmString (L, 1, 2);
	LP_RunBuiltin (58, 2);
	return 0;
}
static int LP_WriteEntity (lua_State *L)
{
	LP_SetParmFloat (0, luaL_checknumber (L, 1));
	LP_SetParmEntity (1, LP_CheckEntity (L, 2));
	LP_RunBuiltin (59, 2);
	return 0;
}
static int LP_MakeStatic (lua_State *L)
{
	LP_SetParmEntity (0, LP_CheckEntity (L, 1));
	LP_RunBuiltin (69, 1);
	return 0;
}
static int LP_ChangeLevel (lua_State *L)
{
	LP_SetParmString (L, 0, 1);
	LP_RunBuiltin (70, 1);
	return 0;
}
static int LP_CvarSet (lua_State *L)
{
	LP_SetParmString (L, 0, 1);
	LP_SetParmString (L, 1, 2);
	LP_RunBuiltin (72, 2);
	return 0;
}
static int LP_SetSpawnParms (lua_State *L)
{
	LP_SetParmEntity (0, LP_CheckEntity (L, 1));
	LP_RunBuiltin (78, 1);
	return 0;
}
static int LP_LightStyle (lua_State *L)
{
	LP_SetParmFloat (0, luaL_checknumber (L, 1));
	LP_SetParmString (L, 1, 2);
	LP_RunBuiltin (35, 2);
	return 0;
}
static int LP_AmbientSound (lua_State *L)
{
	LP_SetParmVector (L, 0, 1);
	LP_SetParmString (L, 1, 2);
	LP_SetParmFloat (2, luaL_checknumber (L, 3));
	LP_SetParmFloat (3, luaL_checknumber (L, 4));
	LP_RunBuiltin (74, 4);
	return 0;
}

static int LP_MakeVectors (lua_State *L)
{
	LP_SetParmVector (L, 0, 1);
	LP_RunBuiltin (1, 1);
	lua_createtable (L, 0, 3);
	LP_PushVector (L, pr_global_struct->v_forward);
	lua_setfield (L, -2, "forward");
	LP_PushVector (L, pr_global_struct->v_right);
	lua_setfield (L, -2, "right");
	LP_PushVector (L, pr_global_struct->v_up);
	lua_setfield (L, -2, "up");
	return 1;
}

static int LP_RegisterEntity (lua_State *L)
{
	const char *name = luaL_checkstring (L, 1);
	luaL_checktype (L, 2, LUA_TFUNCTION);
	lua_rawgeti (L, LUA_REGISTRYINDEX, lp_spawns_ref);
	lua_pushvalue (L, 2);
	lua_setfield (L, -2, name);
	return 0;
}

static int LP_ObjectError (lua_State *L)
{
	const char *message = luaL_checkstring (L, -1);
	return luaL_error (L, "%s", message);
}

static const luaL_Reg lp_quake_functions[] = {
	{"aim", LP_Aim},
	{"ambient_sound", LP_AmbientSound},
	{"bprint", LP_BPrint},
	{"center_print", LP_CenterPrint},
	{"change_level", LP_ChangeLevel},
	{"change_yaw", LP_ChangeYaw},
	{"check_bottom", LP_CheckBottom},
	{"check_client", LP_CheckClient},
	{"crandom", LP_CRandom},
	{"cvar", LP_Cvar},
	{"cvar_set", LP_CvarSet},
	{"dprint", LP_DPrint},
	{"drop_to_floor", LP_DropToFloor},
	{"find", LP_Find},
	{"find_radius", LP_FindRadius},
	{"float_to_string", LP_FloatToString},
	{"light_style", LP_LightStyle},
	{"local_cmd", LP_LocalCmd},
	{"make_static", LP_MakeStatic},
	{"make_vectors", LP_MakeVectors},
	{"move_to_goal", LP_MoveToGoal},
	{"object_error", LP_ObjectError},
	{"particle", LP_Particle},
	{"point_contents", LP_PointContents},
	{"precache_file", LP_PrecacheFile},
	{"precache_file2", LP_PrecacheFile2},
	{"precache_model", LP_PrecacheModel},
	{"precache_model2", LP_PrecacheModel2},
	{"precache_sound", LP_PrecacheSound},
	{"precache_sound2", LP_PrecacheSound2},
	{"random", LP_Random},
	{"register_entity", LP_RegisterEntity},
	{"remove", LP_Remove},
	{"set_model", LP_SetModel},
	{"set_origin", LP_SetOrigin},
	{"set_size", LP_SetSize},
	{"set_spawn_parms", LP_SetSpawnParms},
	{"sound", LP_Sound},
	{"spawn", LP_Spawn},
	{"sprint", LP_SPrint},
	{"stuff_cmd", LP_StuffCmd},
	{"time", LP_Time},
	{"trace_line", LP_TraceLine},
	{"vec3", LP_Vec3},
	{"vector_to_angles", LP_VectorToAngles},
	{"vector_to_string", LP_VectorToStringBuiltin},
	{"vector_to_yaw", LP_VectorToYaw},
	{"walk_move", LP_WalkMove},
	{"write_byte", LP_WriteByte},
	{"write_coord", LP_WriteCoord},
	{"write_entity", LP_WriteEntity},
	{"write_string", LP_WriteString},
	{NULL, NULL}};

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

static void LP_AssignEntry (lua_State *L, int modules, const char *module, const char *member, const char *global_name)
{
	ddef_t *global = ED_FindGlobal (global_name);
	modules = lua_absindex (L, modules);
	if (!global)
		return;
	lua_getfield (L, modules, module);
	lua_getfield (L, -1, member);
	if (!lua_isfunction (L, -1))
		Host_Error ("Lua progs: game.%s.%s is not a function", module, member);
	((eval_t *)&qcvm->globals[global->ofs])->function = LP_StoreFunction (L, -1);
	lua_pop (L, 2);
}

qboolean LP_Init (void)
{
	int searchers;
	if (lp_state)
		LP_Shutdown ();
	lp_state = luaL_newstate ();
	if (!lp_state)
		Host_Error ("Could not create Lua state");
	luaL_openlibs (lp_state);
	LP_CreateMetatables (lp_state);
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
	lp_entity_values_ref = luaL_ref (lp_state, LUA_REGISTRYINDEX);
	lua_newtable (lp_state);
	lp_global_values_ref = luaL_ref (lp_state, LUA_REGISTRYINDEX);
	lua_getglobal (lp_state, "require");
	lua_pushstring (lp_state, "game.init");
	if (lua_pcall (lp_state, 1, 1, 0) != LUA_OK)
		LP_Error ("loading game.init");

	LP_AssignEntry (lp_state, -1, "world", "main", "main");
	LP_AssignEntry (lp_state, -1, "world", "start_frame", "StartFrame");
	LP_AssignEntry (lp_state, -1, "client", "player_pre_think", "PlayerPreThink");
	LP_AssignEntry (lp_state, -1, "client", "player_post_think", "PlayerPostThink");
	LP_AssignEntry (lp_state, -1, "client", "client_kill", "ClientKill");
	LP_AssignEntry (lp_state, -1, "client", "client_connect", "ClientConnect");
	LP_AssignEntry (lp_state, -1, "client", "put_client_in_server", "PutClientInServer");
	LP_AssignEntry (lp_state, -1, "client", "client_disconnect", "ClientDisconnect");
	LP_AssignEntry (lp_state, -1, "client", "set_new_parms", "SetNewParms");
	LP_AssignEntry (lp_state, -1, "client", "set_change_parms", "SetChangeParms");
	lua_pop (lp_state, 1);
	lp_active = true;
	Con_Printf ("Lua progs initialized\n");
	return true;
}

void LP_Shutdown (void)
{
	int i;
	if (lp_state)
		lua_close (lp_state);
	for (i = 0; i < MAX_MODELS; ++i)
	{
		if (lp_frame_names[i].names)
			Mem_Free (lp_frame_names[i].names);
		memset (&lp_frame_names[i], 0, sizeof (lp_frame_names[i]));
	}
	lp_state = NULL;
	lp_spawns_ref = LUA_NOREF;
	lp_entity_values_ref = LUA_NOREF;
	lp_global_values_ref = LUA_NOREF;
	lp_active = false;
}

qboolean LP_ExecuteProgram (func_t function)
{
	if (!lp_active || (int)function >= 0)
		return false;
	lua_rawgeti (lp_state, LUA_REGISTRYINDEX, -(int)function);
	LP_PushEntity (lp_state, PROG_TO_EDICT (pr_global_struct->self), true);
	LP_PushEntity (lp_state, PROG_TO_EDICT (pr_global_struct->other), true);
	if (lua_pcall (lp_state, 2, 0, 0) != LUA_OK)
		LP_Error ("executing callback");
	return true;
}

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
	if (lua_pcall (lp_state, 1, 0, 0) != LUA_OK)
		LP_Error ("spawning entity");
	return true;
}
