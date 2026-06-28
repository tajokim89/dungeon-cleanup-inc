# Codex 상세 작업 지시서 — P2 픽셀아트 UI/시각 개선

## 목표

P0/P1 기능이 동작한 뒤, 코드 UI를 픽셀아트 게임처럼 보이게 개선한다.

아직 최종 아트가 없어도 된다. Godot Control 노드와 StyleBoxFlat만으로 픽셀풍 UI를 만든다.

## 수정 파일

```text
scripts/Main.gd
scripts/TacticalEvent.gd
assets/fonts/     선택사항
assets/ui/        선택사항
```

## 시각 방향

- 다크 판타지 사무소/위생업체 느낌
- 픽셀아트 감성
- 굵은 사각 패널
- 어두운 배경
- 녹색/보라/오렌지 계열 포인트
- 둥근 현대 UI 금지
- 과한 그라데이션 금지

## 기본 팔레트

```text
background: #101014
panel:      #1b1b24
panel_2:    #242432
border:     #5b4a33
gold:       #d9b15f
green:      #86b86b
purple:     #8d6bb8
danger:     #c75c5c
text:       #e6dcc8
muted:      #9a9284
```

## 구현 지시

1. `make_panel_style()` 함수 작성
   - StyleBoxFlat 생성
   - bg_color, border_color, border_width 설정
   - corner_radius는 0 또는 아주 작게

2. `make_label()` 헬퍼 작성
   - 폰트 크기/색상 통일

3. `make_button()` 헬퍼 작성
   - 최소 높이 44
   - hover/pressed는 나중에 가능

4. 의뢰 카드/직원 카드/장비 카드 각각 PanelContainer로 감싼다.

5. HUD는 상단 고정 바처럼 보이게 한다.

## 픽셀아트 자산은 아직 선택사항

현재 단계에서 PNG 생성/삽입은 필수 아님.
나중에 다음을 추가할 수 있게 구조만 둔다.

```text
assets/ui/panel_frame.png
assets/ui/button_normal.png
assets/sprites/staff_grik.png
assets/sprites/staff_melta.png
assets/sprites/staff_volg.png
assets/sprites/staff_pipit.png
```

## 완료 기준

- 여전히 P0/P1 루프가 동작한다.
- UI가 기본 Godot 회색 버튼 느낌에서 벗어난다.
- 스크린샷만 봐도 다크 판타지 경영 게임 느낌이 난다.
