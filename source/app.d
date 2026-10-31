import std.stdio;

import raylib;

import block;
import chunk;
import chunkSmooth;
import gameDebug.hud;
import player;

void main() {
	writeln("SurvivalStone");
	// BlockMesh myBlock;
	// Chunk2 myChunk;
	// myChunk.populateChunk();

	InitWindow(1280, 720, "SurvivalStone");
	SetTargetFPS(60);
	// Escape opens the pause menu. KEY_NULL stops raylib from treating Escape as quit.
	SetExitKey(KeyboardKey.KEY_NULL);
	scope (exit)
		CloseWindow();

	Player view = Player.create();
	// Start above the ground. The old spawn height sits inside it.
	ChunkSmooth ground;
	int gx = floorInt(view.camera.position.x);
	int gz = floorInt(view.camera.position.z);
	view.camera.position.y = ground.terrainHeight(gx, gz) + 2.0f;

	ChunkWorld* world = new ChunkWorld();
	PauseMenu menu;
	world.radius = menu.renderDistance;
	world.update(view.camera.position);
	// Hud hud;

	while (!WindowShouldClose()) {
		if (IsKeyPressed(KeyboardKey.KEY_ESCAPE)) {
			menu.open = !menu.open;
			if (menu.open)
				view.showCursor();
			else
				view.hideCursor();
		}

		if (menu.open && IsMouseButtonPressed(MouseButton.MOUSE_BUTTON_LEFT)) {
			if (menu.press(GetMousePosition(), GetScreenWidth(), GetScreenHeight()))
				view.hideCursor();
		}

		view.setDebugMove(menu.debugMove);
		world.radius = menu.renderDistance;
		if (!menu.open)
			view.update();
		world.update(view.camera.position);

		BeginDrawing();
		scope (exit)
			EndDrawing();

		ClearBackground(Colors.BLACK);

		BeginMode3D(view.camera);

		// myBlock.drawMesh();
		// myChunk.drawChunk();
		world.draw(view.camera);

		// DrawGrid(10, 1);
		EndMode3D();

		if (menu.open)
			menu.draw();

		// hud.draw(view);
	}
}
