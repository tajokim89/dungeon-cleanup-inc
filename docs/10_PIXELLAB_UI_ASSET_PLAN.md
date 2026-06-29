# Pixellab UI Asset Plan

작성일: 2026-06-29

목적:

- Pixellab에서 무엇을 생성해야 하는지 바로 알 수 있게 한다.
- A2 오피스 샘플을 기준으로 Godot UI에 넣을 부품 단위 프롬프트를 정리한다.
- 한글 텍스트는 이미지에 굽지 않고 Godot Label로 얹는다.

참고:

- `assets/sample/A2_office_hub.png`
- `assets/sample/D3_simplified_combat_event.png`
- Pixellab 공식 문서:
  - `https://www.pixellab.ai/docs/tools/create-ui-elements`
  - `https://www.pixellab.ai/docs/tools/create-ui-elements-pro`

## 0. Pixellab 문서에서 확인한 제약

`Create UI elements`:

- 텍스트 설명으로 UI 컴포넌트 1개를 생성한다.
- 생성 전에 width/height 캔버스 크기를 정한다.
- `No background` 옵션으로 투명 배경을 만들 수 있다.
- 한 번 실행하면 이미지 1장만 나온다.
- 캔버스 크기 제한은 계정 티어와 inpainting/depth 사용 여부에 따라 달라진다.

`Create UI elements Pro`:

- 텍스트 설명으로 게임 UI 컴포넌트를 생성한다.
- `No Background`, `Color Palette`, `Concept Image`, `Seed`를 쓸 수 있다.
- 크기에 따라 후보 그리드와 생성 비용이 달라진다.
- 최대 이미지 크기는 `512x512`다.

따라서 여기서는 `A2_office_hub.png`를 전체 화면 정답지로 쓰지 않고, Pro의 `Concept Image` 또는 일반 도구의 `Init image`로 스타일 참고에만 쓴다.

## 1. 결론

Pixellab에는 전체 화면 UI 레이아웃을 맡기지 않는다.

Pixellab에서는 아래만 만든다.

```text
프레임
버튼
아이콘
게이지
툴팁
작은 패널
타일 오버레이
```

Godot에서는 아래를 한다.

```text
실제 화면 배치
한글 텍스트
수치 갱신
버튼 상태
패널 열기/닫기
반응형 위치
```

이유:

- Pixellab `Create UI elements`는 단일 UI 컴포넌트 생성용이다.
- Pro는 작은 아이콘/버튼/오버레이 후보 그리드와 최대 512x512 패널 생성에 맞다.
- 한글 텍스트를 이미지에 굽으면 수정이 어렵고 결과가 깨질 수 있다.

## 2. 도구 선택 기준

### Create UI elements

사용할 때:

- 결과가 1개만 필요할 때
- 특정 크기의 프레임/버튼/게이지를 단일 이미지로 뽑을 때
- 빠르게 한 부품씩 확정할 때
- 캔버스 크기가 현재 계정 제한 안에 확실히 들어갈 때

추천 대상:

- 상호작용 툴팁
- 하단 메시지 바 프레임
- 단일 게이지 바
- 단일 버튼 프레임
- 단일 타일 오버레이

### Create UI elements Pro

사용할 때:

- 같은 스타일의 후보를 여러 개 보고 고를 때
- 버튼/아이콘/슬롯처럼 세트로 톤을 맞춰야 할 때
- A2 샘플을 concept image로 넣고 스타일을 맞출 때
- 일반 도구 제한을 넘는 큰 패널을 `512x512` 안에서 뽑을 때

추천 대상:

- 하단 퀵 메뉴 아이콘 세트
- 전투 행동 아이콘 세트
- 상태 카드 프레임 후보
- 타일 오버레이 후보
- 512px급 큰 패널 후보

주의:

- Pro는 사이즈 구간에 따라 그리드와 생성 비용이 달라진다.
- 작은 크기는 후보가 많이 나오고, 171px 이상은 후보 수가 줄어든다.
- 큰 화면 전체를 만들기보다 32, 64, 128, 256, 512 안의 부품을 뽑는다.

## 3. A2 기준 UI 분해와 배치

A2는 아래 부품으로 나눠서 생성한다.

```text
상단 HUD 카드
상단 상태 게이지
하단 메시지 바
좌하단 퀵 메뉴 버튼
상호작용 툴팁
의뢰 게시판 패널
직원/장비 패널
출동/정산 확인 패널
```

생성하지 말아야 할 것:

```text
전체 오피스 화면
한글 텍스트가 들어간 버튼
게임 수치가 박힌 카드
고정 해상도 전용 전체 UI 스크린샷
```

1270x720 Godot 배치 기준:

```text
상단 HUD:     x 16~1210, y 8~88
오피스 월드:  x 0~1270, y 92~590
좌하단 메뉴:  x 24~310, y 620~700
하단 메시지:  x 340~910, y 610~704
우하단 정보:  x 930~1248, y 610~704
툴팁:         상호작용 오브젝트 위, 월드 좌표에 따라 표시
```

