-- Derived from GPL-licensed Quake game code in CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local C = require("game.constants")
local ai = require("game.ai")
local monsters = require("game.monsters")
local subs = require("game.subs")

local M = {}

function M.killed(target, attacker)
    if target.health < -99 then
        target.health = -99
    end

    if target.movetype == C.MOVETYPE_PUSH or target.movetype == C.MOVETYPE_NONE then
        target.th_die(target)
        return
    end

    target.enemy = attacker
    if (target.flags & C.FL_MONSTER) ~= 0 then
        quake.globals.killed_monsters = (quake.globals.killed_monsters or 0) + 1
        quake.write_byte(C.MSG_ALL, C.SVC_KILLEDMONSTER)
    end

    quake.client_obituary(target, attacker)
    target.takedamage = C.DAMAGE_NO
    target.touch = subs.null

    monsters.death_use(target)
    target.th_die(target)
end

function M.damage(target, inflictor, attacker, damage)
    if not target.takedamage or target.takedamage == C.DAMAGE_NO then
        return
    end

    quake.globals.damage_attacker = attacker
    quake.globals.damage_inflictor = inflictor

    if attacker.super_damage_finished and attacker.super_damage_finished > quake.time() then
        damage = damage * 4
    end

    local saved = math.ceil((target.armortype or 0) * damage)
    if saved >= (target.armorvalue or 0) then
        saved = target.armorvalue or 0
        target.armortype = 0
        target.items = target.items & ~(C.IT_ARMOR1 | C.IT_ARMOR2 | C.IT_ARMOR3)
    end

    target.armorvalue = (target.armorvalue or 0) - saved
    local taken = math.ceil(damage - saved)

    if (target.flags & C.FL_CLIENT) ~= 0 then
        target.dmg_take = (target.dmg_take or 0) + taken
        target.dmg_save = (target.dmg_save or 0) + saved
        target.dmg_inflictor = inflictor
    end

    if inflictor ~= quake.world and target.movetype == C.MOVETYPE_WALK then
        local direction = (target.origin - (inflictor.absmin + inflictor.absmax) * 0.5):normalized()
        target.velocity = target.velocity + direction * damage * 8
    end

    if (target.flags & C.FL_GODMODE) ~= 0 then
        return
    end
    if (target.invincible_finished or 0) >= quake.time() then
        if (target.invincible_sound or 0) < quake.time() then
            quake.sound(target, C.CHAN_ITEM, "items/protect3.wav", 1, C.ATTN_NORM)
            target.invincible_sound = quake.time() + 2
        end
        return
    end

    if quake.cvar("teamplay") == 1
        and target.team > 0
        and target.team == attacker.team then
        return
    end

    target.health = target.health - taken
    if target.health <= 0 then
        M.killed(target, attacker)
        return
    end

    if (target.flags & C.FL_MONSTER) ~= 0 and attacker ~= quake.world then
        if target ~= attacker and attacker ~= target.enemy then
            if target.classname ~= attacker.classname or target.classname == "monster_army" then
                if target.enemy and target.enemy.classname == "player" then
                    target.oldenemy = target.enemy
                end
                target.enemy = attacker
                ai.found_target(target)
            end
        end
    end

    if target.th_pain then
        target.th_pain(target, attacker, taken)
        if quake.cvar("skill") == 3 then
            target.pain_finished = quake.time() + 5
        end
    end
end

return M
