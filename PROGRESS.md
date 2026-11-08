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

## 2026-10-31

Finer marching cubes. The player stays the same size.

- `source/chunkSmooth.d`: `cubesPerUnit` is 2. A chunk is still 16 world units, with 32 cubes and 33 samples. Each cube is half a unit. `populateTerrain` samples `groundHeightAt` at those positions. The face shared with the next chunk is still world position 16.
- `source/player.d`: `surfaceAt` returns `groundHeightAt`, so the feet follow that surface. `eyeHeight` is still 2, `stepHeight` is still 1, `moveSpeed` is still 4, `jumpSpeed` is still 10, and `gravity` is still 24.
- `source/app.d`: the spawn height calls `groundHeight`. It does not put a chunk on the stack.
- `source/aiTest/smooth.d`: the grid checks use the half-unit samples. The flat sheet stays at world y = 4 and has 32×32×2 triangles. The one-corner edges sit at 0.25.
- Verified: `dub build` succeeds. `dub run --config=aiTest` prints `aiTest ok`.
- Same day: a triangle is drawn only when the camera can see it. `drawChunk` skips a triangle that is outside the view, and a triangle that faces away from the camera. A triangle that crosses the edge of the view is still drawn. Chunks outside the view were already skipped. Verified: `dub build` and `aiTest ok`.

- Same day: terrain detail follows distance. Within 2 chunks the cells stay half a unit. Through 6 chunks they are one unit. Farther out they are two units. Walking closer rebuilds a chunk finer, and walking away rebuilds it coarser, one chunk per update. A side that meets a different detail grows a skirt 8 units down so the seam stays covered. The feet still use `groundHeightAt`. Verified: `dub build` and `aiTest ok`.

- Same day: the window clears to sky blue. `app.d` calls `ClearBackground(Colors.SKYBLUE)`. Verified: `dub build` succeeds.
- Same day: detail bumps are scaled by 1.5 instead of 3.5. Ledge noise scale is 0.01 instead of 0.03, so a step covers several chunks. The step shape is unchanged: flat, then a rise at the end. Verified: `dub run --config=aiTest` prints `aiTest ok`.
- Same day: the terrain illustration now has five curves. Height is altitude, then ranges, then ledges, then detail. Ranges are smooth hills with a swing of 40 across 48 chunks. Ledges are a steep rise and a long slope down, peaking at 8. Detail is the jagged noise times 1.5 times `detailIntensityAt`, a smooth 0..1 wave. Verified: `dub run --config=aiTest` prints `aiTest ok`.
- Same day: ledges are scaled by two more smooth waves, in the same family as detail intensity. `ledgeIntensityAt` covers 32 chunks and scales how tall a scarp is. `ledgeChanceAt` covers 48 chunks and fades scarps out where it is low. Each maps Perlin one-to-one into 0..1 and then squares it, so a high stretch is a full ledge and a low stretch stays quiet. `ledgesAt` is the unscaled scarp times those two. The scarp still peaks at 8 before that scale. Verified: `dub run --config=aiTest` prints `aiTest ok`. `dub build` succeeds.
- Same day: the pause menu render distance choices are 10, 20, 40, 100, 200, and 500. The panel is wider so the six buttons fit on one row. In debug flight, holding left ctrl multiplies speed by `debugFast` (8). Walking stays at `moveSpeed` 4. Verified: `dub run --config=aiTest` prints `aiTest ok`. `dub build` succeeds.
- Same day: ranges were a ±40 ripple across 48 chunks, almost flat at the spawn, so they disappeared into the altitude. `rangesAt` is now a rounded mountain: near 0 in a valley, about 120 on a crest, about 16 chunks across. Verified: `dub run --config=aiTest` prints `aiTest ok`. `dub build` succeeds.
- Same day: that round hill was the wrong shape. `rangeWave` is a giant ledge: a steep climb of 300, a drop of 75 that is a little less steep, then a long slope back to the plain. A steep face of that shape stands just east of the spawn. Verified: `dub run --config=aiTest` prints `aiTest ok`. `dub build` succeeds.

Unfinished: `Chunk2` face culling, still the author's fix when they ask. No digging, no day/night cycle, no mesh batcher, and no more materials unless they ask. The finer grid draws more triangles, so a frame is heavier. Leave that until they ask.

## 2026-11-07

Quad grid, first slice. Marching cubes stays in the tree and is not drawn.

