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

## 2026-10-19

Diagnosed `Chunk2` face culling. No source files were changed. The author asked to learn the bug.

- `source/chunk.d`: `drawChunk` draws `drawEAST` when the WEST neighbor is not TEST, and it does that for every index, including empty cells. The east face is covered by the EAST neighbor, and only a TEST cell has a face.
- `source/chunk.d`: `populateChunk` uses `chunkSize-1 * chunkSize-1`, which is `-1` because `*` binds first. With loops at 1..16 the write index is `x - z + 16*y - 1`, so only slots 0..270 become TEST. `getNeighbor` reads the 0..15 layout from `chunkIndex`. Those are different grids.
- Measured on that code: 271 TEST cells, 3841 east faces. From the east the picture is a solid red wall. The opening camera looks north, so those east faces are edge-on and the view is the empty grid.
- Triangle winding is already outward on all six faces. Leave it.
- Fix is still the author's, when they want it. `populateChunk` should store with `chunkIndex(x - 1, y - 1, z - 1)`. The one-face test should require `chunkData[i]` to be TEST and `getNeighbor(i, EAST)` not to be.

## 2026-10-30

Smooth terrain, marching cubes. The block chunk and its culling were left as they were.

- `source/material.d`: `MaterialType` is `AIR` (0), `DIRT` (1), `ROCK` (2). Same shape as `BlockType`. Dirt draws brown, rock draws gray. Air is not a surface color.
- `source/chunkSmooth.d`: `ChunkSmooth` stores a material id and a density on a 17×17×17 sample grid. `populateTerrain` builds a dome (height 1 at the corners, 5 in the middle). Samples just under the surface are dirt, deeper samples are rock, and a patch on the south slope (`x` 6..10, `z` 10..13) is rock all the way up. `buildMesh` runs marching cubes. A triangle's color is the solid material closest to the surface, not the height. `drawChunk` adds `origin`.
- `source/app.d`: draws that chunk. `origin` is `(-8, 0, -18)`, so the dome sits in front of the opening view, which looks north. The old chunk draw stays commented out.
- `source/aiTest/smooth.d`: checks materials, interpolation, the single-corner triangle, color-by-material at two heights, the flat dirt sheet, and the dome. Wired into `aiTest.run`.
- Verified: `dub build` succeeds. `dub run --config=aiTest` prints `aiTest ok`. A hidden frame of the dome shows a brown mound with a gray rock patch on the slope. The top faces the camera.

Unfinished: `Chunk2` face culling, still the author's fix when they ask. No digging, no collision, and no more materials unless they ask.

- Same day: `terrainHeight` no longer builds a dome. It samples 2D Perlin noise, four octaves, then keeps the height between 1 and 10. Dirt, rock, and the rock patch are unchanged. The chunk coordinate is scaled by 0.10 and shifted, because Perlin is 0 at whole numbers. Verified with `dub run --config=aiTest` (`aiTest ok`) and a hidden frame: rolling dirt hills, gray rock in the patch, not a mound.
- Same day: fixed lighting, not a day/night cycle. `drawChunk` shades each triangle with `shadeColor`. The sun is up and a little toward east and south. Ambient is 0.35, so faces turned away stay visible. The stored triangle color is still the material. Verified: `aiTest ok`, and a hidden frame shows brighter tops and darker slopes.
- Same day: `ChunkWorld` keeps every chunk within 2 steps of the player on x, y, and z. A chunk is 16 units. Moving into a new chunk builds the new ones and drops the ones left behind. Height and the rock patch use world coordinates, so the shared face matches and the patch does not repeat. The player starts 2 units above the ground at the spawn column. Verified: `aiTest ok`. A hidden frame shows one continuous landscape, not a tiled hill. The seam test compares the face where two chunks meet, including a pair that crosses x = 0.
- Same day: `Player` and `FreeCamera` no longer use raylib's camera move. Both call `stepLook` in `source/player.d`. `turnLook` is the mouse. `moveLook` is WASD, Space up, Shift down, at 4 units per second on the ground plane. `aimLook` sets the target. `slowMove` and `UpdateCamera` are gone. The compass uses `target - position`. Verified: `dub build` and `aiTest ok`.
- Same day: Escape opens a pause menu. `SetExitKey(KEY_NULL)` so Escape no longer quits. The menu has Debug movement, off by default, and Resume. Debug movement flies along the look, so looking up and pressing W climbs. Normal movement stays on the ground plane. The cursor shows while the menu is open. After it closes, the next two look updates drop the mouse warp. Verified: `dub build` and `aiTest ok`. A hidden frame shows the title Paused, the debug row, and Resume.
- Same day: terrain height is the sum of three Perlin layers from `ideas/terrain gen algorithim.png`. `altitudeAt` is the slow base. `detailAt` is the jagged layer, held at 0 where its mask is low. `ledgesAt` is its own wave, flat along a step and steep at the end. The sum is taller than one chunk. Solid materials come from `terrainMaterial`, another Perlin sample. The old 1..10 clamp, the four-octave `perlinFbm`, and the rock patch are gone. Verified: `dub build` and `aiTest ok`. A hidden view shows cliffs, a valley, jagged ridges, and both dirt and rock.
- Same day: the default render distance is 40 chunks on x and on z. `ChunkWorld` keeps the surface layers in that square and drops a column when the player walks out of range. Empty air above the ground is not stored. Around the spawn that is 13147 chunks and about 9 seconds to build. Verified: `dub build` and `aiTest ok`. The radius checks use a world set to 2 so they do not rebuild the full distance.
- Same day: frustum culling. `ChunkWorld.draw` takes the camera and skips a chunk whose box is outside the view. The six planes use the same projection as `BeginMode3D`: 45 degree fovy converted to radians, near 0.01, far 1000. A box that crosses the edge is still drawn, and so is the box around the camera. Empty chunks are skipped. `app.d` passes `view.camera`. Verified: `dub build` and `aiTest ok`. The visible chunks are still drawn one triangle at a time.
- Same day: the first `world.update` builds one chunk, the surface layer nearest the player. Each later call, including each frame, builds one more missing chunk, nearest first. Chunks past the radius drop when the player changes column. The 40-chunk square still loads, one chunk per frame, so the horizon fills in over time. Verified: `dub build` and `aiTest ok`. The radius checks use a world set to 2 and call update until that square is present.
- Same day: the default render distance is 20 chunks. The pause menu has Render distance choices 10, 20, 40, and 100. The selected one is the lighter button. `app.d` copies that value onto `world.radius` before each update. A smaller distance drops the outside chunks on the next update. A larger distance keeps filling one chunk per frame. Verified: `dub build` and `aiTest ok`.
- Same day: terrain height is altitude, then ledges, then detail. Detail is added after the ledge wave, so it does not reshape the steps. Altitude is one noise feature across 256 chunks, with a swing of 160 around 28. The base barely moves inside one chunk and rises and falls over hundreds of chunks. Verified: `dub build` and `aiTest ok`.
- Same day: the normal player has gravity and ground collision. `moveWalk` falls, lands on the bilinear ground height, jumps with Space from the ground, and stops at a step taller than 1. The eyes stay 2 above the feet. Debug flight is unchanged: no gravity, no collision, Space up, Shift down. Verified: `dub build` and `aiTest ok`.
