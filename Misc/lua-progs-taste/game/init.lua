-- Loader for the Lua ports of GPL-licensed CleanFixedQuakeC modules.
-- SPDX-License-Identifier: GPL-2.0-or-later

local M = {}

-- Keep this list in progs.src order. Requiring a module performs its QuakeC
-- entity registrations. Only the entry-point modules are exported.
require("game.subs")
require("game.fight")
require("game.ai")
require("game.combat")
require("game.items")
require("game.weapons")
M.world = require("game.world")
M.client = require("game.client")
require("game.player")
require("game.monsters")
require("game.doors")
require("game.buttons")
require("game.triggers")
require("game.plats")
require("game.misc")

require("game.ogre")
require("game.demon")
require("game.shambler")
require("game.knight")
require("game.soldier")
require("game.wizard")
require("game.dog")
require("game.zombie")
require("game.boss")

require("game.tarbaby")
require("game.hknight")
require("game.fish")
require("game.shalrath")
require("game.enforcer")
require("game.oldone")

return M
