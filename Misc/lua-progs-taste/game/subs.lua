-- Port of subs.qc from GPL-licensed CleanFixedQuakeC.
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

local SOLID_TRIGGER = 1

local M = {}

---@param _self entity
---@return nil
M.null = quake.register_function("subs.null", function(_self)
end)

---@param self entity
---@return nil
M.remove = quake.register_function("subs.remove", function(self)
    quake.remove(self)
end)

---QuakeEd only writes a single float for angles (bad idea), so up and down are
---just constant angles.
---@param self entity
---@return nil
function M.set_movedir(self)
    if self.angles == quake.vec3(0, -1, 0) then
        self.movedir = quake.vec3(0, 0, 1)
    elseif self.angles == quake.vec3(0, -2, 0) then
        self.movedir = quake.vec3(0, 0, -1)
    else
        self.movedir = quake.make_vectors(self.angles).forward
    end

    self.angles = quake.vec3(0, 0, 0)
end

---@param self entity
---@return nil
function M.init_trigger(self)
    -- trigger angles are used for one-way touches.  An angle of 0 is assumed
    -- to mean no restrictions, so use a yaw of 360 instead.
    if self.angles ~= quake.vec3(0, 0, 0) then
        M.set_movedir(self)
    end
    self.solid = SOLID_TRIGGER
    -- set size and link into world
    quake.set_model(self, self.model)
    self.movetype = C.MOVETYPE_NONE
    self.modelindex = 0
    self.model = ""
end

--[[
=============
SUB_CalcMove

calculate self.velocity and self.nextthink to reach dest from
self.origin traveling at speed
===============
]]
local calc_move_done

---@param ent entity
---@param tdest vec3
---@param tspeed number
---@param func think_callback
---@return nil
local function calc_move_ent(ent, tdest, tspeed, func)
    M.calc_move(ent, tdest, tspeed, func)
end

---@param self entity
---@param tdest vec3
---@param tspeed number
---@param func think_callback
---@return nil
function M.calc_move(self, tdest, tspeed, func)
    if tspeed == 0 then
        quake.object_error("No speed is defined!")
    end

    self.think1 = func
    self.finaldest = tdest
    self.think = calc_move_done

    if tdest == self.origin then
        self.velocity = quake.vec3(0, 0, 0)
        self.nextthink = self.ltime + 0.1
        return
    end

    -- set destdelta to the vector needed to move
    local vdestdelta = tdest - self.origin

    -- calculate length of vector
    local len = vdestdelta:length()

    -- divide by speed to get time to reach dest
    local traveltime = len / tspeed

    if traveltime < 0.1 then
        self.velocity = quake.vec3(0, 0, 0)
        self.nextthink = self.ltime + 0.1
        return
    end

    -- set nextthink to trigger a think when dest is reached
    self.nextthink = self.ltime + traveltime

    -- scale the destdelta vector by the time spent traveling to get velocity
    -- qcc won't take vec/float
    self.velocity = vdestdelta * (1 / traveltime)
end

---After moving, set origin to exact final destination
---@param self entity
---@return nil
calc_move_done = quake.register_function("subs.calc_move_done", function(self)
    quake.set_origin(self, self.finaldest)
    self.velocity = quake.vec3(0, 0, 0)
    self.nextthink = -1
    if self.think1 then
        self.think1(self)
    end
end)

--[[
=============
SUB_CalcAngleMove

calculate self.avelocity and self.nextthink to reach destangle from
self.angles rotating

The calling function should make sure self.think is valid
===============
]]
local calc_angle_move, calc_angle_move_done

---@param ent entity
---@param destangle vec3
---@param tspeed number
---@param func think_callback
---@return nil
local function calc_angle_move_ent(ent, destangle, tspeed, func)
    calc_angle_move(ent, destangle, tspeed, func)
end

---@param self entity
---@param destangle vec3
---@param tspeed number
---@param func think_callback
---@return nil
function calc_angle_move(self, destangle, tspeed, func)
    if tspeed == 0 then
        quake.object_error("No speed is defined!")
    end

    -- set destdelta to the vector needed to move
    local destdelta = destangle - self.angles

    -- calculate length of vector
    local len = destdelta:length()

    -- divide by speed to get time to reach dest
    local traveltime = len / tspeed

    -- set nextthink to trigger a think when dest is reached
    self.nextthink = self.ltime + traveltime

    -- scale the destdelta vector by the time spent traveling to get velocity
    self.avelocity = destdelta * (1 / traveltime)

    self.think1 = func
    self.finalangle = destangle
    self.think = calc_angle_move_done
end

---After rotating, set angle to exact final angle
---@param self entity
---@return nil
calc_angle_move_done = quake.register_function("subs.calc_angle_move_done", function(self)
    self.angles = self.finalangle
    self.avelocity = quake.vec3(0, 0, 0)
    self.nextthink = -1
    if self.think1 then
        self.think1(self)
    end
end)

--=============================================================================

---@param self entity
---@return nil
local delay_think = quake.register_function("subs.delay_think", function(self)
    M.use_targets(self, self.enemy)
    quake.remove(self)
end)

---the global "activator" should be set to the entity that initiated the firing.
---
---If self.delay is set, a DelayedUse entity will be created that will actually
---call use_targets after that many seconds have passed.
---
---Centerprints any self.message to the activator.
---
---Removes all entities with a targetname that match self.killtarget,
---and removes them, so some events can remove other triggers.
---
---Search for (string)targetname in all entities that
---match (string)self.target and call their .use function
---@param self entity
---@param activator entity
---@return nil
M.use_targets = quake.register_function("subs.use_targets", function(self, activator)
    -- check for a delay
    if self.delay ~= 0 then
        -- create a temp object to fire at a later time
        local t = quake.spawn()
        t.classname = "DelayedUse"
        t.nextthink = quake.time() + self.delay
        t.think = delay_think
        t.enemy = activator
        t.message = self.message
        t.killtarget = self.killtarget
        t.target = self.target
        return
    end

    -- print the message
    if activator.classname == "player" and self.message ~= "" then
        quake.center_print(activator, self.message)
        if self.noise == "" then
            quake.sound(activator, C.CHAN_VOICE, "misc/talk.wav", 1, C.ATTN_NORM)
        end
    end

    -- kill the killtargets
    if self.killtarget ~= "" then
        ---@type entity?
        local t = quake.world
        while true do
            t = quake.find(t, "targetname", self.killtarget)
            if not t then
                return
            end
            quake.remove(t)
        end
    end

    -- fire targets
    if self.target ~= "" then
        ---@type entity?
        local t = quake.world
        while true do
            t = quake.find(t, "targetname", self.target)
            if not t then
                return
            end
            if t.use ~= M.null and t.use then
                t.use(t, activator)
            end
        end
    end
end)

---in nightmare mode, all attack_finished times become 0
---some monsters refire twice automatically
---@param self entity
---@param normal number
---@return nil
function M.attack_finished(self, normal)
    -- refire count for nightmare
    self.cnt = 0
    if quake.cvar("skill") ~= 3 then
        self.attack_finished = quake.time() + normal
    end
end

---@param self entity
---@param thinkst think_callback
---@return nil
function M.check_refire(self, thinkst)
    local ai = require("game.ai")

    if quake.cvar("skill") ~= 3 then
        return
    end
    if self.cnt == 1 then
        return
    end
    if not ai.visible(self, self.enemy) then
        return
    end
    self.cnt = 1
    self.think = thinkst
end

return M
