#!/bin/sh
cat <<'EOF'
SurvivalStone handoff, 2026-10-06

Goal: player movement system is in. Waiting on the author for the next task.

Files touched:
- source/player.d: new Player struct. WASD moves relative to facing, Space up, Shift down (not Ctrl), mouse turns via yaw/pitch it owns. Opens facing north, level.
- source/app.d: uses Player instead of gameDebug FreeCamera.
- source/gameDebug/hud.d: Hud.draw and drawCompass now take ref Player.
- source/aiTest/frame.d: one-frame draw uses Player; gameDebug files unchanged otherwise.
- PROGRESS.md updated.

Unfinished: nothing assigned. The blockData comment still says "should be 48"; the arrays hold 4096. slowMove() is commented out in FreeCamera.update. Leave both unless the author asks. FreeCamera is unused by the game now; it stays for reference.

Next: read AGENTS.md, PROGRESS.md, and AGENT_LEARN.md. Wait for the author. When you test or review, run dub run --config=aiTest yourself (currently prints "aiTest ok"). Do not ask the author to run it.
EOF
