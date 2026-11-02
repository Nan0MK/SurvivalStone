module gameDebug.hud;

import core.stdc.stdio : snprintf;

import raylib;

import chunkSmooth;
import player;

struct Hud {
	private string facing = "NORTH";

	void draw(ref Player view) {
		drawCompass(view);
		drawCoordinates(view.camera.position);
	}

	private void drawCompass(ref Player view) {
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

private enum int pausePanelW = 560;
private enum int pauseRowH = 44;
private enum int pauseRowGap = 12;
private enum int pauseInset = 28;
private enum int pauseDebugTop = 72;
private enum int pauseLabelH = 28;
private enum int pauseChoiceGap = 8;
private enum int pauseLabelTop = pauseDebugTop + pauseRowH + pauseRowGap;
private enum int pauseChoicesTop = pauseLabelTop + pauseLabelH;
private enum int pauseResumeTop = pauseChoicesTop + pauseRowH + pauseRowGap;
private enum int pausePanelH = pauseResumeTop + pauseRowH + pauseInset;
private enum int[6] renderChoices = [10, 20, 40, 100, 200, 500];

private Rectangle pausePanelAt(int screenW, int screenH) {
	return Rectangle((screenW - pausePanelW) / 2, (screenH - pausePanelH) / 2, pausePanelW, pausePanelH);
}

// Escape opens this. Debug movement is the fly-along-look option. Resume closes it.
// Render distance is one of 10, 20, 40, 100, 200, or 500 chunks. The default is chunkRadius.
struct PauseMenu {
	bool open;
	bool debugMove;
	int renderDistance = chunkRadius;

	Rectangle debugRowAt(int screenW, int screenH) {
		Rectangle panel = pausePanelAt(screenW, screenH);
		return Rectangle(panel.x + pauseInset, panel.y + pauseDebugTop, panel.width - pauseInset * 2, pauseRowH);
	}

	Rectangle renderChoiceAt(int index, int screenW, int screenH) {
		Rectangle panel = pausePanelAt(screenW, screenH);
		float rowW = panel.width - pauseInset * 2;
		float buttonW = (rowW - pauseChoiceGap * (renderChoices.length - 1)) / renderChoices.length;
		return Rectangle(
			panel.x + pauseInset + index * (buttonW + pauseChoiceGap),
			panel.y + pauseChoicesTop,
			buttonW,
			pauseRowH,
		);
	}

	Rectangle resumeRowAt(int screenW, int screenH) {
		Rectangle panel = pausePanelAt(screenW, screenH);
		return Rectangle(panel.x + pauseInset, panel.y + pauseResumeTop, panel.width - pauseInset * 2, pauseRowH);
	}

	// True when the click was Resume and the menu closed.
	bool press(Vector2 mouse, int screenW, int screenH) {
		if (!open)
			return false;
		if (CheckCollisionPointRec(mouse, debugRowAt(screenW, screenH))) {
			debugMove = !debugMove;
			return false;
		}
		int choice = 0;
		while (choice < renderChoices.length) {
			if (CheckCollisionPointRec(mouse, renderChoiceAt(choice, screenW, screenH))) {
				renderDistance = renderChoices[choice];
				return false;
			}
			choice += 1;
		}
		if (CheckCollisionPointRec(mouse, resumeRowAt(screenW, screenH))) {
			open = false;
			return true;
		}
		return false;
	}

	void draw() {
		int screenW = GetScreenWidth();
		int screenH = GetScreenHeight();
		DrawRectangle(0, 0, screenW, screenH, Color(0, 0, 0, 140));

		Rectangle panel = pausePanelAt(screenW, screenH);
		DrawRectangleRec(panel, Color(24, 24, 28, 235));

		immutable titleSize = 36;
		string title = "Paused";
		int titleWidth = MeasureText(title.ptr, titleSize);
		DrawText(title.ptr, cast(int) (panel.x + (panel.width - titleWidth) / 2), cast(int) panel.y + 18, titleSize, Colors.RAYWHITE);

		immutable rowSize = 22;
		Rectangle debugRow = debugRowAt(screenW, screenH);
		DrawRectangleRec(debugRow, Color(48, 48, 56, 255));
		int rowTextY = cast(int) (debugRow.y + (debugRow.height - rowSize) / 2);
		string label = "Debug movement";
		DrawText(label.ptr, cast(int) debugRow.x + 16, rowTextY, rowSize, Colors.RAYWHITE);
		string state = debugMove ? "On" : "Off";
		int stateWidth = MeasureText(state.ptr, rowSize);
		DrawText(state.ptr, cast(int) (debugRow.x + debugRow.width - stateWidth - 16), rowTextY, rowSize, Colors.RAYWHITE);

		string distanceLabel = "Render distance";
		DrawText(distanceLabel.ptr, cast(int) panel.x + pauseInset, cast(int) panel.y + pauseLabelTop, rowSize, Colors.RAYWHITE);

		int choice = 0;
		while (choice < renderChoices.length) {
			Rectangle button = renderChoiceAt(choice, screenW, screenH);
			Color fill = renderDistance == renderChoices[choice] ? Color(90, 96, 120, 255) : Color(48, 48, 56, 255);
			DrawRectangleRec(button, fill);
			char[8] number;
			snprintf(number.ptr, number.length, "%d", renderChoices[choice]);
			int numberWidth = MeasureText(number.ptr, rowSize);
			DrawText(
				number.ptr,
				cast(int) (button.x + (button.width - numberWidth) / 2),
				cast(int) (button.y + (button.height - rowSize) / 2),
				rowSize,
				Colors.RAYWHITE,
			);
			choice += 1;
		}

		Rectangle resume = resumeRowAt(screenW, screenH);
		DrawRectangleRec(resume, Color(48, 48, 56, 255));
		string resumeLabel = "Resume";
		int resumeWidth = MeasureText(resumeLabel.ptr, rowSize);
		DrawText(
			resumeLabel.ptr,
			cast(int) (resume.x + (resume.width - resumeWidth) / 2),
			cast(int) (resume.y + (resume.height - rowSize) / 2),
			rowSize,
			Colors.RAYWHITE,
		);
	}
}
