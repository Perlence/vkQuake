-- Derived from GPL-licensed Quake game code in CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")

local M = {}

---Creates callbacks equivalent to QuakeC's `=[frame, next] { action }` states.
---@param spec table
---@return table sequence
function M.sequence(spec)
    assert(#spec.frames > 0, "an animation needs at least one frame")

    local sequence = {}

    for index, frame in ipairs(spec.frames) do
        sequence[index] = function(self)
            self.frame = frame
            self.nextthink = quake.time() + (spec.interval or 0.1)

            if index < #spec.frames then
                self.think = sequence[index + 1]
            else
                self.think = assert(spec.next(), "animation has no next state")
            end

            local action = spec.actions and spec.actions[index]
            if action then
                action(self)
            elseif spec.each then
                spec.each(self, index)
            end
        end
    end

    return sequence
end

return M
