module aiTest.frame;

import raylib;

import block;
import gameDebug.camera;
import gameDebug.hud;

import aiTest.check;

// One hidden frame of the chunk, grid, compass, and coordinate panel.
int checkFrame() {
	Report report;
	SetConfigFlags(ConfigFlags.FLAG_WINDOW_HIDDEN);
	InitWindow(1280, 720, "aiTest");
	scope (exit)
		CloseWindow();
	report.expect(IsWindowReady(), "window opened");
	if (!IsWindowReady())
		return report.failed;

	Chunk chunk;
	chunk.populateChunk();

	Camera3D camera;
	camera.position = Vector3(8, 8, 24);
	camera.target = Vector3(8, 8, 8);
	camera.up = Vector3(0, 1, 0);
	camera.fovy = 45;
	camera.projection = CameraProjection.CAMERA_PERSPECTIVE;

	FreeCamera view;
	Vector3 workTarget = Vector3(0, 2.0f / 3.0f, 1.0f / 3.0f);
	view.camera.position = Vector3(workTarget.x, workTarget.y, workTarget.z + 4);
	view.camera.target = workTarget;
	view.camera.up = Vector3(0, 1, 0);
	view.camera.fovy = 45;
	view.camera.projection = CameraProjection.CAMERA_PERSPECTIVE;

	Hud hud;
	BeginDrawing();
	ClearBackground(Colors.BLACK);
	BeginMode3D(camera);
	chunk.drawChunk();
	DrawGrid(10, 1);
	EndMode3D();
	hud.draw(view);
	EndDrawing();
	return report.failed;
}
