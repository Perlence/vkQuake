-- Copyright (C) 1996-1997  Id Software, Inc.
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 2 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
--
-- See file, 'COPYING', for details.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")

local M = {}

--[[
==============================================================================

            SOURCE FOR GLOBALVARS_T C STRUCTURE

==============================================================================
]]

--
-- system globals
--
-- `self` and `other` are passed explicitly to Lua callbacks. `world` and
-- `time` are exposed as `quake.world` and `quake.time()`.
---@class quake_globals
---@field self entity
---@field other entity
---@field world entity
---@field time number
---@field frametime number
---@field force_retouch number force all entities to touch triggers
---next frame.  this is needed because
---non-moving things don't normally scan
---for triggers, and when a trigger is
---created (like a teleport trigger), it
---needs to catch everything.
---decremented each frame, so set to 2
---to guarantee everything is touched
---@field mapname string
---@field deathmatch number
---@field coop number
---@field teamplay number
---@field serverflags number propagated from level to level, used to
---keep track of completed episodes
---@field total_secrets number
---@field total_monsters number
---@field found_secrets number number of secrets found
---@field killed_monsters number number of monsters killed
--
-- spawnparms are used to encode information about clients across server
-- level changes
---@field parm1 number
---@field parm2 number
---@field parm3 number
---@field parm4 number
---@field parm5 number
---@field parm6 number
---@field parm7 number
---@field parm8 number
---@field parm9 number
---@field parm10 number
---@field parm11 number
---@field parm12 number
---@field parm13 number
---@field parm14 number
---@field parm15 number
---@field parm16 number
--
-- global variables set by built in functions
--
---@field v_forward vec3 set by makevectors()
---@field v_up vec3 set by makevectors()
---@field v_right vec3 set by makevectors()
-- set by traceline / tracebox
---@field trace_allsolid number
---@field trace_startsolid number
---@field trace_fraction number
---@field trace_endpos vec3
---@field trace_plane_normal vec3
---@field trace_plane_dist number
---@field trace_ent entity
---@field trace_inopen number
---@field trace_inwater number
---@field msg_entity entity destination of single entity writes
--
-- required prog functions
--
---@field main fun() only for testing
---@field StartFrame fun()
---@field PlayerPreThink fun(self: entity)
---@field PlayerPostThink fun(self: entity)
---@field ClientKill fun(self: entity)
---@field ClientConnect fun(self: entity)
---@field PutClientInServer fun(self: entity) call after setting the parm1... parms
---@field ClientDisconnect fun(self: entity)
---@field SetNewParms fun(self: entity) called when a client first connects to
---a server. sets parms so they can be
---saved off for restarts
---@field SetChangeParms fun(self: entity) call to set parms for self so they can
---be saved for a level transition

--================================================
-- void end_sys_globals; -- flag for structure dumping
--================================================

--[[
==============================================================================

            SOURCE FOR ENTVARS_T C STRUCTURE

==============================================================================
]]

