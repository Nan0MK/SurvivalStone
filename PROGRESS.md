# Progress

## 2026-10-05

The game opens a 1280×720 window, fills one 16×16×16 chunk, and draws it with a player movement system and a HUD.

- 2026-10-06: added `source/player.d` — `Player` moves with WASD, Space up, Shift down (not Ctrl), and turns with the mouse via its own yaw/pitch. `app.d` now uses `Player` instead of `FreeCamera`. `Hud.draw` takes `ref Player`. `aiTest/frame.d` uses `Player` for its one-frame draw. `gameDebug` is unchanged for reference. Verified: `dub run --config=aiTest` prints `aiTest ok`; `dub build` succeeds. No assigned task is waiting.

- `source/block.d`: `blockData` and `meshData` each hold 4096 entries. `populateChunk` and `drawChunk` cover indexes 4095 down through 0. Stored coordinates run from 1 to 16. The comment on `blockData` still says "should be 48". Leave that comment unless the author asks.
- `source/gameDebug/`: `FreeCamera` and `Hud`. `slowMove()` is still defined, and its call in `update` is commented out. Leave that call commented out unless the author asks. The game no longer uses `FreeCamera`; it stays for reference.
- `source/player.d`: `Player` is the active movement system. WASD moves relative to the mouse-facing direction, Space is up, Shift is down, mouse deltas set yaw/pitch. `Hud.draw` takes `ref Player`.
- `source/app.d`: builds the chunk before `InitWindow`, then draws the chunk, the grid, and the HUD. The clear color is black.
- `source/aiTest/`: agent test and review program. Agents run `dub run --config=aiTest` themselves. The author does not run it.
- `AGENTS.md`: task scope, the `aiTest` rule, and the handoff.
- `AGENT_LEARN.md`: programming notes to reuse.

Unfinished: nothing assigned. Wait for the author. Do not expand the game.
