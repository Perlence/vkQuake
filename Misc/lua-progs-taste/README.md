# Lua progs taste

This directory sketches what a Lua replacement for QuakeC could look like. It ports the complete `progs.src` from [CleanFixedQuakeC](https://github.com/Jason2Brownlee/CleanFixedQuakeC) at `dacc69ef13d2c961776b708f33ad2be8e87da224`.

The code is intentionally not wired into vkQuake. The current engine does not provide the required Lua game API. Instead, the prototype assumes that the engine supplies a `quake` module with:

- Mutable entity userdata with ordinary fields and Lua callback fields
- Null entity references represented by `nil`, preserving QuakeC-style truth tests
- QuakeC-style zero or empty defaults for unset numeric, vector, and string fields
- Vector userdata with arithmetic, `length()`, `normalized()`, and `dot()`
- `quake.time()`, `quake.cvar(name)`, `quake.globals`, and `quake.world`
- Entity, model, sound, movement, tracing, precache, and network-message builtins
- `quake.register_entity(classname, spawn_function)` for map entity dispatch

The API deliberately passes `self`, `other`, and `activator` to callbacks rather than emulating their mutable QuakeC globals. Other game globals remain in `quake.globals`.

`animation.frame()` expands to the same assignments as QuakeC's `=[frame, nexttime, nextthink] { code }` declaration. The next-think argument is resolved lazily to support forward references and cycles, and `nexttime` defaults to 0.1 seconds when omitted. Every original frame function is represented explicitly rather than generated as a sequence.

## Layout

- `game/init.lua` – loader in the original `progs.src` order
- `game/defs.lua` – constants, globals, and entity-field declarations
- `game/animation.lua` – Lua expansion of QuakeC frame-function declarations
- `game/constants.lua` – constants shared by the initial supporting modules
- `game/*.lua` – one complete port for every module listed by `progs.src`
- `meta/quake.lua` – Lua Language Server definitions for the engine C module

Original comments, including entity documentation, remain next to the corresponding Lua code.

## Editor support

Open this directory as the Lua workspace. `.luarc.json` adds `meta/` as a Lua Language Server library, providing completion and type information for `require("quake")`. The metadata file is for tooling only and must not be added to the runtime module path.

## Validation

From this directory:

```sh
luac -p game/*.lua meta/*.lua
luacheck game --codes --no-max-line-length --globals require
```

`luac` checks syntax. `luacheck` additionally catches undefined Lua symbols; warnings for intentionally preserved QuakeC locals and externally referenced frame functions are expected. Running the game requires the proposed engine API above.

## Source and license

This is a derivative port of GPL-licensed Quake game code from CleanFixedQuakeC. It is distributed under GPL-2.0-or-later, consistently with that source and vkQuake.
