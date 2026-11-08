module aiTest.quads;

import std.math : sqrt;

import raylib;

import chunkQuads;

import aiTest.check;

int checkQuads() {
	Report report;
	GridQuad[] quads = buildDemo();
	report.expect(quads.length == 10, "demo has eight walls and two ramps");

	float cx = 0;
	float cz = 0;
	int samples = 0;
	int i = 0;
	while (i < 8) {
		float[3] a;
		float[3] b;
		bottomEdge(quads[i], a, b);
		cx += a[0] + b[0];
		cz += a[2] + b[2];
		samples += 2;
		i++;
	}
	cx /= samples;
	cz /= samples;

	float firstSide = 0;
	i = 0;
	while (i < 8) {
		GridQuad wall = quads[i];
		GridQuad next = quads[(i + 1) % 8];
		bool cardinal = (i % 2) == 0;
		if (cardinal)
			report.expect(wall.kind == QuadKind.cardinal, "even wall is cardinal");
		else
			report.expect(wall.kind == QuadKind.diagonalWall, "odd wall is a 45 degree wall");
		report.expect(sharedCorners(wall, next) == 2, "walls share one vertical edge");
		report.expect(wallNormalOut(wall, cx, cz), "wall normal points out of the octagon");

		float[3] a;
		float[3] b;
		bottomEdge(wall, a, b);
		float dx = b[0] - a[0];
		float dz = b[2] - a[2];
		float side = sqrt(dx * dx + dz * dz);
		if (i == 0)
			firstSide = side;
		report.expect(near(a[1], 0) && near(b[1], 0), "bottom edge sits on the ground");
		report.expect(near(side, wallSide), "wall width matches the square side");
		report.expect(near(topY(wall), wallSide), "wall height matches the square side");
		report.expect(near(side, firstSide), "every wall is the same length");
		if (cardinal)
			report.expect(near(dx, 0) || near(dz, 0), "cardinal wall runs on an axis");
		else
			report.expect(near(absOf(dx), absOf(dz)) && absOf(dx) > 0.1f, "diagonal wall is 45 degrees");
		i++;
	}

	report.expect(quads[8].kind == QuadKind.ramp, "straight ramp kind");
	report.expect(quads[9].kind == QuadKind.diagonalRamp, "diagonal ramp kind");
	report.expect(sharedCorners(quads[4], quads[8]) == 2, "straight ramp shares the south edge");
	report.expect(sharedCorners(quads[1], quads[9]) == 2, "diagonal ramp shares the northeast edge");
	report.expect(matchedSquare(quads[8]) && slopeIsAxis(quads[8]), "straight ramp is a 45 degree square");
	report.expect(matchedSquare(quads[9]) && slopeIsDiagonal(quads[9]), "diagonal ramp is a 45 degree square");
	report.expect(normalY(quads[8]) > 0, "straight ramp faces up");
	report.expect(normalY(quads[9]) > 0, "diagonal ramp faces up");
	checkNodes(report);
	return report.failed;
}

private void checkNodes(Report report) {
	Vector3[] nodes = chunkNodes(Vector3(1, 2, 3));
	report.expect(nodes.length == 9 * 9 * 9, "a chunk lists every node on the wallSide lattice");
	report.expect(hasNode(nodes, 0, 0, 0), "the chunk origin is a node");
	report.expect(hasNode(nodes, 16, 16, 16), "the far corner is a node");
	report.expect(hasNode(nodes, 2, 4, 6), "an interior wallSide point is a node");
	report.expect(!hasNode(nodes, 1, 0, 0), "nodes step by wallSide");
	report.expect(!hasNode(nodes, 18, 0, 0), "the next chunk's interior is outside this chunk");

	Vector3[] west = chunkNodes(Vector3(-0.1f, -0.1f, -0.1f));
	report.expect(hasNode(west, -16, -16, -16), "the chunk across the origin starts at -16");
	report.expect(hasNode(west, 0, 0, 0), "that chunk includes the shared face at 0");
	report.expect(!hasNode(west, 2, 2, 2), "that chunk stops at the shared face");
}

