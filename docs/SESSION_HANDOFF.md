# Session Handoff — dungeon-cleanup-inc

Date: 2026-06-28

## Project

- Godot 4.7 Standard project
- WSL path: `/mnt/c/Users/tajok/dev/dungeon-cleanup-inc`
- Windows path: `C:\Users\tajok\dev\dungeon-cleanup-inc`
- Game title: `던전 클린업 주식회사`
- Current main scene: `res://scenes/Office.tscn`
- Autoload: `GameState` -> `res://scripts/GameState.gd`

## Current Direction

The game direction was revised away from a menu-only management prototype.

Target direction:

- Top-down office hub
- Top-down dungeon field work
- SRPG-style turn-based combat only for combat events
- Player directly controls one boss character in both office and dungeon
- Staff and gear are management/tactical resources, not always-controlled party members

Reference doc:

- `docs/04_REVISED_GAME_LOOP.md`

## Implemented So Far

### Core Runtime

- `project.godot`
  - `run/main_scene="res://scenes/Office.tscn"`
  - `GameState` autoload added
  - viewport set to 1270x720
  - GL compatibility renderer

- `scripts/GameState.gd`
  - Holds company stats:
    - `day`
    - `money`
    - `hell_trust`
    - `human_reputation`
    - `hygiene`
    - `illegal_risk`
    - `last_report`
  - Provides HUD text helpers
  - Applies dungeon settlement via `apply_field_report`

- `scripts/PlayerController.gd`
  - Top-down WASD movement
  - Interact with `E` or `Space`
  - Tracks nearest/current interactable

- `scripts/Interactable.gd`
  - Reusable Area2D interaction object
  - Stores `label` and `action`
  - Emits interaction signal

### Office

- Scene: `scenes/Office.tscn`
- Script: `scripts/Office.gd`

Current behavior:

- Builds a procedural top-down office.
- Shows boss placeholder sprite.
- Player can move with WASD.
- Player can interact with:
  - contract board
  - staff desk
  - gear shelf
  - ledger
  - dispatch door
- Dispatch door changes scene to `DungeonTest.tscn`.
- Top HUD shows company stats.
- Bottom message panel shows interaction/status text.
- If returning from dungeon, office displays `GameState.last_report`.

### Dungeon Test

- Scene: `scenes/DungeonTest.tscn`
- Script: `scripts/DungeonTest.gd`

Current behavior:

- Builds a procedural top-down dungeon room.
- Player can move with WASD.
- Player can interact with field tasks:
  - slime puddle cleanup
  - broken trap repair
  - bone pile collection
- Task completion changes visuals and progress.
- Return door blocks completion until all 3 tasks are complete.
- Returning applies settlement:
  - money `+55`
  - hell trust `+6`
  - human reputation `+1`
  - hygiene `+5`
  - illegal risk `+1`
- Then returns to `Office.tscn`.

### Placeholder Art

- `assets/sprites/boss_placeholder.svg`
- `assets/sprites/boss_placeholder.svg.import`

This is temporary. User is making actual boss pixel art separately.

### Old Prototype Still Present

These are earlier menu/prototype slices and are not the current direction:

- `scripts/Main.gd`
- `scenes/Main.tscn`
- `scripts/TacticalEvent.gd`
- `scenes/TacticalEvent.tscn`
- `data/GameData.gd`

Keep them for reference until replacement is clean.

## Current Git State Notes

There are `.omx` runtime files modified. Do not commit them.

Expected commit scope should include:

```text
project.godot
assets/
data/
docs/
scenes/
scripts/
```

But exclude:

```text
.omx/
```

The old doc was moved into archive:

```text
docs/CODEX_BRIEF_dungeon_cleanup_inc.md
-> docs/archive/CODEX_BRIEF_dungeon_cleanup_inc.md
```

## Validation Already Run

Headless Godot checks passed when XDG dirs were redirected to `/tmp`:

```bash
XDG_DATA_HOME=/tmp/godot-data \
XDG_CONFIG_HOME=/tmp/godot-config \
XDG_CACHE_HOME=/tmp/godot-cache \
godot4 --headless --path . --scene res://scenes/Office.tscn --quit-after 2
```

```bash
XDG_DATA_HOME=/tmp/godot-data \
XDG_CONFIG_HOME=/tmp/godot-config \
XDG_CACHE_HOME=/tmp/godot-cache \
godot4 --headless --path . --scene res://scenes/DungeonTest.tscn --quit-after 2
```

Also checked:

```bash
git diff --check -- scripts/GameState.gd scripts/Office.gd scripts/DungeonTest.gd docs/04_REVISED_GAME_LOOP.md
```

## Known Environment Issue

Previous Codex session could edit project files but could not commit/push because its sandbox had:

- `.git` read-only
- shell network restricted
- Windows interop failing

If the next session must commit/push, launch Codex with enough local permissions, for example:

```bash
cd /mnt/c/Users/tajok/dev/dungeon-cleanup-inc
codex -C "$PWD" --sandbox danger-full-access --ask-for-approval on-request
```

or, for a fully unsandboxed local session:

```bash
cd /mnt/c/Users/tajok/dev/dungeon-cleanup-inc
codex -C "$PWD" --dangerously-bypass-approvals-and-sandbox
```

## Immediate Next Work

Recommended next slice:

1. Commit/push current top-down office + dungeon baseline.
2. Replace placeholder boss sprite with user-provided pixel art.
3. Add a simple contract board UI that opens from the office object instead of auto-dispatch-only flow.
4. Add basic contract selection state:
   - selected contract
   - required tasks
   - reward preview
5. Convert `DungeonTest` into a data-driven field operation:
   - tasks generated from selected contract
   - settlement based on completed work
6. After that, build the first SRPG combat prototype as a separate battle scene.

## Commit Command For Human/Unrestricted Session

```bash
cd /mnt/c/Users/tajok/dev/dungeon-cleanup-inc
git status -sb
git add project.godot assets data docs scenes scripts
git status -sb
git commit -m "Build top-down office and dungeon loop"
git push origin main
```

Do not run `git add .` unless `.omx/` is intentionally excluded first.

