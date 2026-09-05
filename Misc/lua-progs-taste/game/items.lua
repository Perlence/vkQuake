-- Port of items.qc from GPL-licensed CleanFixedQuakeC.
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

local C = require("game.constants")
local subs = require("game.subs")
local weapons = require("game.weapons")

local M = {}

---@param self entity
---@return nil
local function hide_item(self)
    quake.set_model(self, "")
    self.solid = C.SOLID_NOT
    self.nextthink = 0
    self.think = subs.null
end

--[[ ALL LIGHTS SHOULD BE 0 1 0 IN COLOR ALL OTHER ITEMS SHOULD
BE .8 .3 .4 IN COLOR ]]

---@param self entity
---@return nil
local regen = quake.register_function("items.regen", function(self)
    -- restore original model
    quake.set_model(self, self.mdl)
    -- allow it to be touched again
    self.solid = 1 -- SOLID_TRIGGER
    -- play respawn sound
    quake.sound(self, C.CHAN_VOICE, "items/itembk2.wav", 1, C.ATTN_NORM)
    quake.set_origin(self, self.origin)
end)

---QUAKED noclass (0 0 0) (-8 -8 -8) (8 8 8)
---prints a warning message when spawned
---@param self entity
---@return nil
local function noclass(self)
    quake.dprint("noclass spawned at")
    quake.dprint(quake.vector_to_string(self.origin))
    quake.dprint("\n")
    quake.remove(self)
end

---plants the object on the floor
---@param self entity
---@return nil
local place_item = quake.register_function("items.place_item", function(self)
    -- so it can be restored on respawn
    self.mdl = self.model
    -- make extra wide
    self.flags = 256 -- FL_ITEM
    self.solid = 1 -- SOLID_TRIGGER
    self.movetype = 6 -- MOVETYPE_TOSS
    self.velocity = quake.vec3(0, 0, 0)
    self.origin.z = self.origin.z + 6
    if not quake.drop_to_floor(self) then
        quake.dprint("Bonus item fell out of level at ")
        quake.dprint(quake.vector_to_string(self.origin))
        quake.dprint("\n")
        quake.remove(self)
        return
    end
end)

---Sets the clipping size and plants the object on the floor
---@param self entity
---@return nil
local function start_item(self)
    self.nextthink = quake.time() + 0.2 -- items start after other solids
    self.think = place_item
end

--[[
=========================================================================

HEALTH BOX

=========================================================================
]]
--
-- T_Heal: add health to an entity, limiting health to max_health
-- "ignore" will ignore max_health limit
--
---@param entity entity
---@param healamount number
---@param ignore integer
---@return integer
local function heal(entity, healamount, ignore)
    if entity.health <= 0 then
        return 0
    end
    if ignore == 0 and entity.health >= entity.max_health then
        return 0
    end
    healamount = math.ceil(healamount)

    entity.health = entity.health + healamount
    if ignore == 0 and entity.health >= entity.max_health then
        entity.health = entity.max_health
    end

    if entity.health > 250 then
        entity.health = 250
    end
    return 1
end

--[[QUAKED item_health (.3 .3 1) (0 0 0) (32 32 32) rotten megahealth
Health box. Normally gives 25 points.
Rotten box heals 5-10 points,
megahealth will add 100 health, then
rot you down to your maximum health limit,
one point per second.
]]

local H_ROTTEN = 1
local H_MEGA = 2

local health_touch

---@param self entity
---@return nil
local function item_health(self)
    self.touch = health_touch

    if (self.spawnflags & H_ROTTEN) ~= 0 then
        quake.precache_model("maps/b_bh10.bsp")

        quake.precache_sound("items/r_item1.wav")
        quake.set_model(self, "maps/b_bh10.bsp")
        self.noise = "items/r_item1.wav"
        self.healamount = 15
        self.healtype = 0
    elseif (self.spawnflags & H_MEGA) ~= 0 then
        quake.precache_model("maps/b_bh100.bsp")
        quake.precache_sound("items/r_item2.wav")
        quake.set_model(self, "maps/b_bh100.bsp")
        self.noise = "items/r_item2.wav"
        self.healamount = 100
        self.healtype = 2
    else
        quake.precache_model("maps/b_bh25.bsp")
        quake.precache_sound("items/health1.wav")
        quake.set_model(self, "maps/b_bh25.bsp")
        self.noise = "items/health1.wav"
        self.healamount = 25
        self.healtype = 1
    end
    quake.set_size(self, quake.vec3(0, 0, 0), quake.vec3(32, 32, 56))
    start_item(self)
end

local item_megahealth_rot

