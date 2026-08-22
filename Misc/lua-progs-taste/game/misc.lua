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
-- Port of misc.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local combat = require("game.combat")
local enforcer = require("game.enforcer")
local subs = require("game.subs")
local weapons = require("game.weapons")

local M = {}

local MOVETYPE_NONE, MOVETYPE_NOCLIP, MOVETYPE_TOSS, MOVETYPE_PUSH = 0, 8, 6, 7
local SOLID_NOT, SOLID_TRIGGER, SOLID_BBOX, SOLID_BSP = 0, 1, 2, 4
local DAMAGE_NO, DAMAGE_AIM = 0, 2
local CHAN_VOICE = 2
local ATTN_NORM, ATTN_STATIC = 1, 3

--[[QUAKED info_null (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for spotlights, etc.
]]
function M.info_null(self)
    quake.remove(self)
end

--[[QUAKED info_notnull (0 0.5 0) (-4 -4 -4) (4 4 4)
Used as a positional target for lightning.
]]
function M.info_notnull(_self)
end

--============================================================================

local START_OFF = 1

local function light_use(self, _activator)
    if (self.spawnflags & START_OFF) ~= 0 then
        quake.light_style(self.style, "m")
        self.spawnflags = self.spawnflags - START_OFF
    else
        quake.light_style(self.style, "a")
        self.spawnflags = self.spawnflags + START_OFF
    end
end

--[[QUAKED light (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
]]
function M.light(self)
    if self.targetname == "" then
        -- inert light
        quake.remove(self)
        return
    end
    if self.style >= 32 then
        self.use = light_use
        if (self.spawnflags & START_OFF) ~= 0 then quake.light_style(self.style, "a")
        else quake.light_style(self.style, "m") end
    end
end

--[[QUAKED light_fluoro (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Non-displayed light.
Default light value is 300
Default style is 0
If targeted, it will toggle between on or off.
Makes steady fluorescent humming sound
]]
function M.light_fluoro(self)
    if self.style >= 32 then
        self.use = light_use
        if (self.spawnflags & START_OFF) ~= 0 then quake.light_style(self.style, "a")
        else quake.light_style(self.style, "m") end
    end
    quake.precache_sound("ambience/fl_hum1.wav")
    quake.ambient_sound(self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC)
end

--[[QUAKED light_fluorospark (0 1 0) (-8 -8 -8) (8 8 8)
Non-displayed light.
Default light value is 300
Default style is 10
Makes sparking, broken fluorescent sound
]]
function M.light_fluorospark(self)
    if self.style == 0 then self.style = 10 end
    quake.precache_sound("ambience/buzz1.wav")
    quake.ambient_sound(self.origin, "ambience/buzz1.wav", 0.5, ATTN_STATIC)
end

--[[QUAKED light_globe (0 1 0) (-8 -8 -8) (8 8 8)
Sphere globe light.
Default light value is 300
Default style is 0
]]
function M.light_globe(self)
    quake.precache_model("progs/s_light.spr")
    quake.set_model(self, "progs/s_light.spr")
    quake.make_static(self)
end

local function fire_ambient(self)
    quake.precache_sound("ambience/fire1.wav")
    -- attenuate fast
    quake.ambient_sound(self.origin, "ambience/fire1.wav", 0.5, ATTN_STATIC)
end

--[[QUAKED light_torch_small_walltorch (0 .5 0) (-10 -10 -20) (10 10 20)
Short wall torch
Default light value is 200
Default style is 0
]]
function M.light_torch_small_walltorch(self)
    quake.precache_model("progs/flame.mdl")
    quake.set_model(self, "progs/flame.mdl")
    fire_ambient(self)
    quake.make_static(self)
end

--[[QUAKED light_flame_large_yellow (0 1 0) (-10 -10 -12) (12 12 18)
Large yellow flame ball
]]
function M.light_flame_large_yellow(self)
    quake.precache_model("progs/flame2.mdl")
    quake.set_model(self, "progs/flame2.mdl")
    self.frame = 1
    fire_ambient(self)
    quake.make_static(self)
end

--[[QUAKED light_flame_small_yellow (0 1 0) (-8 -8 -8) (8 8 8) START_OFF
Small yellow flame ball
]]
function M.light_flame_small_yellow(self)
    quake.precache_model("progs/flame2.mdl")
    quake.set_model(self, "progs/flame2.mdl")
    fire_ambient(self)
    quake.make_static(self)
end

--[[QUAKED light_flame_small_white (0 1 0) (-10 -10 -40) (10 10 40) START_OFF
Small white flame ball
]]
function M.light_flame_small_white(self)
    quake.precache_model("progs/flame2.mdl")
    quake.set_model(self, "progs/flame2.mdl")
    fire_ambient(self)
    quake.make_static(self)
end

--============================================================================

--[[QUAKED misc_fireball (0 .5 .8) (-8 -8 -8) (8 8 8)
Lava Balls
]]

local fire_fly, fire_touch

function M.misc_fireball(self)
    quake.precache_model("progs/lavaball.mdl")
    self.classname = "fireball"
    self.nextthink = quake.time() + quake.random() * 5
    self.think = fire_fly
    if self.speed == 0 then self.speed = 1000 end
end

fire_fly = function(self)
    local fireball = quake.spawn()
    fireball.solid = SOLID_TRIGGER
    fireball.movetype = MOVETYPE_TOSS
    fireball.velocity = quake.vec3(0, 0, 1000)
    fireball.velocity.x = quake.random() * 100 - 50
    fireball.velocity.y = quake.random() * 100 - 50
    fireball.velocity.z = self.speed + quake.random() * 200
    fireball.classname = "fireball"
    quake.set_model(fireball, "progs/lavaball.mdl")
    quake.set_size(fireball, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))
    quake.set_origin(fireball, self.origin)
    fireball.nextthink = quake.time() + 5
    fireball.think = subs.remove
    fireball.touch = fire_touch

    self.nextthink = quake.time() + quake.random() * 5 + 3
    self.think = fire_fly
end

fire_touch = function(self, other)
    combat.damage(other, self, self, 20)
    quake.remove(self)
end

--============================================================================

local function barrel_explode(self)
    self.takedamage = DAMAGE_NO
    self.classname = "explo_box"
    -- did say self.owner
    combat.radius_damage(self, self, 160, quake.world)
    quake.sound(self, CHAN_VOICE, "weapons/r_exp3.wav", 1, ATTN_NORM)
    quake.particle(self.origin, quake.vec3(0, 0, 0), 75, 255)
    self.origin = quake.vec3(self.origin.x, self.origin.y, self.origin.z + 32)
    weapons.become_explosion(self)
end

--[[QUAKED misc_explobox (0 .5 .8) (0 0 0) (32 32 64)
TESTING THING
]]
function M.misc_explobox(self)
    self.solid = SOLID_BBOX
    self.movetype = MOVETYPE_NONE
    quake.precache_model("maps/b_explob.bsp")
    quake.set_model(self, "maps/b_explob.bsp")
    quake.precache_sound("weapons/r_exp3.wav")
    self.health = 20
    self.th_die = barrel_explode
    self.takedamage = DAMAGE_AIM

    self.origin = quake.vec3(self.origin.x, self.origin.y, self.origin.z + 2)
    local oldz = self.origin.z
    quake.drop_to_floor(self)
    if oldz - self.origin.z > 250 then
        quake.dprint("item fell out of level at ")
        quake.dprint(quake.vector_to_string(self.origin))
        quake.dprint("\n")
        quake.remove(self)
    end
end

--[[QUAKED misc_explobox2 (0 .5 .8) (0 0 0) (32 32 64)
Smaller exploding box, REGISTERED ONLY
]]
function M.misc_explobox2(self)
    self.solid = SOLID_BBOX
    self.movetype = MOVETYPE_NONE
    quake.precache_model2("maps/b_exbox2.bsp")
    quake.set_model(self, "maps/b_exbox2.bsp")
    quake.precache_sound("weapons/r_exp3.wav")
    self.health = 20
    self.th_die = barrel_explode
    self.takedamage = DAMAGE_AIM

    self.origin = quake.vec3(self.origin.x, self.origin.y, self.origin.z + 2)
    local oldz = self.origin.z
    quake.drop_to_floor(self)
    if oldz - self.origin.z > 250 then
        quake.dprint("item fell out of level at ")
        quake.dprint(quake.vector_to_string(self.origin))
        quake.dprint("\n")
        quake.remove(self)
    end
end

--============================================================================

local SPAWNFLAG_SUPERSPIKE, SPAWNFLAG_LASER = 1, 2

local function spikeshooter_use(self, _activator)
    if (self.spawnflags & SPAWNFLAG_LASER) ~= 0 then
        quake.sound(self, CHAN_VOICE, "enforcer/enfire.wav", 1, ATTN_NORM)
        enforcer.launch_laser(self, self.origin, self.movedir)
    else
        quake.sound(self, CHAN_VOICE, "weapons/spike2.wav", 1, ATTN_NORM)
        weapons.launch_spike(self, self.origin, self.movedir)
        quake.globals.newmis.velocity = self.movedir * 500
        if (self.spawnflags & SPAWNFLAG_SUPERSPIKE) ~= 0 then
            quake.globals.newmis.touch = weapons.superspike_touch
        end
    end
end

local function shooter_think(self)
    spikeshooter_use(self)
    self.nextthink = quake.time() + self.wait
    quake.globals.newmis.velocity = self.movedir * 500
end

--[[QUAKED trap_spikeshooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser
When triggered, fires a spike in the direction set in QuakeEd.
Laser is only for REGISTERED.
]]
function M.trap_spikeshooter(self)
    subs.set_movedir(self)
    self.use = spikeshooter_use
    if (self.spawnflags & SPAWNFLAG_LASER) ~= 0 then
        quake.precache_model2("progs/laser.mdl")
        quake.precache_sound2("enforcer/enfire.wav")
        quake.precache_sound2("enforcer/enfstop.wav")
    else
        quake.precache_sound("weapons/spike2.wav")
    end
end

--[[QUAKED trap_shooter (0 .5 .8) (-8 -8 -8) (8 8 8) superspike laser
Continuously fires spikes.
"wait" time between spike (1.0 default)
"nextthink" delay before firing first spike, so multiple shooters can be stagered.
]]
function M.trap_shooter(self)
    M.trap_spikeshooter(self)
    if self.wait == 0 then self.wait = 1 end
    self.nextthink = self.nextthink + self.wait + self.ltime
    self.think = shooter_think
end

--[[
===============================================================================


===============================================================================
]]

local make_bubbles, bubble_remove, bubble_bob

--[[QUAKED air_bubbles (0 .5 .8) (-8 -8 -8) (8 8 8)

testing air bubbles
]]
function M.air_bubbles(self)
    if quake.cvar("deathmatch") ~= 0 then
        quake.remove(self)
        return
    end
    quake.precache_model("progs/s_bubble.spr")
    self.nextthink = quake.time() + 1
    self.think = make_bubbles
end

make_bubbles = function(self)
    local bubble = quake.spawn()
    quake.set_model(bubble, "progs/s_bubble.spr")
    quake.set_origin(bubble, self.origin)
    bubble.movetype = MOVETYPE_NOCLIP
    bubble.solid = SOLID_NOT
    bubble.velocity = quake.vec3(0, 0, 15)
    bubble.nextthink = quake.time() + 0.5
    bubble.think = bubble_bob
    bubble.touch = bubble_remove
    bubble.classname = "bubble"
    bubble.frame = 0
    bubble.cnt = 0
    quake.set_size(bubble, quake.vec3(-8, -8, -8), quake.vec3(8, 8, 8))
    self.nextthink = quake.time() + quake.random() + 0.5
    self.think = make_bubbles
end

local function bubble_split(self)
    local bubble = quake.spawn()
    quake.set_model(bubble, "progs/s_bubble.spr")
    quake.set_origin(bubble, self.origin)
    bubble.movetype = MOVETYPE_NOCLIP
    bubble.solid = SOLID_NOT
    bubble.velocity = self.velocity
    bubble.nextthink = quake.time() + 0.5
    bubble.think = bubble_bob
    bubble.touch = bubble_remove
    bubble.classname = "bubble"
    bubble.frame = 1
    bubble.cnt = 10
    quake.set_size(bubble, quake.vec3(-8, -8, -8), quake.vec3(8, 8, 8))
    self.frame = 1
    self.cnt = 10
    if self.waterlevel ~= 3 then quake.remove(self) end
end

bubble_remove = function(self, other)
    if other.classname == self.classname then return end
    quake.remove(self)
end

bubble_bob = function(self)
    self.cnt = self.cnt + 1
    if self.cnt == 4 then bubble_split(self) end
    if self.cnt == 20 then quake.remove(self) end

    local rnd1 = self.velocity.x + -10 + quake.random() * 20
    local rnd2 = self.velocity.y + -10 + quake.random() * 20
    local rnd3 = self.velocity.z + 10 + quake.random() * 10

    if rnd1 > 10 then rnd1 = 5 end
    if rnd1 < -10 then rnd1 = -5 end
    if rnd2 > 10 then rnd2 = 5 end
    if rnd2 < -10 then rnd2 = -5 end
    if rnd3 < 10 then rnd3 = 15 end
    if rnd3 > 30 then rnd3 = 25 end

    self.velocity = quake.vec3(rnd1, rnd2, rnd3)
    self.nextthink = quake.time() + 0.5
    self.think = bubble_bob
end

--[[QUAKED viewthing (0 .5 .8) (-8 -8 -8) (8 8 8)
Just for the debugging level. Don't use
]]
function M.viewthing(self)
    self.movetype = MOVETYPE_NONE
    self.solid = SOLID_NOT
    quake.precache_model("progs/player.mdl")
    quake.set_model(self, "progs/player.mdl")
end

--[[
==============================================================================

SIMPLE BMODELS

==============================================================================
]]

local function func_wall_use(self, _activator)
    -- change to alternate textures
    self.frame = 1 - self.frame
end

--[[QUAKED func_wall (0 .5 .8) ?
This is just a solid wall if not inhibitted
]]
function M.func_wall(self)
    self.angles = quake.vec3(0, 0, 0)
    self.movetype = MOVETYPE_PUSH -- so it doesn't get pushed by anything
    self.solid = SOLID_BSP
    self.use = func_wall_use
    quake.set_model(self, self.model)
end

--[[QUAKED func_illusionary (0 .5 .8) ?
A simple entity that looks solid but lets you walk through it.
]]
function M.func_illusionary(self)
    self.angles = quake.vec3(0, 0, 0)
    self.movetype = MOVETYPE_NONE
    self.solid = SOLID_NOT
    quake.set_model(self, self.model)
    quake.make_static(self)
end

--[[QUAKED func_episodegate (0 .5 .8) ? E1 E2 E3 E4
This bmodel will appear if the episode has allready been completed, so players can't reenter it.
]]
function M.func_episodegate(self)
    if (quake.globals.serverflags & self.spawnflags) == 0 then
        -- can still enter episode
        return
    end
    self.angles = quake.vec3(0, 0, 0)
    self.movetype = MOVETYPE_PUSH -- so it doesn't get pushed by anything
    self.solid = SOLID_BSP
    self.use = func_wall_use
    quake.set_model(self, self.model)
end

--[[QUAKED func_bossgate (0 .5 .8) ?
This bmodel appears unless players have all of the episode sigils.
]]
function M.func_bossgate(self)
    if (quake.globals.serverflags & 15) == 15 then
        -- all episodes completed
        return
    end
    self.angles = quake.vec3(0, 0, 0)
    self.movetype = MOVETYPE_PUSH -- so it doesn't get pushed by anything
    self.solid = SOLID_BSP
    self.use = func_wall_use
    quake.set_model(self, self.model)
end

--============================================================================

--[[QUAKED ambient_suck_wind (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
]]
function M.ambient_suck_wind(self)
    quake.precache_sound("ambience/suck1.wav")
    quake.ambient_sound(self.origin, "ambience/suck1.wav", 1, ATTN_STATIC)
end

--[[QUAKED ambient_drone (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
]]
function M.ambient_drone(self)
    quake.precache_sound("ambience/drone6.wav")
    quake.ambient_sound(self.origin, "ambience/drone6.wav", 0.5, ATTN_STATIC)
end

--[[QUAKED ambient_flouro_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
]]
function M.ambient_flouro_buzz(self)
    quake.precache_sound("ambience/buzz1.wav")
    quake.ambient_sound(self.origin, "ambience/buzz1.wav", 1, ATTN_STATIC)
end

--[[QUAKED ambient_drip (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
]]
function M.ambient_drip(self)
    quake.precache_sound("ambience/drip1.wav")
    quake.ambient_sound(self.origin, "ambience/drip1.wav", 0.5, ATTN_STATIC)
end

--[[QUAKED ambient_comp_hum (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
]]
function M.ambient_comp_hum(self)
    quake.precache_sound("ambience/comp1.wav")
    quake.ambient_sound(self.origin, "ambience/comp1.wav", 1, ATTN_STATIC)
end

--[[QUAKED ambient_thunder (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
]]
function M.ambient_thunder(self)
    quake.precache_sound("ambience/thunder1.wav")
    quake.ambient_sound(self.origin, "ambience/thunder1.wav", 0.5, ATTN_STATIC)
end

--[[QUAKED ambient_light_buzz (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
]]
function M.ambient_light_buzz(self)
    quake.precache_sound("ambience/fl_hum1.wav")
    quake.ambient_sound(self.origin, "ambience/fl_hum1.wav", 0.5, ATTN_STATIC)
end

--[[QUAKED ambient_swamp1 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
]]
function M.ambient_swamp1(self)
    quake.precache_sound("ambience/swamp1.wav")
    quake.ambient_sound(self.origin, "ambience/swamp1.wav", 0.5, ATTN_STATIC)
end

--[[QUAKED ambient_swamp2 (0.3 0.1 0.6) (-10 -10 -8) (10 10 8)
]]
function M.ambient_swamp2(self)
    quake.precache_sound("ambience/swamp2.wav")
    quake.ambient_sound(self.origin, "ambience/swamp2.wav", 0.5, ATTN_STATIC)
end

--============================================================================

local function noise_think(self)
    self.nextthink = quake.time() + 0.5
    quake.sound(self, 1, "enforcer/enfire.wav", 1, ATTN_NORM)
    quake.sound(self, 2, "enforcer/enfstop.wav", 1, ATTN_NORM)
    quake.sound(self, 3, "enforcer/sight1.wav", 1, ATTN_NORM)
    quake.sound(self, 4, "enforcer/sight2.wav", 1, ATTN_NORM)
    quake.sound(self, 5, "enforcer/sight3.wav", 1, ATTN_NORM)
    quake.sound(self, 6, "enforcer/sight4.wav", 1, ATTN_NORM)
    quake.sound(self, 7, "enforcer/pain1.wav", 1, ATTN_NORM)
end

--[[QUAKED misc_noisemaker (1 0.5 0) (-10 -10 -10) (10 10 10)

For optimzation testing, starts a lot of sounds.
]]
function M.misc_noisemaker(self)
    quake.precache_sound2("enforcer/enfire.wav")
    quake.precache_sound2("enforcer/enfstop.wav")
    quake.precache_sound2("enforcer/sight1.wav")
    quake.precache_sound2("enforcer/sight2.wav")
    quake.precache_sound2("enforcer/sight3.wav")
    quake.precache_sound2("enforcer/sight4.wav")
    quake.precache_sound2("enforcer/pain1.wav")
    quake.precache_sound2("enforcer/pain2.wav")
    quake.precache_sound2("enforcer/death1.wav")
    quake.precache_sound2("enforcer/idle1.wav")
    self.nextthink = quake.time() + 0.1 + quake.random()
    self.think = noise_think
end

quake.register_entity("info_null", M.info_null)
quake.register_entity("info_notnull", M.info_notnull)
quake.register_entity("light", M.light)
quake.register_entity("light_fluoro", M.light_fluoro)
quake.register_entity("light_fluorospark", M.light_fluorospark)
quake.register_entity("light_globe", M.light_globe)
quake.register_entity("light_torch_small_walltorch", M.light_torch_small_walltorch)
quake.register_entity("light_flame_large_yellow", M.light_flame_large_yellow)
quake.register_entity("light_flame_small_yellow", M.light_flame_small_yellow)
quake.register_entity("light_flame_small_white", M.light_flame_small_white)
quake.register_entity("misc_fireball", M.misc_fireball)
quake.register_entity("misc_explobox", M.misc_explobox)
quake.register_entity("misc_explobox2", M.misc_explobox2)
quake.register_entity("trap_spikeshooter", M.trap_spikeshooter)
quake.register_entity("trap_shooter", M.trap_shooter)
quake.register_entity("air_bubbles", M.air_bubbles)
quake.register_entity("viewthing", M.viewthing)
quake.register_entity("func_wall", M.func_wall)
quake.register_entity("func_illusionary", M.func_illusionary)
quake.register_entity("func_episodegate", M.func_episodegate)
quake.register_entity("func_bossgate", M.func_bossgate)
quake.register_entity("ambient_suck_wind", M.ambient_suck_wind)
quake.register_entity("ambient_drone", M.ambient_drone)
quake.register_entity("ambient_flouro_buzz", M.ambient_flouro_buzz)
quake.register_entity("ambient_drip", M.ambient_drip)
quake.register_entity("ambient_comp_hum", M.ambient_comp_hum)
quake.register_entity("ambient_thunder", M.ambient_thunder)
quake.register_entity("ambient_light_buzz", M.ambient_light_buzz)
quake.register_entity("ambient_swamp1", M.ambient_swamp1)
quake.register_entity("ambient_swamp2", M.ambient_swamp2)
quake.register_entity("misc_noisemaker", M.misc_noisemaker)

return M
