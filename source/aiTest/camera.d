module aiTest.camera;

import std.conv : to;
import std.math : sin, cos, sqrt;

import raylib;

import chunkSmooth;
import gameDebug.camera;
import gameDebug.hud;
import player;

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
	report.expect(closeTo(surfaceAt(3.5f, 5.25f), groundHeightAt(3.5f, 5.25f)), "the feet use the same height as the mesh");

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

	int cliff = 0;
	int cliffZ = 0;
	bool haveCliff = false;
	int scanZ = -2048;
	while (scanZ <= 2048 && !haveCliff) {
		int scanX = -4096;
		while (scanX < 4096 && !haveCliff) {
			if (groundHeight(scanX + 8, scanZ) > groundHeight(scanX, scanZ) + stepHeight + 0.5f) {
				int fine = scanX;
				while (fine < scanX + 8) {
					if (groundHeight(fine + 1, scanZ) > groundHeight(fine, scanZ) + stepHeight + 0.5f) {
						cliff = fine;
						cliffZ = scanZ;
						haveCliff = true;
						break;
					}
					fine += 1;
				}
			}
			scanX += 8;
		}
		scanZ += 8;
	}
	report.expect(haveCliff, "the ground has a step taller than a stride");
	if (haveCliff) {
		float standX = cast(float) cliff + 0.1f;
		float standZ = cast(float) cliffZ + 0.05f;
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
	report.expect(menu.renderDistance == chunkRadius && chunkRadius == 20, "render distance starts at 20");
	menu.open = true;
	Rectangle debugRow = menu.debugRowAt(1280, 720);
	Vector2 onDebug = Vector2(debugRow.x + debugRow.width / 2, debugRow.y + debugRow.height / 2);
	report.expect(CheckCollisionPointRec(onDebug, debugRow), "debug row contains its center");
	bool closed = menu.press(onDebug, 1280, 720);
	report.expect(!closed && menu.open && menu.debugMove, "debug row turns movement on");
	closed = menu.press(onDebug, 1280, 720);
	report.expect(!closed && menu.open && !menu.debugMove, "debug row turns movement off");

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

	Rectangle resumeRow = menu.resumeRowAt(1280, 720);
	Vector2 onResume = Vector2(resumeRow.x + 2, resumeRow.y + 2);
	report.expect(!CheckCollisionPointRec(onResume, debugRow), "resume is not the debug row");
	closed = menu.press(onResume, 1280, 720);
	report.expect(closed && !menu.open && !menu.debugMove, "resume closes the menu");

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
