-- Port of weapons.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

--[[  Copyright (C) 1996-1997  Id Software, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
]]

local animation = require("game.animation")
local combat = require("game.combat")
local subs = require("game.subs")
local player = require("game.player")

local M = {}

local IT_SHOTGUN = 1
local IT_SUPER_SHOTGUN = 2
local IT_NAILGUN = 4
local IT_SUPER_NAILGUN = 8
local IT_GRENADE_LAUNCHER = 16
local IT_ROCKET_LAUNCHER = 32
local IT_LIGHTNING = 64
local IT_SHELLS = 256
local IT_NAILS = 512
local IT_ROCKETS = 1024
local IT_CELLS = 2048
local IT_AXE = 4096
local IT_KEY1 = 131072
local IT_KEY2 = 262144
local IT_QUAD = 4194304

local MOVETYPE_NONE = 0
local MOVETYPE_FLYMISSILE = 9
local MOVETYPE_BOUNCE = 10
local SOLID_NOT = 0
local SOLID_TRIGGER = 1
local SOLID_BBOX = 2
local DAMAGE_AIM = 2
local CONTENT_SKY = -6
local CHAN_AUTO = 0
local CHAN_WEAPON = 1
local CHAN_BODY = 4
local ATTN_NORM = 1
local MSG_BROADCAST = 0
local SVC_TEMPENTITY = 23
local TE_SPIKE = 0
local TE_SUPERSPIKE = 1
local TE_GUNSHOT = 2
local TE_EXPLOSION = 3
local TE_LIGHTNING2 = 6
local TE_WIZSPIKE = 7
local TE_KNIGHTSPIKE = 8

-- called by worldspawn
---@return nil
function M.precache()
    quake.precache_sound("weapons/r_exp3.wav") -- new rocket explosion
    quake.precache_sound("weapons/rocket1i.wav") -- spike gun
    quake.precache_sound("weapons/sgun1.wav")
    quake.precache_sound("weapons/guncock.wav") -- player shotgun
    quake.precache_sound("weapons/ric1.wav") -- ricochet (used in c code)
    quake.precache_sound("weapons/ric2.wav") -- ricochet (used in c code)
    quake.precache_sound("weapons/ric3.wav") -- ricochet (used in c code)
    quake.precache_sound("weapons/spike2.wav") -- super spikes
    quake.precache_sound("weapons/tink1.wav") -- spikes tink (used in c code)
    quake.precache_sound("weapons/grenade.wav") -- grenade launcher
    quake.precache_sound("weapons/bounce.wav") -- grenade bounce
    quake.precache_sound("weapons/shotgn2.wav") -- super shotgun
end

---@param self entity
---@return nil
function M.fire_axe(self)
    local vectors = quake.make_vectors(self.v_angle)
    local source = self.origin + quake.vec3(0, 0, 16)
    local trace = quake.trace_line(source, source + vectors.forward * 64, false, self)
    if trace.fraction == 1.0 then
        return
    end

    local org = trace.endpos - vectors.forward * 4

    if trace.entity.takedamage ~= 0 then
        trace.entity.axhitme = 1
        M.spawn_blood(org, quake.vec3(0, 0, 0), 20)
        combat.damage(trace.entity, self, self, 20)
    else
        -- hit wall
        quake.sound(self, CHAN_WEAPON, "player/axhit2.wav", 1, ATTN_NORM)
        quake.write_byte(MSG_BROADCAST, SVC_TEMPENTITY)
        quake.write_byte(MSG_BROADCAST, TE_GUNSHOT)
        quake.write_coord(MSG_BROADCAST, org.x)
        quake.write_coord(MSG_BROADCAST, org.y)
        quake.write_coord(MSG_BROADCAST, org.z)
    end
end

--============================================================================

---@param self entity
---@return vec3
local function wall_velocity(self)
    local vel = self.velocity:normalized()
    vel = (vel + quake.globals.v_up * (quake.random() - 0.5)
        + quake.globals.v_right * (quake.random() - 0.5)):normalized()
    vel = vel + quake.globals.trace_plane_normal * 2
    vel = vel * 200

    return vel
end