---@param self entity
---@param other entity
---@return nil
health_touch = quake.register_function("items.health_touch", function(self, other)
    if other.classname ~= "player" then
        return
    end

    -- Megahealth?  Ignore max_health...
    if self.healtype == 2 then
        if other.health >= 250 then
            return
        end
        if heal(other, self.healamount, 1) == 0 then
            return
        end
    else
        if heal(other, self.healamount, 0) == 0 then
            return
        end
    end

    quake.sprint(other, "You receive ")
    local s = quake.float_to_string(self.healamount)
    quake.sprint(other, s)
    quake.sprint(other, " health\n")

    -- health touch sound
    quake.sound(other, C.CHAN_ITEM, self.noise, 1, C.ATTN_NORM)

    quake.stuff_cmd(other, "bf\n")

    hide_item(self)

    -- Megahealth = rot down the player's super health
    if self.healtype == 2 then
        other.items = other.items | 65536 -- IT_SUPERHEALTH
        self.nextthink = quake.time() + 5
        self.think = item_megahealth_rot
        self.owner = other
    else
        -- deathmatch 2 is the silly old rules
        if quake.cvar("deathmatch") ~= 2 then
            if quake.cvar("deathmatch") ~= 0 then
                self.nextthink = quake.time() + 20
            end
            self.think = regen
        end
    end

    -- fire all targets / killtargets
    subs.use_targets(self, other)
end)

---@param self entity
---@return nil
item_megahealth_rot = quake.register_function("items.item_megahealth_rot", function(self)
    local other = assert(self.owner, "megahealth has no owner")

    if other.health > other.max_health then
        other.health = other.health - 1
        self.nextthink = quake.time() + 1
        return
    end

    -- it is possible for a player to die and respawn between rots, so don't
    -- just blindly subtract the flag off
    other.items = other.items - (other.items & 65536) -- IT_SUPERHEALTH

    -- deathmatch 2 is silly old rules
    if quake.cvar("deathmatch") == 1 then
        self.nextthink = quake.time() + 20
        self.think = regen
    end
end)

--[[
===============================================================================

ARMOR

===============================================================================
]]

---@param self entity
---@param other entity
---@return nil
local armor_touch = quake.register_function("items.armor_touch", function(self, other)
    -- initialize variables
    local type = 0
    local bit = 0
    local value = 0

    if other.health <= 0 then
        return
    end
    if other.classname ~= "player" then
        return
    end

    if self.classname == "item_armor1" then
        type = 0.3
        value = 100
        bit = C.IT_ARMOR1
    end
    if self.classname == "item_armor2" then
        type = 0.6
        value = 150
        bit = C.IT_ARMOR2
    end
    if self.classname == "item_armorInv" then
        type = 0.8
        value = 200
        bit = C.IT_ARMOR3
    end
    if other.armortype * other.armorvalue >= type * value then
        return
    end

    other.armortype = type
    other.armorvalue = value
    other.items = other.items - (other.items & (C.IT_ARMOR1 | C.IT_ARMOR2 | C.IT_ARMOR3)) + bit

    hide_item(self)
    if quake.cvar("deathmatch") == 1 then
        self.nextthink = quake.time() + 20
    end
    self.think = regen

    quake.sprint(other, "You got armor\n")
    -- armor touch sound
    quake.sound(other, C.CHAN_ITEM, "items/armor1.wav", 1, C.ATTN_NORM)
    quake.stuff_cmd(other, "bf\n")

    -- fire all targets / killtargets
    subs.use_targets(self, other)
end)

---QUAKED item_armor1 (0 .5 .8) (-16 -16 0) (16 16 32)
---@param self entity
---@return nil
local function item_armor1(self)
    self.touch = armor_touch
    quake.precache_model("progs/armor.mdl")
    quake.set_model(self, "progs/armor.mdl")
    self.skin = 0
    quake.set_size(self, quake.vec3(-16, -16, 0), quake.vec3(16, 16, 56))
    start_item(self)
end

---QUAKED item_armor2 (0 .5 .8) (-16 -16 0) (16 16 32)
---@param self entity
---@return nil
local function item_armor2(self)
    self.touch = armor_touch
    quake.precache_model("progs/armor.mdl")
    quake.set_model(self, "progs/armor.mdl")
    self.skin = 1
    quake.set_size(self, quake.vec3(-16, -16, 0), quake.vec3(16, 16, 56))
    start_item(self)
end

---QUAKED item_armorInv (0 .5 .8) (-16 -16 0) (16 16 32)
---@param self entity
---@return nil
local function item_armor_inv(self)
    self.touch = armor_touch
    quake.precache_model("progs/armor.mdl")
    quake.set_model(self, "progs/armor.mdl")
    self.skin = 2
    quake.set_size(self, quake.vec3(-16, -16, 0), quake.vec3(16, 16, 56))
    start_item(self)
end

--[[
===============================================================================

WEAPONS

===============================================================================
]]

