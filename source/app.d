import std.random : unpredictableSeed;
import std.stdio;

import raylib;

import block;
import chunk;
import chunkQuads;
import chunkSmooth;
import terrainQuads;
import gameDebug.hud;
import player;

void main() {
	uint seed = unpredictableSeed();
	setTerrainSeed(seed);
	writeln("SurvivalStone");
	writeln("seed ", seed);
	// BlockMesh myBlock;
	// Chunk2 myChunk;
	// myChunk.populateChunk();

	InitWindow(1280, 720, "SurvivalStone");
	SetTargetFPS(60);
	// Escape opens the pause menu. KEY_NULL stops raylib from treating Escape as quit.
	SetExitKey(KeyboardKey.KEY_NULL);
	scope (exit)
		CloseWindow();
	loadNodeSprite();
	scope (exit)
		unloadNodeSprite();

	Player view = Player.create();
	// A fixed window on this seed's hills. Debug flight stays off the smooth height.
	float originX = 64;
	float originZ = -32;
	int cells = 32;
	float lookX = originX + cells * wallSide * 0.5f;
	float lookZ = originZ + cells * wallSide * 0.5f;
	float camZ = lookZ + 20;
	view.camera.position = Vector3(lookX, groundHeightAt(lookX, camZ) + 18, camZ);

	// ChunkWorld* world = new ChunkWorld();
	PauseMenu menu;
	menu.debugMove = true;
	view.setDebugMove(true);
	// world.radius = menu.renderDistance;
	// world.update(view.camera.position);
	GridQuad[] quads = buildTerrain(originX, originZ, cells, cells);
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
		// world.radius = menu.renderDistance;
		if (!menu.open)
			view.update();
		// world.update(view.camera.position);

		BeginDrawing();
		scope (exit)
			EndDrawing();

		ClearBackground(Colors.SKYBLUE);

		BeginMode3D(view.camera);

		// myBlock.drawMesh();
		// myChunk.drawChunk();
		// world.draw(view.camera);
		drawQuads(quads);
		if (menu.showNodes)
			drawChunkNodes(view.camera, view.camera.position);

		// DrawGrid(10, 1);
		EndMode3D();

		if (menu.open)
			menu.draw();

		// hud.draw(view);
	}
}
