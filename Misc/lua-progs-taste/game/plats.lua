--[[
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place, Suite 330, Boston, MA 02111-1307 USA.

See file, 'COPYING', for details.
]]
-- Port of plats.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local combat = require("game.combat")
local subs = require("game.subs")

local M = {}

local STATE_TOP, STATE_BOTTOM, STATE_UP, STATE_DOWN = 0, 1, 2, 3
local MOVETYPE_NONE, MOVETYPE_PUSH = 0, 7
local SOLID_NOT, SOLID_TRIGGER, SOLID_BSP = 0, 1, 4
local CHAN_VOICE, ATTN_NORM = 2, 1
local PLAT_LOW_TRIGGER = 1

local plat_center_touch, plat_outside_touch, plat_trigger_use
local plat_go_up, plat_go_down, plat_crush

local function plat_spawn_inside_trigger(self)
    local trigger
    local tmin, tmax

    -- middle trigger
    trigger = quake.spawn()
    trigger.touch = plat_center_touch
    trigger.movetype = MOVETYPE_NONE
    trigger.solid = SOLID_TRIGGER
    trigger.enemy = self

    tmin = self.mins + quake.vec3(25, 25, 0)
    tmax = self.maxs - quake.vec3(25, 25, -8)
    tmin = quake.vec3(tmin.x, tmin.y, tmax.z - (self.pos1.z - self.pos2.z + 8))
    if (self.spawnflags & PLAT_LOW_TRIGGER) ~= 0 then
        tmax = quake.vec3(tmax.x, tmax.y, tmin.z + 8)
    end

    if self.size.x <= 50 then
        tmin = quake.vec3((self.mins.x + self.maxs.x) / 2, tmin.y, tmin.z)
        tmax = quake.vec3(tmin.x + 1, tmax.y, tmax.z)
    end
    if self.size.y <= 50 then
        tmin = quake.vec3(tmin.x, (self.mins.y + self.maxs.y) / 2, tmin.z)
        tmax = quake.vec3(tmax.x, tmin.y + 1, tmax.z)
    end

    quake.set_size(trigger, tmin, tmax)
end

local function plat_hit_top(self)
    quake.sound(self, CHAN_VOICE, self.noise1, 1, ATTN_NORM)
    self.state = STATE_TOP
    self.think = plat_go_down
    self.nextthink = self.ltime + 3
end

local function plat_hit_bottom(self)
    quake.sound(self, CHAN_VOICE, self.noise1, 1, ATTN_NORM)
    self.state = STATE_BOTTOM
end

plat_go_down = function(self)
    quake.sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM)
    self.state = STATE_DOWN
    subs.calc_move(self, self.pos2, self.speed, plat_hit_bottom)
end

plat_go_up = function(self)
    quake.sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM)
    self.state = STATE_UP
    subs.calc_move(self, self.pos1, self.speed, plat_hit_top)
end

plat_center_touch = function(self, other)
    if other.classname ~= "player" then
        return
    end

    if other.health <= 0 then
        return
    end

    self = self.enemy
    if self.state == STATE_BOTTOM then
        plat_go_up(self)
    elseif self.state == STATE_TOP then
        -- delay going down
        self.nextthink = self.ltime + 1
    end
end

plat_outside_touch = function(self, other)
    if other.classname ~= "player" then
        return
    end

    if other.health <= 0 then
        return
    end

    self = self.enemy
    if self.state == STATE_TOP then
        plat_go_down(self)
    end
end

plat_trigger_use = function(self, _activator)
    if self.think then
        -- allready activated
        return
    end
    plat_go_down(self)
end

plat_crush = function(self, other)
    combat.damage(other, self, self, 1)

    if self.state == STATE_UP then
        plat_go_down(self)
    elseif self.state == STATE_DOWN then
        plat_go_up(self)
    else
        quake.object_error(self, "plat_crush: bad self.state\n")
    end
end

local function plat_use(self, _activator)
    self.use = subs.null
    if self.state ~= STATE_UP then
        quake.object_error(self, "plat_use: not in up state")
    end
    plat_go_down(self)
end

--[[QUAKED func_plat (0 .5 .8) ? PLAT_LOW_TRIGGER
speed default 150

Plats are always drawn in the extended position, so they will light correctly.

If the plat is the target of another trigger or button, it will start out disabled in the extended position until it is trigger, when it will lower and become a normal plat.

If the "height" key is set, that will determine the amount the plat moves, instead of being implicitly determined by the model's height.
Set "sounds" to one of the following:
1) base fast
2) chain slow
]]
function M.func_plat(self)
    if self.t_length == 0 then
        self.t_length = 80
    end
    if self.t_width == 0 then
        self.t_width = 10
    end

    if self.sounds == 0 then
        self.sounds = 2
    end

    -- FIX THIS TO LOAD A GENERIC PLAT SOUND
    if self.sounds == 1 then
        quake.precache_sound("plats/plat1.wav")
        quake.precache_sound("plats/plat2.wav")
        self.noise = "plats/plat1.wav"
        self.noise1 = "plats/plat2.wav"
    end

    if self.sounds == 2 then
        quake.precache_sound("plats/medplat1.wav")
        quake.precache_sound("plats/medplat2.wav")
        self.noise = "plats/medplat1.wav"
        self.noise1 = "plats/medplat2.wav"
    end

    self.mangle = self.angles
    self.angles = quake.vec3(0, 0, 0)

    self.classname = "plat"
    self.solid = SOLID_BSP
    self.movetype = MOVETYPE_PUSH
    quake.set_origin(self, self.origin)
    quake.set_model(self, self.model)
    quake.set_size(self, self.mins, self.maxs)

    self.blocked = plat_crush
    if self.speed == 0 then
        self.speed = 150
    end

    -- pos1 is the top position, pos2 is the bottom
    self.pos1 = self.origin
    self.pos2 = self.origin
    if self.height ~= 0 then
        self.pos2 = quake.vec3(self.pos2.x, self.pos2.y, self.origin.z - self.height)
    else
        self.pos2 = quake.vec3(self.pos2.x, self.pos2.y, self.origin.z - self.size.z + 8)
    end

    self.use = plat_trigger_use

    -- the "start moving" trigger
    plat_spawn_inside_trigger(self)

    if self.targetname ~= "" then
        self.state = STATE_UP
        self.use = plat_use
    else
        quake.set_origin(self, self.pos2)
        self.state = STATE_BOTTOM
    end
