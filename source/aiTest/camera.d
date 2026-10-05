module aiTest.camera;

import raylib;

import gameDebug.camera;

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
	return report.failed;
}
