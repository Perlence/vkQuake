-- Port of fish.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local C = require("game.constants")
local ai = require("game.ai")
local animation = require("game.animation")
local combat = require("game.combat")
local fight = require("game.fight")
local gibs = require("game.gibs")
local monsters = require("game.monsters")
local subs = require("game.subs")

local M = {}
local stand, walk, run, attack, death, pain

local function melee(self)
    if not quake.exists(self.enemy) then
        return
    end
    if (self.enemy.origin - self.origin):length() > 60 then
        return
    end

    quake.sound(self, C.CHAN_VOICE, "fish/bite.wav", 1, C.ATTN_NORM)
    local damage = (quake.random() + quake.random()) * 3
    combat.damage(self.enemy, self, self, damage)
end

local function die(self)
    if self.health < -20 then
        quake.sound(self, C.CHAN_VOICE, "player/udeath.wav", 1, C.ATTN_NORM)
        self.think = subs.remove
        self.nextthink = quake.time() + 0.1
        gibs.throw(self, "progs/gib1.mdl", self.health)
        gibs.throw(self, "progs/gib2.mdl", self.health)
        gibs.throw(self, "progs/gib3.mdl", self.health)
        return
    end

    death[1](self)
end

local function on_pain(self, _attacker, _damage)
    pain[1](self)
end

stand = animation.sequence({
    frames = {
        "swim1", "swim2", "swim3", "swim4", "swim5", "swim6",
        "swim7", "swim8", "swim9", "swim10", "swim11", "swim12",
        "swim13", "swim14", "swim15", "swim16", "swim17", "swim18",
    },
    each = function(self) ai.stand(self) end,
    next = function() return stand[1] end,
})

walk = animation.sequence({
    frames = {
        "swim1", "swim2", "swim3", "swim4", "swim5", "swim6",
        "swim7", "swim8", "swim9", "swim10", "swim11", "swim12",
        "swim13", "swim14", "swim15", "swim16", "swim17", "swim18",
    },
    each = function(self) ai.walk(self, 8) end,
    next = function() return walk[1] end,
})

run = animation.sequence({
    frames = {
        "swim1", "swim3", "swim5", "swim7", "swim9",
        "swim11", "swim13", "swim15", "swim17",
    },
    each = function(self, index)
        ai.run(self, 12)
        if index == 1 and quake.random() < 0.5 then
            quake.sound(self, C.CHAN_VOICE, "fish/idle.wav", 1, C.ATTN_NORM)
        end
    end,
    next = function() return run[1] end,
})

local attack_actions = {}
for index = 1, 18 do
    if index == 3 or index == 9 or index == 15 then
        attack_actions[index] = melee
    else
        attack_actions[index] = function(self) fight.charge(self, 10) end
    end
end

attack = animation.sequence({
    frames = {
        "attack1", "attack2", "attack3", "attack4", "attack5", "attack6",
        "attack7", "attack8", "attack9", "attack10", "attack11", "attack12",
        "attack13", "attack14", "attack15", "attack16", "attack17", "attack18",
    },
    actions = attack_actions,
    next = function() return run[1] end,
})

death = animation.sequence({
    frames = {
        "death1", "death2", "death3", "death4", "death5", "death6", "death7",
        "death8", "death9", "death10", "death11", "death12", "death13", "death14",
        "death15", "death16", "death17", "death18", "death19", "death20", "death21",
    },
    actions = {
        [1] = function(self)
            quake.sound(self, C.CHAN_VOICE, "fish/death.wav", 1, C.ATTN_NORM)
        end,
        [2] = function(self) self.solid = C.SOLID_NOT end,
    },
    next = function() return death[21] end,
})

local pain_actions = {}
for index = 2, 9 do
    pain_actions[index] = function(self) ai.pain(self, 6) end
end

pain = animation.sequence({
    frames = {
        "pain1", "pain2", "pain3", "pain4", "pain5",
        "pain6", "pain7", "pain8", "pain9",
    },
    actions = pain_actions,
    next = function() return run[1] end,
})

function M.spawn(self)
    if quake.cvar("deathmatch") ~= 0 then
        quake.remove(self)
        return
    end

    quake.precache_model("progs/fish.mdl")
    quake.precache_sound("fish/death.wav")
    quake.precache_sound("fish/bite.wav")
    quake.precache_sound("fish/idle.wav")

    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP
    quake.set_model(self, "progs/fish.mdl")
    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 24))
    self.health = 25

    self.th_stand = stand[1]
    self.th_walk = walk[1]
    self.th_run = run[1]
    self.th_die = die
    self.th_pain = on_pain
    self.th_melee = attack[1]

    monsters.swim_start(self)
end

quake.register_entity("monster_fish", M.spawn)

return M
