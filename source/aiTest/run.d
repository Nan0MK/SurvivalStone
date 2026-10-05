module aiTest.run;

import std.stdio;

import aiTest;

// dub run --config=aiTest
int main() {
	immutable fails = checkChunk() + checkCamera() + checkFrame();
	if (fails == 0) {
		writeln("aiTest ok");
		return 0;
	}
	writefln("aiTest %s failed", fails);
	return 1;
}
