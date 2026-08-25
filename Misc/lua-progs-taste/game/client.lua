-- Port of client.qc from GPL-licensed CleanFixedQuakeC.
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

local quake = require("quake")
local combat = require("game.combat")
local player = require("game.player")
local subs = require("game.subs")
local triggers = require("game.triggers")
local weapons = require("game.weapons")
local world = require("game.world")

---@class game_client
local M = {}
local g = quake.globals

-- prototypes

local IT_SHOTGUN, IT_SUPER_SHOTGUN, IT_NAILGUN, IT_SUPER_NAILGUN = 1, 2, 4, 8
local IT_GRENADE_LAUNCHER, IT_ROCKET_LAUNCHER, IT_LIGHTNING, IT_AXE = 16, 32, 64, 4096
local IT_KEY1, IT_KEY2, IT_INVISIBILITY = 131072, 262144, 524288
local IT_INVULNERABILITY, IT_SUIT, IT_QUAD = 1048576, 2097152, 4194304
local FL_CLIENT, FL_INWATER, FL_MONSTER, FL_ONGROUND = 8, 16, 32, 512
local FL_WATERJUMP, FL_JUMPRELEASED = 2048, 4096
local MOVETYPE_NONE, MOVETYPE_WALK, MOVETYPE_NOCLIP = 0, 3, 8
local SOLID_NOT, SOLID_SLIDEBOX, SOLID_BSP = 0, 3, 4
local DAMAGE_NO, DAMAGE_AIM = 0, 2
local DEAD_NO, DEAD_DYING, DEAD_DEAD, DEAD_RESPAWNABLE = 0, 1, 2, 3
local CONTENT_WATER, CONTENT_SLIME, CONTENT_LAVA = -3, -4, -5
local CHAN_AUTO, CHAN_VOICE, CHAN_BODY = 0, 2, 4
local ATTN_NONE, ATTN_NORM, ATTN_IDLE = 0, 1, 2
local EF_DIMLIGHT = 8
local MSG_ALL = 2
local SVC_CDTRACK, SVC_INTERMISSION, SVC_FINALE, SVC_SELLSCREEN = 32, 30, 31, 33

--[[
=============================================================================

                LEVEL CHANGING / INTERMISSION

=============================================================================
]]

---QUAKED info_intermission (1 0.5 0.5) (-16 -16 -16) (16 16 16)
---This is the camera point for the intermission.
---Use mangle instead of angle, so you can set pitch or roll as well as yaw.  'pitch roll yaw'
---@param _self entity
---@return nil
local function info_intermission(_self) end

---@param self entity
---@return nil
function M.set_change_parms(self)
    if self.health <= 0 then M.set_new_parms(); return end
    -- remove items
    self.items = self.items - (self.items & (IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD))
    -- cap super health
    if self.health > 100 then self.health = 100 end
    if self.health < 50 then self.health = 50 end
    g.parm1 = self.items
    g.parm2 = self.health
    g.parm3 = self.armorvalue
    if self.ammo_shells < 25 then g.parm4 = 25 else g.parm4 = self.ammo_shells end
    g.parm5 = self.ammo_nails
    g.parm6 = self.ammo_rockets
    g.parm7 = self.ammo_cells
    g.parm8 = self.weapon
    g.parm9 = self.armortype * 100
end

---@return nil
function M.set_new_parms()
    g.parm1 = IT_SHOTGUN | IT_AXE
    g.parm2, g.parm3, g.parm4 = 100, 0, 25
    g.parm5, g.parm6, g.parm7 = 0, 0, 0
    g.parm8, g.parm9 = 1, 0
end

---@param self entity
---@return nil
local function decode_level_parms(self)
    if g.serverflags ~= 0 and quake.world.model == "maps/start.bsp" then
        M.set_new_parms() -- take away all stuff on starting new episode
    end
    self.items = g.parm1
    self.health = g.parm2
    self.armorvalue = g.parm3
    self.ammo_shells = g.parm4
    self.ammo_nails = g.parm5
    self.ammo_rockets = g.parm6
    self.ammo_cells = g.parm7
    self.weapon = g.parm8
    self.armortype = g.parm9 * 0.01
end

---Returns the entity to view from
---@return entity
local function find_intermission()
    -- look for info_intermission first
    local spot = quake.find(quake.world, "classname", "info_intermission")
    if spot then
        -- pick a random one
        local cyc = quake.random() * 4
        while cyc > 1 do
            spot = quake.find(spot, "classname", "info_intermission")
            if not spot then
                spot = quake.find(spot, "classname", "info_intermission")
                assert(spot, "intermission entity disappeared")
            end
            cyc = cyc - 1
        end
        return spot
    end
    -- then look for the start position
    spot = quake.find(quake.world, "classname", "info_player_start")
    if spot then return spot end
    -- testinfo_player_start is only found in regioned levels
    spot = quake.find(quake.world, "classname", "testplayerstart")
    if spot then return spot end
    quake.object_error("FindIntermission: no spot")
    -- avoid compiler warning
    return quake.world
