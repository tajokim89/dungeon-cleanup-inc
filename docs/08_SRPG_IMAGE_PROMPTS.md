# SRPG 전투 UI/비주얼 이미지 프롬프트

작성일: 2026-06-28

목적: `docs/07_SRPG_BATTLE_UI_ANALYSIS.md` 기준으로 SRPG 전투 화면에 필요한 이미지 생성 프롬프트를 먼저 정리한다.

주의:

- 이 문서는 프롬프트만 모은다.
- 실제 이미지는 여기서 생성하지 않는다.
- 결과물은 Godot 2D에서 쓰기 쉬운 픽셀 아트 PNG 기준으로 생각한다.
- UI 아이콘/오버레이는 투명 배경을 기본으로 한다.

## 0. 공통 스타일 기준

모든 프롬프트에 유지할 방향:

```text
pixel art, top-down SRPG, dungeon cleanup company, dark fantasy comedy, transparent background, Godot 2D game asset, readable at small size, limited palette, chunky pixels
```

피해야 할 방향:

```text
smooth illustration, glossy mobile RPG, anime portrait, realistic render, heavy gradients, blurry edges, text, logo, watermark, background scene, overly detailed, unreadable silhouette
```

공통 Negative Prompt:

```text
smooth illustration, glossy anime, mobile RPG icon, realistic render, 3D render, painterly, heavy gradient, blurred, anti-aliased, tiny unreadable details, text, letters, numbers, logo, watermark, background, frame, bevel, drop shadow, weapon fantasy hero look, horror gore, realistic blood
```

## 1. 행동 버튼 아이콘

목표: 전투 행동 메뉴에 들어갈 작은 버튼 아이콘. 24x24 또는 32x32 기준.

공통 조건:

- 투명 배경
- 버튼 프레임 없이 아이콘만
- 한눈에 행동이 읽혀야 함
- 색은 UI에서 tint하기 쉽게 너무 복잡하지 않게

### 1-1. 이동

한글 설명: 보스가 전장 격자에서 이동하는 행동. 발자국 또는 격자 화살표가 적합하다.

```text
Create a 32x32 pixel art action icon, transparent background. Theme: movement command for a top-down SRPG about a dungeon cleanup company. Icon: two small boot prints stepping across a simple grid arrow, readable silhouette, chunky pixels, limited palette, dark fantasy comedy tone, Godot 2D UI asset, no text, no frame, no background.
```

### 1-2. 공격

한글 설명: 무기 전사 느낌보다 `현장 제압` 느낌. 클립보드 찍기, 장갑 낀 손, 단순 충격 표시가 맞다.

```text
Create a 32x32 pixel art action icon, transparent background. Theme: suppress attack command for a dungeon cleanup company SRPG. Icon: a rubber-gloved hand slamming a clipboard with a small impact spark, funny dark fantasy worker tone, readable at small size, chunky pixels, limited palette, no sword, no blood, no text, no frame, no background.
```

### 1-3. 방어

한글 설명: 방패 대신 작업용 클립보드/청소 표지판으로 막는 느낌.

```text
Create a 32x32 pixel art action icon, transparent background. Theme: defend command for a dark fantasy dungeon cleanup SRPG. Icon: a sturdy clipboard used like a shield with a small rubber glove behind it, compact silhouette, chunky pixels, limited palette, readable UI asset, no text, no frame, no background.
```

### 1-4. 스킬

한글 설명: 마법보다 `현장 명령`, 직원 호출, 청소 도구 발동 느낌.

```text
Create a 32x32 pixel art action icon, transparent background. Theme: skill command for a dungeon cleanup company SRPG. Icon: a small megaphone with a sparkle and tiny cleanup tool symbol, dark fantasy comedy, worker-management feel, chunky pixels, limited palette, readable at 32x32, no text, no frame, no background.
```

### 1-5. 철수

한글 설명: 패배가 아니라 현장으로 물러나는 행동. 출구 화살표, 문, 작업 가방이 적합하다.

```text
Create a 32x32 pixel art action icon, transparent background. Theme: retreat command for a top-down SRPG. Icon: a small dungeon doorway with an arrow leaving and a tiny cleanup bag, funny dark fantasy company tone, chunky pixels, limited palette, readable UI asset, no text, no frame, no background.
```

### 1-6. 대기

한글 설명: 아무것도 안 하는 게 아니라 상황을 관망하며 턴을 넘기는 행동.

```text
Create a 32x32 pixel art action icon, transparent background. Theme: wait command for a dungeon cleanup SRPG. Icon: a small hourglass beside a clipboard checklist, calm tactical pause feeling, chunky pixels, limited palette, readable at small size, no text, no frame, no background.
```

