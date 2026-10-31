module player;

import std.math : sin, cos, sqrt;

import raylib;

import chunkSmooth;

// Mouse look and WASD movement, written here. Not raylib's UpdateCamera.
enum float lookSpeed = 0.0025f;
enum float moveSpeed = 4.0f;
enum float pitchLimit = 1.5707f - 0.01f;
// The camera sits this far above the feet. Spawn uses the same offset.
enum float eyeHeight = 2.0f;
enum float gravity = 24.0f;
enum float jumpSpeed = 10.0f;
// A rise taller than this blocks the step. Gentler ground is walked up.
enum float stepHeight = 1.0f;

// One look vector for the camera target and for debug flight.
// Yaw 0, pitch 0 is (0, 0, -1): north. Pitch lifts that vector.
Vector3 lookDirection(float yaw, float pitch) {
	immutable cp = cos(pitch);
	return Vector3(-sin(yaw) * cp, sin(pitch), -cos(yaw) * cp);
}

// Ground forward and right from the same yaw. Yaw 0: forward is -Z, right is +X.
private struct GroundAxes {
	float forwardX;
	float forwardZ;
	float rightX;
	float rightZ;
}

private GroundAxes groundAxes(float yaw) {
	GroundAxes axes;
	axes.forwardX = -sin(yaw);
	axes.forwardZ = -cos(yaw);
	axes.rightX = -axes.forwardZ;
	axes.rightZ = axes.forwardX;
	return axes;
}

// Mouse right turns toward east when facing north. Mouse down looks down.
void turnLook(ref float yaw, ref float pitch, float mouseX, float mouseY) {
	yaw -= mouseX * lookSpeed;
	pitch -= mouseY * lookSpeed;
	if (pitch > pitchLimit)
		pitch = pitchLimit;
	if (pitch < -pitchLimit)
		pitch = -pitchLimit;
}

// forward is W/S, strafe is D/A, vertical is Space/Shift. Yaw faces the ground plane,
// so looking up does not fly you forward. W and D together stay at moveSpeed.
void moveLook(ref Vector3 position, float yaw, float forward, float strafe, float vertical, float dt) {
	GroundAxes axes = groundAxes(yaw);
	float dx = axes.forwardX * forward + axes.rightX * strafe;
	float dz = axes.forwardZ * forward + axes.rightZ * strafe;
	immutable horizontal = sqrt(dx * dx + dz * dz);
	if (horizontal > 1.0f) {
		dx /= horizontal;
		dz /= horizontal;
	}
	immutable step = moveSpeed * dt;
	position.x += dx * step;
	position.y += vertical * step;
	position.z += dz * step;
}

// Height of the ground under a point. The four integer samples are the ones the mesh uses.
float surfaceAt(float x, float z) {
	int x0 = floorInt(x);
	int z0 = floorInt(z);
	float tx = x - cast(float) x0;
	float tz = z - cast(float) z0;
	float h00 = groundHeight(x0, z0);
	float h10 = groundHeight(x0 + 1, z0);
	float h01 = groundHeight(x0, z0 + 1);
	float h11 = groundHeight(x0 + 1, z0 + 1);
	return h00 + (h10 - h00) * tx + (h01 - h00) * tz + (h00 - h10 - h01 + h11) * tx * tz;
}

// Normal movement. WASD stays on the ground plane. Space jumps from the ground.
// Gravity pulls down, and the feet stop on the surface. A tall step is not climbed.
void moveWalk(ref Vector3 position, ref float velocityY, float yaw, float forward, float strafe, bool jump, float dt) {
	float stand = surfaceAt(position.x, position.z) + eyeHeight;
	bool grounded = velocityY <= 0.0f && position.y <= stand + 0.05f;
	Vector3 before = position;
	moveLook(position, yaw, forward, strafe, 0, dt);
	float feet = before.y - eyeHeight;
	if (surfaceAt(position.x, position.z) > feet + stepHeight) {
		position.x = before.x;
		position.z = before.z;
	}
	if (grounded && jump)
		velocityY = jumpSpeed;
	velocityY -= gravity * dt;
	position.y += velocityY * dt;
	float floorY = surfaceAt(position.x, position.z) + eyeHeight;
	if (position.y < floorY) {
		position.y = floorY;
		if (velocityY < 0.0f)
			velocityY = 0.0f;
	}
}

