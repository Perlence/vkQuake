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
-- Port of doors.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local combat = require("game.combat")
local subs = require("game.subs")

local M = {}

local DOOR_START_OPEN, DOOR_DONT_LINK = 1, 4
local DOOR_GOLD_KEY, DOOR_SILVER_KEY, DOOR_TOGGLE = 8, 16, 32
local STATE_TOP, STATE_BOTTOM, STATE_UP, STATE_DOWN = 0, 1, 2, 3
local MOVETYPE_NONE, MOVETYPE_PUSH = 0, 7
local SOLID_TRIGGER, SOLID_BSP = 1, 4
local DAMAGE_NO, DAMAGE_YES = 0, 1
local CHAN_BODY, CHAN_VOICE, CHAN_ITEM = 4, 2, 3
local ATTN_NORM = 1
local IT_KEY1, IT_KEY2 = 131072, 262144

--[[
Doors are similar to buttons, but can spawn a fat trigger field around them
to open without a touch, and they link together to form simultanious
double/quad doors.

Door.owner is the master door. If there is only one door, it points to itself.
If multiple doors, all will point to a single one.

Door.enemy chains from the master door through all doors linked in the chain.
]]

--[[
=============================================================================

THINK FUNCTIONS

=============================================================================
]]

local door_go_down, door_go_up

---@param self entity
---@param other entity
---@return nil
local function door_blocked(self, other)
    combat.damage(other, self, self, self.dmg)

    -- if a door has a negative wait, it would never come back if blocked,
    -- so let it just squash the object to death real fast
    if self.wait >= 0 then
        if self.state == STATE_DOWN then door_go_up(self) else door_go_down(self) end
    end
end

---@param self entity
---@return nil
local function door_hit_top(self)
    quake.sound(self, CHAN_VOICE, self.noise1, 1, ATTN_NORM)
    self.state = STATE_TOP
    if (self.spawnflags & DOOR_TOGGLE) ~= 0 then
        return -- don't come down automatically
    end
    self.think = door_go_down
    self.nextthink = self.ltime + self.wait
end

---@param self entity
---@return nil
local function door_hit_bottom(self)
    quake.sound(self, CHAN_VOICE, self.noise1, 1, ATTN_NORM)
    self.state = STATE_BOTTOM
end

---@param self entity
---@return nil
door_go_down = function(self)
    quake.sound(self, CHAN_VOICE, self.noise2, 1, ATTN_NORM)
    if self.max_health ~= 0 then
        self.takedamage = DAMAGE_YES
        self.health = self.max_health
    end
    self.state = STATE_DOWN
    subs.calc_move(self, self.pos1, self.speed, door_hit_bottom)
end

---@param self entity
---@return nil
function door_go_up(self)
    if self.state == STATE_UP then
        -- allready going up
        return
    end
    if self.state == STATE_TOP then
        -- reset top wait time
        self.nextthink = self.ltime + self.wait
        return
    end
    quake.sound(self, CHAN_VOICE, self.noise2, 1, ATTN_NORM)
    self.state = STATE_UP
    subs.calc_move(self, self.pos2, self.speed, door_hit_top)
    subs.use_targets(self, quake.globals.activator)
end

--[[
=============================================================================

ACTIVATION FUNCTIONS

=============================================================================
]]

---@param self entity
---@param activator entity
---@return nil
local function door_fire(self, activator)
    if self.owner ~= self then quake.object_error(self, "door_fire: self.owner != self") end

    -- play use key sound
    if self.items ~= 0 then quake.sound(self, CHAN_ITEM, self.noise4, 1, ATTN_NORM) end
    self.message = "" -- no more message

    if (self.spawnflags & DOOR_TOGGLE) ~= 0 and (self.state == STATE_UP or self.state == STATE_TOP) then
        local starte = self
        repeat
            door_go_down(self)
            self = self.enemy
        until self == starte or self == quake.world
        return
    end

    -- trigger all paired doors
    local starte = self
    repeat
        quake.globals.activator = activator
        door_go_up(self)
        self = self.enemy
    until self == starte or self == quake.world
end

---@param self entity
---@param activator entity
---@return nil
local function door_use(self, activator)
    -- door message are for touch only
    self.message = ""
    self.owner.message = ""
    self.enemy.message = ""
    door_fire(self.owner, activator)
end

