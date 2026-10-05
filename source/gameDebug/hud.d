module gameDebug.hud;

import core.stdc.stdio : snprintf;

import raylib;

import gameDebug.camera;

struct Hud {
	private string facing = "NORTH";

	void draw(ref FreeCamera view) {
		drawCompass(view);
		drawCoordinates(view.camera.position);
	}

	private void drawCompass(ref FreeCamera view) {
		string nextFacing = view.facingLabel();
		if (nextFacing.length)
			facing = nextFacing;
		immutable facingSize = 40;
		immutable facingWidth = MeasureText(facing.ptr, facingSize);
		DrawText(facing.ptr, (GetScreenWidth() - facingWidth) / 2, (GetScreenHeight() - facingSize) / 2, facingSize, Colors.RED);
	}

	private void drawCoordinates(Vector3 position) {
		char[64] xBuf, yBuf, zBuf;
		snprintf(xBuf.ptr, xBuf.length, "X  %.2f m", cast(double) position.x);
		snprintf(yBuf.ptr, yBuf.length, "Y  %.2f m", cast(double) position.y);
		snprintf(zBuf.ptr, zBuf.length, "Z  %.2f m", cast(double) position.z);
		immutable fontSize = 20;
		immutable line = fontSize + 4;
		immutable pad = 8;
		int widest = MeasureText(xBuf.ptr, fontSize);
		const yWidth = MeasureText(yBuf.ptr, fontSize);
		const zWidth = MeasureText(zBuf.ptr, fontSize);
		if (yWidth > widest) widest = yWidth;
		if (zWidth > widest) widest = zWidth;
		immutable meterX = 16;
		immutable meterY = GetScreenHeight() - (line * 3 + pad);
		DrawRectangle(meterX - pad, meterY - pad, widest + pad * 2, line * 3 + pad, Color(0, 0, 0, 160));
		DrawText(xBuf.ptr, meterX, meterY, fontSize, Colors.RED);
		DrawText(yBuf.ptr, meterX, meterY + line, fontSize, Colors.GREEN);
		DrawText(zBuf.ptr, meterX, meterY + line * 2, fontSize, Colors.BLUE);
	}
}