--
-- system fields (*** = do not set in prog code, maintained by C code)
--
---@class entity
---@field modelindex number *** model index in the precached list
---@field absmin vec3 *** origin + mins / maxs
---@field absmax vec3 *** origin + mins / maxs
---@field ltime number local time for entity
---@field movetype number
---@field solid number
---@field origin vec3 ***
---@field oldorigin vec3 ***
---@field velocity vec3
---@field angles vec3
---@field avelocity vec3
---@field punchangle vec3 temp angle adjust from damage or recoil
---@field classname string spawn function
---@field model string
---@field frame number|string
---@field skin number
---@field effects number
---@field mins vec3 bounding box extents reletive to origin
---@field maxs vec3 bounding box extents reletive to origin
---@field size vec3 maxs - mins
---@field touch fun(self: entity, other: entity)
---@field use fun(self: entity, activator: entity)
---@field think fun(self: entity)
---@field blocked fun(self: entity, other: entity) for doors or plats, called when can't push other
---@field nextthink number
---@field groundentity entity
-- stats
---@field health number
---@field frags number
---@field weapon number one of the IT_SHOTGUN, etc flags
---@field weaponmodel string
---@field weaponframe number
---@field currentammo number
---@field ammo_shells number
---@field ammo_nails number
---@field ammo_rockets number
---@field ammo_cells number
---@field items number bit flags
---@field takedamage number
---@field chain entity
---@field deadflag number
---@field view_ofs vec3 add to origin to get eye point
---@field button0 number fire
---@field button1 number use
---@field button2 number jump
---@field impulse number weapon changes
---@field fixangle number
---@field v_angle vec3 view / targeting angle for players
---@field idealpitch number calculated pitch angle for lookup up slopes
---@field netname string
---@field enemy entity
---@field flags number
---@field colormap number
---@field team number
---@field max_health number players maximum health is stored here
---@field teleport_time number don't back up
---@field armortype number save this fraction of incoming damage
---@field armorvalue number
---@field waterlevel number 0 = not in, 1 = feet, 2 = waist, 3 = eyes
---@field watertype number a contents value
---@field ideal_yaw number
---@field yaw_speed number
---@field aiment entity
---@field goalentity entity a movetarget or an enemy
---@field spawnflags number
---@field target string
---@field targetname string
-- damage is accumulated through a frame. and sent as one single
-- message, so the super shotgun doesn't generate huge messages
---@field dmg_take number
---@field dmg_save number
---@field dmg_inflictor entity
---@field owner entity who launched a missile
---@field movedir vec3 mostly for doors, but also used for waterjump
---@field message string trigger messages
---@field sounds number either a cd track number or sound number
---@field noise string contains names of wavs to play
---@field noise1 string contains names of wavs to play
---@field noise2 string contains names of wavs to play
---@field noise3 string contains names of wavs to play

--================================================
-- void end_sys_fields; -- flag for structure dumping
--================================================

--[[
==============================================================================

                VARS NOT REFERENCED BY C CODE

==============================================================================
]]

--
-- constants
--
M.FALSE = 0
M.TRUE = 1

-- edict.flags
M.FL_FLY = 1
M.FL_SWIM = 2
M.FL_CLIENT = 8 -- set for all client edicts
M.FL_INWATER = 16 -- for enter / leave water splash
M.FL_MONSTER = 32
M.FL_GODMODE = 64 -- player cheat
M.FL_NOTARGET = 128 -- player cheat
M.FL_ITEM = 256 -- extra wide size for bonus items
M.FL_ONGROUND = 512 -- standing on something
M.FL_PARTIALGROUND = 1024 -- not all corners are valid
M.FL_WATERJUMP = 2048 -- player jumping out of water
M.FL_JUMPRELEASED = 4096 -- for jump debouncing

-- edict.movetype values
M.MOVETYPE_NONE = 0 -- never moves
-- float MOVETYPE_ANGLENOCLIP = 1;
-- float MOVETYPE_ANGLECLIP = 2;
M.MOVETYPE_WALK = 3 -- players only
M.MOVETYPE_STEP = 4 -- discrete, not real time unless fall
M.MOVETYPE_FLY = 5
M.MOVETYPE_TOSS = 6 -- gravity
M.MOVETYPE_PUSH = 7 -- no clip to world, push and crush
M.MOVETYPE_NOCLIP = 8
M.MOVETYPE_FLYMISSILE = 9 -- fly with extra size against monsters
M.MOVETYPE_BOUNCE = 10
M.MOVETYPE_BOUNCEMISSILE = 11 -- bounce with extra size

-- edict.solid values
M.SOLID_NOT = 0 -- no interaction with other objects
M.SOLID_TRIGGER = 1 -- touch on edge, but not blocking
M.SOLID_BBOX = 2 -- touch on edge, block
M.SOLID_SLIDEBOX = 3 -- touch on edge, but not an onground
M.SOLID_BSP = 4 -- bsp clip, touch on edge, block

-- range values
M.RANGE_MELEE = 0
M.RANGE_NEAR = 1
M.RANGE_MID = 2
M.RANGE_FAR = 3

-- deadflag values
M.DEAD_NO = 0
M.DEAD_DYING = 1
M.DEAD_DEAD = 2
M.DEAD_RESPAWNABLE = 3

