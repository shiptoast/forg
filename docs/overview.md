# forg Overview

`forg` is a small PICO-8 cartridge project. The cart file is
`frog_game.p8`, and the playable browser export is `forg.html` plus
`forg.js`.

The game is a frog-and-froglets prototype: a frog sits in a tank, aims a
rotating reticle, shoots a tongue to grab falling objects, and drops those
objects into a stack. Three froglets follow one another in a chain when
called.

## Source Layout

- `frog_game.p8`: PICO-8 cartridge wrapper. Its `__lua__` section includes
  `entity.lua`, `physics.lua`, `froglet.lua`, and `main.lua` in that order,
  then stores the cartridge graphics, sound data, and a black label image for
  HTML export.
- `entity.lua`: tiny entity object model. Entities have center-positioned
  bounds, velocity, a draw function, and arbitrary tags such as `static`,
  `grounded`, and `froglet`.
- `physics.lua`: axis-aligned bounding-box collision checks and collision
  resolution. `check_all_collisions` is legacy-style code that is not used by
  the current game loop and references methods not implemented on `Entity`.
- `froglet.lua`: factory and update/draw behavior for follower froglets.
- `main.lua`: game setup, update loop, draw loop, object spawning, tongue
  behavior, dropping/stacking logic, and input handling.
- `forg.html` and `forg.js`: generated PICO-8 web export. Treat these as
  build artifacts unless you are intentionally changing the web shell.
- `README.md`: currently only a project title.

## Runtime Model

This project follows normal PICO-8 style: global functions and global game
state, with no Lua module system or package manager.

`_init()` in `main.lua` initializes the main tunables and runtime state:

- Tank bounds: x `18..110`, y `64..96`.
- Frog start: `(64, 87)`.
- Cursor: angle `90`, distance `32`, rotation speed `3` degrees per tick.
- Tongue: progress from `0` to `120`, moving in chunks of `18`.
- Spawn timer: a falling object every `90` ticks.
- Physics: gravity `0.12`.
- Collections: `renderables`, `uncaught_objects`, `caught_objects`,
  `cursor_btns_pressed`, and `frog_btns_pressed`.

The entity list is intentionally simple. Most update and collision behavior
is driven by tags:

- `static`: tank walls and floor do not move.
- `grounded`: objects no longer receive gravity.
- `grabbable`: falling objects can be caught by the tongue and are skipped by
  normal gravity/collision resolution until they are caught or land.
- `froglet`: froglets skip collision resolution against other froglets.

## Gameplay Loop

Each `_update()` frame:

1. Reads cursor, tongue, and frog controls.
2. Extends or retracts the tongue if active.
3. Checks the tongue tip as a 2x2 AABB against `uncaught_objects`.
4. Moves caught objects along the tongue while the button is held.
5. Drops caught objects near the frog when the tongue button is released.
6. Spawns new falling objects on a timer.
7. Expires uncaught objects whose timer reaches zero.
8. Runs the simple O(n^2) collision pass across `renderables`.
9. Applies gravity and velocity.
10. Updates each froglet.

Each `_draw()` frame clears the screen, draws renderables, draws frog eyes
based on `frog_direction`, draws the cursor, draws the tongue line when
active, and prints the title text.

## Controls

The code documents PICO-8 button ids directly:

- `btn(0)`: frog left input.
- `btn(1)`: frog right input.
- `btn(2)`: tongue button.
- `btn(3)`: froglet call button.
- `btn(4)`: rotate cursor one direction.
- `btn(5)`: rotate cursor the other direction.

`cursor_btns_pressed` and `frog_btns_pressed` act as input stacks so the last
held direction wins while multiple buttons are held.

## Object And Tongue Details

`make_random_obj()` creates a small rectangle at a random x-position inside
the tank, with random size and color. The accessory factories
`make_watch()`, `make_camera()`, and `make_shades()` still exist, but their
selection logic is commented out, so spawned objects are currently plain
rectangles.

When a tongue tip hits a grabbable object:

- The object is removed from `uncaught_objects`.
- Its `grabbable` tag is removed.
- It is added to `caught_objects`.
- `obj.caught` is set to `true`.
- The tongue starts retracting.

If the tongue reaches the frog while the button is still held, the caught
object stays attached at the frog until the button is released. Dropping uses
nearby caught objects to pick a stack height.

## Running And Exporting

There is no local dependency manifest and no automated test command in this
repo.

If PICO-8 is installed, load or run `frog_game.p8` from PICO-8. In this
workspace, `pico8` was not on `PATH`, but the executable was found at
`/home/nick/Development/pico8/pico-8/pico8`.

To try the checked-in browser export, serve the repo root and open
`forg.html`, for example:

```sh
python3 -m http.server 8000
```

Then visit `http://localhost:8000/forg.html`. `forg.html` loads `forg.js`,
so keep both files together.

After changing Lua source or cartridge assets, regenerate the PICO-8 web
export so `forg.html` and `forg.js` match `frog_game.p8`:

```text
load frog_game.p8
export forg.html
```

`export forg.html` is the important PICO-8 command for this repo's browser
build. It emits the HTML shell and matching JavaScript cartridge payload.
The cart has an explicit black `__label__` section because PICO-8's HTML
exporter expects a cartridge label.

The verified headless equivalent from this workspace is:

```sh
SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy /home/nick/Development/pico8/pico-8/pico8 frog_game.p8 -export forg.html
```

## Development Notes

- The source uses the PICO-8 Lua dialect, including operators and functions
  such as `+=`, `-=`, `!=`, `add()`, `del()`, `all()`, `rnd()`, `flr()`,
  `spr()`, `sfx()`, and `btn()`. Stock Lua parsers will not validate this
  code as-is.
- Include order matters because everything is global. `entity.lua` must load
  before code that calls `make_rect()`, and `physics.lua` must load before
  collision helpers are used.
- Prefer editing the included `.lua` files for gameplay changes. Edit
  `frog_game.p8` when changing cartridge metadata, sprites, SFX, or include
  order.
- Do not hand-edit `forg.js` for game logic. It is the generated runtime and
  cartridge payload for the browser export.

## Known Caveats

- `frog_move_speed` and `drag` are initialized but currently unused.
- `control_frog()` initializes `x_dir` to `0` and never assigns it from
  `frog_btns_pressed`; frog jumps still trigger from left/right input, but
  horizontal direction comes from the current cursor-derived `frog_direction`.
- Several values are assigned without `local`, including `grabbable`,
  `draw_color`, `dist`, `is_touching_object`, `dir`, and `drop_offset`.
  PICO-8 accepts this, but accidental globals are easy to introduce here.
- `check_all_collisions()` appears to be unused legacy scaffolding and calls
  `shouldCollideWith()` and `onCollision()`, which `Entity` does not define.
- The current collision pass is O(n^2) over `renderables` and relies on a few
  hard-coded exceptions instead of collision groups or masks.
