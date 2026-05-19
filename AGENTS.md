# AGENTS.md

Start with `docs/overview.md`. It contains the full repo map, gameplay model,
run/export notes, and current caveats.

## Quick Identity

This is a PICO-8 cartridge project named `forg`. The source cart is
`frog_game.p8`, which includes the editable Lua files:

1. `entity.lua`
2. `physics.lua`
3. `froglet.lua`
4. `main.lua`

The checked-in browser export is `forg.html` plus `forg.js`. Treat `forg.js`
as generated output unless the task is specifically about the web export.
`frog_game.p8` has a black `__label__` section so PICO-8's HTML exporter has
a label image.

## What The Game Does

A frog in a small tank aims a rotating cursor, shoots a tongue, catches
falling objects, and drops them into a stack. Three froglets follow in a
target chain when called.

Core behavior lives in `main.lua`:

- `_init()` sets tunables and global collections.
- `_update()` reads input, updates tongue/catch/drop behavior, spawns objects,
  runs collision/gravity, and updates froglets.
- `_draw()` renders the tank, frog, froglets, cursor, tongue, and title.

## Useful Commands

```sh
git status -sb
rg --files --hidden -g '!.git/**'
python3 -m http.server 8000
```

Use the static server only to try the checked-in web export at
`http://localhost:8000/forg.html`.

The verified headless export command in this workspace is:

```sh
SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy /home/nick/Development/pico8/pico-8/pico8 frog_game.p8 -export forg.html
```

There is no package manager, no test runner, and no standard Lua validation
command. The code uses PICO-8 Lua syntax, so stock Lua tools will reject
operators such as `+=`, `-=`, and `!=`.

## Editing Guidance

- For gameplay changes, edit the included `.lua` files.
- Use the named input helpers instead of calling PICO-8 `btn(n)` directly.
  The source of truth is in `main.lua`:
  `left_btn()` = left arrow / `btn(0)`, `right_btn()` = right arrow /
  `btn(1)`, `call_frogs_btn()` = down / `btn(3)`, `jump_btn()` = O /
  `btn(4)`, and `touch_btn()` = X / `btn(5)` for tongue catch/hold/release.
  `btn(2)` is currently unused.
- For sprites, SFX, cartridge metadata, or include order, edit `frog_game.p8`
  through PICO-8 when possible.
- After gameplay or asset changes, regenerate `forg.html` and `forg.js` with
  PICO-8 if the browser export should stay current. In the PICO-8 console,
  run `load frog_game.p8`, then `export forg.html`.
- Keep the include order in `frog_game.p8` unless you also adjust references:
  `entity.lua` defines `Entity`/`make_rect()`, `physics.lua` defines collision
  helpers, `froglet.lua` defines `make_froglet()`, and `main.lua` wires the
  game together.
- Check `git status -sb` before editing. At the time this file was created,
  local `main` was ahead of `origin/main` by one commit.

## Current Sharp Edges

- `forg.html` and `forg.js` are generated export files.
- `check_all_collisions()` in `physics.lua` is unused and references methods
  absent from `Entity`.
- Jump direction follows the current `frog_direction`, which is derived from
  reticle angle.
- Several assignments are global by default. Use `local` for new scratch
  variables unless PICO-8 global state is intentional.
- Collision is intentionally simple and O(n^2). Existing filters are hard
  coded in `main.lua`.
