import core.stdc.stdio : snprintf;

import std.stdio;

import raylib;
import raylib.rcamera;
import raylib.rlgl;

import block;

const Vector3 tx0 = Vector3(0, 0, 0); // v
const Vector3 ty0 = Vector3(0, 1, 0); // ^
const Vector3 tz0 = Vector3(0, 1, 1); // <

const Vector3 tx1 = Vector3(0, 0, 0);
const Vector3 ty1 = Vector3(0, 0, 1);
const Vector3 tz1 = Vector3(0, 1, 1);

const Vector3 tx2 = Vector3(0, 0, 1);
const Vector3 ty2 = Vector3(0, 1, 1);
const Vector3 tz2 = Vector3(-1, 0, 1);

const Vector3 tx3 = Vector3(-1, 1, 1);
const Vector3 ty3 = Vector3(-1, 0, 1);
const Vector3 tz3 = Vector3(0, 1, 1);

const Vector3 tx4 = Vector3(-1, 1, 1);
const Vector3 ty4 = Vector3(-1, 0, 1);
const Vector3 tz4 = Vector3(-1, 0, 0);

const Vector3 tx5 = Vector3(-1, 1, 0);
const Vector3 ty5 = Vector3(-1, 0, 0);
const Vector3 tz5 = Vector3(-1, 1, 1);

const Vector3 tx6 = Vector3(-1, 1, 0);
const Vector3 ty6 = Vector3(-1, 0, 0);
const Vector3 tz6 = Vector3(0, 0, 0);

const Vector3 tx7 = Vector3(0, 1, 0);
const Vector3 ty7 = Vector3(0, 0, 0);
const Vector3 tz7 = Vector3(-1, 1, 0);

const Vector3 tx8 = Vector3(0, 1, 1);
const Vector3 ty8 = Vector3(-1, 1, 1);
const Vector3 tz8 = Vector3(-1, 1, 0);

const Vector3 tx9 = Vector3(-1, 1, 0);
const Vector3 ty9 = Vector3(0, 1, 0);
const Vector3 tz9 = Vector3(0, 1, 1);

const Vector3 tx10 = Vector3(0, 0, 1);
const Vector3 ty10 = Vector3(-1, 0, 1);
const Vector3 tz10 = Vector3(0, 0, 0);

const Vector3 tx11 = Vector3(-1, 0, 1);
const Vector3 ty11 = Vector3(-1, 0, 0);
const Vector3 tz11 = Vector3(0, 0, 0);

// Centroid of the triangle. The camera looks here.
const Vector3 WORK_TARGET = Vector3(0, 2.0f / 3.0f, 1.0f / 3.0f);

// Raylib 5.5 flies CAMERA_FREE at 5.4 m/s. Give the extra back so movement is a little slower.
enum raylibFreeMoveSpeed = 5.4f;
enum freeMoveScale = 0.65f;

void slowFreeCameraMove(ref Camera3D camera) {
	immutable giveBack = raylibFreeMoveSpeed * (1.0f - freeMoveScale) * GetFrameTime();
	if (IsKeyDown(KeyboardKey.KEY_W)) CameraMoveForward(&camera, -giveBack, false);
	if (IsKeyDown(KeyboardKey.KEY_S)) CameraMoveForward(&camera, giveBack, false);
	if (IsKeyDown(KeyboardKey.KEY_A)) CameraMoveRight(&camera, giveBack, false);
	if (IsKeyDown(KeyboardKey.KEY_D)) CameraMoveRight(&camera, -giveBack, false);
	if (IsKeyDown(KeyboardKey.KEY_SPACE)) CameraMoveUp(&camera, -giveBack);
	if (IsKeyDown(KeyboardKey.KEY_LEFT_CONTROL)) CameraMoveUp(&camera, giveBack);
}

void main() {
	writeln("SurvivalStone");
	BlockMesh myBlock;

	InitWindow(1280, 720, "SurvivalStone");
	SetTargetFPS(60);
	scope (exit)
		CloseWindow();

	// North is -Z. Same height as the triangle, due south of it, so the view is level and straight north.
	Camera3D camera;
	camera.position = Vector3(WORK_TARGET.x, WORK_TARGET.y, WORK_TARGET.z + 4);
	camera.target = WORK_TARGET;
	camera.up = Vector3(0, 1, 0);
	camera.fovy = 45;
	camera.projection = CameraProjection.CAMERA_PERSPECTIVE;

	DisableCursor();
	// Cursor lock warps the pointer. Drop those deltas so the view opens on the triangle.
	int settle = 2;

	while (!WindowShouldClose()) {
		if (settle > 0) {
			GetMouseDelta();
			settle--;
		} else {
			UpdateCamera(&camera, CameraMode.CAMERA_FREE);
			slowFreeCameraMove(camera);
		}

		BeginDrawing();
		scope (exit)
			EndDrawing();

		ClearBackground(Colors.RAYWHITE);

		BeginMode3D(camera);

		// DrawTriangle3D(tx0, ty0, tz0, Colors.GREEN);
		// DrawTriangle3D(tx1, tz1, ty1, Colors.DARKGREEN);
		// DrawTriangle3D(tx2, ty2, tz2, Colors.GREEN);
		// DrawTriangle3D(tx3, ty3, tz3, Colors.DARKGREEN);
		// DrawTriangle3D(tx4, tz4, ty4, Colors.GREEN);
		// DrawTriangle3D(tx5, ty5, tz5, Colors.DARKGREEN);
		// DrawTriangle3D(tx6, tz6, ty6, Colors.GREEN);
		// DrawTriangle3D(tx7, ty7, tz7, Colors.DARKGREEN);
		// DrawTriangle3D(tx8, tz8, ty8, Colors.GREEN);
		// DrawTriangle3D(tx9, tz9, ty9, Colors.DARKGREEN);
		// DrawTriangle3D(tx10, ty10, tz10, Colors.GREEN);
		// DrawTriangle3D(tx11, ty11, tz11, Colors.DARKGREEN);
		myBlock.drawMesh();

		DrawGrid(10, 1);
		EndMode3D();

		DrawText("Mouse look    WASD move    Wheel zoom    Esc quit", 16, 16, 20, Colors.DARKGRAY);

		char[64] xBuf, yBuf, zBuf;
		snprintf(xBuf.ptr, xBuf.length, "X  %.2f m", cast(double) camera.position.x);
		snprintf(yBuf.ptr, yBuf.length, "Y  %.2f m", cast(double) camera.position.y);
		snprintf(zBuf.ptr, zBuf.length, "Z  %.2f m", cast(double) camera.position.z);
		immutable fontSize = 20;
		immutable line = fontSize + 4;
		immutable pad = 8;
		int widest = MeasureText(xBuf.ptr, fontSize);
		const yWidth = MeasureText(yBuf.ptr, fontSize);
		const zWidth = MeasureText(zBuf.ptr, fontSize);
		if (yWidth > widest) widest = yWidth;
		if (zWidth > widest) widest = zWidth;
		immutable meterX = 16;
		immutable meterY = GetScreenHeight() - (line * 3 + pad);
		DrawRectangle(meterX - pad, meterY - pad, widest + pad * 2, line * 3 + pad, Color(0, 0, 0, 160));
		DrawText(xBuf.ptr, meterX, meterY, fontSize, Colors.RED);
		DrawText(yBuf.ptr, meterX, meterY + line, fontSize, Colors.GREEN);
		DrawText(zBuf.ptr, meterX, meterY + line * 2, fontSize, Colors.BLUE);
	}
}
