module player;

import std.math : sin, cos, sqrt;

import raylib;
import raylib.rcamera;

// First-person player. WASD moves, Space is up, Shift is down, the mouse turns.
// Not the gameDebug FreeCamera; this one owns its own yaw/pitch.
struct Player {
	Camera3D camera;
	private float yaw;
	private float pitch;
	private int settle = 2;
	private enum moveSpeed = 4.0f;
	private enum mouseSensitivity = 0.0025f;

	static Player create() {
		Player p;
		p.camera.position = Vector3(0, 2.0f / 3.0f, 1.0f / 3.0f + 4);
		p.camera.up = Vector3(0, 1, 0);
		p.camera.fovy = 45;
		p.camera.projection = CameraProjection.CAMERA_PERSPECTIVE;
		p.yaw = 0; // facing north, like FreeCamera opens
		p.pitch = 0;
		DisableCursor();
		// Cursor lock warps the pointer. Drop those deltas so the view opens level.
		p.settle = 2;
		return p;
	}

	void update() {
		if (settle > 0) {
			GetMouseDelta();
			settle--;
		} else {
			turn();
			move();
		}
		// Keep the view glued to the new look direction after moving.
		camera.target = Vector3(
			camera.position.x - sin(yaw) * cos(pitch),
			camera.position.y + sin(pitch),
			camera.position.z - cos(yaw) * cos(pitch),
		);
	}

	private void turn() {
		Vector2 delta = GetMouseDelta();
		yaw -= delta.x * mouseSensitivity;
		pitch -= delta.y * mouseSensitivity;
		// Stop just short of straight up or down so forward stays well-defined.
		immutable limit = 1.5707f - 0.01f;
		if (pitch > limit)
			pitch = limit;
		if (pitch < -limit)
			pitch = -limit;
	}

	private void move() {
		// Forward on the ground plane, so looking up does not fly you skyward.
		immutable fx = -sin(yaw);
		immutable fz = -cos(yaw);
		immutable rx = -fz;
		immutable rz = fx;
		float dx = 0, dy = 0, dz = 0;
		if (IsKeyDown(KeyboardKey.KEY_W)) { dx += fx; dz += fz; }
		if (IsKeyDown(KeyboardKey.KEY_S)) { dx -= fx; dz -= fz; }
		if (IsKeyDown(KeyboardKey.KEY_D)) { dx += rx; dz += rz; }
		if (IsKeyDown(KeyboardKey.KEY_A)) { dx -= rx; dz -= rz; }
		if (IsKeyDown(KeyboardKey.KEY_SPACE)) dy += 1;
		if (IsKeyDown(KeyboardKey.KEY_LEFT_SHIFT) || IsKeyDown(KeyboardKey.KEY_RIGHT_SHIFT)) dy -= 1;

		// Diagonal movement should not be faster than straight movement.
		immutable horizontal = sqrt(dx * dx + dz * dz);
		if (horizontal > 1.0f) {
			dx /= horizontal;
			dz /= horizontal;
		}
		immutable step = moveSpeed * GetFrameTime();
		camera.position.x += dx * step;
		camera.position.y += dy * step;
		camera.position.z += dz * step;
	}

	// Strongest axis of the look direction. North is -Z, east is +X, up is +Y.
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
}
