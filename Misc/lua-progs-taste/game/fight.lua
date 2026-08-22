-- Derived from GPL-licensed Quake game code in CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local C = require("game.constants")
local subs = require("game.subs")

local M = {}

function M.check_attack(self, enemy_range)
    local enemy = self.enemy
    local trace = quake.trace_line(
        self.origin + self.view_ofs,
        enemy.origin + enemy.view_ofs,
        false,
        self
    )

    if trace.entity ~= enemy or (trace.in_open and trace.in_water) then
        return false
    end

    if enemy_range == C.RANGE_MELEE and self.th_melee then
        self.th_melee(self)
        return true
    end

    if not self.th_missile or quake.time() < (self.attack_finished or 0) then
        return false
    end
    if enemy_range == C.RANGE_FAR then
        return false
    end

    local chance = 0
    if enemy_range == C.RANGE_MELEE then
        chance = 0.9
        self.attack_finished = 0
    elseif enemy_range == C.RANGE_NEAR then
        chance = self.th_melee and 0.2 or 0.4
    elseif enemy_range == C.RANGE_MID then
        chance = self.th_melee and 0.05 or 0.1
    end

    if quake.random() < chance then
        self.th_missile(self)
        subs.attack_finished(self, 2 * quake.random())
        return true
    end

    return false
end

function M.face(self)
    self.ideal_yaw = quake.vector_to_yaw(self.enemy.origin - self.origin)
    quake.change_yaw(self)
end

function M.charge(self, distance)
    M.face(self)
    quake.move_to_goal(self, distance)
end

return M
