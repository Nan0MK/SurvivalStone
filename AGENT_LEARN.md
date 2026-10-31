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

Marching cubes builds each cube from the sample at `(x, y, z)` and the sample at `(x+1, y+1, z+1)`. A chunk of 16 cubes needs samples `0` through `16`, so `sampleCount` is `17` and the volume is `17 * 17 * 17` = 4913. The index is `x + y*17 + z*17*17`. Index 0 is `(0, 0, 0)`. Index 4912 is `(16, 16, 16)`.

A corner is inside the ground when its density is greater than the isolevel (`0`). The triangle normal points away from that inside corner. One inside corner at `(0, 0, 0)`, with the other seven corners outside, makes one triangle whose normal points toward `+X`, `+Y`, and `+Z`.

## Perlin is zero on whole numbers

`perlin2(0, 0)` and `perlin2(3, 5)` are 0. A height of `perlin2(x, z)` at integer coordinates is a flat sheet. Each terrain layer scales the coordinate and adds a shift, so the samples land inside the noise cells.

`terrainHeight` builds `altitudeAt`, then adds `ledgesAt`, then adds `detailAt`. Detail is not passed through the ledge wave, so the steps stay steps and the bumps sit on them. Altitude is one Perlin feature across 256 chunks, centered at 28 with a swing of 160, so the base rises and falls over hundreds of chunks and barely moves inside one chunk. Detail is jagged, and it is 0 where its mask is low. `ledgeWave` keeps most of a step near the floor and packs the rise into the end of the step. A solid sample's material is `terrainMaterial`, another Perlin sample, not the depth and not the old rock patch.

## Smooth color reads the material, not the height

The triangle color is the solid material on the inside corner whose density is closest to the isolevel. A dirt sample at density `0.25` colors the cube even when a rock sample at density `5` is also inside, and that choice does not look at `y`. Dirt is brown. Rock is gray. Air is not drawn.

## DrawTriangle3D does not light the triangle

The color passed to `DrawTriangle3D` is the final color. `shadeColor` multiplies the material color by `0.35 + 0.65 * dot(normal, sun)`. The normal is `(b - a) × (c - a)`. The dot is clamped at 0, so a face pointing away from the sun stays at the ambient 0.35 instead of going black. A face whose normal is `sunDirection` keeps the material color unchanged. An upward face is brighter than a downward one, because the sun's y is positive.

## A chunk coordinate uses floor, not truncation

`cast(int)-0.1` is `0`, and `-17 / 16` is `-1`, because both truncate toward 0. The chunk just west of the origin is `-1`, and the chunk that contains `-17` is `-2`. `chunkCoord` floors first. `0` through `15.9` are chunk `0`. `16` is chunk `1`. `-0.1` and `-16` are chunk `-1`. `-16.1` is chunk `-2`.

The sample at local `x = 16` of one chunk is the sample at local `x = 0` of the next. Both must read the height at the same world position, or the seam splits.

`chunkRadius` is the render distance in chunks on x and on z. The default is 20. The pause menu can set it to 10, 20, 40, or 100. A world loads the surface layers in that square. It does not allocate a cube of empty chunks on y. A column whose highest sample sits exactly on a chunk boundary keeps the lower layer. That upper layer would have no solid samples.

`ChunkWorld.update` meshes one missing chunk and returns. The first call builds the surface layer of the player's column nearest the player's y. Later calls move outward one ring at a time. Chunks past the radius are dropped when the player enters a new column, and also when the radius gets smaller. A larger radius keeps loading. Once the square for the current radius is loaded, an update in that same column does nothing.

## A chunk box is drawn only when it meets the view

`ChunkWorld.draw` builds one frustum from the camera. `MatrixPerspective` takes the field of view in radians, so the degrees in `camera.fovy` are multiplied by `DEG2RAD`. Near is `0.01` and far is `1000`, the same distances `BeginMode3D` uses. The clip matrix is `MatrixMultiply(view, projection)`.

Each plane keeps the side where `x*nx + y*ny + z*nz + d` is at least 0. A chunk is the box from its origin to that origin plus `chunkSize` on each axis. The test looks at the corner farthest along the plane. If that corner is outside, the whole box is outside and the chunk is skipped. A box that only crosses the edge, and the box that contains the camera, stay. A chunk with no triangles is skipped before the test.

## Look and move are not UpdateCamera

`Player` and `FreeCamera` both call `stepLook`. The mouse changes yaw and pitch in `turnLook`. `aimLook` puts the target one unit along that look. Yaw 0, pitch 0 looks north: from `(0, 0, 4)` the target is `(0, 0, 3)`. W moves on `-Z`. D moves on `+X`. W and D together still travel at `moveSpeed` (4). Pitch stops at `pitchLimit`, just short of straight up or down.

Normal movement is `moveWalk`. The camera is the eyes, `eyeHeight` (2) above the feet. Gravity accelerates `velocityY` downward. The feet stop on `surfaceAt`, the bilinear blend of the four integer ground samples. A rise taller than `stepHeight` (1) cancels the horizontal step. Space jumps only when the feet are on the ground. Debug movement is still `moveDebug`: Space climbs, Shift descends, and the body does not fall or collide.

The compass reads `target - position`. It does not call `GetCameraForward`. The strongest axis wins, and a tie keeps the earlier name.

## Escape is the exit key until you change it

`WindowShouldClose` is true when Escape is pressed. A pause menu on that key never appears, because the window closes first. `SetExitKey(KeyboardKey.KEY_NULL)` after `InitWindow` leaves the close button as the way to quit.

The menu calls `EnableCursor`. Closing it calls `DisableCursor` and sets `settle` back to 2. Those two look updates throw away the mouse delta from locking the cursor, so the view does not spin.

Debug flight is `moveDebug`. Forward is `lookDirection`, so a positive pitch climbs. Strafe comes from `groundAxes`: at yaw 0, D is +X. The menu holds the flag, and `Player.setDebugMove` copies it before `update` and clears the fall speed. Normal movement does not use that flight.

## `debug` is a keyword

A module cannot be named `debug`. `module debug;` and `import debug.camera;` fail with "identifier expected following module" or "import". The package name has to be a normal identifier, such as `gameDebug`.
