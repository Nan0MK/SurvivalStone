module aiTest.check;

import std.stdio;

struct Report {
	int failed;

	void expect(bool ok, lazy string message) {
		if (ok)
			return;
		failed++;
		writeln("FAIL ", message);
	}
}
