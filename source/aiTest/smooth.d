module aiTest.smooth;

import std.conv : to;

import raylib;

import chunkSmooth;
import material;

import aiTest.check;

bool near(float a, float b) {
	float d = a - b;
	return d < 0.001f && d > -0.001f;
}

bool skirtHangs(ChunkSmooth* chunk, float plane, int axis, float outwardSign) {
	foreach(tri; chunk.triangles) {
		Vector3[3] p = [tri.a, tri.b, tri.c];
		int i = 0;
		while(i < 3) {
			int j = i + 1;
			while(j < 3) {
				float dy = p[i].y - p[j].y;
				if(dy < 0.0f)
					dy = -dy;
				float xi = p[i].x;
				float xj = p[j].x;
				if(axis == 1) {
					xi = p[i].z;
					xj = p[j].z;
				}
				if(dy > skirtDrop - 1.0f && near(xi, plane) && near(xj, plane)) {
					Vector3 nrm = faceNormal(tri.a, tri.b, tri.c);
					float side = nrm.x;
					if(axis == 1)
						side = nrm.z;
					if(side * outwardSign > 0.0f)
						return true;
				}
				j += 1;
			}
			i += 1;
		}
	}
	return false;
}

bool inBox(SmoothTriangle tri, float x0, float y0, float z0, float x1, float y1, float z1) {
	float[3] xs = [tri.a.x, tri.b.x, tri.c.x];
	float[3] ys = [tri.a.y, tri.b.y, tri.c.y];
	float[3] zs = [tri.a.z, tri.b.z, tri.c.z];
	int i = 0;
	while(i < 3) {
		if(xs[i] < x0 || xs[i] > x1 || ys[i] < y0 || ys[i] > y1 || zs[i] < z0 || zs[i] > z1)
			return false;
		i += 1;
	}
	return true;
}

Vector3 cross(Vector3 u, Vector3 v) {
	return Vector3(
		u.y * v.z - u.z * v.y,
		u.z * v.x - u.x * v.z,
		u.x * v.y - u.y * v.x,
	);
}

void fillOutside(ref ChunkSmooth chunk) {
	int air = getMaterialID(MaterialType.AIR);
	int y = 0;
	while(y < chunk.sampleCount) {
		int z = 0;
		while(z < chunk.sampleCount) {
			int x = 0;
			while(x < chunk.sampleCount) {
				chunk.setSample(x, y, z, air, -1.0f);
				x += 1;
			}
			z += 1;
		}
		y += 1;
	}
}

void checkSeed(Report report) {
	float before = groundHeightAt(10.0f, 20.0f);
	scope (exit)
		setTerrainSeed(defaultTerrainSeed);
	setTerrainSeed(1);
	report.expect(!near(before, groundHeightAt(10.0f, 20.0f)), "a new seed moves the hills");
	setTerrainSeed(defaultTerrainSeed);
	report.expect(near(before, groundHeightAt(10.0f, 20.0f)), "the check seed brings the hills back");
	report.expect(buildPerm(1) != buildPerm(defaultTerrainSeed), "two seeds build different shuffles");
}

