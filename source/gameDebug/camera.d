module gameDebug.camera;

import raylib;

import player;

// Centroid of the triangle. The camera looks here before the first update.
private const Vector3 WORK_TARGET = Vector3(0, 2.0f / 3.0f, 1.0f / 3.0f);

// Ground-plane look and move. That is the path Player uses when debug movement is off.
struct FreeCamera {
	Camera3D camera;
	private float yaw;
	private float pitch;
	private int settle = 2;
	private float velocityY;

	static FreeCamera create() {
		FreeCamera view;
		// North is -Z. Same height as the triangle, due south of it, so the view is level and straight north.
		view.camera.position = Vector3(WORK_TARGET.x, WORK_TARGET.y, WORK_TARGET.z + 4);
		view.camera.target = WORK_TARGET;
		view.camera.up = Vector3(0, 1, 0);
		view.camera.fovy = 45;
		view.camera.projection = CameraProjection.CAMERA_PERSPECTIVE;
		view.yaw = 0;
		view.pitch = 0;
		DisableCursor();
		view.settle = 2;
		return view;
	}

	void update() {
		stepLook(camera, yaw, pitch, settle, false, velocityY);
	}

	string facingLabel() {
		return facingOf(camera.target - camera.position);
	}
}
