import std.stdio;
import raylib;
import Util;
import Chunk;

void game(){
	validateRaylibBinding();

	InitWindow(1000, 800, "DLANG!");

	Block myBlock = Block.newBlock(0, 0, 0);

	Camera cam;
	cam.position = Vector3(10, 10, 10);
	cam.target = Vector3(0, 0, 0);
	cam.up = Vector3(0, 1, 0);
	cam.fovy = 60;
	cam.projection = CameraProjection.CAMERA_PERSPECTIVE;

	while( ! WindowShouldClose){

		UpdateCamera(&cam, CameraMode.CAMERA_FREE);
		camControls(cam);

		BeginDrawing();

		ClearBackground(Colors.BLACK);

		BeginMode3D(cam); //______________

		generateChunk(myBlock);
		DrawGrid(16, myBlock.size.x);

		EndMode3D(); //______________

		DrawText("Nan0MK", 350, 250, 60, Colors.GREEN);


		EndDrawing();
	}
	CloseWindow();
}

void main()
{
	writeln("HI! It's ME IN D!!");
	game();
}