int checkSmooth() {
	Report report;
	checkSeed(report);

	int air = getMaterialID(MaterialType.AIR);
	int dirt = getMaterialID(MaterialType.DIRT);
	int rock = getMaterialID(MaterialType.ROCK);
	report.expect(air == 0 && dirt == 1 && rock == 2, "material ids");
	report.expect(!materialIsSolid(air) && materialIsSolid(dirt) && materialIsSolid(rock), "solid");
	report.expect(getMaterialColor(dirt) == Colors.BROWN, "dirt is brown");
	report.expect(getMaterialColor(rock) == Colors.GRAY, "rock is gray");
	report.expect(getMaterialColor(air).a == 0, "air has no color");

	Vector3 mid = vertexInterp(0.0f, Vector3(0, 0, 0), Vector3(2, 0, 0), 2.0f, -2.0f);
	report.expect(near(mid.x, 1.0f) && near(mid.y, 0) && near(mid.z, 0), "interp midpoint");
	Vector3 onIso = vertexInterp(0.0f, Vector3(4, 1, 2), Vector3(9, 9, 9), 0.0f, 3.0f);
	report.expect(near(onIso.x, 4) && near(onIso.y, 1) && near(onIso.z, 2), "interp on isolevel");

	ChunkSmooth* empty = ChunkSmooth.create();
	report.expect(empty.chunkSize == 16, "a chunk stays 16 units");
	report.expect(empty.meshResolution == 2 && empty.cubeCount == 32, "two cubes in each unit");
	report.expect(near(empty.sampleStep, 0.5f), "a cube is half a unit");
	report.expect(empty.sampleCount == empty.cubeCount + 1, "one sample past the cubes");
	report.expect(empty.materials.length == empty.sampleCount * empty.sampleCount * empty.sampleCount, "sample volume");
	int last = empty.sampleCount - 1;
	report.expect(empty.sampleIndex(0, 0, 0) == 0, "first sample");
	report.expect(empty.sampleIndex(last, last, last) == empty.materials.length - 1, "last sample");
	report.expect(empty.sampleIndex(1, 2, 3) == 1 + 2 * empty.sampleCount + 3 * empty.sampleCount * empty.sampleCount, "index order");
	empty.buildMesh();
	report.expect(empty.triangles.length == 0, "default grid is empty");

	// Only sample (0,0,0) is inside. One triangle, facing away from that corner.
	ChunkSmooth* one = ChunkSmooth.create();
	one.setSample(0, 0, 0, dirt, 1.0f);
	int n = 1;
	while(n < 8) {
		one.setSample(cornerOffset[n][0], cornerOffset[n][1], cornerOffset[n][2], air, -1.0f);
		n += 1;
	}
	one.buildMesh();
	report.expect(one.triangles.length == 1, "one corner " ~ to!string(one.triangles.length));
	if(one.triangles.length == 1) {
		SmoothTriangle tri = one.triangles[0];
		report.expect(tri.color == Colors.BROWN, "one corner is dirt");
		float edge = one.sampleStep * 0.5f;
		report.expect(near(tri.a.x, edge) && near(tri.a.y, 0) && near(tri.a.z, 0), "edge 0");
		report.expect(near(tri.b.x, 0) && near(tri.b.y, edge) && near(tri.b.z, 0), "edge 8");
		report.expect(near(tri.c.x, 0) && near(tri.c.y, 0) && near(tri.c.z, edge), "edge 3");
		Vector3 nrm = cross(tri.b - tri.a, tri.c - tri.a);
		report.expect(nrm.x > 0 && nrm.y > 0 && nrm.z > 0, "normal leaves the solid corner");
	}

	// Two heights, both materials. The closer solid sample picks the color, not the height.
	ChunkSmooth* mats = ChunkSmooth.create();
	fillOutside(*mats);
	int highSample = cast(int)(10.0f / mats.sampleStep);
	mats.setSample(0, 0, 0, dirt, 0.25f);
	mats.setSample(1, 0, 0, rock, 5.0f);
	mats.setSample(0, highSample, 0, rock, 0.25f);
	mats.setSample(1, highSample, 0, dirt, 5.0f);
	mats.buildMesh();

	int lowDirt = 0;
	int lowRock = 0;
	int highDirt = 0;
	int highRock = 0;
	int other = 0;
	float cell = mats.sampleStep;
	foreach(tri; mats.triangles) {
		if(inBox(tri, -0.01f, -0.01f, -0.01f, cell + 0.01f, cell + 0.01f, cell + 0.01f)) {
			if(tri.color == Colors.BROWN)
				lowDirt += 1;
			else
				lowRock += 1;
		} else if(inBox(tri, -0.01f, 9.99f, -0.01f, cell + 0.01f, 10.0f + cell + 0.01f, cell + 0.01f)) {
			if(tri.color == Colors.GRAY)
				highRock += 1;
			else
				highDirt += 1;
		} else if(tri.color == Colors.BROWN || tri.color == Colors.GRAY) {
			other += 1;
		} else {
			report.expect(false, "color is not a material");
		}
	}
	report.expect(lowDirt > 0 && lowRock == 0, "low cube is dirt " ~ to!string(lowDirt));
	report.expect(highRock > 0 && highDirt == 0, "high cube is rock " ~ to!string(highRock));
	report.expect(other > 0, "the other solid sample has its own triangles");

	// A flat dirt sheet. The surface sits on y = 4 and faces up.
	ChunkSmooth* flat = ChunkSmooth.create();
	int y = 0;
	while(y < flat.sampleCount) {
		int z = 0;
		while(z < flat.sampleCount) {
			int x = 0;
			while(x < flat.sampleCount) {
				float d = 4.0f - cast(float)y * flat.sampleStep;
				int id = air;
				if(d > flat.isolevel)
					id = dirt;
				flat.setSample(x, y, z, id, d);
				x += 1;
			}
			z += 1;
		}
		y += 1;
	}
	flat.buildMesh();
	report.expect(flat.triangles.length == flat.cubeCount * flat.cubeCount * 2, "flat count " ~ to!string(flat.triangles.length));
	int flatBad = 0;
	foreach(tri; flat.triangles) {
		Vector3 nrm = cross(tri.b - tri.a, tri.c - tri.a);
		if(!near(tri.a.y, 4) || !near(tri.b.y, 4) || !near(tri.c.y, 4) || tri.color != Colors.BROWN || nrm.y <= 0)
			flatBad += 1;
	}
	report.expect(flatBad == 0, "flat dirt sheet " ~ to!string(flatBad));

	ChunkSmooth* terrain = ChunkSmooth.create();
	int surfaceY = chunkCoord(terrain.terrainHeight(8, 8), 16) * 16;
	terrain.origin = Vector3(0, surfaceY, 0);
	terrain.populateTerrain();
	ChunkSmooth* again = ChunkSmooth.create();
	report.expect(near(terrain.terrainHeight(4, 7), again.terrainHeight(4, 7)), "height is stable");
	report.expect(near(perlin2(0.0f, 0.0f), 0.0f) && near(perlin2(3.0f, 5.0f), 0.0f), "perlin is 0 on whole numbers");
	float ledgePeak = 0.18f / 3.0f;
	report.expect(near(ledgeWave(0.0f), 0.0f), "a ledge starts at the bottom of the rise");
	report.expect(near(ledgeWave(ledgePeak), 8.0f), "the rise reaches the top of the ledge");
	report.expect(ledgeWave(0.5f / 3.0f) < 6.0f, "after the rise the ledge slopes down");
	float risePer = 8.0f / ledgePeak;
	float fallSpan = (1.0f / 3.0f) - ledgePeak;
	float fallPer = 8.0f / fallSpan;
	report.expect(risePer > fallPer * 2.0f, "the ledge rise is steeper than the slope down");
	float rangeRiseEnd = 0.02f;
	float rangeDropRun = rangeRiseEnd * (75.0f / 300.0f) * 1.25f;
	float rangeDropEnd = rangeRiseEnd + rangeDropRun;
	report.expect(near(rangeWave(0.0f), 0.0f), "a range starts on the plain");
	report.expect(near(rangeWave(rangeRiseEnd), 300.0f), "the steep side climbs hundreds");
	float shoulder = rangeWave(rangeDropEnd);
	report.expect(300.0f - shoulder > 50.0f && 300.0f - shoulder < 100.0f, "the next slope drops 50 to 100");
	float rangeRiseSlope = 300.0f / rangeRiseEnd;
	float rangeDropSlope = (300.0f - shoulder) / rangeDropRun;
	float rangeTailSlope = shoulder / (1.0f - rangeDropEnd);
	report.expect(rangeDropSlope < rangeRiseSlope && rangeDropSlope > rangeRiseSlope * 0.7f, "that drop is a little less steep than the climb");
	report.expect(rangeTailSlope * 5.0f < rangeDropSlope, "the rest slopes gradually back to the plain");
	report.expect(near(rangeWave(1.0f), 0.0f), "a range ends on the plain");

	float lowH = float.max;
	float highH = -float.max;
	int sameAsDome = 0;
	int columns = 0;
	int materialBad = 0;
	int z = 0;
	while(z < terrain.sampleCount) {
		int x = 0;
		while(x < terrain.sampleCount) {
			float wx = cast(float)x * terrain.sampleStep;
			float wz = cast(float)z * terrain.sampleStep;
			float h = groundHeightAt(wx, wz);
			report.expect(near(h, altitudeAt(wx, wz) + rangesAt(wx, wz) + ledgesAt(wx, wz) + detailAt(wx, wz)), "height is altitude, ranges, ledges, then detail");
			if(h < lowH)
				lowH = h;
			if(h > highH)
				highH = h;
			float dx = wx - 8.0f;
			float dz = wz - 8.0f;
			float dome = 5.0f - (dx * dx + dz * dz) * 0.04f;
			if(dome < 1.0f)
				dome = 1.0f;
			if(near(h, dome))
				sameAsDome += 1;
			columns += 1;

			int sy = 0;
			while(sy < terrain.sampleCount) {
				float wy = cast(float)surfaceY + cast(float)sy * terrain.sampleStep;
				float d = h - wy;
				int want = air;
				if(d > terrain.isolevel)
					want = terrainMaterial(wx, wy, wz);
				int i = terrain.sampleIndex(x, sy, z);
				if(terrain.materials[i] != want || !near(terrain.density[i], d))
					materialBad += 1;
				sy += 1;
			}
			x += 1;
		}
		z += 1;
	}
	report.expect(highH - lowH > 1.0f, "noise changes the height " ~ to!string(highH - lowH));
	report.expect(sameAsDome < columns, "height is not the dome");
	report.expect(materialBad == 0, "samples follow the noise " ~ to!string(materialBad));

	int dirtCols = 0;
	int rockCols = 0;
	int scanX = -80;
	while(scanX <= 160) {
		float h = terrain.terrainHeight(scanX, 20);
		int groundY = floorInt(h);
		if(h - cast(float)groundY == 0)
			groundY -= 1;
		if(terrainMaterial(scanX, groundY, 20) == dirt)
			dirtCols += 1;
		else
			rockCols += 1;
		scanX += 1;
	}
	float spanLo = float.max;
	float spanHi = -float.max;
	int spanX = 0;
	while(spanX <= 200 * 16) {
		float h = terrain.terrainHeight(spanX, 20);
		if(h < spanLo)
			spanLo = h;
		if(h > spanHi)
			spanHi = h;
		spanX += 16;
	}
	report.expect(spanHi - spanLo > 16.0f, "the land is taller than one chunk " ~ to!string(spanHi - spanLo));
	float altLo = float.max;
	float altHi = -float.max;
	float altChunk = 0.0f;
	float climbed = 0.0f;
	float dropped = 0.0f;
	float prevAlt = altitudeAt(0.0f, 20.0f);
	int farX = 16;
	while(farX <= 1600 * 16) {
		float alt = altitudeAt(cast(float)farX, 20.0f);
		if(alt < altLo)
			altLo = alt;
		if(alt > altHi)
			altHi = alt;
		float step = alt - prevAlt;
		if(step >= 0.0f)
			climbed += step;
		else
			dropped -= step;
		float across = step;
		if(across < 0.0f)
			across = -across;
		if(across > altChunk)
			altChunk = across;
		prevAlt = alt;
		farX += 16;
	}
	report.expect(altChunk < 4.0f, "altitude changes gradually across one chunk " ~ to!string(altChunk));
	report.expect(altHi - altLo > 64.0f, "altitude has higher highs and lower lows " ~ to!string(altHi - altLo));
	report.expect(climbed > 16.0f && dropped > 16.0f, "altitude rises and falls over hundreds of chunks " ~ to!string(climbed) ~ " " ~ to!string(dropped));

	float face = 0.0f;
	float tall = 0.0f;
	int faceZ = -800;
	while(faceZ <= 800) {
		int faceX = -800;
		float prevFace = rangesAt(cast(float)faceX, cast(float)faceZ);
		if(prevFace > tall)
			tall = prevFace;
		while(faceX < 800) {
			float h = rangesAt(cast(float)(faceX + 8), cast(float)faceZ);
			if(h > tall)
				tall = h;
			float step = h - prevFace;
			if(step > face)
				face = step;
			prevFace = h;
			faceX += 8;
		}
		faceZ += 16;
	}
	report.expect(tall > 200.0f, "a range climbs hundreds " ~ to!string(tall));
	report.expect(face > 60.0f, "the climb is a steep face " ~ to!string(face));

	float intenseLo = float.max;
	float intenseHi = -float.max;
	int intenseX = 0;
	while(intenseX <= 8000) {
		float intense = detailIntensityAt(cast(float)intenseX, 20.0f);
		if(intense < intenseLo)
			intenseLo = intense;
		if(intense > intenseHi)
			intenseHi = intense;
		intenseX += 16;
	}
	float quietMax = 0.0f;
	float loudMax = 0.0f;
	float lowBand = intenseLo + (intenseHi - intenseLo) * 0.25f;
	float highBand = intenseLo + (intenseHi - intenseLo) * 0.75f;
	intenseX = 0;
	while(intenseX <= 8000) {
		float intense = detailIntensityAt(cast(float)intenseX, 20.0f);
		float bump = detailAt(cast(float)intenseX, 20.0f);
		if(bump < 0.0f)
			bump = -bump;
		if(intense <= lowBand && bump > quietMax)
			quietMax = bump;
		if(intense >= highBand && bump > loudMax)
			loudMax = bump;
		intenseX += 16;
	}
	report.expect(intenseLo >= 0.0f && intenseHi <= 1.0f, "detail intensity stays between 0 and 1");
	report.expect(intenseHi - intenseLo > 0.5f, "detail intensity rises and falls " ~ to!string(intenseHi - intenseLo));
	report.expect(loudMax > quietMax * 2.0f && loudMax > 0.2f, "detail is quieter where intensity is low " ~ to!string(quietMax) ~ " " ~ to!string(loudMax));

	float chanceLo = float.max;
	float chanceHi = -float.max;
	float ledgeIntenseLo = float.max;
	float ledgeIntenseHi = -float.max;
	int ledgeX = 0;
	while(ledgeX <= 8000) {
		float chance = ledgeChanceAt(cast(float)ledgeX, 30.0f);
		float ledgeIntense = ledgeIntensityAt(cast(float)ledgeX, 30.0f);
		if(chance < chanceLo)
			chanceLo = chance;
		if(chance > chanceHi)
			chanceHi = chance;
		if(ledgeIntense < ledgeIntenseLo)
			ledgeIntenseLo = ledgeIntense;
		if(ledgeIntense > ledgeIntenseHi)
			ledgeIntenseHi = ledgeIntense;
		ledgeX += 16;
	}
	report.expect(chanceLo >= 0.0f && chanceHi <= 1.0f, "ledge chance stays between 0 and 1");
	report.expect(chanceHi - chanceLo > 0.5f, "ledge chance rises and falls " ~ to!string(chanceHi - chanceLo));
	report.expect(ledgeIntenseLo >= 0.0f && ledgeIntenseHi <= 1.0f, "ledge intensity stays between 0 and 1");
	report.expect(ledgeIntenseHi - ledgeIntenseLo > 0.5f, "ledge intensity rises and falls " ~ to!string(ledgeIntenseHi - ledgeIntenseLo));
	int scaledLedge = 0;
	ledgeX = 0;
	while(ledgeX <= 8000 && scaledLedge == 0) {
		float shape = ledgeShapeAt(cast(float)ledgeX, 30.0f);
		if(shape > 4.0f) {
			float scaled = shape * ledgeIntensityAt(cast(float)ledgeX, 30.0f) * ledgeChanceAt(cast(float)ledgeX, 30.0f);
			report.expect(near(ledgesAt(cast(float)ledgeX, 30.0f), scaled), "a ledge is scaled by intensity and chance");
			scaledLedge = 1;
		}
		ledgeX += 4;
	}
	report.expect(scaledLedge == 1, "a ledge rises on the scan");
	float wideStep = 0.0f;
	int steepSpans = 0;
	int wideN = 0;
	int wideZ = -2048;
	while(wideZ <= 2048) {
		float prevWide = ledgesAt(-4096.0f, cast(float)wideZ);
		int wideX = -4096;
		while(wideX < 4096) {
			float ledge = ledgesAt(cast(float)(wideX + 8), cast(float)wideZ);
			float jump = ledge - prevWide;
			if(jump < 0.0f)
				jump = -jump;
			if(jump > 2.0f) {
				steepSpans += 1;
				float prevFine = prevWide;
				int fine = wideX + 1;
				while(fine <= wideX + 8) {
					float here = ledgesAt(cast(float)fine, cast(float)wideZ);
					float step = here - prevFine;
					if(step < 0.0f)
						step = -step;
					if(step > wideStep)
						wideStep = step;
					prevFine = here;
					fine += 1;
				}
			}
			wideN += 1;
			prevWide = ledge;
			wideX += 8;
		}
		wideZ += 64;
	}
	report.expect(wideStep > 1.0f, "a ledge still rises " ~ to!string(wideStep));
	report.expect(steepSpans > 0 && steepSpans * 10 < wideN, "ledges stay spread out " ~ to!string(steepSpans) ~ " " ~ to!string(wideN));
	report.expect(dirtCols > 0 && rockCols > 0, "perlin picks both materials");

	int dirtTris = 0;
	int rockTris = 0;
	int offGrid = 0;
	float minY = float.max;
	float maxY = -float.max;
	foreach(tri; terrain.triangles) {
		if(tri.color == Colors.BROWN)
			dirtTris += 1;
		else if(tri.color == Colors.GRAY)
			rockTris += 1;
		else
			report.expect(false, "terrain color is not a material");
		float[3] ys = [tri.a.y, tri.b.y, tri.c.y];
		int k = 0;
		while(k < 3) {
			if(ys[k] < minY)
				minY = ys[k];
			if(ys[k] > maxY)
				maxY = ys[k];
			float whole = cast(float)cast(int)ys[k];
			float frac = ys[k] - whole;
			if(frac < 0)
				frac = -frac;
			if(frac > 0.05f && frac < 0.95f)
				offGrid += 1;
			k += 1;
		}
	}
	report.expect(dirtTris > 0 && rockTris > 0, "both materials reach the surface");
	report.expect(maxY - minY > 1.0f, "the surface is not a flat sheet");
	report.expect(offGrid > 0, "vertices land between the samples");

	Color toward = shadeColor(Colors.GRAY, sunDirection);
	Color away = shadeColor(Colors.GRAY, Vector3(-sunDirection.x, -sunDirection.y, -sunDirection.z));
	Color upward = shadeColor(Colors.BROWN, Vector3(0, 1, 0));
	Color downward = shadeColor(Colors.BROWN, Vector3(0, -1, 0));
	report.expect(toward == Colors.GRAY, "a face aimed at the sun keeps the material color");
	report.expect(away.r == scaleChannel(Colors.GRAY.r, 0.35f), "a face turned away is the ambient fraction");
	report.expect(away.r > 0, "the dark side stays visible");
	report.expect(upward.r > downward.r && upward.g > downward.g, "up is brighter than down");
	report.expect(shadeColor(Colors.BROWN, Vector3(0, 1, 0)) != shadeColor(Colors.GRAY, Vector3(0, 1, 0)), "light keeps dirt and rock apart");

	report.expect(chunkCoord(0, 16) == 0 && chunkCoord(15.9f, 16) == 0, "positions 0 through 15 share a chunk");
	report.expect(chunkCoord(16, 16) == 1, "16 starts the next chunk");
	report.expect(chunkCoord(-0.1f, 16) == -1, "just west of 0 is chunk -1");
	report.expect(chunkCoord(-16.0f, 16) == -1, "-16 stays in chunk -1");
	report.expect(chunkCoord(-16.1f, 16) == -2, "past -16 is chunk -2");

	ChunkSmooth* left = ChunkSmooth.create();
	ChunkSmooth* right = ChunkSmooth.create();
	left.origin = Vector3(-16, 0, 0);
	right.origin = Vector3(0, 0, 0);
	left.populateTerrain();
	right.populateTerrain();
	int seamBad = 0;
	int seamY = 0;
	while(seamY < left.sampleCount) {
		int seamZ = 0;
		while(seamZ < left.sampleCount) {
			int il = left.sampleIndex(left.sampleCount - 1, seamY, seamZ);
			int ir = right.sampleIndex(0, seamY, seamZ);
			if(!near(left.density[il], right.density[ir]) || left.materials[il] != right.materials[ir])
				seamBad += 1;
			seamZ += 1;
		}
		seamY += 1;
	}
	report.expect(seamBad == 0, "chunks share the face at x = 0 " ~ to!string(seamBad));

	float aboveTop = groundHeightAt(0, 0);
	float aboveX = 0;
	while(aboveX <= 16.0f) {
		float aboveZ = 0;
		while(aboveZ <= 16.0f) {
			float column = groundHeightAt(aboveX, aboveZ);
			if(column > aboveTop)
				aboveTop = column;
			aboveZ += terrain.sampleStep;
		}
		aboveX += terrain.sampleStep;
	}
	ChunkSmooth* above = ChunkSmooth.create();
	above.origin = Vector3(0, (chunkCoord(aboveTop, 16) + 1) * 16, 0);
	above.populateTerrain();
	report.expect(above.triangles.length == 0, "a chunk above the ground is empty");

	ChunkSmooth* nextColumn = ChunkSmooth.create();
	float columnH = nextColumn.terrainHeight(38, 0);
	int columnY = floorInt(columnH);
	if(columnH - cast(float)columnY == 0)
		columnY -= 1;
	int columnChunkY = chunkCoord(columnH, 16) * 16;
	nextColumn.origin = Vector3(32, columnChunkY, 0);
	nextColumn.populateTerrain();
	int sampleX = cast(int)(6.0f / nextColumn.sampleStep);
	int sampleY = cast(int)(cast(float)(columnY - columnChunkY) / nextColumn.sampleStep);
	int columnI = nextColumn.sampleIndex(sampleX, sampleY, 0);
	report.expect(nextColumn.density[columnI] > 0 && nextColumn.density[columnI] <= 1.0f, "the sample under the surface");
	report.expect(nextColumn.materials[columnI] == terrainMaterial(38, columnY, 0), "material comes from the noise");

	ChunkWorld* world = new ChunkWorld();
	report.expect(chunkRadius == 20 && world.radius == chunkRadius, "default render distance is 20 chunks");
	world.radius = 2;
	Vector3 homePos = Vector3(0, 2, 0);
	world.update(homePos);

	int homeY0;
	int homeY1;
	surfaceLayers(0, 0, 16, homeY0, homeY1);
	int py = chunkCoord(homePos.y, 16);
	int firstY = homeY0;
	int firstD = homeY0 - py;
	if(firstD < 0)
		firstD = -firstD;
	int layerPick = homeY0 + 1;
	while(layerPick <= homeY1) {
		int yd = layerPick - py;
		if(yd < 0)
			yd = -yd;
		if(yd < firstD || (yd == firstD && layerPick < firstY)) {
			firstD = yd;
			firstY = layerPick;
		}
		layerPick += 1;
	}
	ChunkSmooth* home = world.findChunk(0, firstY, 0);
	report.expect(home !is null, "the first update loads the nearest chunk");
	report.expect(world.loadedCount() == 1, "the first update loads one chunk");
	if(home is null)
		return report.failed;
	int otherLayer = homeY0;
	while(otherLayer <= homeY1) {
		if(otherLayer != firstY)
			report.expect(world.findChunk(0, otherLayer, 0) is null, "the other layer waits");
		otherLayer += 1;
	}

	world.update(homePos);
	report.expect(world.loadedCount() == 2, "the next update loads one more chunk");

	int farY0;
	int farY1;
	surfaceLayers(2, 2, 16, farY0, farY1);
	report.expect(world.findChunk(2, farY0, 2) is null, "the far corner waits");
	int nearY0;
	int nearY1;
	surfaceLayers(-2, 0, 16, nearY0, nearY1);
	int guard = 0;
	while(guard < 500 && (world.findChunk(2, farY0, 2) is null || world.findChunk(-2, nearY0, 0) is null)) {
		world.update(homePos);
		guard += 1;
	}
	int layer = homeY0;
	while(layer <= homeY1) {
		report.expect(world.findChunk(0, layer, 0) !is null, "a surface layer is loaded");
		layer += 1;
	}
	report.expect(world.findChunk(0, homeY1 + 1, 0) is null, "the air above the column is not loaded");
	report.expect(world.findChunk(2, farY0, 2) !is null, "the far corner");
	int pastY0;
	int pastY1;
	surfaceLayers(3, 0, 16, pastY0, pastY1);
	report.expect(world.findChunk(3, pastY0, 0) is null, "one step past the radius");
	report.expect(world.findChunk(-2, nearY0, 0) !is null, "the near edge");

	int settled = world.loadedCount();
	int calm = 0;
	int settleGuard = 0;
	while(calm < 2 && settleGuard < 500) {
		world.update(homePos);
		int now = world.loadedCount();
		if(now == settled)
			calm += 1;
		else {
			settled = now;
			calm = 0;
		}
		settleGuard += 1;
	}
	world.radius = 1;
	world.update(homePos);
	report.expect(world.findChunk(2, farY0, 2) is null, "a shorter distance drops the far corner");
	report.expect(home !is null && world.findChunk(0, firstY, 0) !is null, "a shorter distance keeps the player chunk");
	int shrunk = world.loadedCount();
	world.radius = 2;
	world.update(homePos);
	report.expect(world.loadedCount() == shrunk + 1, "a wider distance loads one more chunk");
	settled = world.loadedCount();
	calm = 0;
	settleGuard = 0;
	while(calm < 2 && settleGuard < 500) {
		world.update(homePos);
		int loadedNow = world.loadedCount();
		if(loadedNow == settled)
			calm += 1;
		else {
			settled = loadedNow;
			calm = 0;
		}
		settleGuard += 1;
	}

	home.triangles.length = 0;
	world.update(Vector3(10, 2, 5));
	report.expect(home.triangles.length == 0, "the same chunk is not rebuilt");
	report.expect(world.loadedCount() == settled, "the same column loads nothing new");
	world.update(Vector3(16, 2, 5));
	report.expect(world.findChunk(-2, nearY0, 0) is null, "a chunk behind the player is dropped");
	int aheadY0;
	int aheadY1;
	surfaceLayers(3, 0, 16, aheadY0, aheadY1);
	int aheadGuard = 0;
	while(world.findChunk(3, aheadY0, 0) is null && aheadGuard < 500) {
		world.update(Vector3(16, 2, 5));
		aheadGuard += 1;
	}
	report.expect(world.findChunk(3, aheadY0, 0) !is null, "a chunk ahead of the player is added");
	report.expect(home.triangles.length == 0, "a chunk that stayed loaded was not rebuilt");

	report.expect(lodCells(0) == 32 && lodCells(2) == 32, "nearby chunks stay at half-unit cells");
	report.expect(lodCells(3) == 16 && lodCells(6) == 16, "middle chunks use one-unit cells");
	report.expect(lodCells(7) == 8, "far chunks use two-unit cells");

	ChunkSmooth* sheet = ChunkSmooth.create(16);
	int sheetY = 0;
	while(sheetY < sheet.sampleCount) {
		int sheetZ = 0;
		while(sheetZ < sheet.sampleCount) {
			int sheetX = 0;
			while(sheetX < sheet.sampleCount) {
				float d = 4.0f - cast(float)sheetY * sheet.sampleStep;
				int id = air;
				if(d > sheet.isolevel)
					id = dirt;
				sheet.setSample(sheetX, sheetY, sheetZ, id, d);
				sheetX += 1;
			}
			sheetZ += 1;
		}
		sheetY += 1;
	}
	sheet.buildMesh();
	int plain = cast(int)sheet.triangles.length;
	sheet.neighborCells[0] = sheet.cubeCount;
	sheet.addSkirts();
	report.expect(cast(int)sheet.triangles.length == plain, "the same resolution adds no skirt");
	sheet.buildMesh();
	sheet.neighborCells[0] = 8;
	sheet.addSkirts();
	report.expect(cast(int)sheet.triangles.length > plain, "a coarser neighbor adds a skirt");
	report.expect(skirtHangs(sheet, 16.0f, 0, 1.0f), "the skirt hangs on the shared face and faces outward");

	ChunkSmooth* fine = ChunkSmooth.create(32);
	ChunkSmooth* coarse = ChunkSmooth.create(8);
	int seamLayer = chunkCoord(groundHeightAt(16.0f, 0.0f), 16) * 16;
	fine.origin = Vector3(0, seamLayer, 0);
	coarse.origin = Vector3(16, seamLayer, 0);
	fine.populateTerrain();
	coarse.populateTerrain();
	int seamMismatch = 0;
	int coarseZ = 0;
	while(coarseZ < coarse.sampleCount) {
		int coarseY = 0;
		while(coarseY < coarse.sampleCount) {
			int ic = coarse.sampleIndex(0, coarseY, coarseZ);
			int fineY = coarseY * 4;
			int fineZ = coarseZ * 4;
			int iff = fine.sampleIndex(fine.sampleCount - 1, fineY, fineZ);
			if(!near(coarse.density[ic], fine.density[iff]) || coarse.materials[ic] != fine.materials[iff])
				seamMismatch += 1;
			coarseY += 1;
		}
		coarseZ += 1;
	}
	report.expect(seamMismatch == 0, "a coarse face matches the fine face on shared samples " ~ to!string(seamMismatch));

	ChunkWorld* detail = new ChunkWorld();
	detail.radius = 3;
	Vector3 detailHome = Vector3(0, 2, 0);
	int detailY0;
	int detailY1;
	surfaceLayers(3, 0, 16, detailY0, detailY1);
	int detailGuard = 0;
	ChunkSmooth* distant = null;
	while(distant is null && detailGuard < 800) {
		detail.update(detailHome);
		int detailLayer = detailY0;
		while(detailLayer <= detailY1) {
			distant = detail.findChunk(3, detailLayer, 0);
			if(distant !is null)
				break;
			detailLayer += 1;
		}
		detailGuard += 1;
	}
	report.expect(distant !is null && distant.cubeCount == 16, "a chunk three steps away is coarser");
	ChunkSmooth* stayed = detail.findChunk(0, firstY, 0);
	report.expect(stayed !is null && stayed.cubeCount == 32, "the chunk under the player stays fine");
	Vector3 walkedUp = Vector3(48.1f, 2, 0.1f);
	detailGuard = 0;
	while(distant !is null && distant.cubeCount != 32 && detailGuard < 800) {
		detail.update(walkedUp);
		detailGuard += 1;
	}
	report.expect(distant !is null && distant.cubeCount == 32, "walking up to a chunk makes it finer");
	detailGuard = 0;
	while(stayed !is null && stayed.cubeCount != 16 && detailGuard < 800) {
		detail.update(walkedUp);
		detailGuard += 1;
	}
	report.expect(stayed !is null && stayed.cubeCount == 16, "walking away makes a chunk coarser");

	drawOnce(*terrain, report);
	return report.failed;
}

