module aiTest.terrain;

import std.math : sqrt;

import chunkQuads;
import chunkSmooth;
import terrainQuads;

import aiTest.check;

int checkTerrain() {
	Report report;
	checkFlat(report);
	checkRamp(report);
	checkCliff(report);
	checkCliffSouth(report);
	checkCliffEast(report);
	checkWalk(report);
	checkWorld(report);
	return report.failed;
}

private void checkFlat(Report report) {
	int[] posts = [2, 2, 2, 2, 2, 2];
	GridQuad[] quads = meshPosts(posts, 3, 2, 0, 0);
	report.expect(quads.length == 2, "a level patch is one flat quad per cell");
	foreach (quad; quads) {
		report.expect(quad.kind == QuadKind.flat, "level cell is a flat square");
		report.expect(near(sideOf(quad), wallSide), "flat square uses wallSide");
		report.expect(near(quad.corner[0][1], 2 * wallSide), "flat sits on the quantized height");
	}
}

private void checkRamp(Report report) {
	int[] posts = [
		0, 0,
		1, 1,
		1, 1,
	];
	GridQuad[] quads = meshPosts(posts, 2, 3, 0, 0);
	int ramps = 0;
	int flats = 0;
	GridQuad ramp;
	GridQuad flat;
	foreach (quad; quads) {
		if (quad.kind == QuadKind.ramp) {
			ramps++;
			ramp = quad;
		}
		if (quad.kind == QuadKind.flat)
			flats++;
		if (quad.kind == QuadKind.flat && near(quad.corner[0][1], wallSide))
			flat = quad;
	}
	report.expect(ramps == 1, "one step up is one ramp");
	report.expect(flats == 1, "the high side stays a flat square");
	report.expect(sharedCorners(ramp, flat) == 2, "ramp meets the flat along the high edge");
	float run = rampHigh(ramp) - rampLow(ramp);
	report.expect(near(run, wallSide), "terrain ramp rises one grid step");
	report.expect(normalY(ramp) > 0, "terrain ramp faces up");
}

private void checkCliff(Report report) {
	int[] posts = [
		0, 0,
		4, 4,
	];
	GridQuad[] quads = meshPosts(posts, 2, 2, 0, 0);
	int walls = 0;
	int flats = 0;
	float top = 0;
	foreach (quad; quads) {
		if (quad.kind == QuadKind.cardinal) {
			walls++;
			float y = quad.corner[0][1];
			if (quad.corner[1][1] > y)
				y = quad.corner[1][1];
			if (y > top)
				top = y;
		}
		if (quad.kind == QuadKind.flat)
			flats++;
	}
	report.expect(flats == 1, "a cliff keeps a flat floor at the low edge");
	report.expect(walls == 4, "a drop of 4 is four stacked squares");
	report.expect(near(top, 4 * wallSide), "the stack reaches the high posts");
	foreach (quad; quads) {
		if (quad.kind != QuadKind.cardinal)
			continue;
		report.expect(edgeAt(quad, 2, wallSide), "a north-high cliff stands on the north edge");
		report.expect(faceOut(quad)[2] > 0, "a north-high cliff faces the low side");
	}
}

private void checkCliffSouth(Report report) {
	int[] posts = [
		4, 4,
		0, 0,
	];
	GridQuad[] quads = meshPosts(posts, 2, 2, 0, 0);
	int walls = 0;
	foreach (quad; quads) {
		if (quad.kind != QuadKind.cardinal)
			continue;
		walls++;
		report.expect(edgeAt(quad, 2, 0), "a south-high cliff stands on the south edge");
		report.expect(faceOut(quad)[2] < 0, "a south-high cliff faces the low side");
	}
	report.expect(walls == 4, "a south-high drop is four stacked squares");
}

private void checkCliffEast(Report report) {
	int[] posts = [
		0, 3,
		0, 3,
	];
	GridQuad[] quads = meshPosts(posts, 2, 2, 0, 0);
	int walls = 0;
	foreach (quad; quads) {
		if (quad.kind != QuadKind.cardinal)
			continue;
		walls++;
		report.expect(edgeAt(quad, 0, wallSide), "an east-high cliff stands on the east edge");
		report.expect(faceOut(quad)[0] < 0, "an east-high cliff faces the low side");
	}
	report.expect(walls == 3, "a drop of 3 is three stacked squares");
}