## 2. 타일 오버레이 스타일

목표: 전투 격자 위에 올리는 반투명 하이라이트 텍스처. 68x68 타일에 맞춰 늘려도 깨지지 않는 단순 형태가 좋다.

공통 조건:

- 투명 배경
- 중앙은 너무 진하지 않게
- 가장자리/모서리 패턴으로 의미 전달
- 실제 구현에서는 ColorRect로 대체 가능하지만, 아트 방향을 잡기 위해 프롬프트를 둔다.

### 2-1. 이동 가능

한글 설명: 파란색 계열, 안전하게 이동 가능한 칸.

```text
Create a 64x64 pixel art tactical tile overlay, transparent background. Meaning: legal movement tile. Blue translucent grid glow, small corner chevrons, clean readable shape, top-down SRPG UI asset, dark fantasy dungeon cleanup game, chunky pixel edges, no text, no icon, no full background.
```

### 2-2. 공격 가능

한글 설명: 빨간색 계열, 기본 공격 가능한 칸/대상.

```text
Create a 64x64 pixel art tactical tile overlay, transparent background. Meaning: basic attack target tile. Red translucent border with small impact marks on the corners, readable top-down SRPG overlay, chunky pixels, limited palette, no text, no character, no background.
```

### 2-3. 스킬 범위

한글 설명: 노랑/청록 계열, 기본 공격과 다른 특수 행동 범위.

```text
Create a 64x64 pixel art tactical tile overlay, transparent background. Meaning: skill target range. Cyan and warm yellow pixel glow, small tool-spark corner marks, dark fantasy cleanup company SRPG tone, readable overlay, chunky pixels, no text, no background.
```

### 2-4. 적 위협

한글 설명: 보라/어두운 빨강 계열, 적이 공격할 수 있는 위험 칸.

```text
Create a 64x64 pixel art tactical tile overlay, transparent background. Meaning: enemy threat area. Dark purple and muted red warning border, subtle jagged danger corners, readable top-down SRPG overlay, limited palette, chunky pixels, no text, no skull, no background.
```

### 2-5. 목표/상호작용

한글 설명: 초록색 계열, 보호/파괴/조작/탈출 같은 목표 칸.

```text
Create a 64x64 pixel art tactical tile overlay, transparent background. Meaning: objective or interaction tile. Muted green border with small cleanup checklist corner marks, top-down SRPG UI asset, dark fantasy comedy tone, chunky pixel style, readable, no text, no full background.
```

### 2-6. 선택 유닛

한글 설명: 현재 행동 유닛을 둘러싸는 흰색/금색 선택 링.

```text
Create a 64x64 pixel art selected-unit ring overlay, transparent background. White and muted gold tactical selection marker, four corner brackets and a subtle pixel pulse shape, top-down SRPG UI asset, readable around a unit sprite, chunky pixels, no text, no background.
```

## 3. 전투 HUD 패널

목표: UI 패널 스타일 기준 이미지. 바로 잘라 쓰기보다 색/질감/형태 방향을 잡는 용도다.

공통 조건:

- 픽셀 UI
- 어두운 던전 금속/석재 느낌
- 코미디 회사물 느낌이 너무 사라지지 않게 클립보드, 서류, 청소 표식 요소 가능
- 텍스트는 넣지 않는다. 실제 글자는 Godot Label로 넣는다.

### 3-1. 턴/목표 바

한글 설명: 화면 상단에 들어갈 현재 턴, 목표, 라운드 표시 바.

```text
Create a wide pixel art HUD panel concept for a top-down SRPG, transparent background. Purpose: top turn and objective bar. Dark dungeon metal and worn clipboard material, muted gold trim, small cleanup company tag shapes, no readable text, no logo, no background scene, Godot 2D UI asset, clean rectangular layout, chunky pixels.
```

### 3-2. 보스 상태 패널

한글 설명: 보스 HP, 행동 상태, 방어 여부를 표시할 작은 상태 패널.

```text
Create a pixel art HUD panel concept, transparent background. Purpose: player boss status panel for a dungeon cleanup company SRPG. Compact dark panel with HP slot, small clipboard tab, rubber glove accent, muted green and gold details, no text, no character portrait, no logo, Godot 2D UI asset, chunky pixels.
```

### 3-3. 적/타겟 패널

한글 설명: 선택한 적의 이름, HP, 예상 피해를 표시할 우측 패널.