end

---@return nil
local function goto_next_map()
    if quake.cvar("samelevel") ~= 0 then -- if samelevel is set, stay on same level
        quake.change_level(g.mapname)
    else
        quake.change_level(g.nextmap)
    end
end

local finale_e1_unregistered = "As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task in the other three\nhaunted lands of Quake. Or are you? If\nyou don't register Quake, you'll never\nknow what awaits you in the Realm of\nBlack Magic, the Netherworld, and the\nElder World!"
local finale_e1 = "As the corpse of the monstrous entity\nChthon sinks back into the lava whence\nit rose, you grip the Rune of Earth\nMagic tightly. Now that you have\nconquered the Dimension of the Doomed,\nrealm of Earth Magic, you are ready to\ncomplete your task. A Rune of magic\npower lies at the end of each haunted\nland of Quake. Go forth, seek the\ntotality of the four Runes!"
local finale_e2 = "The Rune of Black Magic throbs evilly in\nyour hand and whispers dark thoughts\ninto your brain. You learn the inmost\nlore of the Hell-Mother; Shub-Niggurath!\nYou now know that she is behind all the\nterrible plotting which has led to so\nmuch death and horror. But she is not\ninviolate! Armed with this Rune, you\nrealize that once all four Runes are\ncombined, the gate to Shub-Niggurath's\nPit will open, and you can face the\nWitch-Goddess herself in her frightful\notherworld cathedral."
local finale_e3 = "The charred viscera of diabolic horrors\nbubble viscously as you seize the Rune\nof Hell Magic. Its heat scorches your\nhand, and its terrible secrets blight\nyour mind. Gathering the shreds of your\ncourage, you shake the devil's shackles\nfrom your soul, and become ever more\nhard and determined to destroy the\nhideous creatures whose mere existence\nthreatens the souls and psyches of all\nthe population of Earth."
local finale_e4 = "Despite the awful might of the Elder\nWorld, you have achieved the Rune of\nElder Magic, capstone of all types of\narcane wisdom. Beyond good and evil,\nbeyond life and death, the Rune\npulsates, heavy with import. Patient and\npotent, the Elder Being Shub-Niggurath\nweaves her dire plans to clear off all\nlife from the Earth, and bring her own\nfoul offspring to our world! For all the\ndwellers in these nightmare dimensions\nare her descendants! Once all Runes of\nmagic power are united, the energy\nbehind them will blast open the Gateway\nto Shub-Niggurath, and you can travel\nthere to foil the Hell-Mother's plots\nin person."
local finale_all = "Now, you have all four Runes. You sense\ntremendous invisible forces moving to\nunseal ancient barriers. Shub-Niggurath\nhad hoped to use the Runes Herself to\nclear off the Earth, but now instead,\nyou will use them to enter her home and\nconfront her as an avatar of avenging\nEarth-life. If you defeat her, you will\nbe remembered forever as the savior of\nthe planet. If she conquers, it will be\nas if you had never been born."

---@return nil
local function exit_intermission()
    -- skip any text in deathmatch
    if g.deathmatch ~= 0 then goto_next_map(); return end
    g.intermission_exittime = quake.time() + 1
    g.intermission_running = g.intermission_running + 1
    -- run some text if at the end of an episode
    if g.intermission_running == 2 then
        local text
        if quake.world.model == "maps/e1m7.bsp" then
            text = quake.cvar("registered") == 0 and finale_e1_unregistered or finale_e1
        elseif quake.world.model == "maps/e2m6.bsp" then text = finale_e2
        elseif quake.world.model == "maps/e3m6.bsp" then text = finale_e3
        elseif quake.world.model == "maps/e4m7.bsp" then text = finale_e4
        else goto_next_map(); return end
        quake.write_byte(MSG_ALL, SVC_CDTRACK); quake.write_byte(MSG_ALL, 2); quake.write_byte(MSG_ALL, 3)
        quake.write_byte(MSG_ALL, SVC_FINALE); quake.write_string(MSG_ALL, text)
        return
    end
    if g.intermission_running == 3 then
        if quake.cvar("registered") == 0 then
            -- shareware episode has been completed, go to sell screen
            quake.write_byte(MSG_ALL, SVC_SELLSCREEN)
            return
        end
        if (g.serverflags & 15) == 15 then
            quake.write_byte(MSG_ALL, SVC_FINALE)
            quake.write_string(MSG_ALL, finale_all)
            return
        end
    end
    goto_next_map()
end

