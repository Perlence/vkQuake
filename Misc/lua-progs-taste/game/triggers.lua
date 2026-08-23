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
-- Port of triggers.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local combat = require("game.combat")
local subs = require("game.subs")

local M = {}

local SOLID_NOT, SOLID_TRIGGER, SOLID_BBOX, SOLID_SLIDEBOX = 0, 1, 2, 3
local MOVETYPE_NONE = 0
local DAMAGE_NO, DAMAGE_YES = 0, 1
local CHAN_AUTO, CHAN_BODY, CHAN_VOICE = 0, 4, 2
local ATTN_NORM, ATTN_STATIC = 1, 3
local MSG_BROADCAST, MSG_ALL = 0, 2
local SVC_TEMPENTITY, SVC_FOUNDSECRET, TE_TELEPORT = 23, 28, 11
local FL_FLY, FL_SWIM, FL_ONGROUND, FL_MONSTER = 1, 2, 512, 32

---@param self entity
---@return nil
local function trigger_reactivate(self)
    self.solid = SOLID_TRIGGER
end

--=============================================================================

local SPAWNFLAG_NOMESSAGE = 1
local SPAWNFLAG_NOTOUCH = 1

-- the wait time has passed, so set back up for another activation
---@param self entity
---@return nil
local function multi_wait(self)
    if self.max_health ~= 0 then
        self.health = self.max_health
        self.takedamage = DAMAGE_YES
        self.solid = SOLID_BBOX
    end
end

-- the trigger was just touched/killed/used
-- self.enemy should be set to the activator so it can be held through a delay
-- so wait for the delay time before firing
---@param self entity
---@return nil
local function multi_trigger(self)
    if self.nextthink > quake.time() then
        -- already been triggered
        return
    end

    if self.classname == "trigger_secret" then
        if self.enemy.classname ~= "player" then return end
        quake.globals.found_secrets = quake.globals.found_secrets + 1
        quake.write_byte(MSG_ALL, SVC_FOUNDSECRET)
    end

    if self.noise ~= "" then quake.sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM) end

    -- don't trigger again until reset
    self.takedamage = DAMAGE_NO

    local activator = assert(self.enemy, "trigger has no activator")
    subs.use_targets(self, activator)

    if self.wait > 0 then
        self.think = multi_wait
        self.nextthink = quake.time() + self.wait
    else
        -- we can't just remove (self) here, because this is a touch function
        -- called while C code is looping through area links.
        self.touch = subs.null
        self.nextthink = quake.time() + 0.1
        self.think = subs.remove
    end
end

---@param self entity
---@return nil
local function multi_killed(self)
    self.enemy = quake.globals.damage_attacker
    multi_trigger(self)
end

---@param self entity
---@param activator entity
---@return nil
local function multi_use(self, activator)
    self.enemy = activator
    multi_trigger(self)
end

---@param self entity
---@param other entity
---@return nil
local function multi_touch(self, other)
    if other.classname ~= "player" then return end

    -- if the trigger has an angles field, check player's facing direction
    if self.movedir ~= quake.vec3(0, 0, 0) then
        local vectors = quake.make_vectors(other.angles)
        if vectors.forward:dot(self.movedir) < 0 then
            -- not facing the right way
            return
        end
    end

    self.enemy = other
    multi_trigger(self)
end

---QUAKED trigger_multiple (.5 .5 .5) ? notouch
---Variable sized repeatable trigger. Must be targeted at one or more entities. If "health" is set, the trigger must be killed to activate each time.
---If "delay" is set, the trigger waits some time after activating before firing.
---"wait" : Seconds between triggerings. (.2 default)
---If notouch is set, the trigger is only fired by other entities, not by touching.
---NOTOUCH has been obsoleted by trigger_relay!
---sounds
---1) secret
---2) beep beep
---3) large switch
---4)
---set "message" to text string
---@param self entity
---@return nil
function M.trigger_multiple(self)
    if self.sounds == 1 then
        quake.precache_sound("misc/secret.wav"); self.noise = "misc/secret.wav"
    elseif self.sounds == 2 then
        quake.precache_sound("misc/talk.wav"); self.noise = "misc/talk.wav"
    elseif self.sounds == 3 then
        quake.precache_sound("misc/trigger1.wav"); self.noise = "misc/trigger1.wav"
    end

    if self.wait == 0 then self.wait = 0.2 end
    self.use = multi_use
    subs.init_trigger(self)

    if self.health ~= 0 then
        if (self.spawnflags & SPAWNFLAG_NOTOUCH) ~= 0 then
            quake.object_error(self, "health and notouch don't make sense\n")
        end
        self.max_health = self.health
        self.th_die = multi_killed
        self.takedamage = DAMAGE_YES
        self.solid = SOLID_BBOX
        -- make sure it links into the world
        quake.set_origin(self, self.origin)
    elseif (self.spawnflags & SPAWNFLAG_NOTOUCH) == 0 then
        self.touch = multi_touch
    end
