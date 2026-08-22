---@meta

-- Lua Language Server definitions for the engine-provided C module.

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
---@field absmax vec3
---@field absmin vec3
---@field angles vec3
---@field armortype number
---@field armorvalue number
---@field avelocity vec3
---@field attack_finished number
---@field attack_state integer
---@field classname string
---@field dmg_inflictor entity?
---@field dmg_save number
---@field dmg_take number
---@field enemy entity?
---@field flags integer
---@field frame string|integer
---@field goalentity entity?
---@field health number
---@field ideal_yaw number
---@field invincible_finished number
---@field invincible_sound number
---@field items integer
---@field lefty integer
---@field ltime number
---@field movetarget entity?
---@field movetype integer
---@field nextthink number
---@field oldenemy entity?
---@field origin vec3
---@field pain_finished number
---@field pausetime number
---@field search_time number
---@field show_hostile number
---@field solid integer
---@field spawnflags integer
---@field super_damage_finished number
---@field takedamage integer
---@field target string
---@field team number
---@field th_die die_callback?
---@field th_melee think_callback?
---@field th_missile think_callback?
---@field th_pain pain_callback?
---@field th_run think_callback?
---@field th_stand think_callback?
---@field th_walk think_callback?
---@field think think_callback?
---@field touch touch_callback?
---@field use use_callback?
---@field velocity vec3
---@field view_ofs vec3
---@field yaw_speed number
local entity = {}

---@class trace_result
---@field entity entity?
---@field fraction number
---@field in_open boolean
---@field in_water boolean
---@field plane_normal vec3
local trace_result = {}

---@class direction_vectors
---@field forward vec3
---@field right vec3
---@field up vec3
local direction_vectors = {}

---@class quake_globals
---@field damage_attacker entity?
---@field damage_inflictor entity?
---@field killed_monsters number
---@field sight_entity entity?
---@field sight_entity_time number
---@field total_monsters number
local quake_globals = {}

---@class quake
---@field globals quake_globals
---@field world entity
local quake = {}

---@param entity entity
function quake.change_yaw(entity) end

---@return entity?
function quake.check_client() end

---@param target entity
---@param attacker entity
function quake.client_obituary(target, attacker) end

---@return number
function quake.crandom() end

---@param name string
---@return number
function quake.cvar(name) end

---@param ... unknown
function quake.dprint(...) end

---@param start entity
---@param field string
---@param value string
---@return entity?
function quake.find(start, field, value) end

---@param angles vec3
---@return direction_vectors
function quake.make_vectors(angles) end

---@param entity entity
---@param distance number
function quake.move_to_goal(entity, distance) end

---@param path string
function quake.precache_model(path) end

---@param path string
function quake.precache_sound(path) end

---@return number
function quake.random() end

---@param classname string
---@param spawn_function fun(self: entity)
function quake.register_entity(classname, spawn_function) end

---@param entity entity
function quake.remove(entity) end

---@param entity entity
---@param model string
function quake.set_model(entity, model) end

---@param entity entity
---@param mins vec3
---@param maxs vec3
function quake.set_size(entity, mins, maxs) end

---@param entity entity
---@param channel integer
---@param sample string
---@param volume number
---@param attenuation number
function quake.sound(entity, channel, sample, volume, attenuation) end

---@return entity
function quake.spawn() end

---@return number
function quake.time() end

---@param start vec3
---@param destination vec3
---@param ignore_monsters boolean
---@param ignore entity
---@return trace_result
function quake.trace_line(start, destination, ignore_monsters, ignore) end

---@param entity entity
---@param activator entity?
function quake.use_targets(entity, activator) end

---@param x number
---@param y number
---@param z number
---@return vec3
function quake.vec3(x, y, z) end

---@param vector vec3
---@return number
function quake.vector_to_yaw(vector) end

---@param entity entity
---@param yaw number
---@param distance number
---@return boolean
function quake.walk_move(entity, yaw, distance) end

---@param entity entity
---@param speed number
---@return vec3
function quake.aim(entity, speed) end

---@param origin vec3
---@param sample string
---@param volume number
---@param attenuation number
function quake.ambient_sound(origin, sample, volume, attenuation) end

---@param text string
function quake.bprint(text) end

---@param entity entity
---@param text string
function quake.center_print(entity, text) end

---@param map string
function quake.change_level(map) end

---@param entity entity
---@return boolean
function quake.check_bottom(entity) end

---@param name string
---@param value string
function quake.cvar_set(name, value) end

---@param entity entity
---@return boolean
function quake.drop_to_floor(entity) end

---@param origin vec3
---@param radius number
---@return entity?
function quake.find_radius(origin, radius) end

---@param value number
---@return string
function quake.float_to_string(value) end

---@param style integer
---@param value string
function quake.light_style(style, value) end

---@param command string
function quake.local_cmd(command) end

---@param entity entity
function quake.make_static(entity) end

---@param ... unknown
function quake.object_error(...) end

---@param origin vec3
---@param direction vec3
---@param color integer
---@param count number
function quake.particle(origin, direction, color, count) end

---@param origin vec3
---@return integer
function quake.point_contents(origin) end

---@param path string
function quake.precache_file(path) end

---@param path string
function quake.precache_file2(path) end

---@param path string
function quake.precache_model2(path) end

---@param path string
function quake.precache_sound2(path) end

---@param entity entity
---@param origin vec3
function quake.set_origin(entity, origin) end

---@param entity entity
function quake.set_spawn_parms(entity) end

---@param entity entity
---@param text string
function quake.sprint(entity, text) end

---@param entity entity
---@param command string
function quake.stuff_cmd(entity, command) end

---@param vector vec3
---@return vec3
function quake.vector_to_angles(vector) end

---@param vector vec3
---@return string
function quake.vector_to_string(vector) end

---@param destination integer
---@param value integer
function quake.write_byte(destination, value) end

---@param destination integer
---@param value number
function quake.write_coord(destination, value) end

---@param destination integer
---@param entity entity
function quake.write_entity(destination, entity) end

---@param destination integer
---@param value string
function quake.write_string(destination, value) end

return quake
