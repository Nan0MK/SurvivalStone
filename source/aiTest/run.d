module aiTest.run;

import std.stdio;
import std.conv : to;

import raylib;

import aiTest;
import aiTest.view;

// dub run --config=aiTest
// dub run --config=aiTest -- view out.png px py pz tx ty tz
int main(string[] args) {
	if (args.length >= 9 && args[1] == "view") {
		Vector3 position = Vector3(to!float(args[3]), to!float(args[4]), to!float(args[5]));
		Vector3 target = Vector3(to!float(args[6]), to!float(args[7]), to!float(args[8]));
		writeView(args[2], position, target);
		return 0;
	}
	immutable fails = checkChunk() + checkCamera() + checkFrame();
	if (fails == 0) {
		writeln("aiTest ok");
		return 0;
	}
	writefln("aiTest %s failed", fails);
	return 1;
}
