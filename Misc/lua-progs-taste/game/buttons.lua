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
-- Port of buttons.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

-- button and multiple button

local subs = require("game.subs")

local STATE_TOP, STATE_BOTTOM, STATE_UP, STATE_DOWN = 0, 1, 2, 3
local MOVETYPE_PUSH, SOLID_BSP = 7, 4
local DAMAGE_NO, DAMAGE_YES = 0, 1
local CHAN_VOICE, ATTN_NORM = 2, 1

local button_return

---@param self entity
---@return nil
local button_wait = quake.register_function("buttons.button_wait", function(self)
    self.state = STATE_TOP
    self.nextthink = self.ltime + self.wait
    self.think = button_return
    subs.use_targets(self, self.enemy or quake.world)
    self.frame = 1 -- use alternate textures
end)

---@param self entity
---@return nil
local button_done = quake.register_function("buttons.button_done", function(self)
    self.state = STATE_BOTTOM
end)

---@param self entity
---@return nil
button_return = quake.register_function("buttons.button_return", function(self)
    self.state = STATE_DOWN
    subs.calc_move(self, self.pos1, self.speed, button_done)
    self.frame = 0 -- use normal textures
    if self.health ~= 0 then
        self.takedamage = DAMAGE_YES -- can be shot again
    end
end)

-- do nothing, just don't ome all the way back out
---@param _self entity
---@param _other entity
---@return nil
local button_blocked = quake.register_function("buttons.button_blocked", function(_self, _other)
end)

---@param self entity
---@return nil
local function button_fire(self)
    if self.state == STATE_UP or self.state == STATE_TOP then
        return
    end

    quake.sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM)

    self.state = STATE_UP
    subs.calc_move(self, self.pos2, self.speed, button_wait)
end

---@param self entity
---@param activator entity
---@return nil
local button_use = quake.register_function("buttons.button_use", function(self, activator)
    self.enemy = activator
    button_fire(self)
end)

---@param self entity
---@param other entity
---@return nil
local button_touch = quake.register_function("buttons.button_touch", function(self, other)
    if other.classname ~= "player" then
        return
    end
    self.enemy = other
    button_fire(self)
end)

---@param self entity
---@return nil
local button_killed = quake.register_function("buttons.button_killed", function(self)
    self.enemy = quake.globals.damage_attacker
    self.health = self.max_health
    self.takedamage = DAMAGE_NO -- wil be reset upon return
    button_fire(self)
end)

---QUAKED func_button (0 .5 .8) ?
---When a button is touched, it moves some distance in the direction of it's angle, triggers all of it's targets, waits some time, then returns to it's original position where it can be triggered again.
---
---"angle"     determines the opening direction
---"target"    all entities with a matching targetname will be used
---"speed"     override the default 40 speed
---"wait"      override the default 1 second wait (-1 = never return)
---"lip"       override the default 4 pixel lip remaining at end of move
---"health"    if set, the button must be killed instead of touched
---"sounds"
---0) steam metal
---1) wooden clunk
---2) metallic click
---3) in-out
---@param self entity
---@return nil
local function func_button(self)
    if self.sounds == 0 then
        quake.precache_sound("buttons/airbut1.wav")
        self.noise = "buttons/airbut1.wav"
    end
    if self.sounds == 1 then
        quake.precache_sound("buttons/switch21.wav")
        self.noise = "buttons/switch21.wav"
    end
    if self.sounds == 2 then
        quake.precache_sound("buttons/switch02.wav")
        self.noise = "buttons/switch02.wav"
    end
    if self.sounds == 3 then
        quake.precache_sound("buttons/switch04.wav")
        self.noise = "buttons/switch04.wav"
    end

    subs.set_movedir(self)

    self.movetype = MOVETYPE_PUSH
    self.solid = SOLID_BSP
    quake.set_model(self, self.model)

    self.blocked = button_blocked
    self.use = button_use

    if self.health ~= 0 then
        self.max_health = self.health
        self.th_die = button_killed
        self.takedamage = DAMAGE_YES
    else
        self.touch = button_touch
    end

    if self.speed == 0 then
        self.speed = 40
    end
    if self.wait == 0 then
        self.wait = 1
    end
    if self.lip == 0 then
        self.lip = 4
    end

    self.state = STATE_BOTTOM

    self.pos1 = self.origin
    self.pos2 = self.pos1 + self.movedir * (math.abs(self.movedir:dot(self.size)) - self.lip)
end

quake.register_entity("func_button", func_button)