---@param other entity
---@return nil
local function bound_other_ammo(other)
    if other.ammo_shells > 100 then
        other.ammo_shells = 100
    end
    if other.ammo_nails > 200 then
        other.ammo_nails = 200
    end
    if other.ammo_rockets > 100 then
        other.ammo_rockets = 100
    end
    if other.ammo_cells > 100 then
        other.ammo_cells = 100
    end
end

---@param w integer
---@return integer
local function rank_for_weapon(w)
    if w == 64 then -- IT_LIGHTNING
        return 1
    end
    if w == 32 then -- IT_ROCKET_LAUNCHER
        return 2
    end
    if w == 8 then -- IT_SUPER_NAILGUN
        return 3
    end
    if w == 16 then -- IT_GRENADE_LAUNCHER
        return 4
    end
    if w == 2 then -- IT_SUPER_SHOTGUN
        return 5
    end
    if w == 4 then -- IT_NAILGUN
        return 6
    end
    return 7
end

---Deathmatch weapon change rules for picking up a weapon
---
---.float		ammo_shells, ammo_nails, ammo_rockets, ammo_cells;
---@param self entity
---@param _old integer
---@param new integer
---@return nil
local function deathmatch_weapon(self, _old, new)
    -- change self.weapon if desired
    local old_rank = rank_for_weapon(self.weapon)
    local new_rank = rank_for_weapon(new)
    if new_rank < old_rank then
        self.weapon = new
    end
end

---@param self entity
---@param other entity
---@return nil
local weapon_touch = quake.register_function("items.weapon_touch", function(self, other)
    local leave

    if (other.flags & C.FL_CLIENT) == 0 then
        return
    end

    local new = 0

    if quake.cvar("deathmatch") == 2 or quake.cvar("coop") ~= 0 then
        leave = 1
    else
        leave = 0
    end

    if self.classname == "weapon_nailgun" then
        if leave ~= 0 and (other.items & 4) ~= 0 then
            return
        end
        new = 4
        other.ammo_nails = other.ammo_nails + 30
    elseif self.classname == "weapon_supernailgun" then
        if leave ~= 0 and (other.items & 8) ~= 0 then
            return
        end
        new = 8
        other.ammo_nails = other.ammo_nails + 30
    elseif self.classname == "weapon_supershotgun" then
        if leave ~= 0 and (other.items & 2) ~= 0 then
            return
        end
        new = 2
        other.ammo_shells = other.ammo_shells + 5
    elseif self.classname == "weapon_rocketlauncher" then
        if leave ~= 0 and (other.items & 32) ~= 0 then
            return
        end
        new = 32
        other.ammo_rockets = other.ammo_rockets + 5
    elseif self.classname == "weapon_grenadelauncher" then
        if leave ~= 0 and (other.items & 16) ~= 0 then
            return
        end
        new = 16
        other.ammo_rockets = other.ammo_rockets + 5
    elseif self.classname == "weapon_lightning" then
        if leave ~= 0 and (other.items & 64) ~= 0 then
            return
        end
        new = 64
        other.ammo_cells = other.ammo_cells + 15
    else
        quake.object_error(self, "weapon_touch: unknown classname")
    end

    quake.sprint(other, "You got the ")
    quake.sprint(other, self.netname)
    quake.sprint(other, "\n")
    -- weapon touch sound
    quake.sound(other, C.CHAN_ITEM, "weapons/pkup.wav", 1, C.ATTN_NORM)
    quake.stuff_cmd(other, "bf\n")

    bound_other_ammo(other)

    -- change to the weapon
    local old = other.items
    other.items = other.items | new

    if quake.cvar("deathmatch") == 0 then
        other.weapon = new
    else
        deathmatch_weapon(other, old, new)
    end

    weapons.set_current_ammo(other)

    if leave ~= 0 then
        return
    end

    -- remove it in single player, or setup for respawning in deathmatch
    hide_item(self)
    if quake.cvar("deathmatch") == 1 then
        self.nextthink = quake.time() + 30
    end
    self.think = regen

    subs.use_targets(self, other) -- fire all targets / killtargets
end)

---QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32)
---@param self entity
---@return nil
local function weapon_supershotgun(self)
    quake.precache_model("progs/g_shot.mdl")
    quake.set_model(self, "progs/g_shot.mdl")
    self.weapon = 2
    self.netname = "Double-barrelled Shotgun"
    self.touch = weapon_touch
    quake.set_size(self, quake.vec3(-16, -16, 0), quake.vec3(16, 16, 56))
    start_item(self)
end

---QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
---@param self entity
---@return nil
local function weapon_nailgun(self)
    quake.precache_model("progs/g_nail.mdl")
    quake.set_model(self, "progs/g_nail.mdl")
    self.weapon = 4
    self.netname = "Nailgun"
    self.touch = weapon_touch
    quake.set_size(self, quake.vec3(-16, -16, 0), quake.vec3(16, 16, 56))
    start_item(self)
end

---QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32)
---@param self entity
---@return nil
local function weapon_supernailgun(self)
    quake.precache_model("progs/g_nail2.mdl")
    quake.set_model(self, "progs/g_nail2.mdl")
    self.weapon = 8
    self.netname = "Super Nailgun"
    self.touch = weapon_touch
    quake.set_size(self, quake.vec3(-16, -16, 0), quake.vec3(16, 16, 56))
    start_item(self)
end

---QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
---@param self entity
---@return nil
local function weapon_grenadelauncher(self)
    quake.precache_model("progs/g_rock.mdl")
    quake.set_model(self, "progs/g_rock.mdl")
    self.weapon = 16
    self.netname = "Grenade Launcher"
    self.touch = weapon_touch
    quake.set_size(self, quake.vec3(-16, -16, 0), quake.vec3(16, 16, 56))
    start_item(self)
end

---QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
---@param self entity
---@return nil
local function weapon_rocketlauncher(self)
    quake.precache_model("progs/g_rock2.mdl")
    quake.set_model(self, "progs/g_rock2.mdl")
    self.weapon = 32
    self.netname = "Rocket Launcher"
    self.touch = weapon_touch
    quake.set_size(self, quake.vec3(-16, -16, 0), quake.vec3(16, 16, 56))
    start_item(self)
end

---QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
---@param self entity
---@return nil
local function weapon_lightning(self)
    quake.precache_model("progs/g_light.mdl")
    quake.set_model(self, "progs/g_light.mdl")
    self.weapon = 64
    self.netname = "Thunderbolt"
    self.touch = weapon_touch
    quake.set_size(self, quake.vec3(-16, -16, 0), quake.vec3(16, 16, 56))
    start_item(self)
end

--[[
===============================================================================

AMMO

===============================================================================
]]

---@param self entity
---@param other entity
---@return nil
local ammo_touch = quake.register_function("items.ammo_touch", function(self, other)
    if other.classname ~= "player" then
        return
    end
    if other.health <= 0 then
        return
    end

    -- if the player was using his best weapon, change up to the new one if better
    local best = weapons.best_weapon(other)

    -- shotgun
    if self.weapon == 1 then
        if other.ammo_shells >= 100 then
            return
        end
        other.ammo_shells = other.ammo_shells + self.aflag
    end

    -- spikes
    if self.weapon == 2 then
        if other.ammo_nails >= 200 then
            return
        end
        other.ammo_nails = other.ammo_nails + self.aflag
    end

    -- rockets
    if self.weapon == 3 then
        if other.ammo_rockets >= 100 then
            return
        end
        other.ammo_rockets = other.ammo_rockets + self.aflag
    end

    -- cells
    if self.weapon == 4 then
        if other.ammo_cells >= 100 then
            return
        end
        other.ammo_cells = other.ammo_cells + self.aflag
    end

    bound_other_ammo(other)

    quake.sprint(other, "You got the ")
    quake.sprint(other, self.netname)
    quake.sprint(other, "\n")
    -- ammo touch sound
    quake.sound(other, C.CHAN_ITEM, "weapons/lock4.wav", 1, C.ATTN_NORM)
    quake.stuff_cmd(other, "bf\n")

    -- change to a better weapon if appropriate
    if other.weapon == best then
        other.weapon = weapons.best_weapon(other)
        weapons.set_current_ammo(other)
    end

    -- if changed current ammo, update it
    weapons.set_current_ammo(other)

    -- remove it in single player, or setup for respawning in deathmatch
    hide_item(self)
    if quake.cvar("deathmatch") == 1 then
        self.nextthink = quake.time() + 30
    end

    self.think = regen

    -- fire all targets / killtargets
    subs.use_targets(self, other)
end)

local WEAPON_BIG2 = 1

---QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32) big
---@param self entity
---@return nil
local function item_shells(self)
    self.touch = ammo_touch

    if (self.spawnflags & WEAPON_BIG2) ~= 0 then
        quake.precache_model("maps/b_shell1.bsp")
        quake.set_model(self, "maps/b_shell1.bsp")
        self.aflag = 40
    else
        quake.precache_model("maps/b_shell0.bsp")
        quake.set_model(self, "maps/b_shell0.bsp")
        self.aflag = 20
    end
    self.weapon = 1
    self.netname = "shells"
    quake.set_size(self, quake.vec3(0, 0, 0), quake.vec3(32, 32, 56))
    start_item(self)
end

---QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) big
---@param self entity
---@return nil
local function item_spikes(self)
    self.touch = ammo_touch

    if (self.spawnflags & WEAPON_BIG2) ~= 0 then
        quake.precache_model("maps/b_nail1.bsp")
        quake.set_model(self, "maps/b_nail1.bsp")
        self.aflag = 50
    else
        quake.precache_model("maps/b_nail0.bsp")
        quake.set_model(self, "maps/b_nail0.bsp")
        self.aflag = 25
    end
    self.weapon = 2
    self.netname = "nails"
    quake.set_size(self, quake.vec3(0, 0, 0), quake.vec3(32, 32, 56))
    start_item(self)