---When the player presses attack or jump, change to the next level
---@param self entity
---@return nil
local function intermission_think(self)
    if quake.time() < g.intermission_exittime then return end
    if self.button0 == 0 and self.button1 == 0 and self.button2 == 0 then return end
    exit_intermission()
end

---@param _self entity
---@return nil
local function execute_changelevel(_self)
    g.intermission_running = 1
    -- enforce a wait time before allowing changelevel
    if g.deathmatch ~= 0 then g.intermission_exittime = quake.time() + 5
    else g.intermission_exittime = quake.time() + 2 end
    quake.write_byte(MSG_ALL, SVC_CDTRACK); quake.write_byte(MSG_ALL, 3); quake.write_byte(MSG_ALL, 3)
    local pos = find_intermission()
    local other = quake.find(quake.world, "classname", "player")
    while other do
        other.view_ofs = quake.vec3(0, 0, 0)
        other.angles = pos.mangle
        other.v_angle = pos.mangle
        other.fixangle = 1 -- turn this way immediately
        other.nextthink = quake.time() + 0.5
        other.takedamage = DAMAGE_NO
        other.solid = SOLID_NOT
        other.movetype = MOVETYPE_NONE
        other.modelindex = 0
        quake.set_origin(other, pos.origin)
        other = quake.find(other, "classname", "player")
    end
    quake.write_byte(MSG_ALL, SVC_INTERMISSION)
end

---@param self entity
---@param other entity
---@return nil
local function changelevel_touch(self, other)
    if other.classname ~= "player" then return end
    if quake.cvar("noexit") == 1 or (quake.cvar("noexit") == 2 and g.mapname ~= "start") then
        combat.damage(other, self, self, 50000)
        return
    end
    -- don't print the messages in singleplayer
    if g.coop ~= 0 or g.deathmatch ~= 0 then quake.bprint(other.netname); quake.bprint(" exited the level\n") end
    g.nextmap = self.map
    subs.use_targets(self, self)
    if (self.spawnflags & 1) ~= 0 and g.deathmatch == 0 then
        -- NO_INTERMISSION
        goto_next_map()
        return
    end
    self.touch = subs.null
    -- we can't move people right now, because touch functions are called
    -- in the middle of C movement code, so set a think time to do it
    self.think = execute_changelevel
    self.nextthink = quake.time() + 0.1
end

---QUAKED trigger_changelevel (0.5 0.5 0.5) ? NO_INTERMISSION
---When the player touches this, he gets sent to the map listed in the "map" variable.  Unless the NO_INTERMISSION flag is set, the view will go to the info_intermission spot and display stats.
---@param self entity
---@return nil
local function trigger_changelevel(self)
    if self.map == "" then quake.object_error("changelevel trigger doesn't have map") end
    subs.init_trigger(self)
    self.touch = changelevel_touch
end

--[[
=============================================================================

                PLAYER GAME EDGE FUNCTIONS

=============================================================================
]]
-- called by ClientKill and DeadThink
---@param self entity
---@return nil
local function respawn(self)
    if g.coop ~= 0 then
        -- make a copy of the dead body for appearances sake
        world.copy_to_body_que(self)
        -- get the spawn parms as they were at level start
        quake.set_spawn_parms(self)
        -- respawn
        M.put_client_in_server(self)
    elseif g.deathmatch ~= 0 then
        -- make a copy of the dead body for appearances sake
        world.copy_to_body_que(self)
        -- set default spawn parms
        M.set_new_parms()
        -- respawn
        M.put_client_in_server(self)
    else
        -- restart the entire server
        quake.local_cmd("restart\n")
    end
end

---Player entered the suicide command
---@param self entity
---@return nil
function M.client_kill(self)
    quake.bprint(self.netname); quake.bprint(" suicides\n")
    player.set_suicide_frame(self)
    self.modelindex = g.modelindex_player
    self.frags = self.frags - 2 -- extra penalty
    respawn(self)
end

---@param _v vec3
---@return boolean
local function check_spawn_point(_v)
    return false
end

---Returns the entity to spawn at
---@return entity
local function select_spawn_point()
    -- testinfo_player_start is only found in regioned levels
    local spot = quake.find(quake.world, "classname", "testplayerstart")
    if spot then return spot end
    -- choose a info_player_deathmatch point
    if g.coop ~= 0 then
        g.lastspawn = quake.find(g.lastspawn, "classname", "info_player_coop")
        if not g.lastspawn then g.lastspawn = quake.find(g.lastspawn, "classname", "info_player_start") end
        if g.lastspawn then return g.lastspawn end
    elseif g.deathmatch ~= 0 then
        spot = g.lastspawn
        -- loop until a spawn point is located
        while true do
            -- locate a spawn point
            spot = quake.find(spot, "classname", "info_player_deathmatch")
            -- check that a spot was found
            if spot then
                -- check if the spot is the same as the last spawn point checked
                if spot == g.lastspawn then return g.lastspawn end
                -- count the number of players close to the spawn point
                local pcount = 0
                local thing = quake.find_radius(spot.origin, 32)
                while thing do
                    if thing.classname == "player" then pcount = pcount + 1 end
                    thing = thing.chain
                end
                -- use spot if no players at spawn point
                if pcount == 0 then g.lastspawn = spot; return spot end
            end
        end
    end
    if g.serverflags ~= 0 then
        -- return with a rune to start
        spot = quake.find(quake.world, "classname", "info_player_start2")
        if spot then return spot end
    end
    spot = quake.find(quake.world, "classname", "info_player_start")
    if not spot then error("PutClientInServer: no info_player_start on level") end
    return spot
