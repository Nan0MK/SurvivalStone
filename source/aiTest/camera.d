module aiTest.camera;

import std.conv : to;
import std.math : sin, cos, sqrt;

import raylib;

import chunkQuads;
import chunkSmooth;
import gameDebug.camera;
import gameDebug.hud;
import player;
import terrainQuads;

import aiTest.check;

int checkCamera() {
	Report report;

	void facing(string want, Vector3 position, Vector3 target, string where) {
		FreeCamera view;
		view.camera.position = position;
		view.camera.target = target;
		view.camera.up = Vector3(0, 1, 0);
		report.expect(view.facingLabel() == want, where ~ " -> " ~ view.facingLabel());
	}

	// Same pose FreeCamera.create uses: due south of the work target, looking north.
	Vector3 workTarget = Vector3(0, 2.0f / 3.0f, 1.0f / 3.0f);
	facing("NORTH", Vector3(workTarget.x, workTarget.y, workTarget.z + 4), workTarget, "spawn");
	facing("NORTH", Vector3(0, 0, 4), Vector3(0, 0, 0), "north");
	facing("EAST", Vector3(0, 0, 0), Vector3(4, 0, 0), "east");
	facing("SOUTH", Vector3(0, 0, 0), Vector3(0, 0, 4), "south");
	facing("WEST", Vector3(0, 0, 0), Vector3(-4, 0, 0), "west");
	facing("UP", Vector3(0, 0, 0), Vector3(0, 4, 0), "up");
	facing("DOWN", Vector3(0, 4, 0), Vector3(0, 0, 0), "down");
	// 45 degrees stays on the compass name. Steeper than that becomes up or down.
	facing("NORTH", Vector3(0, 0, 0), Vector3(0, 1, -1), "45 up");
	facing("UP", Vector3(0, 0, 0), Vector3(0, 4, -1), "steep up");
	facing("NORTH", Vector3(0, 0, 0), Vector3(0, -1, -1), "45 down");
	facing("DOWN", Vector3(0, 0, 0), Vector3(0, -4, -1), "steep down");

	// The label comes from the look vector, not from raylib's camera helper.
	Player body;
	body.camera.position = Vector3(0, 0, 4);
	body.camera.target = Vector3(0, 0, 0);
	report.expect(body.facingLabel() == "NORTH", "player faces the same way");

	Camera3D aimed;
	aimed.position = Vector3(0, 0, 4);
	aimLook(aimed, 0, 0);
	report.expect(closeTo(aimed.target.x, 0) && closeTo(aimed.target.y, 0) && closeTo(aimed.target.z, 3), "yaw 0 looks north");
	report.expect(facingOf(aimed.target - aimed.position) == "NORTH", "aimed north");

	Vector3 moved = Vector3(0, 0, 0);
	moveLook(moved, 0, 1, 0, 0, 1);
	report.expect(closeTo(moved.x, 0) && closeTo(moved.y, 0) && closeTo(moved.z, -moveSpeed), "W at yaw 0 goes north");
	moved = Vector3(0, 0, 0);
	moveLook(moved, 0, 0, 1, 0, 1);
	report.expect(closeTo(moved.x, moveSpeed) && closeTo(moved.z, 0), "D at yaw 0 goes east");
	moved = Vector3(0, 0, 0);
	moveLook(moved, 0, 0, 0, 1, 1);
	report.expect(closeTo(moved.y, moveSpeed), "space goes up");
	moved = Vector3(0, 0, 0);
	moveLook(moved, 0, 0, 0, -1, 1);
	report.expect(closeTo(moved.y, -moveSpeed), "shift goes down");
	moved = Vector3(0, 0, 0);
	moveLook(moved, 0, 1, 1, 0, 1);
	immutable diagonal = sqrt(moved.x * moved.x + moved.z * moved.z);
	report.expect(closeTo(diagonal, moveSpeed), "W and D together stay at move speed");

	report.expect(eyeHeight == 2.0f && stepHeight == 1.0f && moveSpeed == 4.0f, "the player keeps its size");
	report.expect(closeTo(surfaceAt(3.5f, 5.25f), quadHeightAt(3.5f, 5.25f)), "the feet use the visible quad ground");
	float jumpReach = jumpSpeed * jumpSpeed / (2.0f * gravity);
	report.expect(gravity >= 64.0f, "gravity pulls the player down hard");
	report.expect(jumpReach > wallSide * 2.0f, "a jump rises past a two-square cliff");

	float fallFrom = surfaceAt(2, 2) + eyeHeight + 30;
	Vector3 falling = Vector3(2, fallFrom, 2);
	float fallSpeed = 0;
	moveWalk(falling, fallSpeed, 0, 0, 0, false, 0.5f);
	report.expect(falling.y < fallFrom && fallSpeed < 0, "gravity pulls the normal player down");

	float floorY = surfaceAt(3, 5) + eyeHeight;
	Vector3 landed = Vector3(3, floorY - 4, 5);
	float landSpeed = -8;
	moveWalk(landed, landSpeed, 0, 0, 0, false, 0.1f);
	report.expect(closeTo(landed.y, surfaceAt(landed.x, landed.z) + eyeHeight), "the player lands on the ground");
	report.expect(closeTo(landSpeed, 0), "landing stops the fall");

	Vector3 jumper = Vector3(3, floorY, 5);
	float jumpSpeedY = 0;
	moveWalk(jumper, jumpSpeedY, 0, 0, 0, true, 0.05f);
	report.expect(jumper.y > floorY && jumpSpeedY > 0, "space jumps from the ground");
	float rising = jumpSpeedY;
	moveWalk(jumper, jumpSpeedY, 0, 0, 0, true, 0.05f);
	report.expect(jumpSpeedY < rising, "gravity slows a jump in the air");

	bool haveCliff = false;
	float standX = 0;
	float standZ = 0;
	int scanZ = -128;
	while (scanZ <= 128 && !haveCliff) {
		int scanX = -64;
		while (scanX < 320 && !haveCliff) {
			float edge = cast(float) scanX + wallSide;
			float z = cast(float) scanZ + 0.5f;
			float low = quadHeightAt(edge - 0.3f, z);
			float high = quadHeightAt(edge + 0.5f, z);
			if (high > low + stepHeight) {
				standX = edge - 0.3f;
				standZ = z;
				haveCliff = true;
			}
			scanX += cast(int) wallSide;
		}
		scanZ += cast(int) wallSide;
	}
	report.expect(haveCliff, "the visible ground has a step taller than a stride");
	if (haveCliff) {
		float standY = surfaceAt(standX, standZ) + eyeHeight;
		Vector3 blocked = Vector3(standX, standY, standZ);
		float blockedSpeed = 0;
		moveWalk(blocked, blockedSpeed, 0, 0, 1, false, 0.2f);
		report.expect(closeTo(blocked.x, standX) && closeTo(blocked.z, standZ), "a tall step stops the normal player");
	}

	float yaw = 0, pitch = 0;
	turnLook(yaw, pitch, 0, 1000);
	report.expect(pitch == -pitchLimit, "look down stops short of straight down");
	yaw = 0;
	pitch = 0;
	turnLook(yaw, pitch, 0, -1000);
	report.expect(pitch == pitchLimit, "look up stops short of straight up");

	// Debug flight uses the look. At pitch 0 that look is the same north vector as moveLook.
	immutable float pitched = 0.5f;
	Vector3 flown = Vector3(0, 0, 0);
	moveDebug(flown, 0, 0, 1, 0, 0, 1);
	report.expect(closeTo(flown.x, 0) && closeTo(flown.y, 0) && closeTo(flown.z, -moveSpeed), "debug W at pitch 0 goes north");
	flown = Vector3(0, 0, 0);
	moveDebug(flown, 0, pitched, 1, 0, 0, 1);
	report.expect(closeTo(flown.x, 0), "pitched debug W stays on x");
	report.expect(closeTo(flown.y, sin(pitched) * moveSpeed), "pitched debug W climbs");
	report.expect(closeTo(flown.z, -cos(pitched) * moveSpeed), "pitched debug W still heads north");
	Vector3 walked = Vector3(0, 0, 0);
	moveLook(walked, 0, 1, 0, 0, 1);
	report.expect(closeTo(walked.y, 0) && closeTo(walked.z, -moveSpeed), "normal W ignores pitch and stays on the ground");
	flown = Vector3(0, 0, 0);
	moveDebug(flown, 0, pitched, 0, 1, 0, 1);
	report.expect(closeTo(flown.x, moveSpeed) && closeTo(flown.y, 0) && closeTo(flown.z, 0), "debug D stays east on the ground");
	flown = Vector3(0, 0, 0);
	moveDebug(flown, 0, pitched, 1, 1, 0, 1);
	immutable flownLength = sqrt(flown.x * flown.x + flown.y * flown.y + flown.z * flown.z);
	report.expect(closeTo(flownLength, moveSpeed), "pitched debug W and D stay at move speed");
	flown = Vector3(0, 0, 0);
	moveDebug(flown, 0, 0, 1, 0, 0, 1, debugFast);
	report.expect(closeTo(flown.x, 0) && closeTo(flown.y, 0) && closeTo(flown.z, -moveSpeed * debugFast), "left ctrl speeds debug flight");

	Camera3D pitchedAim;
	pitchedAim.position = Vector3(0, 0, 4);
	aimLook(pitchedAim, 0, pitched);
	Vector3 aimStep = pitchedAim.target - pitchedAim.position;
	report.expect(closeTo(aimStep.x, 0) && closeTo(aimStep.y, sin(pitched)) && closeTo(aimStep.z, -cos(pitched)), "aim uses the same pitched look");

	Player bodyFlags;
	report.expect(!bodyFlags.debugMovement(), "debug movement starts off");
	bodyFlags.setDebugMove(true);
	report.expect(bodyFlags.debugMovement(), "debug movement turns on");

	PauseMenu menu;
	report.expect(!menu.showNodes, "nodes start off");
	report.expect(menu.renderDistance == chunkRadius && chunkRadius == 20, "render distance starts at 20");
	menu.open = true;
	Rectangle debugRow = menu.debugRowAt(1280, 720);
	Vector2 onDebug = Vector2(debugRow.x + debugRow.width / 2, debugRow.y + debugRow.height / 2);
	report.expect(CheckCollisionPointRec(onDebug, debugRow), "debug row contains its center");
	bool closed = menu.press(onDebug, 1280, 720);
	report.expect(!closed && menu.open && menu.debugMove, "debug row turns movement on");
	closed = menu.press(onDebug, 1280, 720);
	report.expect(!closed && menu.open && !menu.debugMove, "debug row turns movement off");

	Rectangle nodesRow = menu.nodesRowAt(1280, 720);
	Vector2 onNodes = Vector2(nodesRow.x + nodesRow.width / 2, nodesRow.y + nodesRow.height / 2);
	report.expect(!CheckCollisionPointRec(onNodes, debugRow), "nodes row is not the debug row");
	closed = menu.press(onNodes, 1280, 720);
	report.expect(!closed && menu.open && menu.showNodes && !menu.debugMove, "nodes row turns nodes on");
	closed = menu.press(onNodes, 1280, 720);
	report.expect(!closed && menu.open && !menu.showNodes && !menu.debugMove, "nodes row turns nodes off");
	closed = menu.press(onNodes, 1280, 720);
	report.expect(menu.showNodes, "nodes stay on for the distance rows");

	int choice = 0;
	int[6] want = [10, 20, 40, 100, 200, 500];
	while (choice < 6) {
		Rectangle button = menu.renderChoiceAt(choice, 1280, 720);
		Vector2 onChoice = Vector2(button.x + button.width / 2, button.y + button.height / 2);
		report.expect(!CheckCollisionPointRec(onChoice, debugRow), "a distance choice is not the debug row");
		closed = menu.press(onChoice, 1280, 720);
		report.expect(!closed && menu.open && menu.renderDistance == want[choice], "distance choice " ~ to!string(want[choice]));
		choice += 1;
	}
	report.expect(!menu.debugMove, "a distance choice leaves debug movement off");
	report.expect(menu.showNodes, "a distance choice leaves nodes on");

	Rectangle resumeRow = menu.resumeRowAt(1280, 720);
	Vector2 onResume = Vector2(resumeRow.x + 2, resumeRow.y + 2);
	report.expect(!CheckCollisionPointRec(onResume, debugRow), "resume is not the debug row");
	report.expect(!CheckCollisionPointRec(onResume, nodesRow), "resume is not the nodes row");
	closed = menu.press(onResume, 1280, 720);
	report.expect(closed && !menu.open && !menu.debugMove && menu.showNodes, "resume closes the menu");

	menu.open = true;
	closed = menu.press(Vector2(0, 0), 1280, 720);
	report.expect(!closed && menu.open, "a click outside the rows leaves the menu open");
	menu.open = false;
	closed = menu.press(onDebug, 1280, 720);
	report.expect(!closed && !menu.open && !menu.debugMove, "a click does nothing while the menu is closed");

	return report.failed;
}

bool closeTo(float a, float b) {
	float d = a - b;
	return d < 0.001f && d > -0.001f;
}