---@param self entity
---@param org vec3
---@param vel vec3
---@return nil
function M.spawn_meat_spray(self, org, vel)
    local missile = quake.spawn()
    missile.owner = self
    missile.movetype = MOVETYPE_BOUNCE
    missile.solid = SOLID_NOT

    quake.make_vectors(self.angles)

    missile.velocity = vel
    missile.velocity.z = missile.velocity.z + 250 + 50 * quake.random()

    missile.avelocity = quake.vec3(3000, 1000, 2000)

    -- set missile duration
    missile.nextthink = quake.time() + 1
    missile.think = subs.remove

    quake.set_model(missile, "progs/zom_gib.mdl")
    quake.set_size(missile, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))
    quake.set_origin(missile, org)
end

---@param org vec3
---@param vel vec3
---@param damage number
---@return nil
function M.spawn_blood(org, vel, damage)
    quake.particle(org, vel * 0.1, 73, damage * 2)
end

---@param self entity
---@param damage number
---@return nil
local function spawn_touchblood(self, damage)
    local vel = wall_velocity(self) * 0.2
    M.spawn_blood(self.origin + vel * 0.01, vel, damage)
end

--[[
==============================================================================

MULTI-DAMAGE

Collects multiple small damages into a single damage

==============================================================================
]]

---@class multi_damage_accumulator
---@field entity entity?
---@field damage number

---@return multi_damage_accumulator
local function clear_multi_damage()
    return { damage = 0 }
end

---@param self entity
---@param accumulator multi_damage_accumulator
---@return nil
local function apply_multi_damage(self, accumulator)
    if not accumulator.entity then
        return
    end
    combat.damage(accumulator.entity, self, self, accumulator.damage)
end

---@param self entity
---@param accumulator multi_damage_accumulator
---@param hit entity?
---@param damage number
---@return multi_damage_accumulator
local function add_multi_damage(self, accumulator, hit, damage)
    if not hit then
        return accumulator
    end

    if hit ~= accumulator.entity then
        apply_multi_damage(self, accumulator)
        accumulator.damage = damage
        accumulator.entity = hit
    else
        accumulator.damage = accumulator.damage + damage
    end
    return accumulator
end

--[[
==============================================================================

BULLETS

==============================================================================
]]

---@param self entity
---@param trace trace_result
---@param damage number
---@param dir vec3
---@param vectors direction_vectors
---@param accumulator multi_damage_accumulator
---@return multi_damage_accumulator
local function trace_attack(self, trace, damage, dir, vectors, accumulator)
    local vel = (dir + vectors.up * quake.crandom() + vectors.right * quake.crandom()):normalized()
    vel = vel + trace.plane_normal * 2
    vel = vel * 200

    local org = trace.endpos - dir * 4

    if trace.entity.takedamage ~= 0 then
        M.spawn_blood(org, vel * 0.2, damage)
        accumulator = add_multi_damage(self, accumulator, trace.entity, damage)
    else
        quake.write_byte(MSG_BROADCAST, SVC_TEMPENTITY)
        quake.write_byte(MSG_BROADCAST, TE_GUNSHOT)
        quake.write_coord(MSG_BROADCAST, org.x)
        quake.write_coord(MSG_BROADCAST, org.y)
        quake.write_coord(MSG_BROADCAST, org.z)
    end
    return accumulator
end

---Used by shotgun, super shotgun, and enemy soldier firing
---Go to the trouble of combining multiple pellets into a single damage call.
---@param self entity
---@param shotcount integer
---@param dir vec3
---@param spread vec3
---@return nil
function M.fire_bullets(self, shotcount, dir, spread)
    local vectors = quake.make_vectors(self.v_angle)

    local src = self.origin + vectors.forward * 10
    src.z = self.absmin.z + self.size.z * 0.7

    local accumulator = clear_multi_damage()
    while shotcount > 0 do
        local direction = dir + vectors.right * (quake.crandom() * spread.x) + vectors.up * (quake.crandom() * spread.y)

        local trace = quake.trace_line(src, src + direction * 2048, false, self)
        if trace.fraction ~= 1.0 then
            accumulator = trace_attack(self, trace, 4, direction, vectors, accumulator)
        end

        shotcount = shotcount - 1
    end
    apply_multi_damage(self, accumulator)
end

---@param self entity
---@return nil
local function fire_shotgun(self)
    quake.sound(self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM)

    self.punchangle.x = -2

    self.ammo_shells = self.ammo_shells - 1
    self.currentammo = self.ammo_shells
    local dir = quake.aim(self, 100000)
    M.fire_bullets(self, 6, dir, quake.vec3(0.04, 0.04, 0))