- `source/chunkQuads.d`: `GridQuad` stores four integer corners. `buildDemo` makes the octagon (axis walls and 45° walls that share vertical edges), a 45° ramp off the south wall, and a diagonal ramp that rises 1 across one diagonal step (about 35°) and shares the dot (5, 0, 1). Cardinal walls draw blue, 45° walls orange, the straight ramp green, the diagonal ramp yellow.
- `source/app.d`: draws that demo from (3, 2, 9), looking north. Debug flight starts on. The `ChunkWorld` update and draw calls are commented out, not deleted.
- `source/chunkSmooth.d`: unchanged.
- `source/aiTest/quads.d`: checks the octagon dots, shared edges, outward wall normals, the 45° ramp, and the diagonal run. Wired through `package.d` and `run.d`.
- Verified: `dub build` succeeds. `dub run --config=aiTest` prints `aiTest ok`.
- Same day: every wall is a square of side 2. The old octagon used blue edges of length 2 and orange edges of length √2, one unit tall, so the corners were shorter rectangles. A 45° side of length 2 ends at √2 on x and z, so those corners are not integer dots. Corners are `float` now. Verified: `dub build` succeeds. `dub run --config=aiTest` prints `aiTest ok`.
- Same day: both ramps are squares of side 2 at 45°. Rise and run are `wallSide / sqrt(2)`. The green ramp shares the whole south edge. The yellow ramp shares the whole northeast edge. The old green ramp rose 1 across a run of 1, and the old yellow ramp met the wall at one corner. Verified: `dub build` succeeds. `dub run --config=aiTest` prints `aiTest ok`.

Unfinished: blocky hills, placing and removing quads, wall thickness, and feet that stand on these quads. Walking still uses `groundHeightAt`. `Chunk2` face culling is still the author's fix when they ask.

- Same day: the window draws a blocky patch of the existing height instead of the octagon. `source/terrainQuads.d` samples `groundHeightAt` on a grid of `wallSide` and rounds each post to that step. A level cell is a flat square. Opposite edges one step apart are a 45° ramp across the whole cell, so that face is a rectangle. A taller step is a flat at the low height plus stacked vertical squares on the high edge, facing the low side. Corners that are not two level edges become one bent quad. `source/chunkQuads.d` stores a color on each quad and shades it with `shadeColor`. Dirt and rock still come from `terrainMaterial`. `source/app.d` builds a 32 by 32 cell patch from (64, −32), which is 64 units centered on the range face near x = 96. The camera sits 20 units south of that center and 18 above the ground there, looking north. Debug flight starts on. `ChunkWorld` stays commented out. `source/chunkSmooth.d` is unchanged. `buildDemo` is still in `chunkQuads.d` and is not drawn. Diagonal ramps are not on the hills. Verified: `dub build` succeeds. `dub run --config=aiTest` prints `aiTest ok`.

Unfinished: one-step hill slopes are rectangles, not the wall squares. Diagonal hill slopes are not built. Placing and removing quads, wall thickness, and feet on these quads are still open. Walking still uses `groundHeightAt`. `Chunk2` face culling is still the author's fix when they ask.

- Same day: the noise shuffle takes a seed. `buildPerm(seed)` and `setTerrainSeed` live in `source/chunkSmooth.d`. The game calls `setTerrainSeed(unpredictableSeed())` before it reads the ground, and prints that seed. The same seed rebuilds the same hills. The checks still start on `defaultTerrainSeed` (127) and put that seed back after they try another one. Verified: `dub build` succeeds. `dub run --config=aiTest` prints `aiTest ok`.

Unfinished: one-step hill slopes are rectangles, not the wall squares. Diagonal hill slopes are not built. Placing and removing quads, wall thickness, and feet on these quads are still open. Walking still uses `groundHeightAt`. `Chunk2` face culling is still the author's fix when they ask. There is no way to type a seed back in.

- Same day: the pause menu has a Nodes row. It starts off. `chunkNodes` lists the `wallSide` lattice of the 16-unit chunk that contains the camera, including the far face. `drawChunkNodes` draws each one with `DrawBillboard`, a white circle that faces the camera, pulled half a sprite toward the camera so a node on a quad stays visible. Verified: `dub build` succeeds. `dub run --config=aiTest` prints `aiTest ok`.

Unfinished: one-step hill slopes are rectangles, not the wall squares. Diagonal hill slopes are not built. Placing and removing quads, wall thickness, and feet on these quads are still open. Walking still uses `groundHeightAt`. `Chunk2` face culling is still the author's fix when they ask. There is no way to type a seed back in. Nodes show one chunk, the one the camera is in.

- Same day: walking stands on the visible quads. `surfaceAt` returns `quadHeightAt`. A flat cell and a cliff floor use the low quantized height. A one-step ramp slopes across the cell. A bent cell uses the same two triangles the mesh draws. `gravity` is 96 and `jumpSpeed` is 32, so a jump rises about 5.3, past a two-square cliff. `eyeHeight`, `stepHeight`, and `moveSpeed` stay 2, 1, and 4. Verified: `dub build` succeeds. `dub run --config=aiTest` prints `aiTest ok`.

Unfinished: one-step hill slopes are rectangles, not the wall squares. Diagonal hill slopes are not built. Placing and removing quads, and wall thickness, are still open. `Chunk2` face culling is still the author's fix when they ask. There is no way to type a seed back in. Nodes show one chunk, the one the camera is in.