-- takedamage values
M.DAMAGE_NO = 0
M.DAMAGE_YES = 1
M.DAMAGE_AIM = 2

-- items
M.IT_AXE = 4096
M.IT_SHOTGUN = 1
M.IT_SUPER_SHOTGUN = 2
M.IT_NAILGUN = 4
M.IT_SUPER_NAILGUN = 8
M.IT_GRENADE_LAUNCHER = 16
M.IT_ROCKET_LAUNCHER = 32
M.IT_LIGHTNING = 64
M.IT_EXTRA_WEAPON = 128
M.IT_SHELLS = 256
M.IT_NAILS = 512
M.IT_ROCKETS = 1024
M.IT_CELLS = 2048
M.IT_ARMOR1 = 8192
M.IT_ARMOR2 = 16384
M.IT_ARMOR3 = 32768
M.IT_SUPERHEALTH = 65536
M.IT_KEY1 = 131072
M.IT_KEY2 = 262144
M.IT_INVISIBILITY = 524288
M.IT_INVULNERABILITY = 1048576
M.IT_SUIT = 2097152
M.IT_QUAD = 4194304

-- point content values
M.CONTENT_EMPTY = -1
M.CONTENT_SOLID = -2
M.CONTENT_WATER = -3
M.CONTENT_SLIME = -4
M.CONTENT_LAVA = -5
M.CONTENT_SKY = -6

M.STATE_TOP = 0
M.STATE_BOTTOM = 1
M.STATE_UP = 2
M.STATE_DOWN = 3

M.VEC_ORIGIN = quake.vec3(0, 0, 0)
M.VEC_HULL_MIN = quake.vec3(-16, -16, -24)
M.VEC_HULL_MAX = quake.vec3(16, 16, 32)
M.VEC_HULL2_MIN = quake.vec3(-32, -32, -24)
M.VEC_HULL2_MAX = quake.vec3(32, 32, 64)

-- protocol bytes
M.SVC_TEMPENTITY = 23
M.SVC_KILLEDMONSTER = 27
M.SVC_FOUNDSECRET = 28
M.SVC_INTERMISSION = 30
M.SVC_FINALE = 31
M.SVC_CDTRACK = 32
M.SVC_SELLSCREEN = 33

M.TE_SPIKE = 0
M.TE_SUPERSPIKE = 1
M.TE_GUNSHOT = 2
M.TE_EXPLOSION = 3
M.TE_TAREXPLOSION = 4
M.TE_LIGHTNING1 = 5
M.TE_LIGHTNING2 = 6
M.TE_WIZSPIKE = 7
M.TE_KNIGHTSPIKE = 8
M.TE_LIGHTNING3 = 9
M.TE_LAVASPLASH = 10
M.TE_TELEPORT = 11

-- sound channels
-- channel 0 never willingly overrides
-- other channels (1-7) always override a playing sound on that channel
M.CHAN_AUTO = 0
M.CHAN_WEAPON = 1
M.CHAN_VOICE = 2
M.CHAN_ITEM = 3
M.CHAN_BODY = 4

M.ATTN_NONE = 0
M.ATTN_NORM = 1
M.ATTN_IDLE = 2
M.ATTN_STATIC = 3

-- update types
M.UPDATE_GENERAL = 0
M.UPDATE_STATIC = 1
M.UPDATE_BINARY = 2
M.UPDATE_TEMP = 3

-- entity effects
M.EF_BRIGHTFIELD = 1
M.EF_MUZZLEFLASH = 2
M.EF_BRIGHTLIGHT = 4
M.EF_DIMLIGHT = 8

-- messages
M.MSG_BROADCAST = 0 -- unreliable to all
M.MSG_ONE = 1 -- reliable to one (msg_entity)
M.MSG_ALL = 2 -- reliable to all
M.MSG_INIT = 3 -- write to the init string

--================================================

