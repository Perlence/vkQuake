-- Loader for the Lua ports of GPL-licensed CleanFixedQuakeC modules.
-- SPDX-License-Identifier: GPL-2.0-or-later

-- Bind engine builtins before loading modules that use them.
require("game.builtins")

-- Keep this list in progs.src order. Requiring a module performs its QuakeC
-- entity registrations.
require("game.subs")
require("game.fight")
require("game.ai")
require("game.combat")
require("game.items")
require("game.weapons")
local world = require("game.world")
local client = require("game.client")
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

quake.globals.main = world.main
quake.globals.StartFrame = world.start_frame
quake.globals.PlayerPreThink = client.player_pre_think
quake.globals.PlayerPostThink = client.player_post_think
quake.globals.ClientKill = client.client_kill
quake.globals.ClientConnect = client.client_connect
quake.globals.PutClientInServer = client.put_client_in_server
quake.globals.ClientDisconnect = client.client_disconnect
quake.globals.SetNewParms = client.set_new_parms
quake.globals.SetChangeParms = client.set_change_parms
