-- Port of ai.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

--[[ Copyright (C) 1996-1997 Id Software, Inc.

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

local quake = require("quake")
local C = require("game.constants")
local fight = require("game.fight")
local subs = require("game.subs")

local ATTN_IDLE = 2
local SOLID_TRIGGER = 1

local M = {}

--[[
.enemy
Will be world if not currently angry at anyone.

.movetarget
The next path spot to walk toward.  If .enemy, ignore .movetarget.
When an enemy is killed, the monster will try to return to it's path.

.hunt_time
Set to time + something when the player is in sight, but movement straight for
him is blocked.  This causes the monster to use wall following code for
movement direction instead of sighting on the player.

.ideal_yaw
A yaw angle of the intended direction, which will be turned towards at up
to 45 deg / state.  If the enemy is in view and hunt_time is not active,
this will be the exact line towards the enemy.

.pausetime
A monster will leave it's stand state and head towards it's .movetarget when
time > .pausetime.

walkmove(angle, speed) primitive is all or nothing
]]

--
-- globals
--

--
-- when a monster becomes angry at a player, that monster will be used
-- as the sight target the next frame so that monsters near that one
-- will wake up even if they wouldn't have noticed the player
--
---@param v number
---@return number
local function angle_mod(v)
    while v >= 360 do
        v = v - 360
    end
    while v < 0 do
        v = v + 360
    end
    return v
end

--[[
==============================================================================

MOVETARGET CODE

The angle of the movetarget effects standing and bowing direction, but has no effect on movement, which always heads to the next target.

targetname
must be present.  The name of this movetarget.

target
the next spot to move to.  If not present, stop here for good.

pausetime
The number of seconds to spend standing or bowing for path_stand or path_bow

==============================================================================
]]

local t_movetarget

---@param self entity
---@return nil
local function movetarget_f(self)
    if self.targetname == "" then
        quake.object_error("monster_movetarget: no targetname")
    end

    self.solid = SOLID_TRIGGER
    self.touch = t_movetarget
    quake.set_size(self, quake.vec3(-8, -8, -8), quake.vec3(8, 8, 8))
end

---QUAKED path_corner (0.5 0.3 0) (-8 -8 -8) (8 8 8)
---Monsters will continue walking towards the next target corner.
---@param self entity
---@return nil
local function path_corner(self)
    movetarget_f(self)
end

---Something has bumped into a movetarget.  If it is a monster
---moving towards it, change the next destination and continue.
---@param self entity
---@param other entity
---@return nil
t_movetarget = quake.register_function("ai.t_movetarget", function(self, other)
    if other.movetarget ~= self then
        return
    end

    if other.enemy then
        return -- fighting, not following a path
    end

    self, other = other, self

    if self.classname == "monster_ogre" then
        quake.sound(self, C.CHAN_VOICE, "ogre/ogdrag.wav", 1, ATTN_IDLE) -- play chainsaw drag sound
    end

    self.goalentity = quake.find(quake.world, "targetname", other.target)
    self.movetarget = self.goalentity
    self.ideal_yaw = quake.vector_to_yaw(self.goalentity.origin - self.origin)
    if not self.movetarget then
        self.pausetime = quake.time() + 999999
        self.th_stand(self)
        return
    end
end)

quake.register_entity("path_corner", path_corner)

--============================================================================

---returns the range catagorization of an entity reletive to self
---0 melee range, will become hostile even if back is turned
---1 visibility and infront, or visibility and show hostile
---2 infront and show hostile
---3 only triggered by damage
---@param self entity
---@param targ entity
---@return integer
local function range(self, targ)
    local spot1 = self.origin + self.view_ofs
    local spot2 = targ.origin + targ.view_ofs

    local r = (spot1 - spot2):length()
    if r < 120 then
        return C.RANGE_MELEE
    end
    if r < 500 then
        return C.RANGE_NEAR
    end
    if r < 1000 then
        return C.RANGE_MID
    end
    return C.RANGE_FAR
end

---returns 1 if the entity is visible to self, even if not infront ()
---@param self entity
---@param targ entity
---@return boolean
function M.visible(self, targ)
    local spot1 = self.origin + self.view_ofs
    local spot2 = targ.origin + targ.view_ofs
    local trace = quake.trace_line(spot1, spot2, true, self) -- see through other monsters

    if trace.in_open and trace.in_water then
        return false -- sight line crossed contents
    end

    if trace.fraction == 1 then
        return true
    end
    return false
end

---returns 1 if the entity is in front (in sight) of self
---@param self entity
---@param targ entity
---@return boolean
local function in_front(self, targ)
    local forward = quake.make_vectors(self.angles).forward
    local vec = (targ.origin - self.origin):normalized()
    local dot = vec:dot(forward)

    if dot > 0.3 then
        return true
    end
    return false
end

--============================================================================

---@param self entity
---@return nil
local function hunt_target(self)
    self.goalentity = self.enemy
    self.think = self.th_run
    self.ideal_yaw = quake.vector_to_yaw(self.enemy.origin - self.origin)
    self.nextthink = quake.time() + 0.1
    subs.attack_finished(self, 1) -- wait a while before first attack
end

---@param self entity
---@return nil
local function sight_sound(self)
    if self.classname == "monster_ogre" then
        quake.sound(self, C.CHAN_VOICE, "ogre/ogwake.wav", 1, C.ATTN_NORM)
    elseif self.classname == "monster_knight" then
        quake.sound(self, C.CHAN_VOICE, "knight/ksight.wav", 1, C.ATTN_NORM)
    elseif self.classname == "monster_shambler" then
        quake.sound(self, C.CHAN_VOICE, "shambler/ssight.wav", 1, C.ATTN_NORM)
    elseif self.classname == "monster_demon1" then
        quake.sound(self, C.CHAN_VOICE, "demon/sight2.wav", 1, C.ATTN_NORM)
    elseif self.classname == "monster_wizard" then
        quake.sound(self, C.CHAN_VOICE, "wizard/wsight.wav", 1, C.ATTN_NORM)
    elseif self.classname == "monster_zombie" then
        quake.sound(self, C.CHAN_VOICE, "zombie/z_idle.wav", 1, C.ATTN_NORM)
    elseif self.classname == "monster_dog" then
        quake.sound(self, C.CHAN_VOICE, "dog/dsight.wav", 1, C.ATTN_NORM)
    elseif self.classname == "monster_hell_knight" then
        quake.sound(self, C.CHAN_VOICE, "hknight/sight1.wav", 1, C.ATTN_NORM)
    elseif self.classname == "monster_tarbaby" then
        quake.sound(self, C.CHAN_VOICE, "blob/sight1.wav", 1, C.ATTN_NORM)
    elseif self.classname == "monster_enforcer" then
        local rsnd = math.floor(quake.random() * 3 + 0.5)
        if rsnd == 1 then
            quake.sound(self, C.CHAN_VOICE, "enforcer/sight1.wav", 1, C.ATTN_NORM)
        elseif rsnd == 2 then
            quake.sound(self, C.CHAN_VOICE, "enforcer/sight2.wav", 1, C.ATTN_NORM)
        elseif rsnd == 0 then
            quake.sound(self, C.CHAN_VOICE, "enforcer/sight3.wav", 1, C.ATTN_NORM)
        else
            quake.sound(self, C.CHAN_VOICE, "enforcer/sight4.wav", 1, C.ATTN_NORM)
        end
    elseif self.classname == "monster_army" then
        quake.sound(self, C.CHAN_VOICE, "soldier/sight1.wav", 1, C.ATTN_NORM)
    elseif self.classname == "monster_shalrath" then
        quake.sound(self, C.CHAN_VOICE, "shalrath/sight.wav", 1, C.ATTN_NORM)
    end
end

---@param self entity
---@return nil
M.found_target = quake.register_function("ai.found_target", function(self)
    if self.enemy.classname == "player" then
        -- let other monsters see this monster for a while
        quake.globals.sight_entity = self
        quake.globals.sight_entity_time = quake.time()
    end

    self.show_hostile = quake.time() + 1 -- wake up other monsters

    sight_sound(self)
    hunt_target(self)
end)

---Self is currently not attacking anything, so try to find a target
---
---Returns TRUE if an enemy was sighted
---
---When a player fires a missile, the point of impact becomes a fakeplayer so
---that monsters that see the impact will respond as if they had seen the
---player.
---
---To avoid spending too much time, only a single client (or fakeclient) is
---checked each frame.  This means multi player games will have slightly
---slower noticing monsters.
---@param self entity
---@return boolean
local function find_target(self)
    local client

    -- if the first spawnflag bit is set, the monster will only wake up on
    -- really seeing the player, not another monster getting angry

    -- spawnflags & 3 is a big hack, because zombie crucified used the first
    -- spawn flag prior to the ambush flag, and I forgot about it, so the second
    -- spawn flag works as well
    if quake.globals.sight_entity_time >= quake.time() - 0.1 and (self.spawnflags & 3) == 0 then
        client = assert(quake.globals.sight_entity, "recent sight entity is missing")
        if client.enemy == self.enemy then
            return false
        end
    else
        client = quake.check_client()
        if not client then
            return false -- current check entity isn't in PVS
        end
    end

    if client == self.enemy then
        return false
    end

    if (client.flags & C.FL_NOTARGET) ~= 0 then
        return false
    end
    if (client.items & C.IT_INVISIBILITY) ~= 0 then
        return false
    end

    local r = range(self, client)
    if r == C.RANGE_FAR then
        return false
    end

    if not M.visible(self, client) then
        return false
    end

    if r == C.RANGE_NEAR then
        if client.show_hostile < quake.time() and not in_front(self, client) then
            return false
        end
    elseif r == C.RANGE_MID then
        if --[[ client.show_hostile < time || ]] not in_front(self, client) then
            return false
        end
    end

    --
    -- got one
    --
    self.enemy = client
    if self.enemy.classname ~= "player" then
        self.enemy = self.enemy.enemy
        if not self.enemy or self.enemy.classname ~= "player" then
            self.enemy = quake.world
            return false
        end
    end

    M.found_target(self)

    return true
end

--=============================================================================

---@param self entity
---@param dist number
---@return nil
function M.forward(self, dist)
    quake.walk_move(self, self.angles.y, dist)
end

---@param self entity
---@param dist number
---@return nil
function M.back(self, dist)
    quake.walk_move(self, self.angles.y + 180, dist)
end

---stagger back a bit
---@param self entity
---@param dist number
---@return nil
function M.pain(self, dist)
    M.back(self, dist)
end

---stagger back a bit
---@param self entity
---@param dist number
---@return nil
function M.pain_forward(self, dist)
    quake.walk_move(self, self.ideal_yaw, dist)
end

---The monster is walking it's beat
---@param self entity
---@param dist number
---@return nil
function M.walk(self, dist)
    quake.globals.movedist = dist

    -- check for noticing a player
    if find_target(self) then
        return
    end

    quake.move_to_goal(self, dist)
end

---The monster is staying in one place for a while, with slight angle turns
---@param self entity
---@return nil
function M.stand(self)
    if find_target(self) then
        return
    end

    if quake.time() > self.pausetime then
        self.th_walk(self)
        return
    end
end

---don't move, but turn towards ideal_yaw
---@param self entity
---@return nil
function M.turn(self)
    if find_target(self) then
        return
    end

    quake.change_yaw(self)
end

--=============================================================================

---@param self entity
---@param dest3 vec3
---@return nil
local function choose_turn(self, dest3)
    local dir = self.origin - dest3
    local normal = quake.globals.trace_plane_normal
    local newdir = quake.vec3(normal.y, 0 - normal.x, 0)

    if dir:dot(newdir) > 0 then
        dir = quake.vec3(0 - normal.y, normal.x, 0)
    else
        dir = quake.vec3(normal.y, 0 - normal.x, 0)
    end

    self.ideal_yaw = quake.vector_to_yaw(dir)
end

---@param self entity
---@return boolean
local function facing_ideal(self)
    local delta = angle_mod(self.angles.y - self.ideal_yaw)
    if delta > 45 and delta < 315 then
        return false
    end
    return true
end

--=============================================================================

---@param self entity
---@param enemy_vis boolean
---@param enemy_range integer
---@return boolean
local function check_any_attack(self, enemy_vis, enemy_range)
    if not enemy_vis then
        return false
    end
    if self.classname == "monster_army" then
        return fight.soldier_check_attack(self, enemy_range)
    end
    if self.classname == "monster_ogre" then
        return fight.ogre_check_attack(self, enemy_range, enemy_vis)
    end
    if self.classname == "monster_shambler" then
        return fight.sham_check_attack(self, enemy_range, enemy_vis)
    end
    if self.classname == "monster_demon1" then
        return self.check_attack(self)
    end
    if self.classname == "monster_dog" then
        return self.check_attack(self)
    end
    if self.classname == "monster_wizard" then
        return self.check_attack(self)
    end
    return fight.check_attack(self, enemy_range)
end

---Turn and close until within an angle to launch a melee attack
---@param self entity
---@param enemy_yaw number
---@return nil
local function run_melee(self, enemy_yaw)
    self.ideal_yaw = enemy_yaw
    quake.change_yaw(self)

    if facing_ideal(self) then
        self.th_melee(self)
        self.attack_state = C.AS_STRAIGHT
    end
end

---Turn in place until within an angle to launch a missile attack
---@param self entity
---@param enemy_yaw number
---@return nil
local function run_missile(self, enemy_yaw)
    self.ideal_yaw = enemy_yaw
    quake.change_yaw(self)
    if facing_ideal(self) then
        self.th_missile(self)
        self.attack_state = C.AS_STRAIGHT
    end
end

---Strafe sideways, but stay at aproximately the same range
---@param self entity
---@param enemy_yaw number
---@param movedist number
---@return nil
local function run_slide(self, enemy_yaw, movedist)
    self.ideal_yaw = enemy_yaw
    quake.change_yaw(self)
    local ofs
    if self.lefty ~= 0 then
        ofs = 90
    else
        ofs = -90
    end

    if quake.walk_move(self, self.ideal_yaw + ofs, movedist) then
        return
    end

    self.lefty = 1 - self.lefty

    quake.walk_move(self, self.ideal_yaw - ofs, movedist)
end

---The monster has an enemy it is trying to kill
---@param self entity
---@param dist number
---@return nil
function M.run(self, dist)
    quake.globals.movedist = dist
    -- see if the enemy is dead
    if not self.enemy or self.enemy.health <= 0 then
        self.enemy = quake.world
        -- FIXME: look all around for other targets
        if self.oldenemy and self.oldenemy.health > 0 then
            self.enemy = self.oldenemy
            hunt_target(self)
        else
            if self.movetarget then
                self.th_walk(self)
            else
                self.th_stand(self)
            end
            return
        end
    end

    -- wake up other monsters
    self.show_hostile = quake.time() + 1

    -- check knowledge of enemy
    local enemy_vis = M.visible(self, self.enemy)
    quake.globals.enemy_vis = enemy_vis
    if enemy_vis then
        self.search_time = quake.time() + 5
    end

    -- look for other coop players
    if quake.cvar("coop") ~= 0 and self.search_time < quake.time() then
        if find_target(self) then
            return
        end
    end

    local enemy_infront = in_front(self, self.enemy)
    local enemy_range = range(self, self.enemy)
    local enemy_yaw = quake.vector_to_yaw(self.enemy.origin - self.origin)
    quake.globals.enemy_infront = enemy_infront
    quake.globals.enemy_range = enemy_range
    quake.globals.enemy_yaw = enemy_yaw

    if self.attack_state == C.AS_MISSILE then
        run_missile(self, enemy_yaw)
        return
    end
    if self.attack_state == C.AS_MELEE then
        run_melee(self, enemy_yaw)
        return
    end

    if check_any_attack(self, enemy_vis, enemy_range) then
        return -- beginning an attack
    end

    if self.attack_state == C.AS_SLIDING then
        run_slide(self, enemy_yaw, dist)
        return
    end

    -- head straight in
    quake.move_to_goal(self, dist) -- done in C code...
end

return M
