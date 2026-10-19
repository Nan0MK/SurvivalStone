module aiTest.view;

import std.conv : to;
import std.string : toStringz;

import raylib;

import block;
import chunk;

// Render two frames from the given camera pose and save a PNG.
// Agents use this to see the world without opening a window:
//   dub run --config=aiTest -- view out.png px py pz tx ty tz
void writeView(string outPath, Vector3 position, Vector3 target) {
	SetConfigFlags(ConfigFlags.FLAG_WINDOW_HIDDEN);
	InitWindow(1280, 720, "view");
	scope (exit)
		CloseWindow();

	Chunk2 myChunk;
	myChunk.populateChunk();

	Camera3D camera;
	camera.position = position;
	camera.target = target;
	camera.up = Vector3(0, 1, 0);
	camera.fovy = 45;
	camera.projection = CameraProjection.CAMERA_PERSPECTIVE;

	foreach (_; 0 .. 2) {
		BeginDrawing();
		scope (exit)
			EndDrawing();
		ClearBackground(Colors.BLACK);
		BeginMode3D(camera);
		myChunk.drawChunk();
		DrawGrid(10, 1);
		EndMode3D();
	}
	TakeScreenshot(toStringz(outPath));
}
