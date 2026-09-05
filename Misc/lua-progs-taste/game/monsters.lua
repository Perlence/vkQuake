-- Port of monsters.qc from GPL-licensed CleanFixedQuakeC.
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

local C = require("constants")
local ai = require("ai")
local subs = require("subs")

local M = {}

-- ALL MONSTERS SHOULD BE 1 0 0 IN COLOR

-- name =[framenum, nexttime, nextthink] {code}
-- expands to:
-- name ()
-- {
--     self.frame=framenum;
--     self.nextthink = time + nexttime;
--     self.think = nextthink
--     <code>
-- };

---Using a monster makes it angry at the current activator
---@param self entity
---@param activator entity
---@return nil
local use = quake.register_function("monsters.use", function(self, activator)
    if self.enemy then
        return
    end
    if self.health <= 0 then
        return
    end
    if (activator.items & C.IT_INVISIBILITY) ~= 0 then
        return
    end
    if (activator.flags & C.FL_NOTARGET) ~= 0 then
        return
    end
    if activator.classname ~= "player" then
        return
    end

    -- delay reaction so if the monster is teleported, its sound is still
    -- heard
    self.enemy = activator
    self.nextthink = quake.time() + 0.1
    self.think = ai.found_target
end)

---When a mosnter dies, it fires all of its targets with the current
---enemy as activator.
---@param self entity
---@return nil
function M.death_use(self)
    -- fall to ground
    if (self.flags & C.FL_FLY) ~= 0 then
        self.flags = self.flags - C.FL_FLY
    end
    if (self.flags & C.FL_SWIM) ~= 0 then
        self.flags = self.flags - C.FL_SWIM
    end

    if self.target == "" then
        return
    end

    subs.use_targets(self, self.enemy)
end

--============================================================================

---@param self entity
---@return nil
local walk_start_go = quake.register_function("monsters.walk_start_go", function(self)
    -- raise off floor a bit
    self.origin = quake.vec3(self.origin.x, self.origin.y, self.origin.z + 1)
    quake.drop_to_floor(self)

    if not quake.walk_move(self, 0, 0) then
        quake.dprint("walkmonster in wall at: ")
        quake.dprint(tostring(self.origin))
        quake.dprint("\n")
    end

    self.takedamage = C.DAMAGE_AIM

    self.ideal_yaw = self.angles.y
    if self.yaw_speed == 0 then
        self.yaw_speed = 20
    end
    self.view_ofs = quake.vec3(0, 0, 25)
    self.use = use

    self.flags = self.flags | C.FL_MONSTER

    if self.target ~= "" then
        self.goalentity = quake.find(quake.world, "targetname", self.target)
        self.movetarget = self.goalentity
        self.ideal_yaw = quake.vector_to_yaw(self.goalentity.origin - self.origin)
        if not self.movetarget then
            quake.dprint("Monster can't find target at ")
            quake.dprint(tostring(self.origin))
            quake.dprint("\n")
        end
        -- this used to be an objerror
        if self.movetarget.classname == "path_corner" then
            self.th_walk(self)
        else
            self.pausetime = 99999999
        end
        self.th_stand(self)
    else
        self.pausetime = 99999999
        self.th_stand(self)
    end

    -- spread think times so they don't all happen at same time
    self.nextthink = self.nextthink + quake.random() * 0.5
end)

---@param self entity
---@return nil
M.walk_start = quake.register_function("monsters.walk_start", function(self)
    -- delay drop to floor to make sure all doors have been spawned
    -- spread think times so they don't all happen at same time
    self.nextthink = self.nextthink + quake.random() * 0.5
    self.think = walk_start_go
    quake.globals.total_monsters = quake.globals.total_monsters + 1
end)

---@param self entity
---@return nil
local fly_start_go = quake.register_function("monsters.fly_start_go", function(self)
    self.takedamage = C.DAMAGE_AIM

    self.ideal_yaw = self.angles.y
    if self.yaw_speed == 0 then
        self.yaw_speed = 10
    end
    self.view_ofs = quake.vec3(0, 0, 25)
    self.use = use

    self.flags = self.flags | C.FL_FLY
    self.flags = self.flags | C.FL_MONSTER

    if not quake.walk_move(self, 0, 0) then
        quake.dprint("flymonster in wall at: ")
        quake.dprint(tostring(self.origin))
        quake.dprint("\n")
    end

    if self.target ~= "" then
        self.goalentity = quake.find(quake.world, "targetname", self.target)
        self.movetarget = self.goalentity
        if not self.movetarget then
            quake.dprint("Monster can't find target at ")
            quake.dprint(tostring(self.origin))
            quake.dprint("\n")
        end
        -- this used to be an objerror
        if self.movetarget.classname == "path_corner" then
            self.th_walk(self)
        else
            self.pausetime = 99999999
        end
        self.th_stand(self)
    else
        self.pausetime = 99999999
        self.th_stand(self)
    end
end)

---@param self entity
---@return nil
function M.fly_start(self)
    -- spread think times so they don't all happen at same time
    self.nextthink = self.nextthink + quake.random() * 0.5
    self.think = fly_start_go
    quake.globals.total_monsters = quake.globals.total_monsters + 1
end

---@param self entity
---@return nil
local swim_start_go = quake.register_function("monsters.swim_start_go", function(self)
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
    self.use = use

    self.flags = self.flags | C.FL_SWIM
    self.flags = self.flags | C.FL_MONSTER

    if self.target ~= "" then
        self.goalentity = quake.find(quake.world, "targetname", self.target)
        self.movetarget = self.goalentity
        if not self.movetarget then
            quake.dprint("Monster can't find target at ")
            quake.dprint(tostring(self.origin))
            quake.dprint("\n")
        end
        -- this used to be an objerror
        self.ideal_yaw = quake.vector_to_yaw(self.goalentity.origin - self.origin)
        self.th_walk(self)
    else
        self.pausetime = 99999999
        self.th_stand(self)
    end

    -- spread think times so they don't all happen at same time
    self.nextthink = self.nextthink + quake.random() * 0.5
end)

---@param self entity
---@return nil
function M.swim_start(self)
    -- spread think times so they don't all happen at same time
    self.nextthink = self.nextthink + quake.random() * 0.5
    self.think = swim_start_go
    quake.globals.total_monsters = quake.globals.total_monsters + 1
end

return M
