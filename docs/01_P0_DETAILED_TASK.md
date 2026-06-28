# Codex 상세 작업 지시서 — P0 경영 루프 구현

## 프로젝트

- 게임명: **던전 클린업 주식회사**
- 엔진: Godot 4.7 Standard
- 언어: GDScript
- 개발 경로:
  - WSL: `/mnt/c/Users/tajok/dev/dungeon-cleanup-inc`
  - Windows: `C:\Users\tajok\dev\dungeon-cleanup-inc`

## Codex에게 주는 목표

이 작업은 제목 화면이 아니라 **실제 P0 MVP 경영 루프**를 구현하는 작업이다.

플레이어가 5일 동안 몬스터 측 던전 복구·위생 관리업체를 운영하며, 매일 의뢰를 고르고, 직원/장비를 배치하고, 처리 방식을 선택하고, 자원 변화를 확인한 뒤 최종 등급을 받는 플레이 가능한 루프를 만든다.

전술/SRPG 전투는 이번 작업에서 구현하지 않는다. 전투는 P1이다.

---

# 1. 현재 상태 가정

이미 존재한다고 가정:

```text
scenes/Main.tscn
scripts/Main.gd
scenes/
scripts/
data/
assets/
docs/
```

`scenes/Main.tscn`의 루트 노드는 `Control`이고 이름은 `Main`이다.

---

# 2. 이번 작업에서 만들 파일

## 생성

```text
data/GameData.gd
```

## 수정

```text
scripts/Main.gd
scenes/Main.tscn
```

필요하면 `Main.tscn`은 스크립트 연결만 확인/수정한다.

---

# 3. 구현 범위

## 반드시 구현할 것

1. 5일 진행 루프
2. 매일 의뢰 3개 표시
3. 의뢰 1개 선택
4. 직원 2명 선택
5. 장비 최대 2개 선택
6. 처리 방식 1개 선택
7. 결과 정산
8. 하루 종료
9. 5일 후 최종 등급 표시
10. 실패 조건 체크

## 구현하지 말 것

- 전술 전투
- 픽셀아트 에셋
- 저장/로드
- 옵션 메뉴
- 사운드
- 애니메이션
- 복잡한 스킬/클래스
- 랜덤 던전

---

# 4. 게임 자원

`Main.gd`에서 다음 상태를 관리한다.

```gdscript
var day: int = 1
var max_day: int = 5
var money: int = 300
var hell_trust: int = 50
var human_reputation: int = 10
var hygiene: int = 70
var illegal_risk: int = 0
```

## 실패 조건

매 정산 후 체크한다.

```text
money <= 0              파산
hell_trust <= 0         마왕성 계약 해지
illegal_risk >= 100     불법 처리 적발
직원 전원 injured=true  운영 불가
```

## 성공 조건

5일 종료 후 최종 평가 표시.

---

# 5. 데이터 파일: data/GameData.gd

`data/GameData.gd`는 `class_name GameData`를 가진다.

아래 데이터를 함수로 반환한다.