// Camera at (0, 2, 10) looks toward -Z. Aspect 16/9, 45 degree fovy.
// At 10 units ahead the view is about 14.7 wide and 8.3 tall.
int checkFrustum() {
	Report report;
	Camera3D camera;
	camera.position = Vector3(0, 2, 10);
	camera.target = Vector3(0, 2, 0);
	camera.up = Vector3(0, 1, 0);
	camera.fovy = 45;
	camera.projection = CameraProjection.CAMERA_PERSPECTIVE;
	Frustum view = frustumFromCamera(camera, 16.0f / 9.0f);

	bool see(float x0, float y0, float z0, float x1, float y1, float z1) {
		return boxInFrustum(view, Vector3(x0, y0, z0), Vector3(x1, y1, z1));
	}

	report.expect(see(-2, 0, -2, 2, 4, 2), "the chunk in front is drawn");
	report.expect(!see(-2, 0, 14, 2, 4, 20), "a chunk behind the camera is skipped");
	report.expect(!see(-2, 8, -2, 2, 12, 2), "a chunk above the view is skipped");
	report.expect(see(-2, 2, -2, 2, 8, 2), "a chunk that crosses the top edge is drawn");
	report.expect(!see(12, 0, -2, 16, 4, 2), "a chunk off to the side is skipped");
	report.expect(see(4, 0, -2, 6, 4, 2), "a chunk inside the side edge is drawn");
	report.expect(see(-8, -8, 2, 8, 18, 18), "the chunk around the camera is drawn");
	report.expect(see(0, 0, -56, 16, 16, -40), "a chunk ahead is drawn");
	report.expect(!see(80, 0, -56, 96, 16, -40), "a chunk ahead but far to the side is skipped");

	Vector3 frontA = Vector3(0, 2, 0);
	Vector3 frontB = Vector3(0.5f, 2, 0);
	Vector3 frontC = Vector3(0, 2.5f, 0);
	report.expect(triangleInFrustum(view, frontA, frontB, frontC), "a triangle in front is drawn");
	report.expect(facesCamera(faceNormal(frontA, frontB, frontC), frontA, camera.position), "that triangle faces the camera");

	Vector3 behindA = Vector3(0, 2, 14);
	Vector3 behindB = Vector3(0.5f, 2, 14);
	Vector3 behindC = Vector3(0, 2.5f, 14);
	report.expect(!triangleInFrustum(view, behindA, behindB, behindC), "a triangle behind the camera is skipped");

	Vector3 aboveA = Vector3(0, 10, 0);
	Vector3 aboveB = Vector3(0.5f, 10, 0);
	Vector3 aboveC = Vector3(0, 10.5f, 0);
	report.expect(!triangleInFrustum(view, aboveA, aboveB, aboveC), "a triangle above the view is skipped");

	Vector3 sideA = Vector3(14, 2, 0);
	Vector3 sideB = Vector3(14.5f, 2, 0);
	Vector3 sideC = Vector3(14, 2.5f, 0);
	report.expect(!triangleInFrustum(view, sideA, sideB, sideC), "a triangle off to the side is skipped");

	report.expect(triangleInFrustum(view, frontA, frontC, frontB), "a back face in front is still in the view");
	report.expect(!facesCamera(faceNormal(frontA, frontC, frontB), frontA, camera.position), "a back face is skipped");

	Vector3 groundA = Vector3(0, 0, 0);
	Vector3 groundB = Vector3(0.5f, 0, 0);
	Vector3 groundC = Vector3(0, 0, -0.5f);
	report.expect(facesCamera(faceNormal(groundA, groundB, groundC), groundA, camera.position), "the ground faces a camera above it");
	report.expect(!facesCamera(faceNormal(groundA, groundB, groundC), groundA, Vector3(0, -2, 0)), "the ground does not face a camera under it");

	Vector3 spanA = Vector3(0, 2, 0);
	Vector3 spanB = Vector3(20, 2, 0);
	Vector3 spanC = Vector3(20, 3, 0);
	report.expect(triangleInFrustum(view, spanA, spanB, spanC), "a triangle that crosses the edge is drawn");
	report.expect(facesCamera(faceNormal(spanA, spanB, spanC), spanA, camera.position), "that crossing triangle faces the camera");
	return report.failed;
}

