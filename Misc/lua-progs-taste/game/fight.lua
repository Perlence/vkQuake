-- Port of fight.qc from GPL-licensed CleanFixedQuakeC.
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
local subs = require("game.subs")

local M = {}

--[[
A monster is in fight mode if it thinks it can effectively attack its
enemy.

When it decides it can't attack, it goes into hunt mode.
]]

function M.knight_attack(self)
    -- decide if now is a good swing time
    local len = (self.enemy.origin + self.enemy.view_ofs - (self.origin + self.view_ofs)):length()

    local knight = require("game.knight")
    if len < 80 then
        knight.atk1(self)
    else
        knight.runatk1(self)
    end
end

--=============================================================================

--[[
===========
CheckAttack

The player is in view, so decide to move or launch an attack
Returns FALSE if movement should continue
============
]]
function M.check_attack(self, enemy_range)
    local targ = self.enemy

    -- see if any entities are in the way of the shot
    local spot1 = self.origin + self.view_ofs
    local spot2 = targ.origin + targ.view_ofs

    local trace = quake.trace_line(spot1, spot2, false, self)

    if trace.entity ~= targ then
        return false -- don't have a clear shot
    end

    if trace.in_open and trace.in_water then
        return false -- sight line crossed contents
    end

    if enemy_range == C.RANGE_MELEE then
        -- melee attack
        if self.th_melee then
            if self.classname == "monster_knight" then
                M.knight_attack(self)
            else
                self.th_melee(self)
            end
            return true
        end
    end

    -- missile attack
    if not self.th_missile then
        return false
    end

    if quake.time() < self.attack_finished then
        return false
    end

    if enemy_range == C.RANGE_FAR then
        return false
    end

    local chance
    if enemy_range == C.RANGE_MELEE then
        chance = 0.9
        self.attack_finished = 0
    elseif enemy_range == C.RANGE_NEAR then
        if self.th_melee then
            chance = 0.2
        else
            chance = 0.4
        end
    elseif enemy_range == C.RANGE_MID then
        if self.th_melee then
            chance = 0.05
        else
            chance = 0.1
        end
    else
        chance = 0
    end

    if quake.random() < chance then
        self.th_missile(self)
        subs.attack_finished(self, 2 * quake.random())
        return true
    end

    return false
end

--[[
=============
ai_face

Stay facing the enemy
=============
]]
function M.face(self)
    self.ideal_yaw = quake.vector_to_yaw(self.enemy.origin - self.origin)
    quake.change_yaw(self)
end

--[[
=============
ai_charge

The monster is in a melee attack, so get as close as possible to .enemy
=============
]]
function M.charge(self, distance)
    M.face(self)
    -- done in C code...
    quake.move_to_goal(self, distance)
end

function M.charge_side(self)
    -- aim to the left of the enemy for a flyby

    self.ideal_yaw = quake.vector_to_yaw(self.enemy.origin - self.origin)
    quake.change_yaw(self)

    local right = quake.make_vectors(self.angles).right
    local dtemp = self.enemy.origin - right * 30
    local heading = quake.vector_to_yaw(dtemp - self.origin)

    quake.walk_move(self, heading, 20)
end

--[[
=============
ai_melee

=============
]]
function M.melee(self)
    if not self.enemy then
        -- removed before stroke
        return
    end

    local delta = self.enemy.origin - self.origin

    if delta:length() > 60 then
        return
    end

    local ldmg = (quake.random() + quake.random() + quake.random()) * 3
    require("game.combat").damage(self.enemy, self, self, ldmg)
end

function M.melee_side(self)
    if not self.enemy then
        return -- removed before stroke
    end

    M.charge_side(self)

    local delta = self.enemy.origin - self.origin

    if delta:length() > 60 then
        return
    end
    local combat = require("game.combat")
    if not combat.can_damage(self.enemy, self) then
        return
    end
    local ldmg = (quake.random() + quake.random() + quake.random()) * 3
    combat.damage(self.enemy, self, self, ldmg)
