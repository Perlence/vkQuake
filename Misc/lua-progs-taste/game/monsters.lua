-- Derived from GPL-licensed Quake game code in CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local C = require("game.constants")
local ai = require("game.ai")

local M = {}

-- Using a monster makes it angry at the current activator.
function M.use(self, activator)
    if self.enemy
        or self.health <= 0
        or (activator.items & C.IT_INVISIBILITY) ~= 0
        or (activator.flags & C.FL_NOTARGET) ~= 0
        or activator.classname ~= "player" then
        return
    end

    -- Delay reaction so if the monster is teleported, its sound is still heard.
    self.enemy = activator
    self.nextthink = quake.time() + 0.1
    self.think = ai.found_target
end

-- When a monster dies, it fires all of its targets with the current enemy as
-- activator.
function M.death_use(self)
    -- Fall to ground.
    self.flags = self.flags & ~(C.FL_FLY | C.FL_SWIM)
    if self.target and self.target ~= "" then
        quake.use_targets(self, self.enemy)
    end
end

function M.swim_start(self)
    -- Spread think times so they don't all happen at the same time.
    self.nextthink = self.nextthink + quake.random() * 0.5
    self.think = M.swim_start_go
    quake.globals.total_monsters = quake.globals.total_monsters + 1
end

function M.swim_start_go(self)
    if quake.cvar("deathmatch") ~= 0 then
        quake.remove(self)
        return
    end

    self.takedamage = C.DAMAGE_AIM

    self.ideal_yaw = self.angles.y
    if self.yaw_speed == 0 then
        self.yaw_speed = 10
    end
    self.view_ofs = quake.vec3(0, 0, 10)
    self.use = M.use
    self.flags = self.flags | C.FL_SWIM | C.FL_MONSTER

    if self.target and self.target ~= "" then
        self.goalentity = quake.find(quake.world, "targetname", self.target)
        self.movetarget = self.goalentity
        self.ideal_yaw = quake.vector_to_yaw(self.goalentity.origin - self.origin)

        if not self.movetarget then
            quake.dprint("Monster can't find target at ", tostring(self.origin), "\n")
        end
        -- This used to be an objerror.
        self.th_walk(self)
    else
        self.pausetime = 99999999
        self.th_stand(self)
    end

    -- Spread think times so they don't all happen at the same time.
    self.nextthink = self.nextthink + quake.random() * 0.5
end

return M