end

---@param self entity
---@return nil
local function fire_super_shotgun(self)
    if self.currentammo == 1 then
        fire_shotgun(self)
        return
    end

    quake.sound(self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM)

    self.punchangle.x = -4

    self.ammo_shells = self.ammo_shells - 2
    self.currentammo = self.ammo_shells
    local dir = quake.aim(self, 100000)
    M.fire_bullets(self, 14, dir, quake.vec3(0.14, 0.08, 0))
end

--[[
==============================================================================

ROCKETS

==============================================================================
]]

local s_explode = animation.sequence("weapons.s_explode", {
    { 0 },
    { 1 },
    { 2 },
    { 3 },
    { 4 },
    { 5 },
}, function() return subs.remove end)

---@param self entity
---@return nil
function M.become_explosion(self)
    self.movetype = MOVETYPE_NONE
    self.velocity = quake.vec3(0, 0, 0)
    self.touch = subs.null
    quake.set_model(self, "progs/s_explod.spr")
    self.solid = SOLID_NOT
    s_explode(self)
end

---@param self entity
---@param other entity
---@return nil
M.missile_touch = quake.register_function("weapons.missile_touch", function(self, other)
    if other == self.owner then
        -- don't explode on owner
        return
    end

    if quake.point_contents(self.origin) == CONTENT_SKY then
        quake.remove(self)
        return
    end

    local damage = 100 + quake.random() * 20

    if other.health ~= 0 then
        if other.classname == "monster_shambler" then
            -- mostly immune
            damage = damage * 0.5
        end
        combat.damage(other, self, self.owner, damage)
    end

    -- don't do radius damage to the other, because all the damage
    -- was done in the impact
    combat.radius_damage(self, self.owner, 120, other)

    self.origin = self.origin - self.velocity:normalized() * 8

    quake.write_byte(MSG_BROADCAST, SVC_TEMPENTITY)
    quake.write_byte(MSG_BROADCAST, TE_EXPLOSION)
    quake.write_coord(MSG_BROADCAST, self.origin.x)
    quake.write_coord(MSG_BROADCAST, self.origin.y)
    quake.write_coord(MSG_BROADCAST, self.origin.z)

    M.become_explosion(self)
end)

---@param self entity
---@return nil
local function fire_rocket(self)
    self.ammo_rockets = self.ammo_rockets - 1
    self.currentammo = self.ammo_rockets

    quake.sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM)

    self.punchangle.x = -2

    local missile = quake.spawn()
    missile.owner = self
    missile.movetype = MOVETYPE_FLYMISSILE
    missile.solid = SOLID_BBOX
    missile.classname = "missile"

    -- set missile speed
    local vectors = quake.make_vectors(self.v_angle)
    missile.velocity = quake.aim(self, 1000)
    missile.velocity = missile.velocity * 1000
    missile.angles = quake.vector_to_angles(missile.velocity)

    missile.touch = M.missile_touch

    -- set missile duration
    missile.nextthink = quake.time() + 5
    missile.think = subs.remove

    quake.set_model(missile, "progs/missile.mdl")
    quake.set_size(missile, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))
    quake.set_origin(missile, self.origin + vectors.forward * 8 + quake.vec3(0, 0, 16))
end

--[[
===============================================================================

LIGHTNING

===============================================================================
]]

---@param self entity
---@param p1 vec3
---@param p2 vec3
---@param from entity
---@param damage number
---@return nil
function M.lightning_damage(self, p1, p2, from, damage)
    local f = p2 - p1
    f:normalized()
    f.x = 0 - f.y
    f.y = f.x
    f.z = 0
    f = f * 16

    local e1 = quake.world
    local e2 = quake.world

    local trace = quake.trace_line(p1, p2, false, self)
    if trace.entity.takedamage ~= 0 then
        quake.particle(trace.endpos, quake.vec3(0, 0, 100), 225, damage * 4)
        combat.damage(trace.entity, from, from, damage)
        if self.classname == "player" then
            local other = quake.globals.other or quake.world
            if other.classname == "player" then
                trace.entity.velocity.z = trace.entity.velocity.z + 400
            end
        end
    end
    e1 = trace.entity

    trace = quake.trace_line(p1 + f, p2 + f, false, self)
    if trace.entity ~= e1 and trace.entity.takedamage ~= 0 then
        quake.particle(trace.endpos, quake.vec3(0, 0, 100), 225, damage * 4)
        combat.damage(trace.entity, from, from, damage)
    end
    e2 = trace.entity

    trace = quake.trace_line(p1 - f, p2 - f, false, self)
    if trace.entity ~= e1 and trace.entity ~= e2 and trace.entity.takedamage ~= 0 then
        quake.particle(trace.endpos, quake.vec3(0, 0, 100), 225, damage * 4)
        combat.damage(trace.entity, from, from, damage)
    end