```text
Create a pixel art HUD panel concept, transparent background. Purpose: enemy target info panel for a top-down SRPG. Dark stone-and-metal panel, red warning accent, small inspection stamp shape, HP bar slot and damage preview slot, no readable text, no logo, no background, chunky pixel UI for Godot 2D.
```

### 3-4. 전투 로그

한글 설명: 하단 메시지 영역. 현장 보고서처럼 보이면 좋다.

```text
Create a wide pixel art HUD panel concept, transparent background. Purpose: combat log message box for a dark fantasy dungeon cleanup SRPG. Looks like a worn field report clipboard laid over dark metal, muted paper strip, small grime marks, no readable text, no logo, no background scene, chunky pixels, Godot 2D UI asset.
```

## 4. 상태 이펙트

목표: 행동 결과를 짧게 보여줄 작은 이펙트. 32x32 또는 48x48 기준.

### 4-1. 방어 태세

```text
Create a 48x48 pixel art status effect, transparent background. Meaning: defend stance active. A small golden shield-like clipboard glow with blue-grey impact sparks, dark fantasy cleanup company SRPG, chunky pixels, readable effect, no text, no character, no background.
```

### 4-2. 스킬 사용

```text
Create a 48x48 pixel art status effect, transparent background. Meaning: field command skill activated. A small megaphone burst with cyan pixel sparks and tiny cleanup tool silhouettes, dark fantasy comedy SRPG, chunky pixels, limited palette, no text, no background.
```

### 4-3. 피해

```text
Create a 48x48 pixel art hit effect, transparent background. Meaning: non-gory impact damage. Red-orange pixel impact burst with dust and tiny paper scraps, funny dungeon cleanup SRPG tone, no blood, no text, no character, chunky pixels, readable at small size.
```

### 4-4. 회피/실패

```text
Create a 48x48 pixel art miss effect, transparent background. Meaning: attack missed or action failed. Pale grey swoosh with a small tilted caution cone silhouette, dark fantasy cleanup comedy, chunky pixels, limited palette, no text, no background.
```

### 4-5. 승리

```text
Create a 48x48 pixel art victory effect, transparent background. Meaning: battle objective cleared. Muted gold checklist sparkle with a tiny clean tile shine, dungeon cleanup company SRPG, chunky pixels, limited palette, no text, no logo, no background.
```

### 4-6. 패배

```text
Create a 48x48 pixel art defeat effect, transparent background. Meaning: battle failed but not horror. Crumpled field report paper with a muted red warning stamp shape, dark fantasy comedy SRPG, chunky pixels, no readable text, no logo, no blood, no background.
```

## 5. 전장 오브젝트

목표: 나중에 전투 목표로 쓰일 격자 오브젝트. 48x48 또는 64x64 기준.

### 5-1. 시체 포대

```text
Create a 48x48 pixel art top-down SRPG battlefield object, transparent background. Object: tied corpse bag for a dungeon cleanup company job, dark cloth sack with tag and rope, dark fantasy comedy tone, not graphic, no blood, readable silhouette, chunky pixels, Godot 2D asset, no text, no background.
```

### 5-2. 오염 핵

```text
Create a 48x48 pixel art top-down SRPG battlefield object, transparent background. Object: slime pollution core that must be cleaned or destroyed, glowing green-purple sludge crystal, dark fantasy cleanup company theme, chunky pixels, readable at small size, no text, no background.
```

### 5-3. 경보 장치

```text
Create a 48x48 pixel art top-down SRPG battlefield object, transparent background. Object: improvised dungeon alarm device used by human inspectors, small bell and red lever on a tripod, dark fantasy comedy, chunky pixels, readable silhouette, no text, no logo, no background.
```

### 5-4. 고장난 함정

```text
Create a 48x48 pixel art top-down SRPG battlefield object, transparent background. Object: broken dungeon trap needing repair, cracked pressure plate with loose springs and warning grime, dark fantasy cleanup company tone, chunky pixels, readable, no text, no background.
```

### 5-5. 탈출 타일

```text
Create a 64x64 pixel art top-down SRPG tile asset, transparent background. Meaning: retreat or extraction tile. Dungeon floor tile with muted green exit arrow symbol made of pixels and a small cleanup bag marker, dark fantasy comedy, readable overlay/object hybrid, no text, no full background.
```

## 6. 파일 저장 후보

실제 이미지를 나중에 뽑으면 아래처럼 분리한다.

```text
assets/sprites/ui/battle/actions/
assets/sprites/ui/battle/overlays/
assets/sprites/ui/battle/panels/
assets/sprites/ui/battle/effects/
assets/sprites/battle/objects/
```

현재 goal에서는 위 폴더나 이미지를 만들지 않는다. 프롬프트 문서만 만든다.

