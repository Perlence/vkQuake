-- Derived from GPL-licensed Quake game code in CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")

---@alias animation.frame_descriptor [integer, fun(self: entity)?]
---@alias animation.next_state_resolver fun(): function
---@alias animation.final_state animation.next_state_resolver|"loop"|"hold"

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

local compile_sequence

---Creates sequential animation frames followed by another state.
---@param frames animation.frame_descriptor[]
---@param next_state animation.next_state_resolver
---@return function first_frame
function M.sequence(frames, next_state)
    assert(type(next_state) == "function", "an animation sequence needs a next-state resolver")
    return compile_sequence(frames, next_state, debug.getinfo(2, "Sl"))
end

---Creates sequential animation frames that restart after the final frame.
---@param frames animation.frame_descriptor[]
---@return function first_frame
function M.loop(frames)
    return compile_sequence(frames, "loop", debug.getinfo(2, "Sl"))
end

---Creates sequential animation frames that remain on the final frame.
---@param frames animation.frame_descriptor[]
---@return function first_frame
function M.hold(frames)
    return compile_sequence(frames, "hold", debug.getinfo(2, "Sl"))
end

local create_frame

---@param frames animation.frame_descriptor[]
---@param final_state animation.final_state
---@param caller table
---@return function first_frame
function compile_sequence(frames, final_state, caller)
    assert(type(frames) == "table" and #frames > 0, "an animation needs at least one frame")

    local compiled = {}
    for index, descriptor in ipairs(frames) do
        assert(type(descriptor) == "table", "animation frame descriptors must be tables")

        local frame = descriptor[1]
        local action = descriptor[2]
        local frame_index = index
        local next_state

        if index < #frames then
            function next_state() return compiled[frame_index + 1] end
        elseif final_state == "loop" then
            function next_state() return compiled[1] end
        elseif final_state == "hold" then
            function next_state() return compiled[frame_index] end
        else
            next_state = final_state
        end

        compiled[index] = create_frame(frame, next_state, action,
            ("%s:%d:%d:%s"):format(caller.source, caller.currentline, index, tostring(frame)))
    end

    return compiled[1]
end

---@param frame integer
---@param next_state animation.next_state_resolver
---@param action fun(self: entity)|nil
---@param identifier string
---@return function frame_function
function create_frame(frame, next_state, action, identifier)
    assert(math.type(frame) == "integer", "animation frame must be an integer")
    assert(type(next_state) == "function", "an animation frame needs a next-state resolver")
    assert(action == nil or type(action) == "function", "animation frame action must be a function")

    local function callback(self)
        self.frame = frame
        self.nextthink = quake.time() + 0.1
        self.think = assert(next_state(), "animation frame resolved to no next state")

        if action then
            action(self)
        end
    end

    return quake.register_callback(identifier, callback)
end

return M