end

---@param self entity
---@return nil
function M.fire_lightning(self)
    if self.ammo_cells < 1 then
        self.weapon = M.best_weapon(self)
        M.set_current_ammo(self)
        return
    end

    -- explode if under water
    if self.waterlevel > 1 then
        local cells = self.ammo_cells
        self.ammo_cells = 0
        M.set_current_ammo(self)
        combat.radius_damage(self, self, 35 * cells, quake.world)
        return
    end

    if self.t_width < quake.time() then
        quake.sound(self, CHAN_WEAPON, "weapons/lhit.wav", 1, ATTN_NORM)
        self.t_width = quake.time() + 0.6
    end
    self.punchangle.x = -2

    self.ammo_cells = self.ammo_cells - 1
    self.currentammo = self.ammo_cells

    local org = self.origin + quake.vec3(0, 0, 16)

    local trace = quake.trace_line(org, org + quake.globals.v_forward * 600, true, self)

    quake.write_byte(MSG_BROADCAST, SVC_TEMPENTITY)
    quake.write_byte(MSG_BROADCAST, TE_LIGHTNING2)
    quake.write_entity(MSG_BROADCAST, self)
    quake.write_coord(MSG_BROADCAST, org.x)
    quake.write_coord(MSG_BROADCAST, org.y)
    quake.write_coord(MSG_BROADCAST, org.z)
    quake.write_coord(MSG_BROADCAST, trace.endpos.x)
    quake.write_coord(MSG_BROADCAST, trace.endpos.y)
    quake.write_coord(MSG_BROADCAST, trace.endpos.z)

    M.lightning_damage(self, self.origin, trace.endpos + quake.globals.v_forward * 4, self, 30)
end

--=============================================================================

---@param self entity
---@return nil
local grenade_explode = quake.register_function("weapons.grenade_explode", function(self)
    combat.radius_damage(self, self.owner, 120, quake.world)

    quake.write_byte(MSG_BROADCAST, SVC_TEMPENTITY)
    quake.write_byte(MSG_BROADCAST, TE_EXPLOSION)
    quake.write_coord(MSG_BROADCAST, self.origin.x)
    quake.write_coord(MSG_BROADCAST, self.origin.y)
    quake.write_coord(MSG_BROADCAST, self.origin.z)

    M.become_explosion(self)
end)

---@param self entity
---@param other entity
---@return nil
local grenade_touch = quake.register_function("weapons.grenade_touch", function(self, other)
    if other == self.owner then
        -- don't explode on owner
        return
    end
    if other.takedamage == DAMAGE_AIM then
        grenade_explode(self)
        return
    end
    -- bounce sound
    quake.sound(self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM)
    if self.velocity == quake.vec3(0, 0, 0) then
        self.avelocity = quake.vec3(0, 0, 0)
    end
end)

---@param self entity
---@return nil
local function fire_grenade(self)
    self.ammo_rockets = self.ammo_rockets - 1
    self.currentammo = self.ammo_rockets

    quake.sound(self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM)

    self.punchangle.x = -2

    local missile = quake.spawn()
    missile.owner = self
    missile.movetype = MOVETYPE_BOUNCE
    missile.solid = SOLID_BBOX
    missile.classname = "grenade"

    -- set missile speed
    local vectors = quake.make_vectors(self.v_angle)

    if self.v_angle.x ~= 0 then
        missile.velocity = vectors.forward * 600 + vectors.up * 200
            + vectors.right * (quake.crandom() * 10) + vectors.up * (quake.crandom() * 10)
    else
        missile.velocity = quake.aim(self, 10000)
        missile.velocity = missile.velocity * 600
        missile.velocity.z = 200
    end

    missile.avelocity = quake.vec3(300, 300, 300)

    missile.angles = quake.vector_to_angles(missile.velocity)

    missile.touch = grenade_touch

    -- set missile duration
    missile.nextthink = quake.time() + 2.5
    missile.think = grenade_explode

    quake.set_model(missile, "progs/grenade.mdl")
    quake.set_size(missile, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))
    quake.set_origin(missile, self.origin)