end

--============================================================================

local train_next, func_train_find

local function train_blocked(self, other)
    if quake.time() < self.attack_finished then
        return
    end
    self.attack_finished = quake.time() + 0.5
    combat.damage(other, self, self, self.dmg)
end

local function train_use(self, _activator)
    if self.think ~= func_train_find then
        -- already activated
        return
    end
    train_next(self)
end

local function train_wait(self)
    if self.wait ~= 0 then
        self.nextthink = self.ltime + self.wait
        quake.sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM)
    else
        self.nextthink = self.ltime + 0.1
    end

    self.think = train_next
end

train_next = function(self)
    local targ

    targ = quake.find(quake.world, "targetname", self.target)
    self.target = targ.target
    if self.target == "" then
        quake.object_error(self, "train_next: no next target")
    end
    if targ.wait ~= 0 then
        self.wait = targ.wait
    else
        self.wait = 0
    end
    quake.sound(self, CHAN_VOICE, self.noise1, 1, ATTN_NORM)
    subs.calc_move(self, targ.origin - self.mins, self.speed, train_wait)
end

func_train_find = function(self)
    local targ

    targ = quake.find(quake.world, "targetname", self.target)
    self.target = targ.target
    quake.set_origin(self, targ.origin - self.mins)
    if self.targetname == "" then
        -- not triggered, so start immediately
        self.nextthink = self.ltime + 0.1
        self.think = train_next
    end
end

--[[QUAKED func_train (0 .5 .8) ?
Trains are moving platforms that players can ride.
The targets origin specifies the min point of the train at each corner.
The train spawns at the first target it is pointing at.
If the train is the target of a button or trigger, it will not begin moving until activated.
speed default 100
dmg default 2
sounds
1) ratchet metal
]]
function M.func_train(self)
    if self.speed == 0 then self.speed = 100 end
    if self.target == "" then quake.object_error(self, "func_train without a target") end
    if self.dmg == 0 then self.dmg = 2 end

    if self.sounds == 0 then
        self.noise = "misc/null.wav"
        quake.precache_sound("misc/null.wav")
        self.noise1 = "misc/null.wav"
        quake.precache_sound("misc/null.wav")
    end

    if self.sounds == 1 then
        self.noise = "plats/train2.wav"
        quake.precache_sound("plats/train2.wav")
        self.noise1 = "plats/train1.wav"
        quake.precache_sound("plats/train1.wav")
    end

    self.cnt = 1
    self.solid = SOLID_BSP
    self.movetype = MOVETYPE_PUSH
    self.blocked = train_blocked
    self.use = train_use
    self.classname = "train"

    quake.set_model(self, self.model)
    quake.set_size(self, self.mins, self.maxs)
    quake.set_origin(self, self.origin)

    -- start trains on the second frame, to make sure their targets have had
    -- a chance to spawn
    self.nextthink = self.ltime + 0.1
    self.think = func_train_find
end

--[[QUAKED misc_teleporttrain (0 .5 .8) (-8 -8 -8) (8 8 8)
This is used for the final bos
]]
function M.misc_teleporttrain(self)
    if self.speed == 0 then self.speed = 100 end
    if self.target == "" then quake.object_error(self, "func_train without a target") end

    self.cnt = 1
    self.solid = SOLID_NOT
    self.movetype = MOVETYPE_PUSH
    self.blocked = train_blocked
    self.use = train_use
    self.avelocity = quake.vec3(100, 200, 300)

    self.noise = "misc/null.wav"
    quake.precache_sound("misc/null.wav")
    self.noise1 = "misc/null.wav"
    quake.precache_sound("misc/null.wav")

    quake.precache_model2("progs/teleport.mdl")
    quake.set_model(self, "progs/teleport.mdl")
    quake.set_size(self, self.mins, self.maxs)
    quake.set_origin(self, self.origin)

    -- start trains on the second frame, to make sure their targets have had
    -- a chance to spawn
    self.nextthink = self.ltime + 0.1
    self.think = func_train_find
end

quake.register_entity("func_plat", M.func_plat)
quake.register_entity("func_train", M.func_train)
quake.register_entity("misc_teleporttrain", M.misc_teleporttrain)

return M