end

---called each time a player is spawned
---@param self entity
---@return nil
function M.put_client_in_server(self)
    local spot = select_spawn_point()
    self.classname = "player"
    self.health = 100
    self.takedamage = DAMAGE_AIM
    self.solid = SOLID_SLIDEBOX
    self.movetype = MOVETYPE_WALK
    self.show_hostile = 0
    self.max_health = 100
    self.flags = FL_CLIENT
    self.air_finished = quake.time() + 12
    self.dmg = 2 -- initial water damage
    self.super_damage_finished = 0
    self.radsuit_finished = 0
    self.invisible_finished = 0
    self.invincible_finished = 0
    self.effects = 0
    self.invincible_time = 0
    decode_level_parms(self)
    weapons.set_current_ammo(self)
    self.attack_finished = quake.time()
    self.th_pain = player.player_pain
    self.th_die = player.player_die
    self.deadflag = DEAD_NO
    -- paustime is set by teleporters to keep the player from moving a while
    self.pausetime = 0
    self.origin = spot.origin + quake.vec3(0, 0, 1)
    self.angles = spot.angles
    self.fixangle = 1 -- turn this way immediately
    -- oh, this is a hack!
    quake.set_model(self, "progs/eyes.mdl")
    g.modelindex_eyes = self.modelindex
    quake.set_model(self, "progs/player.mdl")
    g.modelindex_player = self.modelindex
    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 32))
    self.view_ofs = quake.vec3(0, 0, 22)
    player.player_stand1(self)
    if g.deathmatch ~= 0 or g.coop ~= 0 then
        local vectors = quake.make_vectors(self.angles)
        triggers.spawn_tfog(self.origin + vectors.forward * 20)
    end
    triggers.spawn_tdeath(self.origin, self)
end

--[[
=============================================================================

                QUAKED FUNCTIONS

=============================================================================
]]

---QUAKED info_player_start (1 0 0) (-16 -16 -24) (16 16 24)
---The normal starting point for a level.
---@param _self entity
---@return nil
local function info_player_start(_self) end
---QUAKED info_player_start2 (1 0 0) (-16 -16 -24) (16 16 24)
---Only used on start map for the return point from an episode.
---@param _self entity
---@return nil
local function info_player_start2(_self) end
-- saved out by quaked in region mode
---@param _self entity
---@return nil
local function testplayerstart(_self) end
---QUAKED info_player_deathmatch (1 0 1) (-16 -16 -24) (16 16 24)
---potential spawning position for deathmatch games
---@param _self entity
---@return nil
local function info_player_deathmatch(_self) end
---QUAKED info_player_coop (1 0 1) (-16 -16 -24) (16 16 24)
---potential spawning position for coop games
---@param _self entity
---@return nil
local function info_player_coop(_self) end

--[[
===============================================================================

RULES

===============================================================================
]]

-- go to the next level for deathmatch
---@return nil
local function next_level()
    local o
    if g.mapname == "start" then
        if quake.cvar("registered") == 0 then g.mapname = "e1m1"
        elseif (g.serverflags & 1) == 0 then g.mapname = "e1m1"; g.serverflags = g.serverflags | 1
        elseif (g.serverflags & 2) == 0 then g.mapname = "e2m1"; g.serverflags = g.serverflags | 2
        elseif (g.serverflags & 4) == 0 then g.mapname = "e3m1"; g.serverflags = g.serverflags | 4
        elseif (g.serverflags & 8) == 0 then g.mapname = "e4m1"; g.serverflags = g.serverflags - 7 end
        o = quake.spawn(); o.map = g.mapname
    else
        -- find a trigger changelevel
        o = quake.find(quake.world, "classname", "trigger_changelevel")
        -- go back to start if no trigger for the next level
        if not o then g.mapname = "start"; o = quake.spawn(); o.map = g.mapname end
    end
    g.nextmap = o.map
    g.gameover = 1
    if o.nextthink < quake.time() then o.think = execute_changelevel; o.nextthink = quake.time() + 0.1 end
end

