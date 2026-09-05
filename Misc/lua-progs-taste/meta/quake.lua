---@meta

-- Lua Language Server definitions for the engine-provided C module.

---@alias quake_value_type
---| "bool"
---| "entity"
---| "float"
---| "function"
---| "string"
---| "vector"

---@alias quake_field_type
---| ".entity"
---| ".float"
---| ".function"
---| ".string"
---| ".vector"

---@alias quake_builtin_type quake_value_type | quake_field_type
---@alias quake_builtin_result_type "void" | quake_value_type

---@alias quake_defs { [string]: quake_value_type }

---@alias think_callback fun(self: entity)
---@alias touch_callback fun(self: entity, other: entity)
---@alias use_callback fun(self: entity, activator: entity)
---@alias pain_callback fun(self: entity, attacker: entity, damage: number)
---@alias die_callback fun(self: entity)

---@class vec3
---@field x number
---@field y number
---@field z number
---@operator add(vec3): vec3
---@operator sub(vec3): vec3
---@operator unm: vec3
---@operator mul(number): vec3
local vec3 = {}

---@return number
function vec3:length() end

---@return vec3
function vec3:normalized() end

---@param other vec3
---@return number
function vec3:dot(other) end

---@class entity
---@field modelindex number
---@field absmin vec3
---@field absmax vec3
---@field ltime number
---@field movetype number
---@field solid number
---@field origin vec3
---@field oldorigin vec3
---@field velocity vec3
---@field angles vec3
---@field avelocity vec3
---@field punchangle vec3
---@field classname string
---@field model string
---@field frame integer
---@field skin number
---@field effects number
---@field mins vec3
---@field maxs vec3
---@field size vec3
---@field touch touch_callback?
---@field use use_callback?
---@field think think_callback?
---@field blocked touch_callback?
---@field nextthink number
---@field groundentity entity?
---@field health number
---@field frags number
---@field weapon number
---@field weaponmodel string
---@field weaponframe number
---@field currentammo number
---@field ammo_shells number
---@field ammo_nails number
---@field ammo_rockets number
---@field ammo_cells number
---@field items number
---@field takedamage number
---@field chain entity?
---@field deadflag number
---@field view_ofs vec3
---@field button0 number
---@field button1 number
---@field button2 number
---@field impulse number
---@field fixangle number
---@field v_angle vec3
---@field idealpitch number
---@field netname string
---@field enemy entity?
---@field flags number
---@field colormap number
---@field team number
---@field max_health number
---@field teleport_time number
---@field armortype number
---@field armorvalue number
---@field waterlevel number
---@field watertype number
---@field ideal_yaw number
---@field yaw_speed number
---@field aiment entity?
---@field goalentity entity?
---@field spawnflags number
---@field target string
---@field targetname string
---@field dmg_take number
---@field dmg_save number
---@field dmg_inflictor entity?
---@field owner entity?
---@field movedir vec3
---@field message string
---@field sounds number
---@field noise string
---@field noise1 string
---@field noise2 string
---@field noise3 string
local entity = {}

---@class trace_result
---@field all_solid boolean
---@field start_solid boolean
---@field entity entity?
---@field fraction number
---@field in_open boolean
---@field in_water boolean
---@field endpos vec3
---@field plane_normal vec3
---@field plane_dist number
local trace_result = {}

---@class direction_vectors
---@field forward vec3
---@field right vec3
---@field up vec3
local direction_vectors = {}

---@class quake_globals
---@field main fun()
---@field StartFrame fun()
---@field PlayerPreThink fun(self: entity)
---@field PlayerPostThink fun(self: entity)
---@field ClientKill fun(self: entity)
---@field ClientConnect fun(self: entity)
---@field PutClientInServer fun(self: entity)
---@field ClientDisconnect fun(self: entity)
---@field SetNewParms fun()
---@field SetChangeParms fun(self: entity)
---@field coop number
---@field deathmatch number
---@field force_retouch number
---@field found_secrets number
---@field frametime number
---@field killed_monsters number
---@field mapname string
---@field msg_entity entity?
---@field other entity?
---@field parm1 number
---@field parm2 number
---@field parm3 number
---@field parm4 number
---@field parm5 number
---@field parm6 number
---@field parm7 number
---@field parm8 number
---@field parm9 number
---@field parm10 number
---@field parm11 number
---@field parm12 number
---@field parm13 number
---@field parm14 number
---@field parm15 number
---@field parm16 number
---@field self entity?
---@field serverflags number
---@field teamplay number
---@field total_monsters number
---@field total_secrets number
---@field trace_allsolid number
---@field trace_endpos vec3
---@field trace_ent entity?
---@field trace_fraction number
---@field trace_inopen number
---@field trace_inwater number
---@field trace_plane_dist number
---@field trace_plane_normal vec3
---@field trace_startsolid number
---@field v_forward vec3
---@field v_right vec3
---@field v_up vec3
local quake_globals = {}

---@class quake
---@field globals quake_globals
---@field world entity
quake = {}

---@param number integer
---@param parameters quake_builtin_type[]
---@param result quake_builtin_result_type
---@return function
function quake.bind_builtin(number, parameters, result) end

---@param ... unknown
function quake.object_error(...) end

---@generic T: function
---@param identifier string
---@param func T
---@return T func
function quake.register_function(identifier, func) end

---@param classname string
---@param spawn_function fun(self: entity)
function quake.register_entity(classname, spawn_function) end

---@return number
function quake.time() end

---@param x number
---@param y number
---@param z number
---@return vec3
function quake.vec3(x, y, z) end

return quake