// Debug flight follows the look, including pitch. Strafe uses the same ground right as moveLook.
void moveDebug(ref Vector3 position, float yaw, float pitch, float forward, float strafe, float vertical, float dt) {
	immutable look = lookDirection(yaw, pitch);
	GroundAxes axes = groundAxes(yaw);
	float dx = look.x * forward + axes.rightX * strafe;
	float dy = look.y * forward + vertical;
	float dz = look.z * forward + axes.rightZ * strafe;
	immutable length = sqrt(dx * dx + dy * dy + dz * dz);
	if (length > 1.0f) {
		dx /= length;
		dy /= length;
		dz /= length;
	}
	immutable step = moveSpeed * dt;
	position.x += dx * step;
	position.y += dy * step;
	position.z += dz * step;
}

// Target sits one unit along the look direction. North at yaw 0, pitch 0 is -Z.
void aimLook(ref Camera3D camera, float yaw, float pitch) {
	immutable look = lookDirection(yaw, pitch);
	camera.target = Vector3(
		camera.position.x + look.x,
		camera.position.y + look.y,
		camera.position.z + look.z,
	);
}

// Strongest axis of the look direction. North is -Z, east is +X, up is +Y.
// An exact diagonal keeps the earlier name. 45 degrees up while facing north is NORTH.
string facingOf(Vector3 forward) {
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

// One frame for either camera. The first two calls drop the cursor-lock warp.
// debugMove flies along the look, with no gravity. Otherwise the player walks, falls, and lands.
void stepLook(ref Camera3D camera, ref float yaw, ref float pitch, ref int settle, bool debugMove, ref float velocityY) {
	if (settle > 0) {
		GetMouseDelta();
		settle--;
	} else {
		Vector2 delta = GetMouseDelta();
		turnLook(yaw, pitch, delta.x, delta.y);
		float forward = 0, strafe = 0, vertical = 0;
		if (IsKeyDown(KeyboardKey.KEY_W))
			forward += 1;
		if (IsKeyDown(KeyboardKey.KEY_S))
			forward -= 1;
		if (IsKeyDown(KeyboardKey.KEY_D))
			strafe += 1;
		if (IsKeyDown(KeyboardKey.KEY_A))
			strafe -= 1;
		if (IsKeyDown(KeyboardKey.KEY_SPACE))
			vertical += 1;
		if (IsKeyDown(KeyboardKey.KEY_LEFT_SHIFT) || IsKeyDown(KeyboardKey.KEY_RIGHT_SHIFT))
			vertical -= 1;
		if (debugMove)
			moveDebug(camera.position, yaw, pitch, forward, strafe, vertical, GetFrameTime());
		else
			moveWalk(camera.position, velocityY, yaw, forward, strafe, IsKeyPressed(KeyboardKey.KEY_SPACE), GetFrameTime());
	}
	aimLook(camera, yaw, pitch);
}

// First-person player. The debug FreeCamera calls the same stepLook.
struct Player {
	Camera3D camera;
	private float yaw;
	private float pitch;
	private int settle = 2;
	private bool debugMove;
	private float velocityY;

	static Player create() {
		Player p;
		p.camera.position = Vector3(0, 2.0f / 3.0f, 1.0f / 3.0f + 4);
		p.camera.up = Vector3(0, 1, 0);
		p.camera.fovy = 45;
		p.camera.projection = CameraProjection.CAMERA_PERSPECTIVE;
		p.yaw = 0;
		p.pitch = 0;
		DisableCursor();
		p.settle = 2;
		return p;
	}

	void update() {
		stepLook(camera, yaw, pitch, settle, debugMove, velocityY);
	}

	void setDebugMove(bool enabled) {
		debugMove = enabled;
		velocityY = 0;
	}

	bool debugMovement() {
		return debugMove;
	}

	void showCursor() {
		EnableCursor();
	}

	// Lock the cursor again. The next two look updates drop the warp from that lock.
	void hideCursor() {
		DisableCursor();
		settle = 2;
	}

	string facingLabel() {
		return facingOf(camera.target - camera.position);
	}
}
