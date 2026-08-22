-- Derived from GPL-licensed Quake game code in CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")

local M = {}

function M.null(_self)
end

function M.remove(self)
    quake.remove(self)
end

function M.attack_finished(self, delay)
    self.attack_finished = quake.time() + delay
end

return M
