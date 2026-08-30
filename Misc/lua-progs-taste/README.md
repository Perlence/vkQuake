# Lua progs taste

This directory sketches what a Lua replacement for QuakeC could look like. It ports the complete `progs.src` from [CleanFixedQuakeC](https://github.com/Jason2Brownlee/CleanFixedQuakeC) at `dacc69ef13d2c961776b708f33ad2be8e87da224`.

vkQuake activates Lua game logic when the search path contains `lua/init.lua`. The engine loads modules from `lua/`, exposes the `quake` C module, registers Lua map-spawn functions, and dispatches entity and lifecycle callbacks to Lua.

The schema-only `progs.dat` generated from `dummy/` contains the standard engine ABI and empty lifecycle functions. Placing it beside `lua/` masks inherited QuakeC game logic through Quake's normal union filesystem semantics. Omitting it instead lets Lua extend the resolved `progs.dat`.

The `quake` module provides:

- Mutable entity userdata with ordinary fields and Lua callback fields
- Null entity references represented by `nil`, preserving QuakeC-style truth tests
- QuakeC-style zero or empty defaults for unset numeric, vector, and string fields
- Vector userdata with arithmetic, `length()`, `normalized()`, and `dot()`
- `quake.time()`, `quake.cvar(name)`, `quake.globals`, and `quake.world`
- Entity, model, sound, movement, tracing, precache, and network-message builtins
- `quake.register_function(identifier, callback)` for callbacks stored in function-typed globals and entity fields
- `quake.register_entity(classname, spawn_function)` for map entity dispatch

The engine passes `self` and `other` to Lua callbacks rather than emulating their mutable QuakeC globals. Game code passes `activator` explicitly to use callbacks. Other game globals remain in `quake.globals`.

`game/init.lua` assigns registered Lua functions to the engine-defined `main`, `StartFrame`, `PlayerPreThink`, `PlayerPostThink`, `ClientKill`, `ClientConnect`, `PutClientInServer`, `ClientDisconnect`, `SetNewParms`, and `SetChangeParms` globals. These assignments replace the inherited QuakeC entry points through the existing schema-backed globals, causing the engine's normal lifecycle calls to dispatch to Lua.

A Lua callback must be passed through `quake.register_function()` before it can be stored in a function-typed global or entity field such as `think`, `touch`, or `use`. Registration associates the callback with a stable `lua:<identifier>` name, returns the callback unchanged, and allows function references to be serialized in save files and resolved after Lua initialization when a save is loaded.

`animation.counter()` assigns zero-based model frame numbers in the same order as QuakeC's `$frame` directives. `animation.frame()` expands to the same assignments as QuakeC's `=[frame, nexttime, nextthink] { code }` declaration. The next-think argument is resolved lazily to support forward references and cycles, and `nexttime` defaults to 0.1 seconds when omitted. Every original frame function is represented explicitly rather than generated as a sequence.

## Layout

- `game/defs.lua` – serialized global and entity field schema loaded by the engine before edict allocation
- `game/init.lua` – loader in the original `progs.src` order
- `game/animation.lua` – Lua expansion of QuakeC frame-function declarations
- `game/constants.lua` – constants shared by the initial supporting modules
- `game/*.lua` – one complete port for every module listed by `progs.src`
- `dummy/*.qc` – source for the schema-only `progs.dat`
- `meta/quake.lua` – Lua Language Server definitions for the engine C module and schema types

Original comments, including entity documentation, remain next to the corresponding Lua code.

## Editor support

Open this directory as the Lua workspace. `.luarc.json` adds `meta/` as a Lua Language Server library, providing completion and type information for `require("quake")`. Files under `meta/` are for tooling only and must not be added to the runtime module path. Game-owned global and entity annotations live beside their runtime schema in `game/defs.lua`.

## Validation

From this directory:

```sh
luac -p game/*.lua meta/*.lua
luacheck game --codes --no-max-line-length --globals require
```

`luac` checks syntax. `luacheck` additionally catches undefined Lua symbols; warnings for intentionally preserved QuakeC locals and externally referenced frame functions are expected.

From the repository root, symlink the prototype into the game directory, then build and run it:

```sh
mkdir -p ~/Games/Quake/id1lua
ln -s "$(pwd)/Misc/lua-progs-taste/game" ~/Games/Quake/id1lua/lua
ln -s "$(pwd)/Misc/lua-progs-taste/progs.dat" ~/Games/Quake/id1lua/progs.dat
ninja -C build
build/vkquake -basedir ~/Games/Quake -game id1lua
```

The `id1lua` directory may also contain configuration and replacement assets.

## Source and license

This is a derivative port of GPL-licensed Quake game code from CleanFixedQuakeC. It is distributed under GPL-2.0-or-later, consistently with that source and vkQuake.
