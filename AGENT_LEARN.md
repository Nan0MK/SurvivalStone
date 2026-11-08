# Agent learning notes

Lessons from SurvivalStone to reuse. Add a note when a later change teaches another one. Keep each note short and tied to a check you can run.

## A length is not the last index

A D static array of length `N` has indexes `0` through `N - 1`. The first use of index `N` throws `ArrayIndexError` and names both numbers: index `[N]` is out of bounds for length `N`.

A downward walk starts at `N - 1` and continues while the index is greater than `-1`. That visits `N - 1` down through `0`.

Subtracting 1 from the stored length makes the array shorter. It does not choose the last slot. Keep the length as `N`, and use `N - 1` only as a starting index.

## Nested loops need size cubed

Three loops that each run `chunkSize` times visit `chunkSize * chunkSize * chunkSize` cells. `chunkSize * 3` is a different count. For 16, the volume is 4096 and `16 * 3` is 48.

This chunk stores coordinates 1 through 16, because `x`, `y`, and `z` start at `chunkSize` and stop while greater than 0. Y is the outer loop, Z the middle, X the inner. The slot for `(x, y, z)` is `(y - 1) * 256 + (z - 1) * 16 + (x - 1)`. Index 0 is `(1, 1, 1)`. Index 4095 is `(16, 16, 16)`.

## Raylib directions in this project

Raylib is Y-up. Here, north is −Z, east is +X, and up is +Y.

`GetCameraForward` is the normalized vector from `position` to `target`. The compass label is the strongest axis of that vector:

- `UP` or `DOWN` only when `|y|` is strictly greater than both `|x|` and `|z|`.
- Otherwise `EAST` or `WEST` only when `|x|` is strictly greater than `|z|`.
- Otherwise `NORTH` when `z` is negative, and `SOUTH` when it is not.

An exact diagonal stays on the earlier name. Looking 45 degrees up while facing north still reads `NORTH`. Steeper than that reads `UP`.

The opening view is level and due south of the work target, so it looks straight north. Its position is `(target.x, target.y, target.z + 4)`.

## Raylib 5.5 free-fly speed is fixed

`UpdateCamera` with `CAMERA_FREE` moves at 5.4 m/s. That rate is not a parameter. Giving speed back means calling `CameraMoveForward`, `CameraMoveRight`, and `CameraMoveUp` from `raylib.rcamera` after `UpdateCamera`. Those names are declared in that module and exported from raylib.

## D floats and C varargs

D does not promote `float` to `double` for a C varargs call. Cast the float to `double` before `snprintf` or `TextFormat`. The coordinate HUD does this.

## `*` happens before `-`

`chunkSize - 1 * chunkSize - 1` is `(chunkSize - (1 * chunkSize)) - 1`. With `chunkSize` 16, that is `-1`. Parentheses have to wrap each `chunkSize - 1` if that difference is what you want to multiply. `y*chunkSize - 1` is `(y * chunkSize) - 1`.

## A face checks the neighbor it touches

The east face of a solid block is covered by the block at x+1. The west face is covered by the block at x-1. North is −Z, south is +Z, up is +Y, down is −Y. Draw that face when this cell is solid and that neighbor is not. An empty cell has no faces. `Chunk2.getNeighbor` returns `-1` past the chunk edge, and `-1` is not a solid id, so an exposed border face stays.

`Chunk2` stores ids with `chunkIndex`: `x + y*chunkSize + z*chunkSize*chunkSize`, coordinates 0 through 15. The populate loops still count 16 down through 1, so those loop values go through `chunkIndex` only after subtracting 1.

## A smooth chunk has one more sample than it has cubes

Marching cubes builds each cube from the sample at `(x, y, z)` and the sample at `(x+1, y+1, z+1)`. A chunk is still 16 world units. `cubesPerUnit` is 2, so the chunk holds 32 cubes and 33 samples, and `sampleStep` is 0.5. A sample's position inside the chunk is its index times 0.5. The index is `x + y*33 + z*33*33`. The volume is `33 * 33 * 33` = 35937. Index 0 is `(0, 0, 0)`. Index 35936 is `(32, 32, 32)`, at local position 16. The player eye (2), step (1), and move speed (4) are not scaled with that grid.

A corner is inside the ground when its density is greater than the isolevel (`0`). The triangle normal points away from that inside corner. One inside corner at `(0, 0, 0)`, with the other seven corners outside, makes one triangle whose normal points toward `+X`, `+Y`, and `+Z`.

## Perlin is zero on whole numbers

`perlin2(0, 0)` and `perlin2(3, 5)` are 0. A height of `perlin2(x, z)` at integer coordinates is a flat sheet. Each terrain layer scales the coordinate and adds a shift, so the samples land inside the noise cells.