end

--=============================================================================

local spike_touch

---Used for both the player and the ogre
---@param self entity
---@param org vec3
---@param dir vec3
---@return entity
function M.launch_spike(self, org, dir)
    local newmis = quake.spawn()
    newmis.owner = self
    newmis.movetype = MOVETYPE_FLYMISSILE
    newmis.solid = SOLID_BBOX

    newmis.angles = quake.vector_to_angles(dir)

    newmis.touch = spike_touch
    newmis.classname = "spike"
    newmis.think = subs.remove
    newmis.nextthink = quake.time() + 6
    quake.set_model(newmis, "progs/spike.mdl")
    quake.set_size(newmis, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))
    quake.set_origin(newmis, org)

    newmis.velocity = dir * 1000
    return newmis
end

local superspike_touch

---@param self entity
---@return nil
local function fire_super_spikes(self)
    quake.sound(self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM)
    self.attack_finished = quake.time() + 0.2
    self.ammo_nails = self.ammo_nails - 2
    self.currentammo = self.ammo_nails
    local dir = quake.aim(self, 1000)
    local newmis = M.launch_spike(self, self.origin + quake.vec3(0, 0, 16), dir)
    newmis.touch = superspike_touch
    quake.set_model(newmis, "progs/s_spike.mdl")
    quake.set_size(newmis, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))
    self.punchangle.x = -2
end

---@param self entity
---@param ox number
---@return nil
function M.fire_spikes(self, ox)
    local vectors = quake.make_vectors(self.v_angle)

    if self.ammo_nails >= 2 and self.weapon == IT_SUPER_NAILGUN then
        fire_super_spikes(self)
        return
    end

    if self.ammo_nails < 1 then
        self.weapon = M.best_weapon(self)
        M.set_current_ammo(self)
        return
    end

    quake.sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM)
    self.attack_finished = quake.time() + 0.2
    self.ammo_nails = self.ammo_nails - 1
    self.currentammo = self.ammo_nails
    local dir = quake.aim(self, 1000)
    M.launch_spike(self, self.origin + quake.vec3(0, 0, 16) + vectors.right * ox, dir)

    self.punchangle.x = -2
end

---@param self entity
---@param other entity
---@return nil
spike_touch = quake.register_function("weapons.spike_touch", function(self, other)
    if other == self.owner then
        return
    end

    if other.solid == SOLID_TRIGGER then
        -- trigger field, do nothing
        return
    end

    if quake.point_contents(self.origin) == CONTENT_SKY then
        quake.remove(self)
        return
    end

    -- hit something that bleeds
    if other.takedamage ~= 0 then
        spawn_touchblood(self, 9)
        combat.damage(other, self, self.owner, 9)
    else
        quake.write_byte(MSG_BROADCAST, SVC_TEMPENTITY)

        if self.classname == "wizspike" then
            quake.write_byte(MSG_BROADCAST, TE_WIZSPIKE)
        elseif self.classname == "knightspike" then
            quake.write_byte(MSG_BROADCAST, TE_KNIGHTSPIKE)
        else
            quake.write_byte(MSG_BROADCAST, TE_SPIKE)
        end
        quake.write_coord(MSG_BROADCAST, self.origin.x)
        quake.write_coord(MSG_BROADCAST, self.origin.y)
        quake.write_coord(MSG_BROADCAST, self.origin.z)
    end

    quake.remove(self)
end)

---@param self entity
---@param other entity
---@return nil
superspike_touch = quake.register_function("weapons.superspike_touch", function(self, other)
    if other == self.owner then
        return
    end

    if other.solid == SOLID_TRIGGER then
        -- trigger field, do nothing
        return
    end

    if quake.point_contents(self.origin) == CONTENT_SKY then
        quake.remove(self)
        return
    end

    -- hit something that bleeds
    if other.takedamage ~= 0 then
        spawn_touchblood(self, 18)
        combat.damage(other, self, self.owner, 18)
    else
        quake.write_byte(MSG_BROADCAST, SVC_TEMPENTITY)
        quake.write_byte(MSG_BROADCAST, TE_SUPERSPIKE)
        quake.write_coord(MSG_BROADCAST, self.origin.x)
        quake.write_coord(MSG_BROADCAST, self.origin.y)
        quake.write_coord(MSG_BROADCAST, self.origin.z)
    end

    quake.remove(self)
end)

