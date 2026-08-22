-- Derived from GPL-licensed Quake game code in CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local C = require("game.constants")
local fight = require("game.fight")
local subs = require("game.subs")

local M = {}
local run_melee, run_missile, run_slide

function M.range(self, target)
    local distance = (self.origin + self.view_ofs - target.origin - target.view_ofs):length()
    if distance < 120 then return C.RANGE_MELEE end
    if distance < 500 then return C.RANGE_NEAR end
    if distance < 1000 then return C.RANGE_MID end
    return C.RANGE_FAR
end

function M.visible(self, target)
    local trace = quake.trace_line(
        self.origin + self.view_ofs,
        target.origin + target.view_ofs,
        true,
        self
    )
    return not (trace.in_open and trace.in_water) and trace.fraction == 1
end

function M.in_front(self, target)
    local forward = quake.make_vectors(self.angles).forward
    local direction = (target.origin - self.origin):normalized()
    return direction:dot(forward) > 0.3
end

function M.hunt_target(self)
    self.goalentity = self.enemy
    self.think = self.th_run
    self.ideal_yaw = quake.vector_to_yaw(self.enemy.origin - self.origin)
    self.nextthink = quake.time() + 0.1
    subs.attack_finished(self, 1)
end

function M.found_target(self)
    if self.enemy.classname == "player" then
        quake.globals.sight_entity = self
        quake.globals.sight_entity_time = quake.time()
    end

    self.show_hostile = quake.time() + 1
    M.hunt_target(self)
end

function M.find_target(self)
    local client
    local sight_time = quake.globals.sight_entity_time or -math.huge

    if sight_time >= quake.time() - 0.1 and (self.spawnflags & 3) == 0 then
        client = quake.globals.sight_entity
        if client and client.enemy == self.enemy then
            return false
        end
    else
        client = quake.check_client()
        if not quake.exists(client) then
            return false
        end
    end

    if client == self.enemy
        or (client.flags & C.FL_NOTARGET) ~= 0
        or (client.items & C.IT_INVISIBILITY) ~= 0 then
        return false
    end

    local enemy_range = M.range(self, client)
    if enemy_range == C.RANGE_FAR or not M.visible(self, client) then
        return false
    end
    if enemy_range == C.RANGE_NEAR
        and client.show_hostile < quake.time()
        and not M.in_front(self, client) then
        return false
    end
    if enemy_range == C.RANGE_MID and not M.in_front(self, client) then
        return false
    end

    self.enemy = client
    if self.enemy.classname ~= "player" then
        self.enemy = self.enemy.enemy
        if not quake.exists(self.enemy) or self.enemy.classname ~= "player" then
            self.enemy = quake.world
            return false
        end
    end

    M.found_target(self)
    return true
end

function M.pain(self, distance)
    quake.walk_move(self, self.angles.y + 180, distance)
end

function M.walk(self, distance)
    if not M.find_target(self) then
        quake.move_to_goal(self, distance)
    end
end

function M.stand(self)
    if M.find_target(self) then
        return
    end
    if quake.time() > self.pausetime then
        self.th_walk(self)
    end
end

function M.run(self, distance)
    local enemy = self.enemy
    if not quake.exists(enemy) or enemy.health <= 0 then
        self.enemy = quake.world

        if quake.exists(self.oldenemy) and self.oldenemy.health > 0 then
            self.enemy = self.oldenemy
            M.hunt_target(self)
        else
            local idle = quake.exists(self.movetarget) and self.th_walk or self.th_stand
            idle(self)
            return
        end
    end

    self.show_hostile = quake.time() + 1

    local enemy_visible = M.visible(self, self.enemy)
    if enemy_visible then
        self.search_time = quake.time() + 5
    end
    if quake.cvar("coop") ~= 0 and self.search_time < quake.time() and M.find_target(self) then
        return
    end

    local enemy_range = M.range(self, self.enemy)
    local enemy_yaw = quake.vector_to_yaw(self.enemy.origin - self.origin)

    if self.attack_state == C.AS_MISSILE then
        run_missile(self, enemy_yaw)
        return
    end
    if self.attack_state == C.AS_MELEE then
        run_melee(self, enemy_yaw)
        return
    end
    if enemy_visible and fight.check_attack(self, enemy_range) then
        return
    end
    if self.attack_state == C.AS_SLIDING then
        run_slide(self, enemy_yaw, distance)
        return
    end

    quake.move_to_goal(self, distance)
end

function M.turn(self)
    if not M.find_target(self) then
        quake.change_yaw(self)
    end
end

local function facing_ideal(self)
    local delta = (self.angles.y - self.ideal_yaw) % 360
    return delta <= 45 or delta >= 315
end

function run_melee(self, enemy_yaw)
    self.ideal_yaw = enemy_yaw
    quake.change_yaw(self)
    if facing_ideal(self) then
        self.th_melee(self)
        self.attack_state = C.AS_STRAIGHT
    end
end

function run_missile(self, enemy_yaw)
    self.ideal_yaw = enemy_yaw
    quake.change_yaw(self)
    if facing_ideal(self) then
        self.th_missile(self)
        self.attack_state = C.AS_STRAIGHT
    end
end

function run_slide(self, enemy_yaw, distance)
    self.ideal_yaw = enemy_yaw
    quake.change_yaw(self)

    local offset = self.lefty ~= 0 and 90 or -90
    if not quake.walk_move(self, self.ideal_yaw + offset, distance) then
        self.lefty = 1 - self.lefty
        quake.walk_move(self, self.ideal_yaw - offset, distance)
    end
end

return M
