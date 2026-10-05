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

## `debug` is a keyword

A module cannot be named `debug`. `module debug;` and `import debug.camera;` fail with "identifier expected following module" or "import". The package name has to be a normal identifier, such as `gameDebug`.