--
-- globals
--
-- Shared mutable QuakeC globals live in the engine-owned table so every
-- translated module observes the same values and their QuakeC zero defaults.
---@class quake_globals
---@field movedist number
---@field gameover number set when a rule exits
-- evaluates as FALSE (like NULL or 0) but treated like "" (empty string)
---@field string_null string null string, nothing should be held here
---@field newmis entity launch_spike sets this after spawning it
---@field activator entity the entity that activated a trigger or brush
---@field damage_attacker entity set by T_Damage
---@field damage_inflictor entity track source of damage for throwing gibs
---@field framecount number
---@field skill number
M.globals = quake.globals

--================================================

--
-- world fields (FIXME: make globals)
--
---@class entity
---@field wad string
---@field map string
---@field worldtype number 0=medieval 1=metal 2=base
---@field killtarget string
--
-- quakeed fields
--
---@field light_lev number not used by game, but parsed by light util
---@field style number

--
-- monster ai
--
---@field th_stand fun(self: entity)
---@field th_walk fun(self: entity)
---@field th_run fun(self: entity)
---@field th_missile fun(self: entity)
---@field th_melee fun(self: entity)
---@field th_pain fun(self: entity, attacker: entity, damage: number)
---@field th_die fun(self: entity)
---@field oldenemy entity mad at this player before taking damage
---@field speed number
---@field lefty number
---@field search_time number
---@field attack_state number

M.AS_STRAIGHT = 1
M.AS_SLIDING = 2
M.AS_MELEE = 3
M.AS_MISSILE = 4

--
-- player only fields
--
---@field walkframe number
---@field attack_finished number
---@field pain_finished number
---@field invincible_finished number
---@field invisible_finished number
---@field super_damage_finished number
---@field radsuit_finished number
---@field invincible_time number
---@field invincible_sound number
---@field invisible_time number
---@field invisible_sound number
---@field super_time number
---@field super_sound number
---@field rad_time number
---@field fly_sound number
---@field axhitme number
---@field show_hostile number set to time+0.2 whenever a client fires a
---weapon or takes damage.  Used to alert
---monsters that otherwise would let the player go
---@field jump_flag number player jump flag
---@field swim_flag number player swimming sound flag
---@field air_finished number when time > air_finished, start drowning
---@field bubble_count number keeps track of the number of bubbles
---@field deathtype string keeps track of how the player died

--
-- object stuff
--
---@field mdl string
---@field mangle vec3 angle at start
---@field oldorigin vec3 only used by secret door
---@field t_length number
---@field t_width number

--
-- doors, etc
--
---@field dest vec3
---@field dest1 vec3
---@field dest2 vec3
---@field wait number time from firing to restarting
---@field delay number time from activation to firing
---@field trigger_field entity door's trigger entity
---@field noise4 string

--
-- monsters
--
---@field pausetime number
---@field movetarget entity

--
-- doors
--
---@field aflag number
---@field dmg number damage done by door when hit

--
-- misc
--
---@field cnt number misc flag

--
-- subs
--
---@field think1 fun(self: entity)
---@field finaldest vec3
---@field finalangle vec3

--
-- triggers
--
---@field count number for counting triggers

--
-- plats / doors / buttons
--
---@field lip number
---@field state number
---@field pos1 vec3 top and bottom positions
---@field pos2 vec3 top and bottom positions
---@field height number

--
-- sounds
--
---@field waitmin number
---@field waitmax number
---@field distance number
---@field volume number

--===========================================================================

--
-- builtin functions
--
-- The declarations below document the corresponding engine binding. Lua ports
-- call the snake_case members of `quake` directly.
-- makevectors(vector ang) = #1; -- sets v_forward, etc globals
-- setorigin(entity e, vector o) = #2;
-- setmodel(entity e, string m) = #3; -- set movetype and solid first
-- setsize(entity e, vector min, vector max) = #4;
-- #5 was removed
-- break() = #6;
-- random() = #7; -- returns 0 - 1
-- sound(entity e, float chan, string samp, float vol, float atten) = #8;
-- normalize(vector v) = #9;
-- error(string e) = #10;
-- objerror(string e) = #11;
-- vlen(vector v) = #12;
-- vectoyaw(vector v) = #13;
-- spawn() = #14;
-- remove(entity e) = #15;

-- sets trace_* globals
-- nomonsters can be:
-- An entity will also be ignored for testing if forent == test,
-- forent->owner == test, or test->owner == forent
-- a forent of world is ignored
-- traceline(vector v1, vector v2, float nomonsters, entity forent) = #16;