--[[
===============================================================================

PLAYER WEAPON USE

===============================================================================
]]

---@param self entity
---@return nil
function M.set_current_ammo(self)
    -- get out of any weapon firing states
    if self.model ~= "" then
        player.player_run(self)
    end

    self.items = self.items - (self.items & (IT_SHELLS | IT_NAILS | IT_ROCKETS | IT_CELLS))

    if self.weapon == IT_AXE then
        self.currentammo = 0
        self.weaponmodel = "progs/v_axe.mdl"
        self.weaponframe = 0
    elseif self.weapon == IT_SHOTGUN then
        self.currentammo = self.ammo_shells
        self.weaponmodel = "progs/v_shot.mdl"
        self.weaponframe = 0
        self.items = self.items | IT_SHELLS
    elseif self.weapon == IT_SUPER_SHOTGUN then
        self.currentammo = self.ammo_shells
        self.weaponmodel = "progs/v_shot2.mdl"
        self.weaponframe = 0
        self.items = self.items | IT_SHELLS
    elseif self.weapon == IT_NAILGUN then
        self.currentammo = self.ammo_nails
        self.weaponmodel = "progs/v_nail.mdl"
        self.weaponframe = 0
        self.items = self.items | IT_NAILS
    elseif self.weapon == IT_SUPER_NAILGUN then
        self.currentammo = self.ammo_nails
        self.weaponmodel = "progs/v_nail2.mdl"
        self.weaponframe = 0
        self.items = self.items | IT_NAILS
    elseif self.weapon == IT_GRENADE_LAUNCHER then
        self.currentammo = self.ammo_rockets
        self.weaponmodel = "progs/v_rock.mdl"
        self.weaponframe = 0
        self.items = self.items | IT_ROCKETS
    elseif self.weapon == IT_ROCKET_LAUNCHER then
        self.currentammo = self.ammo_rockets
        self.weaponmodel = "progs/v_rock2.mdl"
        self.weaponframe = 0
        self.items = self.items | IT_ROCKETS
    elseif self.weapon == IT_LIGHTNING then
        self.currentammo = self.ammo_cells
        self.weaponmodel = "progs/v_light.mdl"
        self.weaponframe = 0
        self.items = self.items | IT_CELLS
    else
        self.currentammo = 0
        self.weaponmodel = ""
        self.weaponframe = 0
    end
end

---@param self entity
---@return integer
function M.best_weapon(self)
    local it = self.items

    if self.waterlevel <= 1 and self.ammo_cells >= 1 and (it & IT_LIGHTNING) ~= 0 then
        return IT_LIGHTNING
    elseif self.ammo_nails >= 2 and (it & IT_SUPER_NAILGUN) ~= 0 then
        return IT_SUPER_NAILGUN
    elseif self.ammo_shells >= 2 and (it & IT_SUPER_SHOTGUN) ~= 0 then
        return IT_SUPER_SHOTGUN
    elseif self.ammo_nails >= 1 and (it & IT_NAILGUN) ~= 0 then
        return IT_NAILGUN
    elseif self.ammo_shells >= 1 and (it & IT_SHOTGUN) ~= 0 then
        return IT_SHOTGUN
    end

    return IT_AXE
end

---@param self entity
---@return boolean
local function check_no_ammo(self)
    if self.currentammo > 0 then
        return true
    end

    if self.weapon == IT_AXE then
        return true
    end

    self.weapon = M.best_weapon(self)

    M.set_current_ammo(self)

    -- drop the weapon down
    return false
end

