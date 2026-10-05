import std.stdio;

import raylib;

import block;
import gameDebug.camera;
import gameDebug.hud;

void main() {
	writeln("SurvivalStone");
	// BlockMesh myBlock;
	Chunk myChunk;
	myChunk.populateChunk();

	InitWindow(1280, 720, "SurvivalStone");
	SetTargetFPS(60);
	scope (exit)
		CloseWindow();

	FreeCamera view = FreeCamera.create();
	Hud hud;

	while (!WindowShouldClose()) {
		view.update();

		BeginDrawing();
		scope (exit)
			EndDrawing();

		ClearBackground(Colors.BLACK);

		BeginMode3D(view.camera);

		// myBlock.drawMesh();
		myChunk.drawChunk();

		DrawGrid(10, 1);
		EndMode3D();

		hud.draw(view);
	}
}