`terrainHeight` follows the terrain illustration from the bottom up: `altitudeAt`, then `rangesAt`, then `ledgesAt`, then `detailAt`. Detail is not passed through the ledge wave, so the scarps stay scarps and the bumps sit on them. Altitude is one Perlin feature across 256 chunks, centered at 28 with a swing of 160. Ranges are giant ledges on the altitude. `rangeWave` climbs 300 on a steep face, drops 75 on a slope a little less steep, then slopes gradually back to 0. The round hill of about 120 is gone. `detailIntensityAt` is a smooth 0..1 wave across 24 chunks, and detail is the jagged noise times 1.5 times that intensity. `ledgeWave` is a steep rise and then a long slope down, peaking at 8, three times across the noise. The ledge noise scale is 0.01, so those scarps sit several chunks apart. `ledgeIntensityAt` (32 chunks) and `ledgeChanceAt` (48 chunks) are the same kind of wave. Each uses `n + 0.5`, clamped to 0..1, then squared. Half-scale (`n * 0.5 + 0.5`) leaves the product of the two under a stride, so no ledge stops the player. `ledgesAt` is `ledgeShapeAt` times those two waves. A solid sample's material is `terrainMaterial`, another Perlin sample, not the depth and not the old rock patch.

## Smooth color reads the material, not the height

The triangle color is the solid material on the inside corner whose density is closest to the isolevel. A dirt sample at density `0.25` colors the cube even when a rock sample at density `5` is also inside, and that choice does not look at `y`. Dirt is brown. Rock is gray. Air is not drawn.

## DrawTriangle3D does not light the triangle

The color passed to `DrawTriangle3D` is the final color. `shadeColor` multiplies the material color by `0.35 + 0.65 * dot(normal, sun)`. The normal is `(b - a) × (c - a)`. The dot is clamped at 0, so a face pointing away from the sun stays at the ambient 0.35 instead of going black. A face whose normal is `sunDirection` keeps the material color unchanged. An upward face is brighter than a downward one, because the sun's y is positive.

## A chunk coordinate uses floor, not truncation

`cast(int)-0.1` is `0`, and `-17 / 16` is `-1`, because both truncate toward 0. The chunk just west of the origin is `-1`, and the chunk that contains `-17` is `-2`. `chunkCoord` floors first. `0` through `15.9` are chunk `0`. `16` is chunk `1`. `-0.1` and `-16` are chunk `-1`. `-16.1` is chunk `-2`.

The sample at local position 16 of one chunk is index `sampleCount - 1`. It is the sample at local position 0 of the next chunk. Both must read the height at the same world position, or the seam splits.

`chunkRadius` is the render distance in chunks on x and on z. The default is 20. The pause menu can set it to 10, 20, 40, 100, 200, or 500. A world loads the surface layers in that square. It does not allocate a cube of empty chunks on y. A column whose highest sample sits exactly on a chunk boundary keeps the lower layer. That upper layer would have no solid samples.

`ChunkWorld.update` does one chunk of work and returns. The first call builds the surface layer of the player's column nearest the player's y. Later calls move outward one ring at a time. Chunks past the radius are dropped when the player enters a new column, and also when the radius gets smaller. A larger radius keeps loading. Once the square for the current radius is loaded and every chunk's detail matches its distance, an update in that same column does nothing.

Detail follows distance. Within 2 chunks the cells are half a unit (32 cubes along the chunk). Through 6 chunks the cells are one unit. Farther than that the cells are two units. Walking closer rebuilds the chunk finer, one chunk on each update, nearest first. Walking away rebuilds it coarser. The feet use `quadHeightAt`, so a coarser marching-cubes mesh would not move the ground under the player. The visible quad ground does.

Two chunks of the same detail still share the face sample for sample. Two chunks of different detail do not, so each of those shared sides grows a skirt `skirtDrop` (8) units down. The skirt faces away from the chunk. A side whose neighbor is outside the loaded square does not grow one.

## A chunk box is drawn only when it meets the view

`ChunkWorld.draw` builds one frustum from the camera. `MatrixPerspective` takes the field of view in radians, so the degrees in `camera.fovy` are multiplied by `DEG2RAD`. Near is `0.01` and far is `1000`, the same distances `BeginMode3D` uses. The clip matrix is `MatrixMultiply(view, projection)`.

Each plane keeps the side where `x*nx + y*ny + z*nz + d` is at least 0. A chunk is the box from its origin to that origin plus `chunkSize` on each axis. The test looks at the corner farthest along the plane. If that corner is outside, the whole box is outside and the chunk is skipped. A box that only crosses the edge, and the box that contains the camera, stay. A chunk with no triangles is skipped before the test.

A chunk that stays is still drawn one triangle at a time. `drawChunk` skips a triangle when all three corners are outside one plane, and when the camera is on the back side of `(b - a) × (c - a)`. A triangle that only crosses the edge is drawn. The ground faces a camera above it and does not face a camera under it.

## Look and move are not UpdateCamera

`Player` and `FreeCamera` both call `stepLook`. The mouse changes yaw and pitch in `turnLook`. `aimLook` puts the target one unit along that look. Yaw 0, pitch 0 looks north: from `(0, 0, 4)` the target is `(0, 0, 3)`. W moves on `-Z`. D moves on `+X`. W and D together still travel at `moveSpeed` (4). Pitch stops at `pitchLimit`, just short of straight up or down.