-- checkclient() = #17; -- returns a client to look for
-- find(entity start, .string fld, string match) = #18;
-- precache_sound(string s) = #19;
-- precache_model(string s) = #20;
-- stuffcmd(entity client, string s) = #21;
-- findradius(vector org, float rad) = #22;
-- bprint(string s) = #23;
-- sprint(entity client, string s) = #24;
-- dprint(string s) = #25;
-- ftos(float f) = #26;
-- vtos(vector v) = #27;
-- coredump() = #28; -- prints all edicts
-- traceon() = #29; -- turns statment trace on
-- traceoff() = #30;
-- eprint(entity e) = #31; -- prints an entire edict
-- walkmove(float yaw, float dist) = #32; -- returns TRUE or FALSE
-- #33 was removed
-- droptofloor() = #34; -- TRUE if landed on floor
-- lightstyle(float style, string value) = #35;
-- rint(float v) = #36; -- round to nearest int
-- floor(float v) = #37; -- largest integer <= v
-- ceil(float v) = #38; -- smallest integer >= v
-- #39 was removed
-- checkbottom(entity e) = #40; -- true if self is on ground
-- pointcontents(vector v) = #41; -- returns a CONTENT_*
-- #42 was removed
-- fabs(float f) = #43;
-- aim(entity e, float speed) = #44; -- returns the shooting vector
-- cvar(string s) = #45; -- return cvar.value
-- localcmd(string s) = #46; -- put string into local que
-- nextent(entity e) = #47; -- for looping through all ents
-- particle(vector o, vector d, float color, float count) = #48; -- start a particle effect
-- ChangeYaw() = #49; -- turn towards self.ideal_yaw
--                         at self.yaw_speed
-- #50 was removed
-- vectoangles(vector v) = #51;

--
-- direct client message generation
--
-- WriteByte(float to, float f) = #52;
-- WriteChar(float to, float f) = #53;
-- WriteShort(float to, float f) = #54;
-- WriteLong(float to, float f) = #55;
-- WriteCoord(float to, float f) = #56;
-- WriteAngle(float to, float f) = #57;
-- WriteString(float to, string s) = #58;
-- WriteEntity(float to, entity s) = #59;

--
-- broadcast client message generation
--
-- void(float f) bWriteByte = #59;
-- void(float f) bWriteChar = #60;
-- void(float f) bWriteShort = #61;
-- void(float f) bWriteLong = #62;
-- void(float f) bWriteCoord = #63;
-- void(float f) bWriteAngle = #64;
-- void(string s) bWriteString = #65;
-- void(entity e) bWriteEntity = #66;

-- movetogoal(float step) = #67;
-- precache_file(string s) = #68; -- no effect except for -copy
-- makestatic(entity e) = #69;
-- changelevel(string s) = #70;
-- #71 was removed
-- cvar_set(string var, string val) = #72; -- sets cvar.value
-- centerprint(entity client, string s) = #73; -- sprint, but in middle
-- ambientsound(vector pos, string samp, float vol, float atten) = #74;
-- precache_model2(string s) = #75; -- registered version only
-- precache_sound2(string s) = #76; -- registered version only
-- precache_file2(string s) = #77; -- registered version only
-- setspawnparms(entity e) = #78; -- set parm1... to the
--                                 values at level start
--                                 for coop respawn

--============================================================================

--
-- subs.qc
--
-- SUB_CalcMove(vector tdest, float tspeed, void() func);
-- SUB_CalcMoveEnt(entity ent, vector tdest, float tspeed, void() func);
-- SUB_CalcAngleMove(vector destangle, float tspeed, void() func);
-- SUB_CalcMoveDone();
-- SUB_CalcAngleMoveDone();
-- SUB_Null();
-- SUB_UseTargets();
-- SUB_Remove();

--
-- combat.qc
--
-- T_Damage(entity targ, entity inflictor, entity attacker, float damage);
-- T_Heal(entity e, float healamount, float ignore); -- health function
-- CanDamage(entity targ, entity inflictor);

return M
