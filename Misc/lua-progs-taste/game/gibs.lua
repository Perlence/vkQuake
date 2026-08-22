-- Derived from GPL-licensed Quake game code in CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local C = require("game.constants")
local subs = require("game.subs")

local M = {}
local velocity_for_damage

function M.throw(self, model, damage)
    local gib = quake.spawn()
    gib.origin = self.origin
    quake.set_model(gib, model)
    quake.set_size(gib, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))
    gib.velocity = velocity_for_damage(self, damage)
    gib.movetype = C.MOVETYPE_BOUNCE
    gib.solid = C.SOLID_NOT
    gib.avelocity = quake.vec3(
        quake.random() * 600,
        quake.random() * 600,
        quake.random() * 600
    )
    gib.think = subs.remove
    gib.ltime = quake.time()
    gib.nextthink = quake.time() + 10 + quake.random() * 10
    gib.frame = 0
    gib.flags = 0
end

function velocity_for_damage(self, damage)
    local inflictor = quake.globals.damage_inflictor
    local velocity

    if inflictor and inflictor.velocity:length() > 0 then
        velocity = inflictor.velocity * 0.5
            + (self.origin - inflictor.origin):normalized() * 25
        velocity = quake.vec3(
            velocity.x + 50 * quake.crandom(),
            velocity.y + 50 * quake.crandom(),
            100 + 100 * quake.random()
        )
    else
        velocity = quake.vec3(
            100 * quake.crandom(),
            100 * quake.crandom(),
            200 + 100 * quake.random()
        )
    end

    if damage > -50 then
        return velocity * 0.7
    elseif damage > -200 then
        return velocity * 2
    end
    return velocity * 10
end

return M
