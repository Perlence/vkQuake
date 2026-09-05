-- Loader for the Lua ports of GPL-licensed CleanFixedQuakeC modules.
-- SPDX-License-Identifier: GPL-2.0-or-later

-- Bind engine builtins before loading modules that use them.
require("builtins")

-- Keep this list in progs.src order. Requiring a module performs its QuakeC
-- entity registrations.
require("subs")
require("fight")
require("ai")
require("combat")
require("items")
require("weapons")
local world = require("world")
local client = require("client")
require("player")
require("monsters")
require("doors")
require("buttons")
require("triggers")
require("plats")
require("misc")

require("ogre")
require("demon")
require("shambler")
require("knight")
require("soldier")
require("wizard")
require("dog")
require("zombie")
require("boss")

require("tarbaby")
require("hknight")
require("fish")
require("shalrath")
require("enforcer")
require("oldone")

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
