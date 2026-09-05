-- QuakeC builtin bindings.
-- SPDX-License-Identifier: GPL-2.0-or-later

local function with_self(self, builtin, ...)
    local previous = quake.globals.self
    quake.globals.self = self
    local ok, result = pcall(builtin, ...)
    quake.globals.self = previous
    if not ok then error(result, 0) end
    return result
end

---@type fun(angles: vec3)
local _make_vectors = quake.bind_builtin(1, { "vector" }, "void")

---@param angles vec3
---@return direction_vectors
function quake.make_vectors(angles)
    _make_vectors(angles)
    local forward = quake.globals.v_forward
    local right = quake.globals.v_right
    local up = quake.globals.v_up
    return {
        forward = quake.vec3(forward.x, forward.y, forward.z),
        right = quake.vec3(right.x, right.y, right.z),
        up = quake.vec3(up.x, up.y, up.z),
    }
end

---@type fun(ent: entity, origin: vec3)
quake.set_origin = quake.bind_builtin(2, { "entity", "vector" }, "void")

---@type fun(ent: entity, model: string)
quake.set_model = quake.bind_builtin(3, { "entity", "string" }, "void")

---@type fun(ent: entity, mins: vec3, maxs: vec3)
quake.set_size = quake.bind_builtin(4, { "entity", "vector", "vector" }, "void")

---@type fun(): number
quake.random = quake.bind_builtin(7, {}, "float")

---@return number
function quake.crandom()
    return 2 * (quake.random() - 0.5)
end

---@type fun(ent: entity, channel: integer, sample: string, volume: number, attenuation: number)
quake.sound = quake.bind_builtin(8, { "entity", "float", "string", "float", "float" }, "void")

---@type fun(vector: vec3): number
quake.vector_to_yaw = quake.bind_builtin(13, { "vector" }, "float")

---@type fun(): entity
quake.spawn = quake.bind_builtin(14, {}, "entity")

---@type fun(ent: entity)
quake.remove = quake.bind_builtin(15, { "entity" }, "void")

---@type fun(start: vec3, destination: vec3, ignore_monsters: boolean, ignore: entity)
local _trace_line = quake.bind_builtin(16, { "vector", "vector", "bool", "entity" }, "void")

---@param start vec3
---@param destination vec3
---@param ignore_monsters boolean
---@param ignore entity
---@return trace_result
function quake.trace_line(start, destination, ignore_monsters, ignore)
    _trace_line(start, destination, ignore_monsters, ignore)
    local globals = quake.globals
    local endpos = globals.trace_endpos
    local plane_normal = globals.trace_plane_normal
    return {
        all_solid = globals.trace_allsolid,
        start_solid = globals.trace_startsolid,
        fraction = globals.trace_fraction,
        in_open = globals.trace_inopen,
        in_water = globals.trace_inwater,
        entity = globals.trace_ent or quake.world,
        endpos = quake.vec3(endpos.x, endpos.y, endpos.z),
        plane_normal = quake.vec3(plane_normal.x, plane_normal.y, plane_normal.z),
        plane_dist = globals.trace_plane_dist,
    }
end

---@type fun(): entity?
quake.check_client = quake.bind_builtin(17, {}, "entity")

---@type fun(start: entity?, field: string, value: string): entity?
quake.find = quake.bind_builtin(18, { "entity", ".string", "string" }, "entity")

---@type fun(path: string): string
quake.precache_sound = quake.bind_builtin(19, { "string" }, "string")

---@type fun(path: string): string
quake.precache_model = quake.bind_builtin(20, { "string" }, "string")

---@type fun(ent: entity, command: string)
quake.stuff_cmd = quake.bind_builtin(21, { "entity", "string" }, "void")

---@type fun(origin: vec3, radius: number): entity?
quake.find_radius = quake.bind_builtin(22, { "vector", "float" }, "entity")

---@type fun(text: string)
quake.bprint = quake.bind_builtin(23, { "string" }, "void")

---@type fun(ent: entity, text: string)
quake.sprint = quake.bind_builtin(24, { "entity", "string" }, "void")