Pixellab은 위 배치를 만들지 않는다. 위 배치는 Godot `Control`/`CanvasLayer`에서 고정하고, Pixellab 결과물은 각 칸 안에 들어갈 프레임/아이콘/오버레이로만 쓴다.

## 4. 공통 프롬프트 규칙

모든 프롬프트 끝에 붙인다.

```text
transparent background, no readable text, no letters, no numbers, pixel art game UI asset, dark fantasy dungeon cleanup company theme, worn brass trim, black stone and dark wood, subtle grime, readable at small size, clean silhouette, Godot 2D UI asset
```

한글 텍스트는 절대 요청하지 않는다.

색 팔레트:

```text
black stone, dark charcoal, worn brass, muted gold, dirty parchment, slime green accent, cyan hygiene accent, purple trust accent, red risk accent
```

## 5. 우선 생성 목록

### 5-1. 상단 HUD 카드 프레임

용도:

- Day, 자금, 신뢰, 평판, 위생, 리스크 공통 카드

도구:

- `Create UI elements`

크기:

- `256x96`

프롬프트:

```text
Create a horizontal pixel art HUD stat card frame for a dark fantasy dungeon cleanup management game. Empty center for engine-rendered Korean text and numbers. Left circular icon socket, right horizontal gauge slot, black stone panel, worn brass trim, tiny bolts, subtle grime, readable at small UI scale, transparent background, no readable text, no letters, no numbers, Godot 2D UI asset.
```

Godot 배치:

- 상단 HUD에 5~6개 반복 사용
- 아이콘/텍스트/게이지는 별도 노드로 얹기

### 5-2. 상태 게이지 바

용도:

- 마왕성 신뢰, 인간 평판, 위생, 불법 리스크

도구:

- `Create UI elements Pro`

크기:

- `128x24`

프롬프트:

```text
Create pixel art horizontal progress bar UI frames for dungeon cleanup company resources. Empty fill area, small brass border, black recessed background, subtle worn metal corners, multiple variants for trust, reputation, hygiene, risk. Transparent background, no readable text, no letters, no numbers, Godot 2D UI asset.
```

Godot 배치:

- 프레임 이미지는 고정
- 실제 fill은 ColorRect 또는 별도 1px/9-slice로 처리

### 5-3. 하단 메시지 바

용도:

- 상호작용 안내, 결과 로그, 현재 상태

도구:

- `Create UI elements`

크기:

- `512x96`

메모:

- 일반 도구에서 계정 제한에 걸리면 `384x72`로 뽑고 Godot에서 9-slice로 늘린다.

프롬프트:

```text
Create a wide pixel art bottom message panel frame for a dark fantasy dungeon cleanup office game. Black lacquer and dark stone interior, worn brass border, small corner bolts, slightly dirty field-report feel, large empty center for engine-rendered Korean prompt text. Transparent background, no readable text, no letters, no numbers, Godot 2D UI asset.
```

Godot 배치:

- 1270x720 기준 하단 중앙
- 필요하면 9-slice로 늘려 쓰기

### 5-4. 상호작용 툴팁

용도:

- `E / Space: 의뢰 게시판`

도구:

- `Create UI elements`

크기:

- `256x72`

프롬프트:

```text
Create a compact pixel art interaction tooltip frame. Black panel, worn brass outline, small downward pointer triangle, dark fantasy monster office style, empty interior for keyboard prompt text added in engine. Transparent background, no readable text, no letters, no numbers, clean silhouette, Godot 2D UI asset.
```

Godot 배치:

- 오브젝트 위에 표시
- 텍스트는 Label로 얹기

### 5-5. 좌하단 퀵 메뉴 버튼

용도:

- 의뢰, 직원, 장비, 연구, 회사

도구:

- `Create UI elements Pro`

크기:

- `64x64`

프롬프트:

```text
Create a set of square pixel art quick menu button icons for a dark fantasy dungeon cleanup management game. Icons: contract scroll, staff skull badge, crossed cleanup tools, potion flask research, company building. Matching black stone button base, worn brass frame, selected-state friendly silhouette, transparent background, no readable text, no letters, no numbers, Godot 2D UI asset.
```

Godot 배치:

- 아이콘 이미지만 버튼 안에 넣기
- 선택/hover/disabled는 Godot tint 또는 별도 StyleBox로 처리

### 5-6. 의뢰 게시판 패널

용도:

- 오피스 의뢰 선택 UI

도구:

- `Create UI elements Pro`

크기:

- `512x384`

대안:

- Pro 비용이 부담되면 일반 도구에서 `320x240` 빈 게시판 프레임만 먼저 뽑고 Godot에서 확대/9-slice 처리한다.

프롬프트:

```text
Create a pixel art contract board UI panel for a dungeon cleanup company office. Wooden notice board with dirty parchment sheets, brass title plate area, several blank paper slots for contract cards, dark fantasy workplace comedy tone, empty spaces for engine-rendered Korean labels. Transparent background, no readable text, no letters, no numbers, Godot 2D UI asset.
```

Godot 배치:

