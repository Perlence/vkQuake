-- Loader for the Lua ports of GPL-licensed CleanFixedQuakeC modules.
-- SPDX-License-Identifier: GPL-2.0-or-later

local M = {}

-- Keep this list in progs.src order. Requiring a module performs its QuakeC
-- entity registrations and exposes it here for callers that need the module.
M.defs = require("game.defs")
M.subs = require("game.subs")
M.fight = require("game.fight")
M.ai = require("game.ai")
M.combat = require("game.combat")
M.items = require("game.items")
M.weapons = require("game.weapons")
M.world = require("game.world")
M.client = require("game.client")
M.player = require("game.player")
M.monsters = require("game.monsters")
M.doors = require("game.doors")
M.buttons = require("game.buttons")
M.triggers = require("game.triggers")
M.plats = require("game.plats")
M.misc = require("game.misc")

M.ogre = require("game.ogre")
M.demon = require("game.demon")
M.shambler = require("game.shambler")
M.knight = require("game.knight")
M.soldier = require("game.soldier")
M.wizard = require("game.wizard")
M.dog = require("game.dog")
M.zombie = require("game.zombie")
M.boss = require("game.boss")

M.tarbaby = require("game.tarbaby") -- registered
M.hknight = require("game.hknight") -- registered
M.fish = require("game.fish") -- registered
M.shalrath = require("game.shalrath") -- registered
M.enforcer = require("game.enforcer") -- registered
M.oldone = require("game.oldone") -- registered

return M
