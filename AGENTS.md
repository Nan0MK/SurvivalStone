# SurvivalStone

SurvivalStone is a voxel survival game with crafting and mechanics that players are meant to be able to exploit. The author is writing most of it by hand, in D and raylib, to learn graphics programming. Help with the task you were given. Do not take over the project.

## Do only the task

When asked for code, do that task and the work it requires. Do not add features, refactors, or files that were not asked for.

When you change code, say what you changed and why in plain language. The author is using that explanation to learn. Do not add a tutorial they did not ask for.

## aiTest

Agent testing and review tools go in the `aiTest` package, `source/aiTest`. That is the one place you may add files the author did not name.

The author does not run this package. Do not tell them to run it. Agents run it themselves when they test or review:

```
dub run --config=aiTest
```

Success prints `aiTest ok`. `dub build` is the game. That build excludes `source/aiTest`.

## Handoff

Leave a handoff so the next agent can continue.

- Append progress to `PROGRESS.md` in the repo root. Each note has the date, what changed, which files, and what is unfinished. Keep this file for rules only.
- Read `AGENT_LEARN.md` before changing code. Add a short note when this project teaches a programming lesson that later work should reuse.
- Maintain `resume.ps1` and `resume.sh` in the repo root. Update both before the session ends. Replace the contents of those two files. Do not create a new resume file per session.
- Both scripts print the handoff and then exit. They do not edit files, build, or start the game. Include the current goal, the files touched, the unfinished work, and the next step.
- The next agent runs `resume.ps1` on Windows or `resume.sh` on Linux, reads the output, and continues from that.
