# Design

## Source of truth
- Status: Draft
- Last refreshed: 2026-06-29
- Primary product surfaces: Office hub, dungeon field exploration, SRPG combat event, settlement/report panels.
- Evidence reviewed:
  - `project.godot` viewport: 1270x720 canvas layout.
  - `assets/sample/A2_office_hub.png`: approved office hub visual direction.
  - `assets/sample/README.md`: approved A-F concept sample list.
  - `docs/04_REVISED_GAME_LOOP.md`: top-down office, dungeon field work, SRPG event loop.
  - `docs/07_SRPG_BATTLE_UI_ANALYSIS.md`: combat screen layout and SRPG HUD rules.
  - `docs/08_SRPG_IMAGE_PROMPTS.md`: SRPG UI asset prompt direction.
  - `docs/09_REMAINING_WORK_AND_PROJECT_MEMORY.md`: remaining work and current product direction.
  - `scripts/Office.gd`, `scripts/DungeonTest.gd`, `scripts/BattleTest.gd`: current procedural UI layout.

## Brand
- Personality: Dark fantasy workplace comedy; practical monster-side cleanup contractor, not heroic adventure fantasy.
- Trust signals: Ledger-like numbers, contract papers, brass-framed panels, clear operational status, readable warnings.
- Avoid: Modern rounded app UI, glossy mobile-game gradients, oversized marketing hero layout, unclear decorative panels, full-screen opaque UI that hides the play space.

## Product goals
- Goals:
  - Make the player feel they are running a dungeon cleanup company through direct movement and operational choices.
  - Keep management, field work, and combat visually connected through one HUD language.
  - Make each screen readable at a glance: current status, current objective, available action, expected consequence.
- Non-goals:
  - Full final art pass before the core loop is proven.
  - Dense simulation UI that overwhelms field exploration.
  - Long SRPG campaign battle UI.
- Success signals:
  - A player can tell what to do next without reading a long instruction paragraph.
  - Office, dungeon, and battle screens feel like the same game.
  - Important choices are visible before committing: contract risk, field objective, combat objective, reward/punishment.

## Personas and jobs
- Primary personas:
  - Player who likes management games but wants direct field control.
  - Player who understands SRPG basics and expects clear grid state.
- User jobs:
  - Choose today's contract.
  - Prepare staff and equipment.
  - Explore the field, find work objects, trigger/resolve incidents.
  - Read settlement results and decide the next day.
- Key contexts of use:
  - Keyboard-first movement with mouse-supported UI.
  - Short prototype sessions where the loop must be legible immediately.

## Information architecture
- Primary navigation:
  - Bottom-left quick buttons: Contract, Staff, Gear, Research/Upgrade, Company.
  - In-world interactables: contract board, staff desks, gear shelf, ledger, dispatch door, field objects.
- Core routes/screens:
  - Office hub: preparation and company state.
  - Dungeon field: exploration and physical task handling.
  - Battle event: short tactical incident resolution.
  - Settlement/report: reward, reputation, risk, staff/equipment consequences.
- Content hierarchy:
  - Top: persistent company/time/status HUD.
  - Center: playable world or tactical board.
  - Right: current context panel, such as schedule, minimap, target info, selected object, or dispatch details.
  - Bottom: immediate prompt, log, and short feedback.

## Design principles
- Direct control first: the world must stay visible; UI supports the player instead of replacing the play space.
- Operational clarity: every screen shows objective, available action, and consequence.
- One layout grammar: office, dungeon, and battle share the same HUD zones even when their content changes.
- Tradeoffs:
  - Prefer stable HUD zones over dynamic panel movement.
  - Prefer small readable panels over ornate frames that consume the map.
  - Use generated UI art as frames/icons; keep Korean text in Godot labels.

## Visual language
- Color:
  - Backgrounds: black stone, dark slate, charcoal wood.
  - Frames: worn brass/gold trim.
  - Positive/status: muted green, cyan hygiene, purple hell trust.
  - Warning/risk: red/orange used sparingly for illegal risk, combat danger, failed objective.
- Typography:
  - Korean labels must remain Godot-rendered text for editability.
  - Use compact labels in panels; reserve large type for current objective and major result.
- Spacing/layout rhythm:
  - Current base viewport is 1270x720.
  - Use 16-24 px outer margins.
  - Keep top HUD height around 86-110 px.
  - Keep bottom message/command band around 96-128 px.
- Shape/radius/elevation:
  - Pixel-framed rectangular panels, low radius, strong borders.
  - Avoid floating card piles; panels should feel bolted to screen edges or attached to in-world objects.
- Motion:
  - Minimal; use small highlight pulses for interactable, selected tile, danger tile, and objective tile.
- Imagery/iconography:
  - Pixel icons with transparent backgrounds.
  - UI art should avoid readable text; labels are added in-engine.

## Layout Contract
- Global viewport target:
  - Base: 1270x720.
  - Keep layout functional at this size before expanding to other aspect ratios.
- Shared screen zones:
  - Top HUD band: company/day/resources/objective summary.
  - Center play area: office floor, dungeon exploration, or SRPG board. Never cover this with permanent large panels.
  - Right context panel: schedule/minimap in office, field objective/minimap in dungeon, target/action info in battle.
  - Bottom message band: one primary status line plus one compact prompt/log line.
  - Bottom-left quick nav: icon buttons for major management panels.