end

--=============================================================================

--[[
===========
SoldierCheckAttack

The player is in view, so decide to move or launch an attack
Returns FALSE if movement should continue
============
]]
function M.soldier_check_attack(self, enemy_range)
    local targ = self.enemy

    -- see if any entities are in the way of the shot
    local spot1 = self.origin + self.view_ofs
    local spot2 = targ.origin + targ.view_ofs

    local trace = quake.trace_line(spot1, spot2, false, self)

    if trace.in_open and trace.in_water then
        return false -- sight line crossed contents
    end

    if trace.entity ~= targ then
        return false -- don't have a clear shot
    end

    -- missile attack
    if quake.time() < self.attack_finished then
        return false
    end

    if enemy_range == C.RANGE_FAR then
        return false
    end

    local chance
    if enemy_range == C.RANGE_MELEE then
        chance = 0.9
    elseif enemy_range == C.RANGE_NEAR then
        chance = 0.4
    elseif enemy_range == C.RANGE_MID then
        chance = 0.05
    else
        chance = 0
    end

    if quake.random() < chance then
        self.th_missile(self)
        subs.attack_finished(self, 1 + quake.random())
        if quake.random() < 0.3 then
            self.lefty = 1 - self.lefty
        end

        return true
    end

    return false
end
--=============================================================================

--[[
===========
ShamCheckAttack

The player is in view, so decide to move or launch an attack
Returns FALSE if movement should continue
============
]]
function M.sham_check_attack(self, enemy_range, enemy_vis)
    local combat = require("game.combat")
    if enemy_range == C.RANGE_MELEE then
        if combat.can_damage(self.enemy, self) then
            self.attack_state = C.AS_MELEE
            return true
        end
    end

    if quake.time() < self.attack_finished then
        return false
    end

    if not enemy_vis then
        return false
    end

    local targ = self.enemy

    -- see if any entities are in the way of the shot
    local spot1 = self.origin + self.view_ofs
    local spot2 = targ.origin + targ.view_ofs

    if (spot1 - spot2):length() > 600 then
        return false
    end

    local trace = quake.trace_line(spot1, spot2, false, self)

    if trace.in_open and trace.in_water then
        return false -- sight line crossed contents
    end

    if trace.entity ~= targ then
        return false -- don't have a clear shot
    end

    -- missile attack
    if enemy_range == C.RANGE_FAR then
        return false
    end

    self.attack_state = C.AS_MISSILE
    subs.attack_finished(self, 2 + 2 * quake.random())
    return true
end

--============================================================================

--[[
===========
OgreCheckAttack

The player is in view, so decide to move or launch an attack
Returns FALSE if movement should continue
============
]]
function M.ogre_check_attack(self, enemy_range, enemy_vis)
    local combat = require("game.combat")
    if enemy_range == C.RANGE_MELEE then
        if combat.can_damage(self.enemy, self) then
            self.attack_state = C.AS_MELEE
            return true
        end
    end

    if quake.time() < self.attack_finished then
        return false
    end

    if not enemy_vis then
        return false
    end

    local targ = self.enemy

    -- see if any entities are in the way of the shot
    local spot1 = self.origin + self.view_ofs
    local spot2 = targ.origin + targ.view_ofs

    local trace = quake.trace_line(spot1, spot2, false, self)

    if trace.in_open and trace.in_water then
        -- sight line crossed contents
        return false
    end

    if trace.entity ~= targ then
        -- don't have a clear shot
        return false
    end

    -- missile attack
    if quake.time() < self.attack_finished then
        return false
    end

    if enemy_range == C.RANGE_FAR then
        return false
    end

    local chance
    if enemy_range == C.RANGE_NEAR then
        chance = 0.10
    elseif enemy_range == C.RANGE_MID then
        chance = 0.05
    else
        chance = 0
    end

    self.attack_state = C.AS_MISSILE
    subs.attack_finished(self, 1 + 2 * quake.random())
    return true
end

return M