---@param self entity
---@param other entity
---@return nil
local function door_trigger_touch(self, other)
    if other.health <= 0 then return end
    if quake.time() < self.attack_finished then return end
    self.attack_finished = quake.time() + 1
    door_use(self.owner, other)
end

---@param self entity
---@return nil
local function door_killed(self)
    local owner = assert(self.owner, "door has no owner")
    owner.health = owner.max_health
    -- will be reset upon return
    owner.takedamage = DAMAGE_NO
    door_use(owner, quake.globals.damage_attacker)
end

---Prints messages and opens key doors
---@param self entity
---@param other entity
---@return nil
local function door_touch(self, other)
    if other.classname ~= "player" then return end
    if self.owner.attack_finished > quake.time() then return end
    self.owner.attack_finished = quake.time() + 2

    if self.owner.message ~= "" then
        quake.center_print(other, self.owner.message)
        quake.sound(other, CHAN_VOICE, "misc/talk.wav", 1, ATTN_NORM)
    end

    -- key door stuff
    if self.items == 0 then return end

    -- FIXME: blink key on player's status bar
    if (self.items & other.items) ~= self.items then
        if self.owner.items == IT_KEY1 then
            if quake.world.worldtype == 2 then
                quake.center_print(other, "You need the silver keycard")
                quake.sound(self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
            elseif quake.world.worldtype == 1 then
                quake.center_print(other, "You need the silver runekey")
                quake.sound(self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
            elseif quake.world.worldtype == 0 then
                quake.center_print(other, "You need the silver key")
                quake.sound(self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
            end
        else
            if quake.world.worldtype == 2 then
                quake.center_print(other, "You need the gold keycard")
                quake.sound(self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
            elseif quake.world.worldtype == 1 then
                quake.center_print(other, "You need the gold runekey")
                quake.sound(self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
            elseif quake.world.worldtype == 0 then
                quake.center_print(other, "You need the gold key")
                quake.sound(self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
            end
        end
        return
    end

    other.items = other.items - self.items
    self.touch = subs.null
    if self.enemy then
        -- get paired door
        self.enemy.touch = subs.null
    end
    door_use(self, other)
end

--[[
=============================================================================

SPAWNING FUNCTIONS

=============================================================================
]]

---@param self entity
---@param fmins vec3
---@param fmaxs vec3
---@return entity
local function spawn_field(self, fmins, fmaxs)
    local trigger = quake.spawn()
    trigger.movetype = MOVETYPE_NONE
    trigger.solid = SOLID_TRIGGER
    trigger.owner = self
    trigger.touch = door_trigger_touch

    local t1 = fmins
    local t2 = fmaxs
    quake.set_size(trigger, t1 - quake.vec3(60, 60, 8), t2 + quake.vec3(60, 60, 8))
    return trigger
end

---@param e1 entity
---@param e2 entity
---@return boolean
local function entities_touching(e1, e2)
    if e1.mins.x > e2.maxs.x then return false end
    if e1.mins.y > e2.maxs.y then return false end
    if e1.mins.z > e2.maxs.z then return false end
    if e1.maxs.x < e2.mins.x then return false end
    if e1.maxs.y < e2.mins.y then return false end
    if e1.maxs.z < e2.mins.z then return false end
    return true
end

---@param self entity
---@return nil
local function link_doors(self)
    if self.enemy then return end -- already linked by another door
    if (self.spawnflags & DOOR_DONT_LINK) ~= 0 then
        self.owner = self
        self.enemy = self
        return -- don't want to link this door
    end

    local cmins, cmaxs = self.mins, self.maxs
    local starte = self
    ---@type entity?
    local t = self

    while true do
        -- master door
        self.owner = starte
        if self.health ~= 0 then starte.health = self.health end
        if self.targetname ~= "" then starte.targetname = self.targetname end
        if self.message ~= "" then starte.message = self.message end

        t = quake.find(t, "classname", self.classname)
        if not t then
            -- make the chain a loop
            self.enemy = starte

            -- shootable, fired, or key doors just needed the owner/enemy links,
            -- they don't spawn a field
            self = assert(self.owner, "door has no owner")
            if self.health ~= 0 then return end
            if self.targetname ~= "" then return end
            if self.items ~= 0 then return end
            self.owner.trigger_field = spawn_field(self, cmins, cmaxs)
            return
        end

        if entities_touching(self, t) then
            if t.enemy then quake.object_error(self, "cross connected doors") end
            self.enemy = t
            self = t
            cmins = quake.vec3(math.min(t.mins.x, cmins.x), math.min(t.mins.y, cmins.y), math.min(t.mins.z, cmins.z))
            cmaxs = quake.vec3(math.max(t.maxs.x, cmaxs.x), math.max(t.maxs.y, cmaxs.y), math.max(t.maxs.z, cmaxs.z))
        end
    end
end

---QUAKED func_door (0 .5 .8) ? START_OPEN x DOOR_DONT_LINK GOLD_KEY SILVER_KEY TOGGLE
---if two doors touch, they are assumed to be connected and operate as a unit.
---
---TOGGLE causes the door to wait in both the start and end states for a trigger event.
---
---START_OPEN causes the door to move to its destination when spawned, and operate in reverse. It is used to temporarily or permanently close off an area when triggered (not usefull for touch or takedamage doors).
---
---Key doors are always wait -1.
---
---"message" is printed when the door is touched if it is a trigger door and it hasn't been fired yet
---"angle" determines the opening direction
---"targetname" if set, no touch field will be spawned and a remote button or trigger field activates the door.
---"health" if set, door must be shot open
---"speed" movement speed (100 default)
---"wait" wait before returning (3 default, -1 = never return)
---"lip" lip remaining at end of move (8 default)
---"dmg" damage to inflict when blocked (2 default)
---"sounds"
---0) no sound
---1) stone
---2) base
---3) stone chain
---4) screechy metal
---@param self entity
---@return nil
function M.func_door(self)
    if quake.world.worldtype == 0 then
        quake.precache_sound("doors/medtry.wav"); quake.precache_sound("doors/meduse.wav")
        self.noise3 = "doors/medtry.wav"; self.noise4 = "doors/meduse.wav"
    elseif quake.world.worldtype == 1 then
        quake.precache_sound("doors/runetry.wav"); quake.precache_sound("doors/runeuse.wav")
        self.noise3 = "doors/runetry.wav"; self.noise4 = "doors/runeuse.wav"
    elseif quake.world.worldtype == 2 then
        quake.precache_sound("doors/basetry.wav"); quake.precache_sound("doors/baseuse.wav")
        self.noise3 = "doors/basetry.wav"; self.noise4 = "doors/baseuse.wav"
    else
        quake.dprint("no worldtype set!\n")
    end

    if self.sounds == 0 then
        quake.precache_sound("misc/null.wav")
        quake.precache_sound("misc/null.wav")
        self.noise1 = "misc/null.wav"
        self.noise2 = "misc/null.wav"
    end
    if self.sounds == 1 then
        quake.precache_sound("doors/drclos4.wav")
        quake.precache_sound("doors/doormv1.wav")
        self.noise1 = "doors/drclos4.wav"
        self.noise2 = "doors/doormv1.wav"
    end
    if self.sounds == 2 then
        quake.precache_sound("doors/hydro1.wav")
        quake.precache_sound("doors/hydro2.wav")
        self.noise2 = "doors/hydro1.wav"
        self.noise1 = "doors/hydro2.wav"
    end
    if self.sounds == 3 then
        quake.precache_sound("doors/stndr1.wav")
        quake.precache_sound("doors/stndr2.wav")
        self.noise2 = "doors/stndr1.wav"
        self.noise1 = "doors/stndr2.wav"
    end
    if self.sounds == 4 then
        quake.precache_sound("doors/ddoor1.wav")
        quake.precache_sound("doors/ddoor2.wav")
        self.noise1 = "doors/ddoor2.wav"
        self.noise2 = "doors/ddoor1.wav"
    end

    subs.set_movedir(self)
    self.max_health = self.health
    self.solid = SOLID_BSP
    self.movetype = MOVETYPE_PUSH
    quake.set_origin(self, self.origin)
    quake.set_model(self, self.model)
    self.classname = "door"
    self.blocked = door_blocked
    self.use = door_use

    if (self.spawnflags & DOOR_SILVER_KEY) ~= 0 then self.items = IT_KEY1 end
    if (self.spawnflags & DOOR_GOLD_KEY) ~= 0 then self.items = IT_KEY2 end
    if self.speed == 0 then self.speed = 100 end
    if self.wait == 0 then self.wait = 3 end
    if self.lip == 0 then self.lip = 8 end
    if self.dmg == 0 then self.dmg = 2 end

    self.pos1 = self.origin
    self.pos2 = self.pos1 + self.movedir * (math.abs(self.movedir:dot(self.size)) - self.lip)

    -- DOOR_START_OPEN is to allow an entity to be lighted in the closed position
    -- but spawn in the open position
    if (self.spawnflags & DOOR_START_OPEN) ~= 0 then
        quake.set_origin(self, self.pos2)
        self.pos2 = self.pos1
        self.pos1 = self.origin
    end

    self.state = STATE_BOTTOM
    if self.health ~= 0 then
        self.takedamage = DAMAGE_YES
        self.th_die = door_killed
    end
    if self.items ~= 0 then self.wait = -1 end
    self.touch = door_touch

    -- LinkDoors can't be done until all of the doors have been spawned, so
    -- the sizes can be detected properly.
    self.think = link_doors
    self.nextthink = self.ltime + 0.1
end

--[[
=============================================================================

SECRET DOORS

=============================================================================
]]

local SECRET_OPEN_ONCE = 1 -- stays open
local SECRET_1ST_LEFT = 2 -- 1st move is left of arrow
local SECRET_1ST_DOWN = 4 -- 1st move is down from arrow
local SECRET_NO_SHOOT = 8 -- only opened by trigger
local SECRET_YES_SHOOT = 16 -- shootable even if targeted

local fd_secret_move1, fd_secret_move2, fd_secret_move3, fd_secret_move4,
    fd_secret_move5, fd_secret_move6, fd_secret_done

-- empty pain function
---@param _self entity
---@param _attacker entity
---@param _damage number
---@return nil
local function pain_empty(_self, _attacker, _damage)
end

---@param self entity
---@param _activator entity
---@return nil
local function fd_secret_use(self, _activator)
    self.health = 10000

    -- exit if still moving around...
    if self.origin ~= self.oldorigin then return end

    -- no more message
    self.message = ""

    -- fire all targets / killtargets
    subs.use_targets(self, _activator)

    if (self.spawnflags & SECRET_NO_SHOOT) == 0 then
        self.th_pain = pain_empty
        self.takedamage = DAMAGE_NO
    end
    self.velocity = quake.vec3(0, 0, 0)

    -- Make a sound, wait a little...
    quake.sound(self, CHAN_VOICE, self.noise1, 1, ATTN_NORM)
    self.nextthink = self.ltime + 0.1

    -- 1 or -1
    local temp = 1 - (self.spawnflags & SECRET_1ST_LEFT)
    local vectors = quake.make_vectors(self.mangle)

    if self.t_width == 0 then
        if (self.spawnflags & SECRET_1ST_DOWN) ~= 0 then
            self.t_width = math.abs(vectors.up:dot(self.size))
        else
            self.t_width = math.abs(vectors.right:dot(self.size))
        end
    end
    if self.t_length == 0 then self.t_length = math.abs(vectors.forward:dot(self.size)) end

    if (self.spawnflags & SECRET_1ST_DOWN) ~= 0 then
        self.dest1 = self.origin - vectors.up * self.t_width
    else
        self.dest1 = self.origin + vectors.right * (self.t_width * temp)
    end
    self.dest2 = self.dest1 + vectors.forward * self.t_length
    subs.calc_move(self, self.dest1, self.speed, fd_secret_move1)
    quake.sound(self, CHAN_VOICE, self.noise2, 1, ATTN_NORM)
end

-- wrapper function for fd_secret_use for use with th_pain
---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local function fd_secret_pain(self, _attacker, _damage)
    fd_secret_use(self, quake.globals.activator)
end

-- Wait after first movement...
---@param self entity
---@return nil
fd_secret_move1 = function(self)
    self.nextthink = self.ltime + 1
    self.think = fd_secret_move2
    quake.sound(self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
end

-- Start moving sideways w/sound...
---@param self entity
---@return nil
fd_secret_move2 = function(self)
    quake.sound(self, CHAN_VOICE, self.noise2, 1, ATTN_NORM)
    subs.calc_move(self, self.dest2, self.speed, fd_secret_move3)
end

-- Wait here until time to go back...
---@param self entity
---@return nil
fd_secret_move3 = function(self)
    quake.sound(self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
    if (self.spawnflags & SECRET_OPEN_ONCE) == 0 then
        self.nextthink = self.ltime + self.wait
        self.think = fd_secret_move4
    end
end

-- Move backward...
---@param self entity
---@return nil
fd_secret_move4 = function(self)
    quake.sound(self, CHAN_VOICE, self.noise2, 1, ATTN_NORM)
    subs.calc_move(self, self.dest1, self.speed, fd_secret_move5)
end

-- Wait 1 second...
---@param self entity
---@return nil
fd_secret_move5 = function(self)
    self.nextthink = self.ltime + 1
    self.think = fd_secret_move6
    quake.sound(self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
end

---@param self entity
---@return nil
fd_secret_move6 = function(self)
    quake.sound(self, CHAN_VOICE, self.noise2, 1, ATTN_NORM)
    subs.calc_move(self, self.oldorigin, self.speed, fd_secret_done)
end

---@param self entity
---@return nil
fd_secret_done = function(self)
    if self.targetname == "" or (self.spawnflags & SECRET_YES_SHOOT) ~= 0 then
        self.health = 10000
        self.takedamage = DAMAGE_YES
        self.th_pain = fd_secret_pain
        self.th_die = fd_secret_use
    end
    quake.sound(self, CHAN_VOICE, self.noise3, 1, ATTN_NORM)
end

---@param self entity
---@param other entity
---@return nil
local function secret_blocked(self, other)
    if quake.time() < self.attack_finished then return end
    self.attack_finished = quake.time() + 0.5
    combat.damage(other, self, self, self.dmg)
end

---Prints messages
---@param self entity
---@param other entity
---@return nil
local function secret_touch(self, other)
    if other.classname ~= "player" then return end
    if self.attack_finished > quake.time() then return end
    self.attack_finished = quake.time() + 2
    if self.message ~= "" then
        quake.center_print(other, self.message)
        quake.sound(other, CHAN_BODY, "misc/talk.wav", 1, ATTN_NORM)
    end
end

---QUAKED func_door_secret (0 .5 .8) ? open_once 1st_left 1st_down no_shoot always_shoot
---Basic secret door. Slides back, then to the side. Angle determines direction.
---wait = # of seconds before coming back
---1st_left = 1st move is left of arrow
---1st_down = 1st move is down from arrow
---always_shoot = even if targeted, keep shootable
---t_width = override WIDTH to move back (or height if going down)
---t_length = override LENGTH to move sideways
---"dmg" damage to inflict when blocked (2 default)
---
---If a secret door has a targetname, it will only be opened by it's botton or trigger, not by damage.
---"sounds"
---1) medieval
---2) metal
---3) base
---@param self entity
---@return nil
function M.func_door_secret(self)
    if self.sounds == 0 then self.sounds = 3 end
    if self.sounds == 1 then
        quake.precache_sound("doors/latch2.wav")
        quake.precache_sound("doors/winch2.wav")
        quake.precache_sound("doors/drclos4.wav")
        self.noise1 = "doors/latch2.wav"
        self.noise2 = "doors/winch2.wav"
        self.noise3 = "doors/drclos4.wav"
    end
    if self.sounds == 2 then
        quake.precache_sound("doors/airdoor1.wav")
        quake.precache_sound("doors/airdoor2.wav")
        self.noise2 = "doors/airdoor1.wav"
        self.noise1 = "doors/airdoor2.wav"
        self.noise3 = "doors/airdoor2.wav"
    end
    if self.sounds == 3 then
        quake.precache_sound("doors/basesec1.wav")
        quake.precache_sound("doors/basesec2.wav")
        self.noise2 = "doors/basesec1.wav"
        self.noise1 = "doors/basesec2.wav"
        self.noise3 = "doors/basesec2.wav"
    end

    if self.dmg == 0 then self.dmg = 2 end

    -- Magic formula...
    self.mangle = self.angles
    self.angles = quake.vec3(0, 0, 0)
    self.solid = SOLID_BSP
    self.movetype = MOVETYPE_PUSH
    self.classname = "door"
    quake.set_model(self, self.model)
    quake.set_origin(self, self.origin)

    self.touch = secret_touch
    self.blocked = secret_blocked
    self.speed = 50
    self.use = fd_secret_use
    if self.targetname == "" or (self.spawnflags & SECRET_YES_SHOOT) ~= 0 then
        self.health = 10000
        self.takedamage = DAMAGE_YES
        self.th_pain = fd_secret_pain
        self.th_die = fd_secret_use
    end
    self.oldorigin = self.origin
    if self.wait == 0 then
        -- 5 seconds before closing
        self.wait = 5
    end
end

M.go_down = door_go_down

quake.register_entity("func_door", M.func_door)
quake.register_entity("func_door_secret", M.func_door_secret)

return M
