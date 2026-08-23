-- Derived from GPL-licensed Quake game code in CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")

local M = {}

---Creates a zero-based sequential counter.
---@return fun(amount: integer): (...: integer)
function M.counter()
    local next_value = 0

    return function(amount)
        assert(math.type(amount) == "integer" and amount > 0,
            "counter amount must be a positive integer")

        local values = {}
        for index = 1, amount do
            values[index] = next_value
            next_value = next_value + 1
        end

        return table.unpack(values, 1, amount)
    end
end

---Expands one QuakeC-style `[frame, nexttime, nextthink] { code }` state.
---When nexttime is omitted, it defaults to 0.1 seconds.
---@overload fun(frame: integer, nextthink: function, code?: function): function
---@param frame integer
---@param nexttime number
---@param nextthink function
---@param code? function
---@return function frame_function
function M.frame(frame, nexttime, nextthink, code)
    if type(nexttime) ~= "number" then
        code = nextthink
        nextthink = nexttime
        nexttime = 0.1
    end

    assert(math.type(frame) == "integer", "animation frame must be an integer")
    assert(type(nextthink) == "function", "an animation frame needs a next-think resolver")

    local caller = debug.getinfo(2, "Sl")
    local callback = function(self)
        self.frame = frame
        self.nextthink = quake.time() + nexttime
        self.think = assert(nextthink(), "animation frame resolved to no next think")

        if code then
            code(self)
        end
    end

    quake.register_callback(callback, ("%s:%d:%s"):format(caller.source, caller.currentline, tostring(frame)))
    return callback
end

return M