---An attack impulse can be triggered now
---@param self entity
---@return nil
local function attack(self)
    if not check_no_ammo(self) then
        return
    end

    -- calculate forward angle for velocity
    quake.make_vectors(self.v_angle)
    -- wake monsters up
    self.show_hostile = quake.time() + 1

    if self.weapon == IT_AXE then
        quake.sound(self, CHAN_WEAPON, "weapons/ax1.wav", 1, ATTN_NORM)
        local r = quake.random()
        if r < 0.25 then
            player.player_axe1(self)
        elseif r < 0.5 then
            player.player_axeb1(self)
        elseif r < 0.75 then
            player.player_axec1(self)
        else
            player.player_axed1(self)
        end
        self.attack_finished = quake.time() + 0.5
    elseif self.weapon == IT_SHOTGUN then
        player.player_shot1(self)
        fire_shotgun(self)
        self.attack_finished = quake.time() + 0.5
    elseif self.weapon == IT_SUPER_SHOTGUN then
        player.player_shot1(self)
        fire_super_shotgun(self)
        self.attack_finished = quake.time() + 0.7
    elseif self.weapon == IT_NAILGUN then
        player.player_nail1(self)
    elseif self.weapon == IT_SUPER_NAILGUN then
        player.player_nail1(self)
    elseif self.weapon == IT_GRENADE_LAUNCHER then
        player.player_rocket1(self)
        fire_grenade(self)
        self.attack_finished = quake.time() + 0.6
    elseif self.weapon == IT_ROCKET_LAUNCHER then
        player.player_rocket1(self)
        fire_rocket(self)
        self.attack_finished = quake.time() + 0.8
    elseif self.weapon == IT_LIGHTNING then
        player.player_light1(self)
        self.attack_finished = quake.time() + 0.1
        quake.sound(self, CHAN_AUTO, "weapons/lstart.wav", 1, ATTN_NORM)
    end
end

---@param self entity
---@return nil
local function change_weapon(self)
    local am = 0
    local fl = 0

    if self.impulse == 1 then
        fl = IT_AXE
    elseif self.impulse == 2 then
        fl = IT_SHOTGUN
        if self.ammo_shells < 1 then
            am = 1
        end
    elseif self.impulse == 3 then
        fl = IT_SUPER_SHOTGUN
        if self.ammo_shells < 2 then
            am = 1
        end
    elseif self.impulse == 4 then
        fl = IT_NAILGUN
        if self.ammo_nails < 1 then
            am = 1
        end
    elseif self.impulse == 5 then
        fl = IT_SUPER_NAILGUN
        if self.ammo_nails < 2 then
            am = 1
        end
    elseif self.impulse == 6 then
        fl = IT_GRENADE_LAUNCHER
        if self.ammo_rockets < 1 then
            am = 1
        end
    elseif self.impulse == 7 then
        fl = IT_ROCKET_LAUNCHER
        if self.ammo_rockets < 1 then
            am = 1
        end
    elseif self.impulse == 8 then
        fl = IT_LIGHTNING
        if self.ammo_cells < 1 then
            am = 1
        end
    end

    self.impulse = 0

    if (self.items & fl) == 0 then
        -- don't have the weapon or the ammo
        quake.sprint(self, "no weapon.\n")
        return
    end

    if am ~= 0 then
        -- don't have the ammo
        quake.sprint(self, "not enough ammo.\n")
        return
    end

    -- set weapon, set ammo
    self.weapon = fl
    M.set_current_ammo(self)
end

---@param self entity
---@return nil
local function cheat_command(self)
    if quake.cvar("deathmatch") ~= 0 or quake.cvar("coop") ~= 0 then
        return
    end

    self.ammo_rockets = 100
    self.ammo_nails = 200
    self.ammo_shells = 100
    self.items = self.items
        | IT_AXE
        | IT_SHOTGUN
        | IT_SUPER_SHOTGUN
        | IT_NAILGUN
        | IT_SUPER_NAILGUN
        | IT_GRENADE_LAUNCHER
        | IT_ROCKET_LAUNCHER
        | IT_KEY1 | IT_KEY2

    self.ammo_cells = 200
    self.items = self.items | IT_LIGHTNING

    self.weapon = IT_ROCKET_LAUNCHER
    self.impulse = 0
    M.set_current_ammo(self)
end

