-- Port of combat.qc from GPL-licensed CleanFixedQuakeC.
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
local ai = require("game.ai")
local monsters = require("game.monsters")
local subs = require("game.subs")

local M = {}

--============================================================================

--[[
============
CanDamage

Returns true if the inflictor can directly damage the target.  Used for
explosions and melee attacks.
============
]]
function M.can_damage(targ, inflictor)
    -- bmodels need special checking because their origin is 0,0,0
    if targ.movetype == C.MOVETYPE_PUSH then
        local trace = quake.trace_line(inflictor.origin, (targ.absmin + targ.absmax) * 0.5, true, inflictor)
        if trace.fraction == 1 then
            return true
        end
        if trace.entity == targ then
            return true
        end
        return false
    end

    local trace = quake.trace_line(inflictor.origin, targ.origin, true, inflictor)
    if trace.fraction == 1 then
        return true
    end
    trace = quake.trace_line(inflictor.origin, targ.origin + quake.vec3(15, 15, 0), true, inflictor)
    if trace.fraction == 1 then
        return true
    end
    trace = quake.trace_line(inflictor.origin, targ.origin + quake.vec3(-15, -15, 0), true, inflictor)
    if trace.fraction == 1 then
        return true
    end
    trace = quake.trace_line(inflictor.origin, targ.origin + quake.vec3(-15, 15, 0), true, inflictor)
    if trace.fraction == 1 then
        return true
    end
    trace = quake.trace_line(inflictor.origin, targ.origin + quake.vec3(15, -15, 0), true, inflictor)
    if trace.fraction == 1 then
        return true
    end

    return false
end

--[[
============
Killed
============
]]
function M.killed(targ, attacker)
    if targ.health < -99 then
        -- don't let sbar look bad if a player
        targ.health = -99
    end

    if targ.movetype == C.MOVETYPE_PUSH or targ.movetype == C.MOVETYPE_NONE then
        -- doors, triggers, etc
        targ.th_die(targ)
        return
    end

    targ.enemy = attacker

    -- bump the monster counter
    if (targ.flags & C.FL_MONSTER) ~= 0 then
        quake.globals.killed_monsters = quake.globals.killed_monsters + 1
        quake.write_byte(C.MSG_ALL, C.SVC_KILLEDMONSTER)
    end

    quake.client_obituary(targ, attacker)

    targ.takedamage = C.DAMAGE_NO
    targ.touch = subs.null

    monsters.death_use(targ)
    targ.th_die(targ)
end

--[[
============
T_Damage

The damage is coming from inflictor, but get mad at attacker
This should be the only function that ever reduces health.
============
]]
function M.damage(targ, inflictor, attacker, damage)
    if targ.takedamage == 0 then
        return
    end

    -- used by buttons and triggers to set activator for target firing
    quake.globals.damage_attacker = attacker
    -- keep track of the source of damage, used in gibs
    quake.globals.damage_inflictor = inflictor

    -- check for quad damage powerup on the attacker
    if attacker.super_damage_finished > quake.time() then
        damage = damage * 4
    end

    -- save damage based on the target's armor level
    local save = math.ceil(targ.armortype * damage)
    if save >= targ.armorvalue then
        save = targ.armorvalue
        targ.armortype = 0 -- lost all armor
        targ.items = targ.items - (targ.items & (C.IT_ARMOR1 | C.IT_ARMOR2 | C.IT_ARMOR3))
    end

    targ.armorvalue = targ.armorvalue - save
    local take = math.ceil(damage - save)

    -- add to the damage total for clients, which will be sent as a single
    -- message at the end of the frame
    -- FIXME: remove after combining shotgun blasts?
    if (targ.flags & C.FL_CLIENT) ~= 0 then
        targ.dmg_take = targ.dmg_take + take
        targ.dmg_save = targ.dmg_save + save
        targ.dmg_inflictor = inflictor
    end

    -- figure momentum add
    if inflictor ~= quake.world and targ.movetype == C.MOVETYPE_WALK then
        local dir = targ.origin - (inflictor.absmin + inflictor.absmax) * 0.5
        dir = dir:normalized()
        targ.velocity = targ.velocity + dir * damage * 8
    end

    -- check for godmode or invincibility
    if (targ.flags & C.FL_GODMODE) ~= 0 then
        return
    end
    if targ.invincible_finished >= quake.time() then
        if targ.invincible_sound < quake.time() then
            quake.sound(targ, C.CHAN_ITEM, "items/protect3.wav", 1, C.ATTN_NORM)
            targ.invincible_sound = quake.time() + 2
        end
        return
    end

    -- team play damage avoidance
    if quake.cvar("teamplay") == 1 and targ.team > 0 and targ.team == attacker.team then
        return
    end

    -- do the damage
    targ.health = targ.health - take

    if targ.health <= 0 then
        M.killed(targ, attacker)
        return
    end

    -- react to the damage
    if (targ.flags & C.FL_MONSTER) ~= 0 and attacker ~= quake.world then
        -- get mad unless of the same class (except for soldiers)
        if targ ~= attacker and attacker ~= targ.enemy then
            if targ.classname ~= attacker.classname or targ.classname == "monster_army" then
                if targ.enemy and targ.enemy.classname == "player" then
                    targ.oldenemy = targ.enemy
                end
                targ.enemy = attacker
                ai.found_target(targ)
            end
        end
    end

    if targ.th_pain then
        targ.th_pain(targ, attacker, take)
        -- nightmare mode monsters don't go into pain frames often
        if quake.cvar("skill") == 3 then
            targ.pain_finished = quake.time() + 5
        end
    end
end

--[[
============
T_RadiusDamage
============
]]
function M.radius_damage(inflictor, attacker, damage, ignore)
    local head = quake.find_radius(inflictor.origin, damage + 40)

    while head do
        if head ~= ignore then
            if head.takedamage ~= 0 then
                local org = head.origin + (head.mins + head.maxs) * 0.5
                local points = 0.5 * (inflictor.origin - org):length()
                if points < 0 then
                    points = 0
                end
                points = damage - points
                if head == attacker then
                    points = points * 0.5
                end
                if points > 0 then
                    if M.can_damage(head, inflictor) then
                        -- shambler takes half damage from all explosions
                        if head.classname == "monster_shambler" then
                            M.damage(head, inflictor, attacker, points * 0.5)
                        else
                            M.damage(head, inflictor, attacker, points)
                        end
                    end
                end
            end
        end
        head = head.chain
    end
end

--[[
============
T_BeamDamage
============
]]
function M.beam_damage(attacker, damage)
    local head = quake.find_radius(attacker.origin, damage + 40)

    while head do
        if head.takedamage ~= 0 then
            local points = 0.5 * (attacker.origin - head.origin):length()
            if points < 0 then
                points = 0
            end
            points = damage - points
            if head == attacker then
                points = points * 0.5
            end
            if points > 0 then
                if M.can_damage(head, attacker) then
                    if head.classname == "monster_shambler" then
                        M.damage(head, attacker, attacker, points * 0.5)
                    else
                        M.damage(head, attacker, attacker, points)
                    end
                end
            end
        end
        head = head.chain
    end
end

return M
