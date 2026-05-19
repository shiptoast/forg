# Updates

## 2026-05-19

- Changed tongue behavior so caught objects stay held after the tongue retracts
  to the frog, and only release when the touch/tongue button is released.
- Released objects now drop from frog-face height with gravity instead of
  snapping directly into the stack.
- Added named input helpers in `main.lua` so gameplay code uses `left_btn()`,
  `right_btn()`, `jump_btn()`, `touch_btn()`, and `call_frogs_btn()` instead
  of raw PICO-8 `btn(n)` calls.
- Updated froglet calling to use `call_frogs_btn()`.
- Current bindings: left/right rotate the reticle, O jumps, X shoots/holds the
  tongue, and down calls froglets.
- Added airborne left/right control that adds small velocity changes and caps
  air steering at half the frog's initial horizontal jump speed.
- Regenerated the browser export (`forg.js`) after gameplay changes.
- The Apphost-managed browser build is available at
  `http://100.100.196.79:4174/forg.html`.