end

---QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) big
---@param self entity
---@return nil
local function item_rockets(self)
    self.touch = ammo_touch

    if (self.spawnflags & WEAPON_BIG2) ~= 0 then
        quake.precache_model("maps/b_rock1.bsp")
        quake.set_model(self, "maps/b_rock1.bsp")
        self.aflag = 10
    else
        quake.precache_model("maps/b_rock0.bsp")
        quake.set_model(self, "maps/b_rock0.bsp")
        self.aflag = 5
    end
    self.weapon = 3
    self.netname = "rockets"
    quake.set_size(self, quake.vec3(0, 0, 0), quake.vec3(32, 32, 56))
    start_item(self)
end

---QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) big
---@param self entity
---@return nil
local function item_cells(self)
    self.touch = ammo_touch

    if (self.spawnflags & WEAPON_BIG2) ~= 0 then
        quake.precache_model("maps/b_batt1.bsp")
        quake.set_model(self, "maps/b_batt1.bsp")
        self.aflag = 12
    else
        quake.precache_model("maps/b_batt0.bsp")
        quake.set_model(self, "maps/b_batt0.bsp")
        self.aflag = 6
    end
    self.weapon = 4
    self.netname = "cells"
    quake.set_size(self, quake.vec3(0, 0, 0), quake.vec3(32, 32, 56))
    start_item(self)
end

--[[QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
]]

local WEAPON_SHOTGUN = 1
local WEAPON_ROCKET = 2
local WEAPON_SPIKES = 4
local WEAPON_BIG = 8

---@param self entity
---@return nil
local function item_weapon(self)
    self.touch = ammo_touch

    if (self.spawnflags & WEAPON_SHOTGUN) ~= 0 then
        if (self.spawnflags & WEAPON_BIG) ~= 0 then
            quake.precache_model("maps/b_shell1.bsp")
            quake.set_model(self, "maps/b_shell1.bsp")
            self.aflag = 40
        else
            quake.precache_model("maps/b_shell0.bsp")
            quake.set_model(self, "maps/b_shell0.bsp")
            self.aflag = 20
        end
        self.weapon = 1
        self.netname = "shells"
    end

    if (self.spawnflags & WEAPON_SPIKES) ~= 0 then
        if (self.spawnflags & WEAPON_BIG) ~= 0 then
            quake.precache_model("maps/b_nail1.bsp")
            quake.set_model(self, "maps/b_nail1.bsp")
            self.aflag = 40
        else
            quake.precache_model("maps/b_nail0.bsp")
            quake.set_model(self, "maps/b_nail0.bsp")
            self.aflag = 20
        end
        self.weapon = 2
        self.netname = "spikes"
    end

    if (self.spawnflags & WEAPON_ROCKET) ~= 0 then
        if (self.spawnflags & WEAPON_BIG) ~= 0 then
            quake.precache_model("maps/b_rock1.bsp")
            quake.set_model(self, "maps/b_rock1.bsp")
            self.aflag = 10
        else
            quake.precache_model("maps/b_rock0.bsp")
            quake.set_model(self, "maps/b_rock0.bsp")
            self.aflag = 5
        end
        self.weapon = 3
        self.netname = "rockets"
    end

    quake.set_size(self, quake.vec3(0, 0, 0), quake.vec3(32, 32, 56))
    start_item(self)
end

--[[
===============================================================================

KEYS

===============================================================================
]]

---@param self entity
---@param other entity
---@return nil
local key_touch = quake.register_function("items.key_touch", function(self, other)
    if other.classname ~= "player" then
        return
    end
    if other.health <= 0 then
        return
    end
    if (other.items & self.items) ~= 0 then
        return
    end

    quake.sprint(other, "You got the ")
    quake.sprint(other, self.netname)
    quake.sprint(other, "\n")

    quake.sound(other, C.CHAN_ITEM, self.noise, 1, C.ATTN_NORM)
    quake.stuff_cmd(other, "bf\n")
    other.items = other.items | self.items

    if quake.cvar("coop") == 0 then
        hide_item(self)
    end

    -- fire all targets / killtargets
    subs.use_targets(self, other)
end)

---@param self entity
---@return nil
local function key_setsounds(self)
    if quake.world.worldtype == 0 then
        quake.precache_sound("misc/medkey.wav")
        self.noise = "misc/medkey.wav"
    end
    if quake.world.worldtype == 1 then
        quake.precache_sound("misc/runekey.wav")
        self.noise = "misc/runekey.wav"
    end
    if quake.world.worldtype == 2 then
        quake.precache_sound2("misc/basekey.wav")
        self.noise = "misc/basekey.wav"
    end
