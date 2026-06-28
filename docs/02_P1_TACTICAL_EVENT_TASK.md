# Codex 상세 작업 지시서 — P1 전술 이벤트 1종

## 목표

P0 경영 루프가 완성된 뒤, 위험 의뢰 1개에만 짧은 전술 이벤트를 연결한다.

전투는 게임의 본체가 아니다. 목적은 “경영 판단의 위험 상황을 짧게 체험”하게 하는 것이다.

## 생성/수정 파일

```text
scenes/TacticalEvent.tscn
scripts/TacticalEvent.gd
scripts/Main.gd
```

## 전술 이벤트 조건

- 특정 의뢰에 `requires_tactical_event = true` 추가.
- 처리 방식 선택 후 바로 정산하지 않고 TacticalEvent 화면으로 이동.
- TacticalEvent 성공/실패 결과를 Main.gd로 돌려보내 정산에 반영.

## MVP 전술 규칙

- 5x5 그리드
- 턴 제한: 3턴
- 아군: 청소팀 토큰 1개
- 목표: `시체 포대`를 들고 출구까지 이동
- 위험: 인간 정찰병 1명 또는 오염 타일 2개
- 승리: 3턴 안에 출구 도달
- 실패: 턴 초과 또는 HP 0

## TacticalEvent.gd 상태

```gdscript
var turn: int = 1
var max_turn: int = 3
var player_pos: Vector2i = Vector2i(0, 4)
var exit_pos: Vector2i = Vector2i(4, 0)
var player_hp: int = 2
var carrying_body: bool = true
var pollution_tiles: Array[Vector2i] = [Vector2i(2, 2), Vector2i(3, 1)]
```

## 조작

- 버튼 기반 이동: 상/하/좌/우
- 이동마다 턴 +1
- 오염 타일 밟으면 HP -1
- 출구 도달 시 success

## UI

- 상단: `전술 이벤트: 시체 포대 회수`
- 상태: `Turn 1/3 | HP 2 | 목표: 출구 도달`
- 5x5 GridContainer
- 각 셀 텍스트:
  - 청소팀: `팀`
  - 출구: `출`
  - 오염: `오염`
  - 빈칸: `·`
- 하단 이동 버튼 4개

## Main.gd 연동

P0의 result 계산 전에 전술 이벤트가 필요한 경우:

1. 현재 선택 의뢰/직원/장비/처리방식을 보존
2. TacticalEvent로 전환
3. 성공하면 정산 보너스:
   - hell_trust +3
   - hygiene +3
4. 실패하면 패널티:
   - hell_trust -5
   - hygiene -8
   - selected staff stamina -10 추가

## 완료 기준

- 위험 의뢰 선택 시 전술 이벤트가 나온다.
- 이동 버튼으로 5x5 그리드에서 위치가 바뀐다.
- 승리/실패 후 경영 화면 정산으로 돌아온다.
- 전투는 1분 이내에 끝난다.