```gdscript
extends RefCounted
class_name GameData

static func get_staff() -> Array[Dictionary]:
    return [
        {
            "id": "grik",
            "name": "그릭",
            "species": "고블린",
            "role": "잡동사니 회수",
            "cleanup": 3,
            "pollution": 1,
            "hauling": 1,
            "trap": 1,
            "stamina": 100,
            "injured": false
        },
        {
            "id": "melta",
            "name": "멜타",
            "species": "슬라임",
            "role": "오염 제거",
            "cleanup": 2,
            "pollution": 4,
            "hauling": 1,
            "trap": 1,
            "stamina": 100,
            "injured": false
        },
        {
            "id": "volg",
            "name": "볼그",
            "species": "오크",
            "role": "시체/잔해 운반",
            "cleanup": 2,
            "pollution": 1,
            "hauling": 4,
            "trap": 1,
            "stamina": 100,
            "injured": false
        },
        {
            "id": "pipit",
            "name": "피핏",
            "species": "임프",
            "role": "함정 복구/장부 조작",
            "cleanup": 1,
            "pollution": 1,
            "hauling": 1,
            "trap": 4,
            "stamina": 100,
            "injured": false
        }
    ]

static func get_gear() -> Array[Dictionary]:
    return [
        {"id": "disinfect_slime", "name": "소독 점액통", "cost": 20, "effect": "pollution", "power": 2},
        {"id": "corpse_bag", "name": "사체 운반 포대", "cost": 15, "effect": "hauling", "power": 2},
        {"id": "trap_kit", "name": "함정 수리 키트", "cost": 25, "effect": "trap", "power": 2},
        {"id": "relic_lens", "name": "유품 감정 렌즈", "cost": 20, "effect": "human_profit", "power": 15},
        {"id": "black_ledger", "name": "검은 장부", "cost": 0, "effect": "illegal_profit", "power": 30}
    ]

static func get_contract_pool() -> Array[Dictionary]:
    return [
        {
            "id": "goblin_barracks_cleanup",
            "title": "고블린 막사 사후 정리",
            "client": "지하 2층 막사 관리실",
            "pay": 75,
            "difficulty": 2,
            "primary_stat": "cleanup",
            "description": "용사 파티가 지나간 뒤 침상, 식기, 부서진 방패를 정리해야 한다.",
            "options": ["proper_restore", "cheap_cleanup", "black_market"]
        },
        {
            "id": "holy_water_sanitation",
            "title": "성수 오염 구역 소독",
            "client": "흡혈귀 거주구",
            "pay": 90,
            "difficulty": 3,
            "primary_stat": "pollution",
            "description": "성기사의 성수 폭탄이 터진 복도를 소독해야 한다.",
            "options": ["proper_restore", "cheap_cleanup", "corpse_return"]
        },
        {
            "id": "treasure_room_repair",
            "title": "보물방 약탈 피해 복구",
            "client": "미믹 조합",
            "pay": 110,
            "difficulty": 3,
            "primary_stat": "trap",
            "description": "보물상자 위장 장치와 경보 함정을 복구해야 한다.",
            "options": ["proper_restore", "cheap_cleanup", "black_market"]
        },
        {
            "id": "mimic_corpse_recovery",
            "title": "미믹 사체 회수",
            "client": "던전 생태관리과",
            "pay": 100,
            "difficulty": 3,
            "primary_stat": "hauling",
            "description": "반쯤 열린 미믹 사체와 안에 남은 인간 장비를 수습해야 한다.",
            "options": ["proper_restore", "corpse_return", "black_market"]
        },
        {
            "id": "human_body_return",
            "title": "인간 모험가 시체 반환",
            "client": "던전 외곽 연락소",
            "pay": 60,
            "difficulty": 2,
            "primary_stat": "hauling",
            "description": "인간 길드에서 시체 반환 요청이 들어왔다. 유료 인도 가능.",
            "options": ["corpse_return", "black_market", "cheap_cleanup"]
        },
        {
            "id": "sealed_route_repair",
            "title": "침입로 봉쇄 및 함정 복구",
            "client": "마왕성 보안감사실",
            "pay": 120,
            "difficulty": 4,
            "primary_stat": "trap",
            "description": "도적 파티가 뚫어놓은 비밀 통로를 막고 함정을 다시 설치해야 한다.",
            "options": ["proper_restore", "cheap_cleanup"]
        }
    ]

static func get_resolution_options() -> Dictionary:
    return {
        "proper_restore": {
            "name": "정식 복구",
            "desc": "규정대로 처리한다. 수익은 낮지만 신뢰와 위생이 좋아진다.",
            "money_bonus": 0,
            "hell_trust": 6,
            "human_reputation": 0,
            "hygiene": 8,
            "illegal_risk": 0,
            "stamina_cost": 18
        },
        "cheap_cleanup": {
            "name": "저가 처리",
            "desc": "보이는 곳만 치운다. 비용은 줄지만 위생과 신뢰가 떨어질 수 있다.",
            "money_bonus": 25,
            "hell_trust": -4,
            "human_reputation": 0,
            "hygiene": -8,
            "illegal_risk": 5,
            "stamina_cost": 10
        },
        "corpse_return": {
            "name": "시체 유료 인도",
            "desc": "인간 길드에 시체/유품을 유료 반환한다.",
            "money_bonus": 45,
            "hell_trust": -2,
            "human_reputation": 8,
            "hygiene": 2,
            "illegal_risk": 8,
            "stamina_cost": 16
        },
        "black_market": {
            "name": "암시장 판매",
            "desc": "주운 인간 장비와 유품을 몰래 판다. 돈은 좋지만 위험하다.",
            "money_bonus": 70,
            "hell_trust": -6,
            "human_reputation": -5,
            "hygiene": -3,
            "illegal_risk": 20,
            "stamina_cost": 14
        }
    }
```

---

# 6. Main.gd 상태 머신

`Main.gd`는 다음 화면 상태를 가진다.

```gdscript
var phase: String = "contract_select"
```

허용 phase:

```text
contract_select   오늘 의뢰 선택
staff_select      직원/장비 선택
resolution_select 처리 방식 선택
result            정산 결과
game_over         최종 결과 또는 실패
```

---

# 7. UI 요구사항

모든 UI는 코드로 생성해도 된다. 아트 없음.

## 공통 HUD

항상 상단에 표시:

```text
Day 1/5 | 자금 300 | 마왕성 신뢰 50 | 인간 평판 10 | 위생 70 | 불법 리스크 0
```

## contract_select 화면

- 제목: `오늘의 사고 접수`
- 의뢰 카드 3개 표시
- 각 카드 표시 내용:
  - 의뢰명
  - 의뢰인
  - 보수
  - 난이도
  - 설명
- 각 카드 버튼: `이 의뢰 선택`

선택하면 `selected_contract`에 저장하고 `staff_select`로 이동.

## staff_select 화면

- 선택한 의뢰 요약 표시
- 직원 4명 표시
- 직원은 정확히 2명 선택 가능
- 장비 5개 표시
- 장비는 최대 2개 선택 가능
- 버튼: `팀 확정`
- 직원 2명 선택 전에는 팀 확정 버튼 disabled

