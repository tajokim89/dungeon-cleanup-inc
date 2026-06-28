# 캐릭터 제작 프롬프트 — GPT 픽셀 레퍼런스 → Pixcellab 스프라이트

## 0. 사용 목적

현재 `Office.tscn`은 사장 캐릭터 이미지를 임시 SVG로 사용한다.

```text
assets/sprites/boss_placeholder.svg
```

제작 순서는 다음으로 잡는다.

1. GPT 이미지 생성으로 귀여운 캐릭터 기준 이미지를 만든다.
2. 마음에 드는 결과를 Pixcellab reference image로 넣는다.
3. Pixcellab에서 실제 게임용 픽셀 스프라이트를 뽑는다.
4. 우선 단일 idle 이미지를 다음 경로로 저장한다.

```text
assets/sprites/boss_player.png
```

초기 권장 기준:

```text
48x48
transparent background
pixel art
top-down 3/4 view
single idle frame first
```

32x32은 얼굴이 귀엽게 읽히기 어렵다. 64x64은 나중에 타일/충돌 스케일과 맞출 때 부담이 커질 수 있다. 지금은 48x48 단일 스프라이트가 적당하다.

## 1. GPT 이미지 생성용 프롬프트 3개

GPT에서도 처음부터 픽셀아트 느낌을 강하게 잡는다. 목표는 말끔한 치비 일러스트가 아니라, 작은 화면에서 읽히는 "투박하지만 귀여운 몬스터 측 사장"이다.

피해야 할 방향:

```text
MapleStory-style, glossy anime mascot, clean mobile RPG character, smooth illustration, plastic chibi, big polished eyes, overly cute idol look
```

### GPT-1. 작은 고블린 사장

```text
Create a small pixel art character reference, 48x48 game sprite style, transparent background, top-down 3/4 view. Character: a tiny goblin boss who runs a dungeon cleanup company. Cute but scrappy, not polished. Short body, slightly big head, small tired eyes, tiny fangs, round ears, simple dark work coat, rubber gloves, little tool belt, small clipboard. Make it feel like an indie pixel game NPC, readable silhouette, limited palette, chunky pixels, no smooth anime illustration, no MapleStory style, no glossy mobile RPG look, no weapon, no text.
```

### GPT-2. 피곤하지만 귀여운 현장 대표

```text
Pixel art sprite concept, 48x48, top-down 3/4 view, transparent background. A worn-out but cute goblin field manager for a monster-side dungeon sanitation company. Compact body, stubby legs, small boots, tired half-lidded eyes, tiny confident grin, oversized patched work jacket, rubber gloves, mini brush and cloth on the belt. Keep it rough, charming, and readable, like a small indie tactics game unit. Muted dungeon colors with one warm accent. Avoid smooth concept art, avoid anime mascot, avoid MapleStory proportions, avoid huge shiny eyes, no background, no text.
```

### GPT-3. 마왕성 납품업체 사장

```text
Create a 48x48 pixel art game sprite reference, transparent background, top-down 3/4 view. Character: goblin-like small business owner contracted by the Demon Castle, responsible for cleaning slime, repairing traps, and restoring dungeons. Cute in a rough worker way: squat silhouette, pointy ears, small nose, tired eyes, simple work coat, rubber gloves, tool pouch, folded invoice paper. Make the sprite chunky, low-detail, readable, slightly funny, and grounded in dark fantasy. No clean modern CEO suit, no shiny anime chibi, no MapleStory style, no weapon, no text, no background.
```

## 2. Pixcellab용 프롬프트 3개

Pixcellab에는 GPT에서 만든 마음에 드는 이미지를 reference image로 넣고 아래 프롬프트를 사용한다.

### Pixcellab-1. 단일 idle 스프라이트

```text
Use the reference image to create a 48x48 pixel art game character sprite, transparent background, top-down 3/4 view, single idle pose. Keep the same character identity: tiny goblin dungeon cleanup company boss, squat body, pointy ears, tired eyes, tiny fangs, patched work coat, rubber gloves, compact tool belt, small boots. Make it cute but rough, not glossy. Clear silhouette, chunky pixels, limited palette, readable at small size, no background, no text, no logo, no weapon, no MapleStory style.
```

### Pixcellab-2. 4방향 idle 스프라이트시트

```text
Use the reference image to create a pixel art character sprite sheet, 48x48 per frame, transparent background, 4 direction idle poses: down, left, right, up. Keep the character consistent in every direction: tiny goblin dungeon cleanup boss, squat body, pointy ears, tired eyes, patched work coat, rubber gloves, tool belt, small boots. Top-down indie game style, chunky pixels, limited palette, readable silhouette, no background, no text, no weapon, no glossy anime chibi, no MapleStory style.
```

### Pixcellab-3. 4방향 걷기 스프라이트시트

```text
Use the reference image to create a pixel art walking sprite sheet, 48x48 per frame, transparent background, 4 directions: down, left, right, up, 3 frames per direction. Keep the same tiny goblin dungeon cleanup boss design: squat body, pointy ears, tired eyes, tiny fangs, patched work coat, rubber gloves, compact tool belt, small boots. Small readable movement, chunky pixels, consistent proportions, limited palette, no background, no text, no logo, no weapon, no glossy anime chibi, no MapleStory style.
```

## 3. 공통 Negative Prompt

GPT나 Pixcellab에서 결과가 너무 안 귀엽거나 칙칙해질 때 같이 넣는다.

```text
MapleStory-style, glossy anime mascot, clean mobile RPG character, plastic chibi, huge shiny eyes, idol character, smooth illustration, realistic render, over-detailed armor, weapon, blood, horror, scary, creepy, long limbs, bulky body, muddy unreadable colors, low contrast, messy silhouette, blurry, background, text, logo, extra arms, extra legs, distorted hands, realistic proportions
```

## 4. 파일 교체 기준

단일 이미지부터 시작한다.

```text
assets/sprites/boss_player.png
```

나중에 이동 애니메이션을 넣을 때:

```text
assets/sprites/boss_walk_sheet.png
```

현재 코드에서는 우선 `Office.gd`의 `BossTexture`만 교체하면 된다.

```gdscript
const BossTexture = preload("res://assets/sprites/boss_player.png")
```

## 5. 피해야 할 결과

```text
정면 초상화만 있는 이미지
배경이 포함된 이미지
너무 큰 일러스트
무기 든 전사처럼 보이는 디자인
무섭거나 징그러운 디자인
현대 회사원만 보이고 던전/위생업체 느낌이 없는 디자인
실루엣이 뭉개지는 과한 디테일
색이 어둡고 탁해서 작은 화면에서 안 읽히는 디자인
```