---Go to the next weapon with ammo
---@param self entity
---@return nil
local function cycle_weapon_command(self)
    self.impulse = 0

    while true do
        local am = 0

        if self.weapon == IT_LIGHTNING then
            self.weapon = IT_AXE
        elseif self.weapon == IT_AXE then
            self.weapon = IT_SHOTGUN
            if self.ammo_shells < 1 then
                am = 1
            end
        elseif self.weapon == IT_SHOTGUN then
            self.weapon = IT_SUPER_SHOTGUN
            if self.ammo_shells < 2 then
                am = 1
            end
        elseif self.weapon == IT_SUPER_SHOTGUN then
            self.weapon = IT_NAILGUN
            if self.ammo_nails < 1 then
                am = 1
            end
        elseif self.weapon == IT_NAILGUN then
            self.weapon = IT_SUPER_NAILGUN
            if self.ammo_nails < 2 then
                am = 1
            end
        elseif self.weapon == IT_SUPER_NAILGUN then
            self.weapon = IT_GRENADE_LAUNCHER
            if self.ammo_rockets < 1 then
                am = 1
            end
        elseif self.weapon == IT_GRENADE_LAUNCHER then
            self.weapon = IT_ROCKET_LAUNCHER
            if self.ammo_rockets < 1 then
                am = 1
            end
        elseif self.weapon == IT_ROCKET_LAUNCHER then
            self.weapon = IT_LIGHTNING
            if self.ammo_cells < 1 then
                am = 1
            end
        end

        if (self.items & self.weapon) ~= 0 and am == 0 then
            M.set_current_ammo(self)
            return
        end
    end
end

---Go to the prev weapon with ammo
---@param self entity
---@return nil
local function cycle_weapon_reverse_command(self)
    local it = self.items
    self.impulse = 0

    while true do
        local am = 0

        if self.weapon == IT_LIGHTNING then
            self.weapon = IT_ROCKET_LAUNCHER
            if self.ammo_rockets < 1 then
                am = 1
            end
        elseif self.weapon == IT_ROCKET_LAUNCHER then
            self.weapon = IT_GRENADE_LAUNCHER
            if self.ammo_rockets < 1 then
                am = 1
            end
        elseif self.weapon == IT_GRENADE_LAUNCHER then
            self.weapon = IT_SUPER_NAILGUN
            if self.ammo_nails < 2 then
                am = 1
            end
        elseif self.weapon == IT_SUPER_NAILGUN then
            self.weapon = IT_NAILGUN
            if self.ammo_nails < 1 then
                am = 1
            end
        elseif self.weapon == IT_NAILGUN then
            self.weapon = IT_SUPER_SHOTGUN
            if self.ammo_shells < 2 then
                am = 1
            end
        elseif self.weapon == IT_SUPER_SHOTGUN then
            self.weapon = IT_SHOTGUN
            if self.ammo_shells < 1 then
                am = 1
            end
        elseif self.weapon == IT_SHOTGUN then
            self.weapon = IT_AXE
        elseif self.weapon == IT_AXE then
            self.weapon = IT_LIGHTNING
            if self.ammo_cells < 1 then
                am = 1
            end
        end

        if (it & self.weapon) ~= 0 and am == 0 then
            M.set_current_ammo(self)
            return
        end
    end
end

---Just for development
---@return nil
local function serverflags_command()
    quake.globals.serverflags = quake.globals.serverflags * 2 + 1
end

---@param self entity
---@return nil
local function quad_cheat(self)
    if quake.cvar("deathmatch") ~= 0 or quake.cvar("coop") ~= 0 then
        return
    end
    self.super_time = 1
    self.super_damage_finished = quake.time() + 30
    self.items = self.items | IT_QUAD
    quake.dprint("quad cheat\n")
end

---@param self entity
---@return nil
local function impulse_commands(self)
    if self.impulse >= 1 and self.impulse <= 8 then
        change_weapon(self)
    end

    if self.impulse == 9 then
        cheat_command(self)
    end
    if self.impulse == 10 then
        cycle_weapon_command(self)
    end
    if self.impulse == 11 then
        serverflags_command()
    end
    if self.impulse == 12 then
        cycle_weapon_reverse_command(self)
    end
    if self.impulse == 255 then
        quad_cheat(self)
    end

    self.impulse = 0
end

---Called every frame so impulse events can be handled as well as possible
---@param self entity
---@return nil
function M.weapon_frame(self)
    if quake.time() < self.attack_finished then
        return
    end

    impulse_commands(self)

    -- check for attack
    if self.button0 then
        M.super_damage_sound(self)
        attack(self)
    end
end

--[[
========
SuperDamageSound

Plays sound if needed
========
]]
M.superspike_touch = superspike_touch
M.explode = s_explode

---@param self entity
---@return nil
function M.super_damage_sound(self)
    if self.super_damage_finished > quake.time() then
        if self.super_sound < quake.time() then
            self.super_sound = quake.time() + 1
            quake.sound(self, CHAN_BODY, "items/damage3.wav", 1, ATTN_NORM)
        end
    end
end

return M