---@type fun(text: string)
quake.dprint = quake.bind_builtin(25, { "string" }, "void")

---@type fun(value: number): string
quake.float_to_string = quake.bind_builtin(26, { "float" }, "string")

---@type fun(vector: vec3): string
quake.vector_to_string = quake.bind_builtin(27, { "vector" }, "string")

---@type fun(yaw: number, distance: number): boolean
local _walk_move = quake.bind_builtin(32, { "float", "float" }, "bool")

---@param ent entity
---@param yaw number
---@param distance number
---@return boolean
function quake.walk_move(ent, yaw, distance)
    return with_self(ent, _walk_move, yaw, distance)
end

---@type fun(): boolean
local _drop_to_floor = quake.bind_builtin(34, {}, "bool")

---@param ent entity
---@return boolean
function quake.drop_to_floor(ent)
    return with_self(ent, _drop_to_floor)
end

---@type fun(style: integer, value: string)
quake.light_style = quake.bind_builtin(35, { "float", "string" }, "void")

---@type fun(ent: entity): boolean
quake.check_bottom = quake.bind_builtin(40, { "entity" }, "bool")

---@type fun(origin: vec3): integer
quake.point_contents = quake.bind_builtin(41, { "vector" }, "float")

---@type fun(ent: entity, speed: number): vec3
quake.aim = quake.bind_builtin(44, { "entity", "float" }, "vector")

---@type fun(name: string): number
quake.cvar = quake.bind_builtin(45, { "string" }, "float")

---@type fun(command: string)
quake.local_cmd = quake.bind_builtin(46, { "string" }, "void")

---@type fun(origin: vec3, direction: vec3, color: integer, count: number)
quake.particle = quake.bind_builtin(48, { "vector", "vector", "float", "float" }, "void")

---@type fun()
local _change_yaw = quake.bind_builtin(49, {}, "void")

---@param ent entity
function quake.change_yaw(ent)
    with_self(ent, _change_yaw)
end

---@type fun(vector: vec3): vec3
quake.vector_to_angles = quake.bind_builtin(51, { "vector" }, "vector")

---@type fun(destination: integer, value: integer)
quake.write_byte = quake.bind_builtin(52, { "float", "float" }, "void")

---@type fun(destination: integer, value: number)
quake.write_coord = quake.bind_builtin(56, { "float", "float" }, "void")

---@type fun(destination: integer, value: string)
quake.write_string = quake.bind_builtin(58, { "float", "string" }, "void")

---@type fun(destination: integer, ent: entity)
quake.write_entity = quake.bind_builtin(59, { "float", "entity" }, "void")

---@type fun(distance: number)
local _move_to_goal = quake.bind_builtin(67, { "float" }, "void")

---@param ent entity
---@param distance number
function quake.move_to_goal(ent, distance)
    with_self(ent, _move_to_goal, distance)
end

---@type fun(path: string): string
quake.precache_file = quake.bind_builtin(68, { "string" }, "string")

---@type fun(ent: entity)
quake.make_static = quake.bind_builtin(69, { "entity" }, "void")

---@type fun(map: string)
quake.change_level = quake.bind_builtin(70, { "string" }, "void")

---@type fun(name: string, value: string)
quake.cvar_set = quake.bind_builtin(72, { "string", "string" }, "void")

---@type fun(ent: entity, text: string)
quake.center_print = quake.bind_builtin(73, { "entity", "string" }, "void")

---@type fun(origin: vec3, sample: string, volume: number, attenuation: number)
quake.ambient_sound = quake.bind_builtin(74, { "vector", "string", "float", "float" }, "void")

---@type fun(path: string): string
quake.precache_model2 = quake.bind_builtin(75, { "string" }, "string")

---@type fun(path: string): string
quake.precache_sound2 = quake.bind_builtin(76, { "string" }, "string")

---@type fun(path: string): string
quake.precache_file2 = quake.bind_builtin(77, { "string" }, "string")

---@type fun(ent: entity)
quake.set_spawn_parms = quake.bind_builtin(78, { "entity" }, "void")