void drawOnce(ref ChunkSmooth chunk, ref Report report) {
	SetConfigFlags(ConfigFlags.FLAG_WINDOW_HIDDEN);
	InitWindow(1280, 720, "smooth");
	scope(exit)
		CloseWindow();
	report.expect(IsWindowReady(), "smooth window");
	if(!IsWindowReady())
		return;

	float ground = chunk.terrainHeight(0, -8);
	int groundChunk = chunkCoord(ground, 16) * 16;
	chunk.origin = Vector3(-8, groundChunk, -18);
	chunk.populateTerrain();
	Camera3D camera;
	camera.position = Vector3(0, ground + 10, 14);
	camera.target = Vector3(0, ground, -8);
	camera.up = Vector3(0, 1, 0);
	camera.fovy = 45;
	camera.projection = CameraProjection.CAMERA_PERSPECTIVE;

	BeginDrawing();
	scope(exit)
		EndDrawing();
	ClearBackground(Colors.BLACK);
	BeginMode3D(camera);
	float screenHeight = cast(float)GetScreenHeight();
	float aspect = 1.0f;
	if(screenHeight > 0.0f)
		aspect = cast(float)GetScreenWidth() / screenHeight;
	chunk.drawChunk(camera, frustumFromCamera(camera, aspect));
	DrawGrid(20, 1);
	EndMode3D();
}