---Exit deathmatch games upon conditions
---@param self entity
---@return nil
local function check_rules(self)
    if g.gameover ~= 0 then return end -- someone else quit the game already
    local timelimit = quake.cvar("timelimit") * 60
    local fraglimit = quake.cvar("fraglimit")
    if timelimit ~= 0 and quake.time() >= timelimit then next_level(); return end
    if fraglimit ~= 0 and self.frags >= fraglimit then next_level(); return end
end

--============================================================================
---@param self entity
---@return nil
local function player_death_think(self)
    if (self.flags & FL_ONGROUND) ~= 0 then
        local forward = self.velocity:length() - 20
        if forward <= 0 then self.velocity = quake.vec3(0, 0, 0)
        else self.velocity = self.velocity:normalized() * forward end
    end
    -- wait for all buttons released
    if self.deadflag == DEAD_DEAD then
        if self.button2 ~= 0 or self.button1 ~= 0 or self.button0 ~= 0 then return end
        self.deadflag = DEAD_RESPAWNABLE
        return
    end
    -- wait for any button down
    if self.button2 == 0 and self.button1 == 0 and self.button0 == 0 then return end
    self.button0, self.button1, self.button2 = 0, 0, 0
    respawn(self)
end

---@param self entity
---@return nil
local function player_jump(self)
    if (self.flags & FL_WATERJUMP) ~= 0 then return end
    if self.waterlevel >= 2 then
        if self.watertype == CONTENT_WATER then self.velocity = quake.vec3(self.velocity.x, self.velocity.y, 100)
        elseif self.watertype == CONTENT_SLIME then self.velocity = quake.vec3(self.velocity.x, self.velocity.y, 80)
        else self.velocity = quake.vec3(self.velocity.x, self.velocity.y, 50) end
        -- play swimming sound
        if self.swim_flag < quake.time() then
            self.swim_flag = quake.time() + 1
            if quake.random() < 0.5 then quake.sound(self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM)
            else quake.sound(self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM) end
        end
        return
    end
    if (self.flags & FL_ONGROUND) == 0 then return end
    if (self.flags & FL_JUMPRELEASED) == 0 then return end -- don't pogo stick
    self.flags = self.flags - (self.flags & FL_JUMPRELEASED)
    self.flags = self.flags - FL_ONGROUND -- don't stairwalk
    self.button2 = 0
    -- player jumping sound
    quake.sound(self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM)
    self.velocity = quake.vec3(self.velocity.x, self.velocity.y, self.velocity.z + 270)
end

---@param self entity
---@return nil
local function water_move(self)
    if self.movetype == MOVETYPE_NOCLIP then return end
    if self.health < 0 then return end
    if self.waterlevel ~= 3 then
        if self.air_finished < quake.time() then quake.sound(self, CHAN_VOICE, "player/gasp2.wav", 1, ATTN_NORM)
        elseif self.air_finished < quake.time() + 9 then quake.sound(self, CHAN_VOICE, "player/gasp1.wav", 1, ATTN_NORM) end
        self.air_finished = quake.time() + 12
        self.dmg = 2
    elseif self.air_finished < quake.time() then
        -- drown!
        if self.pain_finished < quake.time() then
            self.dmg = self.dmg + 2
            if self.dmg > 15 then self.dmg = 10 end
            combat.damage(self, quake.world, quake.world, self.dmg)
            self.pain_finished = quake.time() + 1
        end
    end
    if self.waterlevel == 0 then
        if (self.flags & FL_INWATER) ~= 0 then
            -- play leave water sound
            quake.sound(self, CHAN_BODY, "misc/outwater.wav", 1, ATTN_NORM)
            self.flags = self.flags - FL_INWATER
        end
        return
    end
    if self.watertype == CONTENT_LAVA then
        -- do damage
        if self.dmgtime < quake.time() then
            if self.radsuit_finished > quake.time() then self.dmgtime = quake.time() + 1
            else self.dmgtime = quake.time() + 0.2 end
            combat.damage(self, quake.world, quake.world, 10 * self.waterlevel)
        end
    elseif self.watertype == CONTENT_SLIME then
        -- do damage
        if self.dmgtime < quake.time() and self.radsuit_finished < quake.time() then
            self.dmgtime = quake.time() + 1
            combat.damage(self, quake.world, quake.world, 4 * self.waterlevel)
        end
    end
    if (self.flags & FL_INWATER) == 0 then
        -- player enter water sound
        if self.watertype == CONTENT_LAVA then quake.sound(self, CHAN_BODY, "player/inlava.wav", 1, ATTN_NORM) end
        if self.watertype == CONTENT_WATER then quake.sound(self, CHAN_BODY, "player/inh2o.wav", 1, ATTN_NORM) end
        if self.watertype == CONTENT_SLIME then quake.sound(self, CHAN_BODY, "player/slimbrn2.wav", 1, ATTN_NORM) end
        self.flags = self.flags + FL_INWATER
        self.dmgtime = 0
    end
    if (self.flags & FL_WATERJUMP) == 0 then self.velocity = self.velocity - self.velocity * (0.8 * self.waterlevel * g.frametime) end
