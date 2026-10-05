Write-Output @'
SurvivalStone handoff, 2026-10-05

Goal: leave a handoff the next agent can read. No game task is assigned.

Files touched:
- AGENTS.md now points agents at PROGRESS.md and AGENT_LEARN.md.
- PROGRESS.md records the current game state.
- AGENT_LEARN.md holds the programming notes to reuse.
- resume.ps1 and resume.sh print this handoff.

Unfinished: nothing assigned. The blockData comment still says "should be 48"; the arrays hold 4096. slowMove() is commented out in FreeCamera.update. Leave both unless the author asks.

Next: read AGENTS.md, PROGRESS.md, and AGENT_LEARN.md. Wait for the author. When you test or review, run dub run --config=aiTest yourself. Do not ask the author to run it.
'@
