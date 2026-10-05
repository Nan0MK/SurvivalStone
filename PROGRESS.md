# Progress

## 2026-10-05

The game opens a 1280×720 window, fills one 16×16×16 chunk, and draws it with a free camera and a HUD. No assigned task is waiting.

- `source/block.d`: `blockData` and `meshData` each hold 4096 entries. `populateChunk` and `drawChunk` cover indexes 4095 down through 0. Stored coordinates run from 1 to 16. The comment on `blockData` still says "should be 48". Leave that comment unless the author asks.
- `source/gameDebug/`: `FreeCamera` and `Hud`. `slowMove()` is still defined, and its call in `update` is commented out. Leave that call commented out unless the author asks.
- `source/app.d`: builds the chunk before `InitWindow`, then draws the chunk, the grid, and the HUD. The clear color is black.
- `source/aiTest/`: agent test and review program. Agents run `dub run --config=aiTest` themselves. The author does not run it.
- `AGENTS.md`: task scope, the `aiTest` rule, and the handoff.
- `AGENT_LEARN.md`: programming notes to reuse.

Unfinished: nothing assigned. Wait for the author. Do not expand the game.