Normal movement is `moveWalk`. The camera is the eyes, `eyeHeight` (2) above the feet. Gravity is 96 and `jumpSpeed` is 32, so a jump rises about 5.3, past a two-square cliff of 4. The feet stop on `surfaceAt`, which is `quadHeightAt`: the same flats, ramps, cliff floors, and bent triangles the window draws. A rise taller than `stepHeight` (1) cancels the horizontal step. Space jumps only when the feet are on the ground. Debug movement is still `moveDebug`: Space climbs, Shift descends, and the body does not fall or collide. Holding left ctrl multiplies that flight by `debugFast` (8). Walking ignores that key.

The compass reads `target - position`. It does not call `GetCameraForward`. The strongest axis wins, and a tie keeps the earlier name.

## Escape is the exit key until you change it

`WindowShouldClose` is true when Escape is pressed. A pause menu on that key never appears, because the window closes first. `SetExitKey(KeyboardKey.KEY_NULL)` after `InitWindow` leaves the close button as the way to quit.

The menu calls `EnableCursor`. Closing it calls `DisableCursor` and sets `settle` back to 2. Those two look updates throw away the mouse delta from locking the cursor, so the view does not spin.

Debug flight is `moveDebug`. Forward is `lookDirection`, so a positive pitch climbs. Strafe comes from `groundAxes`: at yaw 0, D is +X. The menu holds the flag, and `Player.setDebugMove` copies it before `update` and clears the fall speed. Normal movement does not use that flight.

## A fine sample grid is too big for the stack

A near chunk stores `33 * 33 * 33` material ids and the same number of densities. That is about 288KB before any triangles. Those arrays are sized to the chunk's detail and live on the heap. A far chunk stores `9 * 9 * 9` instead. The checks allocate each chunk with `ChunkSmooth.create`. The game does the same in `fillChunk`. Spawn height calls `groundHeight` and does not build a chunk just to read it.

## A diagonal grid step is longer than a straight one

Nodes are integer x, y, z. A straight step (1, 0) has length 1, so a rise of 1 is 45°. A diagonal step (1, 1) has length √2, so a rise of 1 is about 35°, and the corners still sit on the dots. A 45° slope along that diagonal would end between the dots.

The demo slopes are not that integer step. Each one is a square of `wallSide`, same as the walls, and the rise equals the run, so both are 45°. That rise is `wallSide / sqrt(2)`. The green ramp shares the whole south edge. The yellow ramp shares the whole northeast edge. A rise of 1 on those edges was a shorter rectangle, and the old yellow ramp met the wall at one corner only.

## A terrain cell shares posts with its neighbors

Hill posts sit `wallSide` apart. `heightLevel` rounds `groundHeightAt` to that step. A negative height rounds away from zero on the halfway case: `-1.5` steps becomes `-2`.

Four equal posts are one flat square at that height. Opposite edges that differ by one step are one ramp across the cell. Its rise and its run are both `wallSide`, so it is 45° and the face is a rectangle. A larger difference keeps a flat at the lower height and stacks that many vertical squares on the high edge. Those squares face the low side: a north-high stack stands on the north edge and its normal points south.

If the four posts are not two level edges, the cell is one bent quad through those four heights. Neighboring cells share the posts, so a ramp, a cliff, and a bent quad meet on the same edge. A ramp that used its own center, next to a flat of the same height, would leave a triangular hole.

A regular octagon does not keep every corner on an integer dot. Equal sides of length `wallSide` make each wall a square that tall. The 45° side then moves `wallSide / sqrt(2)` on x and on z. Those corners are floats. Snapping both ends to integer dots forces the orange side to √2 while the blue side stays an integer, which is the shorter corner the demo used first.

## A chunk node is a wallSide dot

`chunkNodes` uses the chunk that contains the camera. A chunk is 16 units. Nodes sit every `wallSide` (2) on x, y, and z, from the chunk origin through the far face, so 16 is included and the next step (18) is not. The chunk just west of the origin starts at -16 and includes the shared face at 0.

`DrawBillboard` turns a texture toward the camera. The node texture is a white circle. The draw pulls each dot toward the camera by half the sprite size, so a node sitting on a quad is not buried in that quad.

## The noise seed is the shuffle

`buildPerm` starts its shuffle from the seed. `defaultTerrainSeed` is 127, and that is the world the checks measure. `setTerrainSeed` replaces `perm`. The game does that with `unpredictableSeed` before `groundHeightAt` or `buildTerrain`. A height read before that call is still the 127 world. A check that calls `setTerrainSeed` has to put 127 back before it returns, or the later height checks measure a different world.

## `debug` is a keyword

A module cannot be named `debug`. `module debug;` and `import debug.camera;` fail with "identifier expected following module" or "import". The package name has to be a normal identifier, such as `gameDebug`.