private bool hasNode(Vector3[] nodes, float x, float y, float z) {
	foreach (node; nodes) {
		if (near(node.x, x) && near(node.y, y) && near(node.z, z))
			return true;
	}
	return false;
}

private bool near(float a, float b) {
	float d = a - b;
	return d < 0.001f && d > -0.001f;
}

private float absOf(float v) {
	if (v < 0)
		return -v;
	return v;
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

private void bottomEdge(GridQuad quad, out float[3] a, out float[3] b) {
	int n = 0;
	foreach (corner; quad.corner) {
		if (!near(corner[1], 0))
			continue;
		if (n == 0)
			a = corner;
		else
			b = corner;
		n++;
	}
}

private float topY(GridQuad quad) {
	float top = 0;
	foreach (corner; quad.corner) {
		if (corner[1] > top)
			top = corner[1];
	}
	return top;
}

private bool wallNormalOut(GridQuad quad, float cx, float cz) {
	float[3] n = faceOut(quad);
	if (!near(n[1], 0))
		return false;
	float[3] a;
	float[3] b;
	bottomEdge(quad, a, b);
	float mx = (a[0] + b[0]) * 0.5f - cx;
	float mz = (a[2] + b[2]) * 0.5f - cz;
	return n[0] * mx + n[2] * mz > 0;
}

private bool slopeEnds(GridQuad quad, out float[3] low0, out float[3] low1, out float[3] offset) {
	float[3][2] low;
	float[3][2] high;
	int lows = 0;
	int highs = 0;
	float lowY = quad.corner[0][1];
	float highY = quad.corner[0][1];
	foreach (corner; quad.corner) {
		if (corner[1] < lowY)
			lowY = corner[1];
		if (corner[1] > highY)
			highY = corner[1];
	}
	foreach (corner; quad.corner) {
		if (near(corner[1], lowY) && lows < 2) {
			low[lows] = corner;
			lows++;
		} else if (near(corner[1], highY) && highs < 2) {
			high[highs] = corner;
			highs++;
		}
	}
	low0 = low[0];
	low1 = low[1];
	offset = [0, 0, 0];
	if (lows != 2 || highs != 2)
		return false;
	offset = [
		(high[0][0] + high[1][0] - low[0][0] - low[1][0]) * 0.5f,
		(high[0][1] + high[1][1] - low[0][1] - low[1][1]) * 0.5f,
		(high[0][2] + high[1][2] - low[0][2] - low[1][2]) * 0.5f,
	];
	return true;
}

private bool matchedSquare(GridQuad quad) {
	float[3] low0;
	float[3] low1;
	float[3] offset;
	if (!slopeEnds(quad, low0, low1, offset))
		return false;
	float ex = low1[0] - low0[0];
	float ez = low1[2] - low0[2];
	float edge = sqrt(ex * ex + ez * ez);
	float run = sqrt(offset[0] * offset[0] + offset[2] * offset[2]);
	float span = sqrt(run * run + offset[1] * offset[1]);
	float dot = ex * offset[0] + ez * offset[2];
	return near(edge, wallSide) && near(span, wallSide) && near(dot, 0) && near(run, offset[1]);
}

private bool slopeIsAxis(GridQuad quad) {
	float[3] low0;
	float[3] low1;
	float[3] offset;
	if (!slopeEnds(quad, low0, low1, offset))
		return false;
	return near(offset[0], 0) || near(offset[2], 0);
}

private bool slopeIsDiagonal(GridQuad quad) {
	float[3] low0;
	float[3] low1;
	float[3] offset;
	if (!slopeEnds(quad, low0, low1, offset))
		return false;
	return absOf(offset[0]) > 0.1f && absOf(offset[2]) > 0.1f;
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