- Office layout:
  - Top HUD: Day, money, hell trust, human reputation, hygiene, illegal risk, settings.
  - Left/mid world: contract board and staff desks.
  - Right world: gear shelf and dispatch door.
  - Bottom-left quick buttons: contract, staff, gear, research, company.
  - Bottom-center: interaction prompt and last report.
  - Bottom-right: today's schedule and map/company panel.
- Dungeon field layout:
  - Top HUD: selected contract, field progress, company resource summary.
  - Center: larger-than-screen map with Camera2D tracking the boss.
  - Right context panel: field checklist, discovered objects, compact minimap.
  - Bottom: current interactable prompt and action result log.
  - Do not show all tasks at once; layout must support exploration and discovery.
- Battle layout:
  - Top HUD: combat title, objective, boss HP, turn/phase.
  - Center-left: tactical board, larger than the action panel.
  - Right panel: action buttons, target info, staff support.
  - Bottom: combat log and confirmation prompts.
  - Board must reserve visual language for movement, threat, objective, obstacle, and selected unit tiles.

## Components
- Existing components to reuse:
  - Godot `PanelContainer`, `MarginContainer`, `VBoxContainer`, `HBoxContainer`, `GridContainer`, `Label`, `Button`, `ColorRect`.
  - Existing `make_panel_style`, `make_label`, `make_badge`, and stat chip patterns.
- New/changed components:
  - Shared top HUD stat card.
  - Shared bottom message bar.
  - Shared quick-nav icon button.
  - Shared tooltip frame for `E / Space`.
  - Context panel frame variants: office, dungeon, battle.
  - Battle tile overlays: move, attack, skill, threat, objective, obstacle, selected unit.
- Variants and states:
  - Normal, selected, disabled, danger, success, pending.
  - Buttons should not disappear when unavailable; disabled state must explain why in the status line.
- Token/component ownership:
  - Keep colors and panel helpers centralized when refactoring starts.
  - Until then, keep changes scoped to screen scripts and avoid a premature UI framework.

## Accessibility
- Target standard: Prototype-level keyboard accessibility and high readability.
- Keyboard/focus behavior:
  - WASD movement and `E`/`Space` interaction remain primary.
  - Battle supports keyboard cursor and confirm/cancel.
- Contrast/readability:
  - Text must contrast against dark panels.
  - Warning colors must not be the only signal; pair with labels/log text.
- Screen-reader semantics:
  - Not a current prototype target.
- Reduced motion and sensory considerations:
  - Avoid constant flashing; highlight pulses should be subtle and optional later.

## Responsive behavior
- Supported breakpoints/devices:
  - Prototype target: desktop 1270x720.
- Layout adaptations:
  - Wider screens may expand center play area and right context panel.
  - Smaller screens should preserve top HUD, center play, bottom prompt; optional panels can collapse.
- Touch/hover differences:
  - Mouse hover is secondary; all critical actions need keyboard/click alternatives.

## Interaction states
- Loading:
  - Not currently needed beyond scene transition.
- Empty:
  - Contract board shows no selected contract and disabled dispatch.
- Error:
  - Use bottom message band for blocked actions.
- Success:
  - Use bottom message band and settlement/report panel.
- Disabled:
  - Disable controls but keep them visible; explain reason in the detail/status panel.
- Offline/slow network:
  - Not applicable.

## Content voice
- Tone:
  - Dry workplace comedy with dark fantasy terms.
- Terminology:
  - Use "의뢰", "직원", "장비", "현장", "정산", "위생", "불법 리스크", "마왕성 신뢰", "인간 평판".
- Microcopy rules:
  - Prompts should be short: `E / Space: 의뢰 게시판`.
  - Avoid long tutorial sentences in persistent UI.
  - Use logs for consequences, not basic control explanations.

## Implementation constraints
- Framework/styling system:
  - Godot 4.7, procedural GDScript UI in current prototype.
- Design-token constraints:
  - No token file yet. Keep reusable constants in scripts until a UI helper is justified.
- Performance constraints:
  - UI art should be lightweight PNGs with transparent backgrounds.
  - Large dungeon maps should use camera bounds and simple static geometry for the prototype.
- Compatibility constraints:
  - Current renderer is GL Compatibility.
- Test/screenshot expectations:
  - After UI layout changes, run headless loads for `Office.tscn`, `DungeonTest.tscn`, and `BattleTest.tscn`.
  - When visual layout changes become larger, capture screenshots for office, dungeon, and battle.

## Pixellab Asset Prompts To Prepare
- Use `docs/10_PIXELLAB_UI_ASSET_PLAN.md` as the practical generation sheet.
- Generate separate UI parts, not full screen mockups.
- Prefer transparent-background components that Godot can assemble with real Korean labels.
- Use `assets/sample/A2_office_hub.png` as the concept/init reference for office UI style.

## Open questions
- [ ] Should office quick-nav buttons open panels anywhere, or only mirror in-world interactables?
- [ ] Should the right context panel always be visible in dungeon exploration, or appear only after discovering the map/contract details?
- [ ] Should staff appear as full units in battle or support tokens first?
- [ ] Should the first field map use a minimap immediately, or wait until exploration feels too unclear?