- 의뢰 게시판 팝업의 배경 프레임
- 개별 의뢰 카드와 텍스트는 Godot Control로 배치

### 5-7. 직원/장비 편성 패널

용도:

- 직원 선택, 장비 선택, 출동 준비

도구:

- `Create UI elements Pro`

크기:

- `512x384`

대안:

- Pro 비용이 부담되면 일반 도구에서 `320x240` 슬롯 프레임만 뽑고 카드/칸은 Godot Control로 만든다.

프롬프트:

```text
Create a pixel art dispatch preparation panel for a dark fantasy dungeon cleanup company. Split empty slots for staff cards and equipment items, black stone and dark wood frame, worn brass separators, small monster office details, no readable text, no letters, no numbers, transparent background, Godot 2D UI asset.
```

Godot 배치:

- 직원/장비 선택 팝업 공통 프레임
- 카드/수치/상태는 Godot Label과 Button으로 처리

### 5-8. 정산 보고 패널

용도:

- 하루 결과, 보상, 신뢰/평판/위생/리스크 변화

도구:

- `Create UI elements Pro`

크기:

- `512x384`

대안:

- Pro 비용이 부담되면 일반 도구에서 `320x240` 보고서 프레임만 뽑고 행/수치는 Godot Label로 만든다.

프롬프트:

```text
Create a pixel art settlement report panel for a dungeon cleanup company. Worn clipboard over dark metal frame, dirty parchment report area, brass clips, small wax seal space, empty rows for reward and reputation changes, no readable text, no letters, no numbers, transparent background, Godot 2D UI asset.
```

Godot 배치:

- 정산 결과 화면 배경
- 변화량은 Godot Label로 표시

### 5-9. 전투 행동 아이콘

용도:

- 이동, 공격, 방어, 스킬, 철수, 대기

도구:

- `Create UI elements Pro`

크기:

- `32x32`

프롬프트:

```text
Create a matching set of 32x32 pixel art SRPG action icons for a dungeon cleanup company combat event. Icons: movement boots on grid, authority attack stamp, clipboard shield defend, staff support whistle skill, retreat door arrow, wait hourglass. Transparent background, no readable text, no letters, no numbers, strong silhouettes, limited palette, Godot 2D UI asset.
```

Godot 배치:

- 전투 명령 버튼 왼쪽 아이콘
- 버튼 텍스트는 Godot Label

### 5-10. 전투 타일 오버레이

용도:

- 이동 가능, 공격 가능, 스킬 범위, 적 위협, 목표, 장애물

도구:

- `Create UI elements Pro`

크기:

- `64x64`

프롬프트:

```text
Create a matching set of 64x64 transparent pixel art tactical tile overlays for a top-down SRPG dungeon cleanup event. Variants: blue movement tile, red attack tile, cyan skill tile, dark purple enemy threat tile, green objective tile, gray blocked obstacle tile. No readable text, no letters, no numbers, clear border shapes, chunky pixel corners, Godot 2D UI asset.
```

Godot 배치:

- 현재 ColorRect 하이라이트를 이미지 오버레이로 교체

## 6. 작업 순서

추천 순서:

```text
1. 하단 메시지 바
2. 상호작용 툴팁
3. 상단 HUD 카드 프레임
4. 좌하단 퀵 메뉴 버튼
5. 의뢰 게시판 패널
6. 전투 행동 아이콘
7. 전투 타일 오버레이
8. 직원/장비 편성 패널
9. 정산 보고 패널
```

이유:

- 1~4는 Office/Dungeon/Battle 공통 체감을 바로 올린다.
- 5는 의뢰 선택 UI 실제화에 필요하다.
- 6~7은 SRPG 전투가 빈 프로토타입처럼 보이는 문제를 줄인다.
- 8~9는 경영 루프가 더 굵어질 때 붙인다.

## 7. Godot 적용 규칙

- 이미지는 `assets/ui/` 아래에 넣는다.
- 원본 후보는 `assets/ui/source/` 또는 `assets/sample/`에 보관한다.
- 최종 사용 이미지만 씬/스크립트에서 참조한다.
- 한글 텍스트, 숫자, 게이지 값은 모두 Godot에서 렌더링한다.
- 늘려 쓸 프레임은 가능하면 9-slice 가능한 형태로 만든다.
- 버튼 상태는 이미지에 굽지 말고 Godot에서 normal/hover/pressed/disabled 스타일로 처리한다.

## 8. 지금 당장 만들 것

최초 Pixellab 생성 3개:

```text
1. 512x96 하단 메시지 바
2. 256x72 상호작용 툴팁
3. 256x96 상단 HUD 카드 프레임
```

이 3개만 있어도 A2 느낌을 현재 Godot UI에 바로 얹을 수 있다.

실행 메모:

- 1번이 일반 Create UI 계정 제한에 걸리면 `384x72`로 먼저 만든다.
- 2~3번은 일반 Create UI로 먼저 확정한다.
- A2 이미지는 `Init image` 또는 Pro `Concept Image`로만 넣고, 화면 전체를 다시 생성하지 않는다.
