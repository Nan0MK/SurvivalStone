#!/bin/sh
cat <<'EOF'
SurvivalStone handoff, 2026-10-31

Goal: make ranges a giant ledge, not a round hill. That is in the game.

Files touched:
- source/chunkSmooth.d — rangeWave climbs 300 on a steep face, drops 75 on a slope a little less steep, then slopes gradually back to 0. rangesAt slides Perlin along that shape. A steep face is just east of the spawn, near x=96.
- source/aiTest/smooth.d — checks the three parts of rangeWave, and that a face in the world climbs hundreds and is steep.
- source/aiTest/camera.d — the gravity check starts above the local ground, because the spawn now sits up on a range.
- AGENT_LEARN.md — the range shape.

What is true:
- The spawn is already up on a range, near the start of the long slope. The wall is a short way east.
- Ledges are still the small scarp times ledgeIntensityAt times ledgeChanceAt.
- The pause menu distances are 10, 20, 40, 100, 200, and 500. Holding left ctrl in debug flight multiplies speed by debugFast (8).
- The window clears to Colors.SKYBLUE. Detail follows distance. The player size is unchanged.
- The checks passed: dub run --config=aiTest printed aiTest ok. dub build succeeded.

Unfinished: Chunk2 face culling. When the author asks, store blocks with chunkIndex(x - 1, y - 1, z - 1), and draw EAST only when chunkData[i] is TEST and getNeighbor(i, EAST) is not. Leave that unless the author asks.

Next: read AGENTS.md, PROGRESS.md, and AGENT_LEARN.md. Wait for the author. When you test or review, run dub run --config=aiTest yourself. Do not ask the author to run it.
EOF