end

---QUAKED trigger_once (.5 .5 .5) ? notouch
---Variable sized trigger. Triggers once, then removes itself. You must set the key "target" to the name of another object in the level that has a matching
---"targetname". If "health" is set, the trigger must be killed to activate.
---If notouch is set, the trigger is only fired by other entities, not by touching.
---if "killtarget" is set, any objects that have a matching "target" will be removed when the trigger is fired.
---if "angle" is set, the trigger will only fire when someone is facing the direction of the angle. Use "360" for an angle of 0.
---sounds
---1) secret
---2) beep beep
---3) large switch
---4)
---set "message" to text string
---@param self entity
---@return nil
function M.trigger_once(self)
    self.wait = -1
    M.trigger_multiple(self)
end

--=============================================================================

---QUAKED trigger_relay (.5 .5 .5) (-8 -8 -8) (8 8 8)
---This fixed size trigger cannot be touched, it can only be fired by other events. It can contain killtargets, targets, delays, and messages.
---@param self entity
---@return nil
function M.trigger_relay(self)
    self.use = subs.use_targets
end

--=============================================================================

---QUAKED trigger_secret (.5 .5 .5) ?
---secret counter trigger
---sounds
---1) secret
---2) beep beep
---3)
---4)
---set "message" to text string
---@param self entity
---@return nil
function M.trigger_secret(self)
    quake.globals.total_secrets = quake.globals.total_secrets + 1
    self.wait = -1
    if self.message == "" then self.message = "You found a secret area!" end
    if self.sounds == 0 then self.sounds = 1 end

    if self.sounds == 1 then
        quake.precache_sound("misc/secret.wav"); self.noise = "misc/secret.wav"
    elseif self.sounds == 2 then
        quake.precache_sound("misc/talk.wav"); self.noise = "misc/talk.wav"
    end
    M.trigger_multiple(self)
end

--=============================================================================