end

---@param self entity
---@return nil
local function check_water_jump(self)
    -- check for a jump-out-of-water
    local vectors = quake.make_vectors(self.angles)
    local start = self.origin + quake.vec3(0, 0, 8)
    local forward = quake.vec3(vectors.forward.x, vectors.forward.y, 0):normalized()
    local finish = start + forward * 24
    local trace = quake.trace_line(start, finish, true, self)
    if trace.fraction < 1 then
        -- solid at waist
        start = start + quake.vec3(0, 0, self.maxs.z - 8)
        finish = start + forward * 24
        self.movedir = trace.plane_normal * -50
        trace = quake.trace_line(start, finish, true, self)
        if trace.fraction == 1 then
            -- open at eye level
            self.flags = self.flags | FL_WATERJUMP
            self.velocity = quake.vec3(self.velocity.x, self.velocity.y, 225)
            self.flags = self.flags - (self.flags & FL_JUMPRELEASED)
            self.teleport_time = quake.time() + 2 -- safety net
            return
        end
    end
end

---Called every frame before physics are run
---@param self entity
---@return nil
function M.player_pre_think(self)
    if g.intermission_running ~= 0 then
        -- otherwise a button could be missed between the think tics
        intermission_think(self)
        return
    end
    -- intermission or finale
    if self.view_ofs == quake.vec3(0, 0, 0) then return end
    -- is this still used
    quake.make_vectors(self.v_angle)
    check_rules(self)
    water_move(self)
    if self.waterlevel == 2 then check_water_jump(self) end
    if self.deadflag >= DEAD_DEAD then player_death_think(self); return end
    -- dying, so do nothing
    if self.deadflag == DEAD_DYING then return end
    if self.button2 ~= 0 then player_jump(self) else self.flags = self.flags | FL_JUMPRELEASED end
    -- teleporters can force a non-moving pause time
    if quake.time() < self.pausetime then self.velocity = quake.vec3(0, 0, 0) end
    if quake.time() > self.attack_finished and self.currentammo == 0 and self.weapon ~= IT_AXE then
        self.weapon = weapons.best_weapon(self)
        weapons.set_current_ammo(self)
    end
end

---@param self entity
---@param message string
---@param sound string
---@return nil
local function flash(self, message, sound)
    quake.sprint(self, message)
    quake.stuff_cmd(self, "bf\n")
    quake.sound(self, CHAN_AUTO, sound, 1, ATTN_NORM)
end

---Check for turning off powerups
---@param self entity
---@return nil
local function check_powerups(self)
    if self.health <= 0 then return end
    -- invisibility
    if self.invisible_finished ~= 0 then
        -- sound and screen flash when items starts to run out
        if self.invisible_sound < quake.time() then
            quake.sound(self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE)
            self.invisible_sound = quake.time() + quake.random() * 3 + 1
        end
        if self.invisible_finished < quake.time() + 3 then
            if self.invisible_time == 1 then flash(self, "Ring of Shadows magic is fading\n", "items/inv2.wav"); self.invisible_time = quake.time() + 1 end
            if self.invisible_time < quake.time() then self.invisible_time = quake.time() + 1; quake.stuff_cmd(self, "bf\n") end
        end
        if self.invisible_finished < quake.time() then
            -- just stopped
            self.items = self.items - IT_INVISIBILITY
            self.invisible_finished, self.invisible_time = 0, 0
        end
        -- use the eyes
        self.frame = 0
        self.modelindex = g.modelindex_eyes
    else
        -- don't use eyes
        self.modelindex = g.modelindex_player
    end
    -- invincibility
    if self.invincible_finished ~= 0 then
        -- sound and screen flash when items starts to run out
        if self.invincible_finished < quake.time() + 3 then
            if self.invincible_time == 1 then flash(self, "Protection is almost burned out\n", "items/protect2.wav"); self.invincible_time = quake.time() + 1 end
            if self.invincible_time < quake.time() then self.invincible_time = quake.time() + 1; quake.stuff_cmd(self, "bf\n") end
        end
        if self.invincible_finished < quake.time() then
            -- just stopped
            self.items = self.items - IT_INVULNERABILITY
            self.invincible_time, self.invincible_finished = 0, 0
        end
        if self.invincible_finished > quake.time() then self.effects = self.effects | EF_DIMLIGHT
        else self.effects = self.effects - (self.effects & EF_DIMLIGHT) end
    end
    -- super damage
    if self.super_damage_finished ~= 0 then
        -- sound and screen flash when items starts to run out
        if self.super_damage_finished < quake.time() + 3 then
            if self.super_time == 1 then flash(self, "Quad Damage is wearing off\n", "items/damage2.wav"); self.super_time = quake.time() + 1 end
            if self.super_time < quake.time() then self.super_time = quake.time() + 1; quake.stuff_cmd(self, "bf\n") end
        end
        if self.super_damage_finished < quake.time() then
            -- just stopped
            self.items = self.items - IT_QUAD
            self.super_damage_finished, self.super_time = 0, 0
        end
        if self.super_damage_finished > quake.time() then self.effects = self.effects | EF_DIMLIGHT
        else self.effects = self.effects - (self.effects & EF_DIMLIGHT) end
    end
    -- suit
    if self.radsuit_finished ~= 0 then
        -- don't drown
        self.air_finished = quake.time() + 12
        -- sound and screen flash when items starts to run out
        if self.radsuit_finished < quake.time() + 3 then
            if self.rad_time == 1 then flash(self, "Air supply in Biosuit expiring\n", "items/suit2.wav"); self.rad_time = quake.time() + 1 end
            if self.rad_time < quake.time() then self.rad_time = quake.time() + 1; quake.stuff_cmd(self, "bf\n") end
        end
        if self.radsuit_finished < quake.time() then
            -- just stopped
            self.items = self.items - IT_SUIT
            self.rad_time, self.radsuit_finished = 0, 0
        end
    end
