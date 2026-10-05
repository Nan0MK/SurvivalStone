module aiTest.chunk;

import std.conv : to;

import raylib;

import block;

import aiTest.check;

// Y is the outer loop, Z the middle, X the inner. Each runs from chunkSize down to 1.
// Slot (x, y, z) lands at (y - 1) * 256 + (z - 1) * 16 + (x - 1).
int checkChunk() {
	Report report;
	Chunk chunk;
	chunk.populateChunk();

	immutable size = chunk.chunkSize;
	immutable cells = size * size * size;
	report.expect(chunk.blockData.length == cells, "blockData length " ~ to!string(chunk.blockData.length));
	report.expect(chunk.meshData.length == cells, "meshData length " ~ to!string(chunk.meshData.length));

	foreach (index, block; chunk.blockData) {
		immutable x = (index % size) + 1;
		immutable z = ((index / size) % size) + 1;
		immutable y = (index / (size * size)) + 1;
		report.expect(block.x == x && block.y == y && block.z == z,
			"block " ~ to!string(index) ~ " is (" ~ to!string(block.x) ~ ", " ~
			to!string(block.y) ~ ", " ~ to!string(block.z) ~ ")");
	}

	report.expect(chunk.blockData[0] == Vector3(1, 1, 1), "first cell");
	report.expect(chunk.blockData[$ - 1] == Vector3(size, size, size), "last cell");
	return report.failed;
}
