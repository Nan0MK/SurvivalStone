#!/bin/sh
cat <<'EOF'
SurvivalStone handoff, 2026-10-30

Goal: gravity and ground collision for the normal player. Debug flight stays free. That is in the game.

Files touched:
- source/player.d — moveWalk, surfaceAt, eyeHeight 2, gravity 24, jumpSpeed 10, stepHeight 1. The normal branch of stepLook calls moveWalk. Space jumps from the ground. setDebugMove clears velocityY.
- source/gameDebug/camera.d — FreeCamera passes its own velocityY into stepLook, so the shared normal path can fall.
- source/aiTest/camera.d — a fall leaves the air, landing stops on the surface, a jump starts upward and then slows, and a tall step blocks the stride. moveLook and moveDebug checks are unchanged.
- PROGRESS.md, AGENT_LEARN.md — normal movement falls and lands. Debug flight does not.

What is true:
- The camera is the eyes. The feet are 2 below it. The ground is the bilinear blend of the four integer terrain samples under the player.
- A rise of more than 1 cancels that horizontal step. Gentler ground is walked up, then the feet snap to it.
- Debug movement still flies along the look. Space climbs, Shift descends, and the body does not collide.
- The checks passed: dub build, then dub run --config=aiTest, which printed aiTest ok.

Unfinished: Chunk2 face culling. When the author asks, store blocks with chunkIndex(x - 1, y - 1, z - 1), and draw EAST only when chunkData[i] is TEST and getNeighbor(i, EAST) is not. The blockData comment still says "should be 48". Leave it unless the author asks. Do not add a day/night cycle, digging, a mesh batcher, or more materials unless they ask.

Next: read AGENTS.md, PROGRESS.md, and AGENT_LEARN.md. Wait for the author. When you test or review, run dub run --config=aiTest yourself. Do not ask the author to run it.
EOF