end

---Called every frame after physics are run
---@param self entity
---@return nil
function M.player_post_think(self)
    -- intermission or finale
    if self.view_ofs == quake.vec3(0, 0, 0) then return end
    if self.deadflag ~= 0 then return end
    -- do weapon stuff
    weapons.weapon_frame(self)
    -- check to see if player landed and play landing sound
    if self.jump_flag < -300 and (self.flags & FL_ONGROUND) ~= 0 and self.health > 0 then
        if self.watertype == CONTENT_WATER then quake.sound(self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM)
        elseif self.jump_flag < -650 then
            combat.damage(self, quake.world, quake.world, 5)
            quake.sound(self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM)
            self.deathtype = "falling"
        else quake.sound(self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM) end
        self.jump_flag = 0
    end
    if (self.flags & FL_ONGROUND) == 0 then self.jump_flag = self.velocity.z end
    check_powerups(self)
end

---called when a player connects to a server
---@param self entity
---@return nil
function M.client_connect(self)
    quake.bprint(self.netname); quake.bprint(" entered the game\n")
    -- a client connecting during an intermission can cause problems
    if g.intermission_running ~= 0 then exit_intermission() end
end

---called when a player disconnects from a server
---@param self entity
---@return nil
function M.client_disconnect(self)
    if g.gameover ~= 0 then return end
    -- if the level end trigger has been activated, just return
    -- since they aren't *really* leaving
    -- let everyone else know
    quake.bprint(self.netname); quake.bprint(" left the game with "); quake.bprint(tostring(self.frags)); quake.bprint(" frags\n")
    quake.sound(self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE)
    player.set_suicide_frame(self)
end

