-- Derived from GPL-licensed Quake game code in CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local C = require("game.constants")

local M = {}

function M.use(self, activator)
    if quake.exists(self.enemy)
        or self.health <= 0
        or (activator.items & C.IT_INVISIBILITY) ~= 0
        or (activator.flags & C.FL_NOTARGET) ~= 0
        or activator.classname ~= "player" then
        return
    end

    self.enemy = activator
    self.nextthink = quake.time() + 0.1
    self.think = function(monster)
        require("game.ai").found_target(monster)
    end
end

function M.death_use(self)
    self.flags = self.flags & ~(C.FL_FLY | C.FL_SWIM)
    if self.target and self.target ~= "" then
        quake.use_targets(self, self.enemy)
    end
end

function M.swim_start(self)
    self.nextthink = (self.nextthink or quake.time()) + quake.random() * 0.5
    self.think = M.swim_start_go
    quake.globals.total_monsters = (quake.globals.total_monsters or 0) + 1
end

function M.swim_start_go(self)
    if quake.cvar("deathmatch") ~= 0 then
        quake.remove(self)
        return
    end

    self.takedamage = C.DAMAGE_AIM
    self.ideal_yaw = self.angles.y
    if not self.yaw_speed or self.yaw_speed == 0 then
        self.yaw_speed = 10
    end
    self.view_ofs = quake.vec3(0, 0, 10)
    self.use = M.use
    self.flags = self.flags | C.FL_SWIM | C.FL_MONSTER

    if self.target and self.target ~= "" then
        self.goalentity = quake.find(quake.world, "targetname", self.target)
        self.movetarget = self.goalentity

        if not quake.exists(self.movetarget) then
            quake.dprint("Monster can't find target at ", tostring(self.origin), "\n")
        else
            self.ideal_yaw = quake.vector_to_yaw(self.goalentity.origin - self.origin)
        end
        self.th_walk(self)
    else
        self.pausetime = 99999999
        self.th_stand(self)
    end

    self.nextthink = self.nextthink + quake.random() * 0.5
end

return M