private void checkWalk(Report report) {
	report.expect(near(cellSurface(0.4f, 0.6f, 0, 0, 2, 2, 2, 2), 4), "a flat cell is the quantized height");
	report.expect(near(cellSurface(1, 0, 0, 0, 0, 0, 1, 1), 0), "a north ramp starts on the low edge");
	report.expect(near(cellSurface(1, 1, 0, 0, 0, 0, 1, 1), 1), "a north ramp is halfway up at mid-cell");
	report.expect(near(cellSurface(1, 2, 0, 0, 0, 0, 1, 1), wallSide), "a north ramp meets the high edge");
	report.expect(near(cellSurface(1, 0, 0, 0, 1, 1, 0, 0), wallSide), "a south ramp is high on the south edge");
	report.expect(near(cellSurface(0, 1, 0, 0, 0, 1, 0, 1), 0), "an east ramp starts on the low edge");
	report.expect(near(cellSurface(2, 1, 0, 0, 0, 1, 0, 1), wallSide), "an east ramp meets the high edge");
	report.expect(near(cellSurface(0, 1, 0, 0, 1, 0, 1, 0), wallSide), "a west ramp is high on the west edge");
	report.expect(near(cellSurface(1, 1.5f, 0, 0, 0, 0, 4, 4), 0), "a cliff cell is walked on its low floor");
	report.expect(near(cellSurface(0.4f, 1.6f, 0, 0, 0, 2, 1, 3), 2.4f), "a bent cell follows the triangle");

	int[] rampPosts = [0, 0, 1, 1];
	GridQuad[] rampQuads = meshPosts(rampPosts, 2, 2, 0, 0);
	report.expect(rampQuads.length == 1, "the walked ramp is one quad");
	foreach (corner; rampQuads[0].corner)
		report.expect(near(cellSurface(corner[0], corner[2], 0, 0, 0, 0, 1, 1), corner[1]), "the ramp quad matches the walked height");

	int[] cliffPosts = [0, 0, 4, 4];
	GridQuad[] cliffQuads = meshPosts(cliffPosts, 2, 2, 0, 0);
	int floors = 0;
	foreach (quad; cliffQuads) {
		if (quad.kind != QuadKind.flat)
			continue;
		floors++;
		foreach (corner; quad.corner)
			report.expect(near(cellSurface(corner[0], corner[2], 0, 0, 0, 0, 4, 4), corner[1]), "the cliff floor is the walked height");
	}
	report.expect(floors == 1, "the cliff has one walked floor");

	float x = 3.5f;
	float z = -1.25f;
	int cx = floorInt(x / wallSide);
	int cz = floorInt(z / wallSide);
	float ox = cast(float) cx * wallSide;
	float oz = cast(float) cz * wallSide;
	int sw = heightLevel(groundHeightAt(ox, oz));
	int se = heightLevel(groundHeightAt(ox + wallSide, oz));
	int nw = heightLevel(groundHeightAt(ox, oz + wallSide));
	int ne = heightLevel(groundHeightAt(ox + wallSide, oz + wallSide));
	report.expect(near(quadHeightAt(x, z), cellSurface(x, z, ox, oz, sw, se, nw, ne)), "quad height uses the four posts of the cell");
}

private void checkWorld(Report report) {
	GridQuad[] quads = buildTerrain(64, -32, 8, 8);
	report.expect(quads.length >= 64, "a terrain patch has a quad per cell");
	foreach (quad; quads) {
		foreach (corner; quad.corner) {
			float steps = corner[1] / wallSide;
			report.expect(near(steps, cast(float) cast(int)(steps + (steps >= 0 ? 0.5f : -0.5f))), "terrain height stays on the wallSide steps");
		}
	}
}

private bool near(float a, float b) {
	float d = a - b;
	return d < 0.001f && d > -0.001f;
}

private float sideOf(GridQuad quad) {
	float dx = quad.corner[2][0] - quad.corner[1][0];
	float dz = quad.corner[2][2] - quad.corner[1][2];
	return sqrt(dx * dx + dz * dz);
}

private int sharedCorners(GridQuad a, GridQuad b) {
	int count = 0;
	foreach (ca; a.corner) {
		foreach (cb; b.corner) {
			if (near(ca[0], cb[0]) && near(ca[1], cb[1]) && near(ca[2], cb[2]))
				count++;
		}
	}
	return count;
}

private float rampLow(GridQuad quad) {
	float y = quad.corner[0][1];
	foreach (corner; quad.corner) {
		if (corner[1] < y)
			y = corner[1];
	}
	return y;
}

private float rampHigh(GridQuad quad) {
	float y = quad.corner[0][1];
	foreach (corner; quad.corner) {
		if (corner[1] > y)
			y = corner[1];
	}
	return y;
}

private float normalY(GridQuad quad) {
	return faceOut(quad)[1];
}

private float[3] faceOut(GridQuad quad) {
	float[3] a = quad.corner[0];
	float[3] b = quad.corner[1];
	float[3] c = quad.corner[2];
	float bx = b[0] - a[0];
	float by = b[1] - a[1];
	float bz = b[2] - a[2];
	float cx = c[0] - a[0];
	float cy = c[1] - a[1];
	float cz = c[2] - a[2];
	return [
		by * cz - bz * cy,
		bz * cx - bx * cz,
		bx * cy - by * cx,
	];
}

private bool edgeAt(GridQuad quad, int axis, float value) {
	foreach (corner; quad.corner) {
		if (!near(corner[axis], value))
			return false;
	}
	return true;
}