장비 비용은 팀 확정 시 차감한다. 돈 부족하면 로그에 표시하고 진행하지 않는다.

## resolution_select 화면

- 선택한 의뢰의 가능한 처리 방식만 표시
- 각 처리 방식의 설명과 예상 변화 표시
- 버튼 클릭 시 결과 계산 후 result 화면으로 이동

## result 화면

- 이번 의뢰 결과 표시
- 변경된 자원 표시
- 직원 피로/부상 변화 표시
- 버튼:
  - `다음 날로` 또는 5일차 이후 `최종 평가 보기`

## game_over 화면

- 실패 사유 또는 최종 등급 표시
- 최종 자원 요약 표시
- 버튼: `처음부터 다시`

---

# 8. 의뢰 3개 선정 방식

MVP에서는 단순하게 한다.

- `contract_pool`에서 day 기준으로 3개를 순환 표시한다.
- 랜덤은 사용하지 않아도 된다.
- 같은 의뢰가 반복되어도 MVP에서는 허용한다.

예:

```gdscript
func generate_today_contracts() -> void:
    today_contracts.clear()
    var pool = GameData.get_contract_pool()
    for i in range(3):
        var idx = ((day - 1) * 3 + i) % pool.size()
        today_contracts.append(pool[idx].duplicate(true))
```

---

# 9. 결과 계산 규칙

정산 시 다음을 적용한다.

## 기본 보상

```text
money += contract.pay
```

## 장비 비용

팀 확정 시:

```text
money -= sum(selected_gear.cost)
```

## 처리 방식 효과

선택한 resolution option의 값을 적용:

```text
money += money_bonus
hell_trust += option.hell_trust
human_reputation += option.human_reputation
hygiene += option.hygiene
illegal_risk += option.illegal_risk
```

## 직원/장비 보정

선택 직원 2명의 `primary_stat` 합산 + 장비 보정이 난이도보다 높으면 보너스.

```text
score = selected_staff_stat_sum + gear_effect_bonus
required = contract.difficulty * 2
```

성공도가 충분하면:

```text
hell_trust += 2
hygiene += 2
```

부족하면:

```text
hell_trust -= 3
hygiene -= 5
illegal_risk += 5
```

## 직원 피로

선택된 직원의 stamina 감소:

```text
staff.stamina -= option.stamina_cost
```

만약 stamina <= 0:

```text
staff.injured = true
staff.stamina = 0
```

부상 직원은 선택 불가.

---

# 10. 최종 등급 규칙

5일 종료 후 다음 기준으로 등급 표시.

```gdscript
func get_final_grade() -> String:
    if money <= 0:
        return "F: 파산한 청소업체"
    if hell_trust <= 0:
        return "F: 마왕성 계약 해지"
    if illegal_risk >= 100:
        return "F: 불법 처리 적발"
    if money >= 600 and hell_trust >= 70 and hygiene >= 75 and illegal_risk < 40:
        return "A: 마왕성 공인 우수 위생업체"
    if money >= 450 and hell_trust >= 50:
        return "B: 흑자 청소회사"
    if human_reputation >= 40 and illegal_risk >= 60:
        return "D: 인간 장물 브로커"
    return "C: 간신히 버틴 하청업체"
```

---

# 11. 코드 품질 지시

- Godot 4.7 GDScript 문법 사용.
- 타입 추론이 애매한 곳에는 명시 타입 사용.
- UI 재생성 전 기존 자식 노드 삭제.
- 버튼 signal 연결은 Godot 4 방식 사용.
- 가능한 한 함수 단위로 분리:
  - `_ready`
  - `load_data`
  - `generate_today_contracts`
  - `refresh_ui`
  - `draw_hud`
  - `draw_contract_select`
  - `draw_staff_select`
  - `draw_resolution_select`
  - `draw_result`
  - `draw_game_over`
  - `apply_result`
  - `check_failure`
  - `get_final_grade`
  - `restart_game`

---

# 12. 검증 방법

Codex는 작업 후 다음을 보고해야 한다.

1. 변경/생성한 파일 목록
2. 실행 방법
3. 수동 테스트 시나리오
4. 알려진 제한사항

## 수동 테스트 시나리오

Godot에서 Play 후:

1. Day 1 HUD가 보인다.
2. 의뢰 3개가 보인다.
3. 의뢰 하나 선택 가능.
4. 직원 2명 선택 가능.
5. 부상 직원은 선택 불가.
6. 장비 최대 2개 선택 가능.
7. 처리 방식 선택 가능.
8. 정산 후 자원이 변한다.
9. 다음 날로 넘어간다.
10. Day 5 이후 최종 평가가 나온다.
11. 처음부터 다시 버튼이 작동한다.

---

# 13. 이번 작업 완료 기준

아래가 되면 완료다.

- 플레이어가 Day 1부터 Day 5까지 진행할 수 있다.
- 의뢰 선택 → 직원/장비 배치 → 처리 선택 → 정산 → 다음 날 흐름이 끊기지 않는다.
- 자원 변화가 화면에 보인다.
- 직원 stamina와 injured 상태가 반영된다.
- 5일 후 최종 등급이 표시된다.
- 전술 전투는 아직 없다.
