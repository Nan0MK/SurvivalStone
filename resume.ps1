Write-Output @'
SurvivalStone handoff, 2026-11-07

Goal: walking stands on the visible quad ground. Gravity and jump are stronger.

Files touched:
- source/terrainQuads.d — quadHeightAt and cellSurface. A ramp slopes across the cell. A cliff is the low floor. A bent cell uses the same two triangles the mesh draws.
- source/player.d — surfaceAt returns quadHeightAt. gravity is 96. jumpSpeed is 32. A jump rises about 5.3. eyeHeight, stepHeight, and moveSpeed stay 2, 1, and 4.
- source/aiTest/terrain.d — checkWalk matches flats, ramps, cliff floors, bent triangles, and the drawn quads.
- source/aiTest/camera.d — the feet use quadHeightAt. A tall visible step still blocks a walk. The jump reach is past a two-square cliff.
- AGENT_LEARN.md — surfaceAt is the visible quad ground. gravity 96, jumpSpeed 32.

What is true:
- Leaving debug flight drops you onto the quads you can see. One-step slopes can be walked. A taller cliff stops you, and a jump clears a two-square cliff.
- dub build succeeded. dub run --config=aiTest printed aiTest ok.

Unfinished: diagonal hill slopes, placing and removing quads, and wall thickness. There is no way to type a seed back in. Nodes show the chunk the camera is in. Chunk2 face culling stays the author's fix unless they ask.

Next: read AGENTS.md, PROGRESS.md, and AGENT_LEARN.md. Wait for the author. When you test or review, run dub run --config=aiTest yourself. Do not ask the author to run it.
'@
