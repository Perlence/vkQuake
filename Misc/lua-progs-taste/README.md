# Lua progs taste

This directory sketches what a Lua replacement for QuakeC could look like. It ports `fish.qc` from [CleanFixedQuakeC](https://github.com/Jason2Brownlee/CleanFixedQuakeC) and the portions of its supporting modules needed by the fish.

The code is intentionally not wired into vkQuake. The current engine does not provide the required Lua game API. Instead, the prototype assumes that the engine supplies a `quake` module with:

- Mutable entity userdata with ordinary fields and Lua callback fields
- Vector userdata with arithmetic, `length()`, and `normalized()`
- `quake.time()`, `quake.cvar(name)`, `quake.globals`, and `quake.world`
- Entity functions such as `spawn()`, `remove()`, `exists()`, `find()`, and `check_client()`
- Model, size, sound, movement, trace, precache, and network-message builtins
- `quake.register_entity(classname, spawn_function)` for map entity dispatch

The API deliberately passes `self` to callbacks rather than emulating QuakeC's mutable global `self`. `animation.frame()` expands to the same assignments as QuakeC's `=[frame, nexttime, nextthink] { code }` declaration. The next-think argument is resolved lazily to support forward references and cycles, and `nexttime` defaults to 0.1 seconds when omitted.

## Files

- `game/fish.lua` – the complete fish definition and animations
- `game/ai.lua` – targeting and movement behavior used by the fish
- `game/fight.lua` – generic attack selection and charge movement
- `game/combat.lua` – damage and death handling
- `game/monsters.lua` – common swimming-monster initialization
- `game/gibs.lua` – gib spawning used by the fish death handler
- `game/subs.lua` – common removal and attack-delay helpers
- `game/animation.lua` – Lua expansion of QuakeC frame-function declarations
- `game/constants.lua` – relevant engine and game constants

## Running a syntax check

From this directory:

```sh
luac -p game/*.lua
```

This only checks Lua syntax. Running the game requires the proposed engine API above.

## Source and license

This is a derivative port of GPL-licensed Quake game code from CleanFixedQuakeC. It is distributed under GPL-2.0-or-later, consistently with that source and vkQuake.
