module gameDebug.camera;

import raylib;
import raylib.rcamera;

// Centroid of the triangle. The camera looks here.
private const Vector3 WORK_TARGET = Vector3(0, 2.0f / 3.0f, 1.0f / 3.0f);

// Raylib 5.5 flies CAMERA_FREE at 5.4 m/s. Give the extra back so movement is a little slower.
private enum raylibFreeMoveSpeed = 5.4f;
private enum freeMoveScale = 0.65f;

struct FreeCamera {
	Camera3D camera;
	private int settle = 2;

	static FreeCamera create() {
		FreeCamera view;
		// North is -Z. Same height as the triangle, due south of it, so the view is level and straight north.
		view.camera.position = Vector3(WORK_TARGET.x, WORK_TARGET.y, WORK_TARGET.z + 4);
		view.camera.target = WORK_TARGET;
		view.camera.up = Vector3(0, 1, 0);
		view.camera.fovy = 45;
		view.camera.projection = CameraProjection.CAMERA_PERSPECTIVE;
		DisableCursor();
		// Cursor lock warps the pointer. Drop those deltas so the view opens on the triangle.
		view.settle = 2;
		return view;
	}

	void update() {
		if (settle > 0) {
			GetMouseDelta();
			settle--;
		} else {
			UpdateCamera(&camera, CameraMode.CAMERA_FREE);
			// slowMove();
		}
	}

	// Strongest axis of the camera facing. North is -Z, east is +X, up is +Y.
	string facingLabel() {
		Vector3 forward = GetCameraForward(&camera);
		immutable float ax = forward.x < 0 ? -forward.x : forward.x;
		immutable float ay = forward.y < 0 ? -forward.y : forward.y;
		immutable float az = forward.z < 0 ? -forward.z : forward.z;
		if (ax + ay + az < 1.0e-8f)
			return null;

		if (ay > ax && ay > az)
			return forward.y > 0 ? "UP" : "DOWN";
		if (ax > az)
			return forward.x > 0 ? "EAST" : "WEST";
		return forward.z < 0 ? "NORTH" : "SOUTH";
	}

	private void slowMove() {
		immutable giveBack = raylibFreeMoveSpeed * (1.0f - freeMoveScale) * GetFrameTime();
		if (IsKeyDown(KeyboardKey.KEY_W)) CameraMoveForward(&camera, -giveBack, false);
		if (IsKeyDown(KeyboardKey.KEY_S)) CameraMoveForward(&camera, giveBack, false);
		if (IsKeyDown(KeyboardKey.KEY_A)) CameraMoveRight(&camera, giveBack, false);
		if (IsKeyDown(KeyboardKey.KEY_D)) CameraMoveRight(&camera, -giveBack, false);
		if (IsKeyDown(KeyboardKey.KEY_SPACE)) CameraMoveUp(&camera, -giveBack);
		if (IsKeyDown(KeyboardKey.KEY_LEFT_CONTROL)) CameraMoveUp(&camera, giveBack);
	}
}