end

---QUAKED item_key1 (0 .5 .8) (-16 -16 -24) (16 16 32)
---SILVER key
---In order for keys to work
---you MUST set your maps
---worldtype to one of the
---following:
---0: medieval
---1: metal
---2: base
---@param self entity
---@return nil
local function item_key1(self)
    if quake.world.worldtype == 0 then
        quake.precache_model("progs/w_s_key.mdl")
        quake.set_model(self, "progs/w_s_key.mdl")
        self.netname = "silver key"
    elseif quake.world.worldtype == 1 then
        quake.precache_model("progs/m_s_key.mdl")
        quake.set_model(self, "progs/m_s_key.mdl")
        self.netname = "silver runekey"
    elseif quake.world.worldtype == 2 then
        quake.precache_model2("progs/b_s_key.mdl")
        quake.set_model(self, "progs/b_s_key.mdl")
        self.netname = "silver keycard"
    end
    key_setsounds(self)
    self.touch = key_touch
    self.items = 131072 -- IT_KEY1
    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 32))
    start_item(self)
end

---QUAKED item_key2 (0 .5 .8) (-16 -16 -24) (16 16 32)
---GOLD key
---In order for keys to work
---you MUST set your maps
---worldtype to one of the
---following:
---0: medieval
---1: metal
---2: base
---@param self entity
---@return nil
local function item_key2(self)
    if quake.world.worldtype == 0 then
        quake.precache_model("progs/w_g_key.mdl")
        quake.set_model(self, "progs/w_g_key.mdl")
        self.netname = "gold key"
    end
    if quake.world.worldtype == 1 then
        quake.precache_model("progs/m_g_key.mdl")
        quake.set_model(self, "progs/m_g_key.mdl")
        self.netname = "gold runekey"
    end
    if quake.world.worldtype == 2 then
        quake.precache_model2("progs/b_g_key.mdl")
        quake.set_model(self, "progs/b_g_key.mdl")
        self.netname = "gold keycard"
    end
    key_setsounds(self)
    self.touch = key_touch
    self.items = 262144 -- IT_KEY2
    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 32))
    start_item(self)
end

--[[
===============================================================================

END OF LEVEL RUNES

===============================================================================
]]

---@param self entity
---@param other entity
---@return nil
local sigil_touch = quake.register_function("items.sigil_touch", function(self, other)
    if other.classname ~= "player" then
        return
    end
    if other.health <= 0 then
        return
    end

    quake.center_print(other, "You got the rune!")

    quake.sound(other, C.CHAN_ITEM, self.noise, 1, C.ATTN_NORM)
    quake.stuff_cmd(other, "bf\n")
    hide_item(self)
    quake.globals.serverflags = quake.globals.serverflags | (self.spawnflags & 15)
    -- so rune doors won't find it
    self.classname = ""

    -- fire all targets / killtargets
    subs.use_targets(self, other)
end)

---QUAKED item_sigil (0 .5 .8) (-16 -16 -24) (16 16 32) E1 E2 E3 E4
---End of level sigil, pick up to end episode and return to jrstart.
---@param self entity
---@return nil
local function item_sigil(self)
    if self.spawnflags == 0 then
        quake.object_error(self, "no spawnflags")
    end

    quake.precache_sound("misc/runekey.wav")
    self.noise = "misc/runekey.wav"

    if (self.spawnflags & 1) ~= 0 then
        quake.precache_model("progs/end1.mdl")
        quake.set_model(self, "progs/end1.mdl")
    end
    if (self.spawnflags & 2) ~= 0 then
        quake.precache_model2("progs/end2.mdl")
        quake.set_model(self, "progs/end2.mdl")
    end
    if (self.spawnflags & 4) ~= 0 then
        quake.precache_model2("progs/end3.mdl")
        quake.set_model(self, "progs/end3.mdl")
    end
    if (self.spawnflags & 8) ~= 0 then
        quake.precache_model2("progs/end4.mdl")
        quake.set_model(self, "progs/end4.mdl")
    end

    self.touch = sigil_touch
    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 32))
    start_item(self)
end

--[[
===============================================================================

POWERUPS

===============================================================================
]]