---@param self entity
---@param activator entity
---@return nil
local function counter_use(self, activator)
    self.count = self.count - 1
    if self.count < 0 then return end

    if self.count ~= 0 then
        if activator.classname == "player" and (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0 then
            if self.count >= 4 then quake.center_print(activator, "There are more to go...")
            elseif self.count == 3 then quake.center_print(activator, "Only 3 more to go...")
            elseif self.count == 2 then quake.center_print(activator, "Only 2 more to go...")
            else quake.center_print(activator, "Only 1 more to go...") end
        end
        return
    end

    if activator.classname == "player" and (self.spawnflags & SPAWNFLAG_NOMESSAGE) == 0 then
        quake.center_print(activator, "Sequence completed!")
    end
    self.enemy = activator
    multi_trigger(self)
end

---QUAKED trigger_counter (.5 .5 .5) ? nomessage
---Acts as an intermediary for an action that takes multiple inputs.
---
---If nomessage is not set, t will print "1 more.. " etc when triggered and "sequence complete" when finished.
---
---After the counter has been triggered "count" times (default 2), it will fire all of it's targets and remove itself.
---@param self entity
---@return nil
function M.trigger_counter(self)
    self.wait = -1
    if self.count == 0 then self.count = 2 end
    self.use = counter_use
end

--[[
==============================================================================

TELEPORT TRIGGERS

==============================================================================
]]

local PLAYER_ONLY, SILENT = 1, 2

---@param self entity
---@return nil
local function play_teleport(self)
    local v = quake.random() * 5
    local tmpstr
    if v < 1 then tmpstr = "misc/r_tele1.wav"
    elseif v < 2 then tmpstr = "misc/r_tele2.wav"
    elseif v < 3 then tmpstr = "misc/r_tele3.wav"
    elseif v < 4 then tmpstr = "misc/r_tele4.wav"
    else tmpstr = "misc/r_tele5.wav" end
    quake.sound(self, CHAN_VOICE, tmpstr, 1, ATTN_NORM)
    quake.remove(self)
end

---@param org vec3
---@return nil
function M.spawn_tfog(org)
    local s = quake.spawn()
    s.origin = org
    s.nextthink = quake.time() + 0.2
    s.think = play_teleport

    quake.write_byte(MSG_BROADCAST, SVC_TEMPENTITY)
    quake.write_byte(MSG_BROADCAST, TE_TELEPORT)
    quake.write_coord(MSG_BROADCAST, org.x)
    quake.write_coord(MSG_BROADCAST, org.y)
    quake.write_coord(MSG_BROADCAST, org.z)
end

---@param self entity
---@param other entity
---@return nil
local function tdeath_touch(self, other)
    if other == self.owner then return end

    -- frag anyone who teleports in on top of an invincible player
    if other.classname == "player" then
        if other.invincible_finished > quake.time() then self.classname = "teledeath2" end
        if self.owner.classname ~= "player" then
            -- other monsters explode themselves
            combat.damage(self.owner, self, self, 50000)
            return
        end
    end
    if other.health ~= 0 then combat.damage(other, self, self, 50000) end
end

---@param org vec3
---@param death_owner entity
---@return nil
function M.spawn_tdeath(org, death_owner)
    local death = quake.spawn()
    death.classname = "teledeath"
    death.movetype = MOVETYPE_NONE
    death.solid = SOLID_TRIGGER
    death.angles = quake.vec3(0, 0, 0)
    quake.set_size(death, death_owner.mins - quake.vec3(1, 1, 1), death_owner.maxs + quake.vec3(1, 1, 1))
    quake.set_origin(death, org)
    death.touch = tdeath_touch
    death.nextthink = quake.time() + 0.2
    death.think = subs.remove
    death.owner = death_owner

    quake.globals.force_retouch = 2 -- make sure even still objects get hit
end

---@param self entity
---@param other entity
---@return nil
local function teleport_touch(self, other)
    if self.targetname ~= "" then
        if self.nextthink < quake.time() then return end -- not fired yet
    end
    if (self.spawnflags & PLAYER_ONLY) ~= 0 and other.classname ~= "player" then return end

    -- only teleport living creatures
    if other.health <= 0 or other.solid ~= SOLID_SLIDEBOX then return end

    subs.use_targets(self, other)

    -- put a tfog where the player was
    M.spawn_tfog(other.origin)

    local t = quake.find(quake.world, "targetname", self.target)
    if not t then quake.object_error(self, "couldn't find target") end

    -- spawn a tfog flash in front of the destination
    local vectors = quake.make_vectors(t.mangle)
    local org = t.origin + vectors.forward * 32
    M.spawn_tfog(org)
    M.spawn_tdeath(t.origin, other)

    -- move the player and lock him down for a little while
    if other.health == 0 then
        other.origin = t.origin
        other.velocity = vectors.forward * other.velocity.x + vectors.forward * other.velocity.y
        return
    end

    quake.set_origin(other, t.origin)
    other.angles = t.mangle
    if other.classname == "player" then
        -- turn this way immediately
        other.fixangle = 1
        other.teleport_time = quake.time() + 0.7
        if (other.flags & FL_ONGROUND) ~= 0 then other.flags = other.flags - FL_ONGROUND end
        other.velocity = vectors.forward * 300
    end
    other.flags = other.flags - (other.flags & FL_ONGROUND)
end

---QUAKED info_teleport_destination (.5 .5 .5) (-8 -8 -8) (8 8 32)
---This is the destination marker for a teleporter. It should have a "targetname" field with the same value as a teleporter's "target" field.
---@param self entity
---@return nil
function M.info_teleport_destination(self)
    -- this does nothing, just serves as a target spot
    self.mangle = self.angles
    self.angles = quake.vec3(0, 0, 0)
    self.model = ""
    self.origin = self.origin + quake.vec3(0, 0, 27)
    if self.targetname == "" then quake.object_error(self, "no targetname") end
end

---@param self entity
---@param _activator entity
---@return nil
local function teleport_use(self, _activator)
    self.nextthink = quake.time() + 0.2
    quake.globals.force_retouch = 2 -- make sure even still objects get hit
    self.think = subs.null
end

---QUAKED trigger_teleport (.5 .5 .5) ? PLAYER_ONLY SILENT
---Any object touching this will be transported to the corresponding info_teleport_destination entity. You must set the "target" field, and create an object with a "targetname" field that matches.
---
---If the trigger_teleport has a targetname, it will only teleport entities when it has been fired.
---@param self entity
---@return nil
function M.trigger_teleport(self)
    subs.init_trigger(self)
    self.touch = teleport_touch
    -- find the destination
    if self.target == "" then quake.object_error(self, "no target") end
    self.use = teleport_use

    if (self.spawnflags & SILENT) == 0 then
        quake.precache_sound("ambience/hum1.wav")
        local o = (self.mins + self.maxs) * 0.5
        quake.ambient_sound(o, "ambience/hum1.wav", 0.5, ATTN_STATIC)
    end
end

--[[
==============================================================================

trigger_setskill

==============================================================================
]]

---@param self entity
---@param other entity
---@return nil
local function trigger_skill_touch(self, other)
    if other.classname ~= "player" then return end
    quake.cvar_set("skill", self.message)
    quake.globals.skill = tonumber(self.message) or 0
end

---QUAKED trigger_setskill (.5 .5 .5) ?
---sets skill level to the value of "message".
---Only used on start map.
---@param self entity
---@return nil
function M.trigger_setskill(self)
    subs.init_trigger(self)
    self.touch = trigger_skill_touch
end

--[[
==============================================================================

ONLY REGISTERED TRIGGERS

==============================================================================
]]

---@param self entity
---@param other entity
---@return nil
local function trigger_onlyregistered_touch(self, other)
    if other.classname ~= "player" then return end
    if self.attack_finished > quake.time() then return end

    self.attack_finished = quake.time() + 2
    if quake.cvar("registered") ~= 0 then
        self.message = ""
        subs.use_targets(self, other)
        quake.remove(self)
    elseif self.message ~= "" then
        quake.center_print(other, self.message)
        quake.sound(other, CHAN_BODY, "misc/talk.wav", 1, ATTN_NORM)
    end
end

---QUAKED trigger_onlyregistered (.5 .5 .5) ?
---Only fires if playing the registered version, otherwise prints the message
---@param self entity
---@return nil
function M.trigger_onlyregistered(self)
    quake.precache_sound("misc/talk.wav")
    subs.init_trigger(self)
    self.touch = trigger_onlyregistered_touch
end

--============================================================================

---@param self entity
---@return nil
local function hurt_on(self)
    self.solid = SOLID_TRIGGER
    self.nextthink = -1
end

---@param self entity
---@param other entity
---@return nil
local function hurt_touch(self, other)
    if other.takedamage ~= 0 then
        self.solid = SOLID_NOT
        combat.damage(other, self, self, self.dmg)
        self.think = hurt_on
        self.nextthink = quake.time() + 1
    end
end

---QUAKED trigger_hurt (.5 .5 .5) ?
---Any object touching this will be hurt
---set dmg to damage amount
---defalt dmg = 5
---@param self entity
---@return nil
function M.trigger_hurt(self)
    subs.init_trigger(self)
    self.touch = hurt_touch
    if self.dmg == 0 then self.dmg = 5 end
end

--============================================================================

local PUSH_ONCE = 1

---@param self entity
---@param other entity
---@return nil
local function trigger_push_touch(self, other)
    if other.classname == "grenade" then
        other.velocity = self.movedir * self.speed * 10
    elseif other.health > 0 then
        other.velocity = self.movedir * self.speed * 10
        if other.classname == "player" and other.fly_sound < quake.time() then
            other.fly_sound = quake.time() + 1.5
            quake.sound(other, CHAN_AUTO, "ambience/windfly.wav", 1, ATTN_NORM)
        end
    end
    if (self.spawnflags & PUSH_ONCE) ~= 0 then quake.remove(self) end
end

---QUAKED trigger_push (.5 .5 .5) ? PUSH_ONCE
---Pushes the player
---@param self entity
---@return nil
function M.trigger_push(self)
    subs.init_trigger(self)
    quake.precache_sound("ambience/windfly.wav")
    self.touch = trigger_push_touch
    if self.speed == 0 then self.speed = 1000 end
end

--============================================================================

---@param self entity
---@param other entity
---@return nil
local function trigger_monsterjump_touch(self, other)
    if (other.flags & (FL_MONSTER | FL_FLY | FL_SWIM)) ~= FL_MONSTER then return end

    -- set XY even if not on ground, so the jump will clear lips
    other.velocity = quake.vec3(self.movedir.x * self.speed, self.movedir.y * self.speed, other.velocity.z)
    if (other.flags & FL_ONGROUND) == 0 then return end
    other.flags = other.flags - FL_ONGROUND
    other.velocity = quake.vec3(other.velocity.x, other.velocity.y, self.height)
end

---QUAKED trigger_monsterjump (.5 .5 .5) ?
---Walking monsters that touch this will jump in the direction of the trigger's angle
---"speed" default to 200, the speed thrown forward
---"height" default to 200, the speed thrown upwards
---@param self entity
---@return nil
function M.trigger_monsterjump(self)
    if self.speed == 0 then self.speed = 200 end
    if self.height == 0 then self.height = 200 end
    if self.angles == quake.vec3(0, 0, 0) then self.angles = quake.vec3(0, 360, 0) end
    subs.init_trigger(self)
    self.touch = trigger_monsterjump_touch
end

quake.register_entity("trigger_multiple", M.trigger_multiple)
quake.register_entity("trigger_once", M.trigger_once)
quake.register_entity("trigger_relay", M.trigger_relay)
quake.register_entity("trigger_secret", M.trigger_secret)
quake.register_entity("trigger_counter", M.trigger_counter)
quake.register_entity("info_teleport_destination", M.info_teleport_destination)
quake.register_entity("trigger_teleport", M.trigger_teleport)
quake.register_entity("trigger_setskill", M.trigger_setskill)
quake.register_entity("trigger_onlyregistered", M.trigger_onlyregistered)
quake.register_entity("trigger_hurt", M.trigger_hurt)
quake.register_entity("trigger_push", M.trigger_push)
quake.register_entity("trigger_monsterjump", M.trigger_monsterjump)

return M