---called when a player dies
---@param targ entity
---@param attacker entity
---@return nil
function M.client_obituary(targ, attacker)
    local rnum = quake.random()
    local deathstring, deathstring2 = "", ""
    if targ.classname == "player" then
        if attacker.classname == "teledeath" then
            quake.bprint(targ.netname); quake.bprint(" was telefragged by "); quake.bprint(attacker.owner.netname); quake.bprint("\n")
            attacker.owner.frags = attacker.owner.frags + 1
            return
        end
        if attacker.classname == "teledeath2" then
            quake.bprint("Satan's power deflects "); quake.bprint(targ.netname); quake.bprint("'s telefrag\n")
            targ.frags = targ.frags - 1
            return
        end
        if attacker.classname == "player" then
            if targ == attacker then
                -- killed self
                attacker.frags = attacker.frags - 1
                quake.bprint(targ.netname)
                if targ.weapon == IT_LIGHTNING and targ.waterlevel > 1 then quake.bprint(" discharges into the water.\n"); return end
                if targ.weapon == IT_GRENADE_LAUNCHER then quake.bprint(" tries to put the pin back in\n")
                else quake.bprint(" becomes bored with life\n") end
                return
            elseif g.teamplay == 2 and targ.team > 0 and targ.team == attacker.team then
                if rnum < 0.25 then deathstring = " mows down a teammate\n"
                elseif rnum < 0.50 then deathstring = " checks his glasses\n"
                elseif rnum < 0.75 then deathstring = " gets a frag for the other team\n"
                else deathstring = " loses another friend\n" end
                quake.bprint(attacker.netname); quake.bprint(deathstring)
                attacker.frags = attacker.frags - 1
                return
            else
                attacker.frags = attacker.frags + 1
                rnum = attacker.weapon
                if rnum == IT_AXE then deathstring, deathstring2 = " was ax-murdered by ", "\n" end
                if rnum == IT_SHOTGUN then deathstring, deathstring2 = " chewed on ", "'s boomstick\n" end
                if rnum == IT_SUPER_SHOTGUN then deathstring, deathstring2 = " ate 2 loads of ", "'s buckshot\n" end
                if rnum == IT_NAILGUN then deathstring, deathstring2 = " was nailed by ", "\n" end
                if rnum == IT_SUPER_NAILGUN then deathstring, deathstring2 = " was punctured by ", "\n" end
                if rnum == IT_GRENADE_LAUNCHER then
                    deathstring, deathstring2 = " eats ", "'s pineapple\n"
                    if targ.health < -40 then deathstring, deathstring2 = " was gibbed by ", "'s grenade\n" end
                end
                if rnum == IT_ROCKET_LAUNCHER then
                    deathstring, deathstring2 = " rides ", "'s rocket\n"
                    if targ.health < -40 then deathstring, deathstring2 = " was gibbed by ", "'s rocket\n" end
                end
                if rnum == IT_LIGHTNING then
                    deathstring = " accepts "
                    if attacker.waterlevel > 1 then deathstring2 = "'s discharge\n" else deathstring2 = "'s shaft\n" end
                end
                quake.bprint(targ.netname); quake.bprint(deathstring); quake.bprint(attacker.netname); quake.bprint(deathstring2)
            end
            return
        else
            -- killed self
            targ.frags = targ.frags - 1
            quake.bprint(targ.netname)
            if (attacker.flags & FL_MONSTER) ~= 0 then
                if attacker.classname == "monster_army" then quake.bprint(" was shot by a Grunt\n") end
                if attacker.classname == "monster_demon1" then quake.bprint(" was eviscerated by a Fiend\n") end
                if attacker.classname == "monster_dog" then quake.bprint(" was mauled by a Rottweiler\n") end
                if attacker.classname == "monster_enforcer" then quake.bprint(" was blasted by an Enforcer\n") end
                if attacker.classname == "monster_fish" then quake.bprint(" was fed to the Rotfish\n") end
                if attacker.classname == "monster_hell_knight" then quake.bprint(" was slain by a Death Knight\n") end
                if attacker.classname == "monster_knight" then quake.bprint(" was slashed by a Knight\n") end
                if attacker.classname == "monster_ogre" then quake.bprint(" was destroyed by an Ogre\n") end
                if attacker.classname == "monster_oldone" then quake.bprint(" became one with Shub-Niggurath\n") end
                if attacker.classname == "monster_shalrath" then quake.bprint(" was exploded by a Vore\n") end
                if attacker.classname == "monster_shambler" then quake.bprint(" was smashed by a Shambler\n") end
                if attacker.classname == "monster_tarbaby" then quake.bprint(" was slimed by a Spawn\n") end
                if attacker.classname == "monster_wizard" then quake.bprint(" was scragged by a Scrag\n") end
                if attacker.classname == "monster_zombie" then quake.bprint(" joins the Zombies\n") end
                return
            end
            if attacker.classname == "explo_box" then quake.bprint(" blew up\n"); return end
            if attacker.solid == SOLID_BSP and attacker ~= quake.world then quake.bprint(" was squished\n"); return end
            if attacker.classname == "trap_shooter" or attacker.classname == "trap_spikeshooter" then quake.bprint(" was spiked\n"); return end
            if attacker.classname == "fireball" then quake.bprint(" ate a lavaball\n"); return end
            if attacker.classname == "trigger_changelevel" then quake.bprint(" tried to leave\n"); return end
            rnum = targ.watertype
            if rnum == -3 then
                if quake.random() < 0.5 then quake.bprint(" sleeps with the fishes\n") else quake.bprint(" sucks it down\n") end
                return
            elseif rnum == -4 then
                if quake.random() < 0.5 then quake.bprint(" gulped a load of slime\n") else quake.bprint(" can't exist on slime alone\n") end
                return
            elseif rnum == -5 then
                if targ.health < -15 then quake.bprint(" burst into flames\n"); return end
                if quake.random() < 0.5 then quake.bprint(" turned into hot slag\n") else quake.bprint(" visits the Volcano God\n") end
                return
            end
            if targ.deathtype == "falling" then targ.deathtype = ""; quake.bprint(" fell to his death\n"); return end
            quake.bprint(" died\n")
        end
    end
end

quake.register_entity("info_intermission", info_intermission)
quake.register_entity("trigger_changelevel", trigger_changelevel)
quake.register_entity("info_player_start", info_player_start)
quake.register_entity("info_player_start2", info_player_start2)
quake.register_entity("testplayerstart", testplayerstart)
quake.register_entity("info_player_deathmatch", info_player_deathmatch)
quake.register_entity("info_player_coop", info_player_coop)

return M