---@param self entity
---@param other entity
---@return nil
local powerup_touch = quake.register_function("items.powerup_touch", function(self, other)
    if other.classname ~= "player" then
        return
    end
    if other.health <= 0 then
        return
    end

    quake.sprint(other, "You got the ")
    quake.sprint(other, self.netname)
    quake.sprint(other, "\n")

    if quake.cvar("deathmatch") ~= 0 then
        self.mdl = self.model

        if self.classname == "item_artifact_invulnerability"
            or self.classname == "item_artifact_invisibility" then
            self.nextthink = quake.time() + 60 * 5
        else
            self.nextthink = quake.time() + 60
        end

        self.think = regen
    end

    quake.sound(other, C.CHAN_VOICE, self.noise, 1, C.ATTN_NORM)
    quake.stuff_cmd(other, "bf\n")
    other.items = other.items | self.items
    hide_item(self)

    -- do the appropriate action
    if self.classname == "item_artifact_envirosuit" then
        other.rad_time = 1
        other.radsuit_finished = quake.time() + 30
    end

    if self.classname == "item_artifact_invulnerability" then
        other.invincible_time = 1
        other.invincible_finished = quake.time() + 30
    end

    if self.classname == "item_artifact_invisibility" then
        other.invisible_time = 1
        other.invisible_finished = quake.time() + 30
    end

    if self.classname == "item_artifact_super_damage" then
        other.super_time = 1
        other.super_damage_finished = quake.time() + 30
    end

    -- fire all targets / killtargets
    subs.use_targets(self, other)
end)

---QUAKED item_artifact_invulnerability (0 .5 .8) (-16 -16 -24) (16 16 32)
---Player is invulnerable for 30 seconds
---@param self entity
---@return nil
local function item_artifact_invulnerability(self)
    self.touch = powerup_touch

    quake.precache_model("progs/invulner.mdl")
    quake.precache_sound("items/protect.wav")
    quake.precache_sound("items/protect2.wav")
    quake.precache_sound("items/protect3.wav")
    self.noise = "items/protect.wav"
    quake.set_model(self, "progs/invulner.mdl")
    self.netname = "Pentagram of Protection"
    self.items = 1048576 -- IT_INVULNERABILITY
    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 32))
    start_item(self)
end

---QUAKED item_artifact_envirosuit (0 .5 .8) (-16 -16 -24) (16 16 32)
---Player takes no damage from water or slime for 30 seconds
---@param self entity
---@return nil
local function item_artifact_envirosuit(self)
    self.touch = powerup_touch

    quake.precache_model("progs/suit.mdl")
    quake.precache_sound("items/suit.wav")
    quake.precache_sound("items/suit2.wav")
    self.noise = "items/suit.wav"
    quake.set_model(self, "progs/suit.mdl")
    self.netname = "Biosuit"
    self.items = 2097152 -- IT_SUIT
    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 32))
    start_item(self)
end

---QUAKED item_artifact_invisibility (0 .5 .8) (-16 -16 -24) (16 16 32)
---Player is invisible for 30 seconds
---@param self entity
---@return nil
local function item_artifact_invisibility(self)
    self.touch = powerup_touch

    quake.precache_model("progs/invisibl.mdl")
    quake.precache_sound("items/inv1.wav")
    quake.precache_sound("items/inv2.wav")
    quake.precache_sound("items/inv3.wav")
    self.noise = "items/inv1.wav"
    quake.set_model(self, "progs/invisibl.mdl")
    self.netname = "Ring of Shadows"
    self.items = C.IT_INVISIBILITY
    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 32))
    start_item(self)
end

---QUAKED item_artifact_super_damage (0 .5 .8) (-16 -16 -24) (16 16 32)
---The next attack from the player will do 4x damage
---@param self entity
---@return nil
local function item_artifact_super_damage(self)
    self.touch = powerup_touch

    quake.precache_model("progs/quaddama.mdl")
    quake.precache_sound("items/damage.wav")
    quake.precache_sound("items/damage2.wav")
    quake.precache_sound("items/damage3.wav")
    self.noise = "items/damage.wav"
    quake.set_model(self, "progs/quaddama.mdl")
    self.netname = "Quad Damage"
    self.items = 4194304 -- IT_QUAD
    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 32))
    start_item(self)
end

--[[
===============================================================================

PLAYER BACKPACKS

===============================================================================
]]

---@param self entity
---@param other entity
---@return nil
local backpack_touch = quake.register_function("items.backpack_touch", function(self, other)
    if other.classname ~= "player" then
        return
    end
    if other.health <= 0 then
        return
    end

    local acount = 0
    quake.sprint(other, "You get ")

    if self.items ~= 0 then
        if (other.items & self.items) == 0 then
            acount = 1
            quake.sprint(other, "the ")
            quake.sprint(other, self.netname)
        end
    end

    -- change weapons
    other.ammo_shells = other.ammo_shells + self.ammo_shells
    other.ammo_nails = other.ammo_nails + self.ammo_nails
    other.ammo_rockets = other.ammo_rockets + self.ammo_rockets
    other.ammo_cells = other.ammo_cells + self.ammo_cells

    local new = self.items
    if new == 0 then
        new = other.weapon
    end
    local old = other.items
    other.items = other.items | new

    bound_other_ammo(other)

    if self.ammo_shells ~= 0 then
        if acount ~= 0 then
            quake.sprint(other, ", ")
        end
        acount = 1
        local s = quake.float_to_string(self.ammo_shells)
        quake.sprint(other, s)
        quake.sprint(other, " shells  ")
    end
    if self.ammo_nails ~= 0 then
        if acount ~= 0 then
            quake.sprint(other, ", ")
        end
        acount = 1
        local s = quake.float_to_string(self.ammo_nails)
        quake.sprint(other, s)
        quake.sprint(other, " nails ")
    end
    if self.ammo_rockets ~= 0 then
        if acount ~= 0 then
            quake.sprint(other, ", ")
        end
        acount = 1
        local s = quake.float_to_string(self.ammo_rockets)
        quake.sprint(other, s)
        quake.sprint(other, " rockets  ")
    end
    if self.ammo_cells ~= 0 then
        if acount ~= 0 then
            quake.sprint(other, ", ")
        end
        acount = 1
        local s = quake.float_to_string(self.ammo_cells)
        quake.sprint(other, s)
        quake.sprint(other, " cells  ")
    end

    quake.sprint(other, "\n")
    -- backpack touch sound
    quake.sound(other, C.CHAN_ITEM, "weapons/lock4.wav", 1, C.ATTN_NORM)
    quake.stuff_cmd(other, "bf\n")

    -- remove the backpack
    quake.remove(self)

    -- check if the player is in water
    if (other.flags & 16) ~= 0 then -- FL_INWATER
        -- switch best weapon if there is no lightning gun in the pack
        if new ~= 64 then -- IT_LIGHTNING
            deathmatch_weapon(other, old, new)
        end
    else
        -- switch to the best weapon in backpack
        deathmatch_weapon(other, old, new)
    end

    weapons.set_current_ammo(other)
end)

---@param self entity
---@return nil
function M.drop_backpack(self)
    if self.ammo_shells + self.ammo_nails + self.ammo_rockets + self.ammo_cells == 0 then
        -- nothing in it
        return
    end

    local item = quake.spawn()
    item.origin = self.origin - quake.vec3(0, 0, 24)

    item.items = self.weapon
    if item.items == 4096 then
        item.netname = "Axe"
    elseif item.items == 1 then
        item.netname = "Shotgun"
    elseif item.items == 2 then
        item.netname = "Double-barrelled Shotgun"
    elseif item.items == 4 then
        item.netname = "Nailgun"
    elseif item.items == 8 then
        item.netname = "Super Nailgun"
    elseif item.items == 16 then
        item.netname = "Grenade Launcher"
    elseif item.items == 32 then
        item.netname = "Rocket Launcher"
    elseif item.items == 64 then
        item.netname = "Thunderbolt"
    else
        item.netname = ""
    end

    item.ammo_shells = self.ammo_shells
    item.ammo_nails = self.ammo_nails
    item.ammo_rockets = self.ammo_rockets
    item.ammo_cells = self.ammo_cells

    item.velocity.z = 300
    item.velocity.x = -100 + quake.random() * 200
    item.velocity.y = -100 + quake.random() * 200

    item.flags = 256 -- FL_ITEM
    item.solid = 1 -- SOLID_TRIGGER
    item.movetype = 6 -- MOVETYPE_TOSS
    quake.set_model(item, "progs/backpack.mdl")
    quake.set_size(item, quake.vec3(-16, -16, 0), quake.vec3(16, 16, 56))
    item.touch = backpack_touch

    -- remove after 2 minutes
    item.nextthink = quake.time() + 120
    item.think = subs.remove
end

quake.register_entity("noclass", noclass)
quake.register_entity("item_health", item_health)
quake.register_entity("item_armor1", item_armor1)
quake.register_entity("item_armor2", item_armor2)
quake.register_entity("item_armorInv", item_armor_inv)
quake.register_entity("weapon_supershotgun", weapon_supershotgun)
quake.register_entity("weapon_nailgun", weapon_nailgun)
quake.register_entity("weapon_supernailgun", weapon_supernailgun)
quake.register_entity("weapon_grenadelauncher", weapon_grenadelauncher)
quake.register_entity("weapon_rocketlauncher", weapon_rocketlauncher)
quake.register_entity("weapon_lightning", weapon_lightning)
quake.register_entity("item_shells", item_shells)
quake.register_entity("item_spikes", item_spikes)
quake.register_entity("item_rockets", item_rockets)
quake.register_entity("item_cells", item_cells)
quake.register_entity("item_weapon", item_weapon)
quake.register_entity("item_key1", item_key1)
quake.register_entity("item_key2", item_key2)
quake.register_entity("item_sigil", item_sigil)
quake.register_entity("item_artifact_invulnerability", item_artifact_invulnerability)
quake.register_entity("item_artifact_envirosuit", item_artifact_envirosuit)
quake.register_entity("item_artifact_invisibility", item_artifact_invisibility)
quake.register_entity("item_artifact_super_damage", item_artifact_super_damage)

return M
