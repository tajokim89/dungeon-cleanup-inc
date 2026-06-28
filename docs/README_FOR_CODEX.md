# Codex 진행 순서

## 작업 원칙

1. 한 번에 하나의 문서만 구현한다.
2. P0가 끝나기 전 P1/P2로 가지 않는다.
3. 전술 전투보다 경영 루프가 우선이다.
4. 변경 후 반드시 Godot에서 실행 확인한다.
5. 사용자에게 보고할 때는 변경 파일, 실행법, 수동 테스트 결과만 짧게 보고한다.

## 권장 순서

### 1단계
읽을 문서:

```text
00_PROJECT_OVERVIEW.md
01_P0_DETAILED_TASK.md
```

목표:
P0 경영 루프 완성.

### 2단계
읽을 문서:

```text
02_P1_TACTICAL_EVENT_TASK.md
```

목표:
위험 의뢰 1개에 짧은 전술 이벤트 연결.

### 3단계
읽을 문서:

```text
03_P2_PIXEL_UI_TASK.md
```

목표:
기본 UI를 픽셀풍 경영 게임 UI로 개선.

## Codex에 처음 줄 프롬프트 예시

```text
Read the planning files in this zip, especially 00_PROJECT_OVERVIEW.md and 01_P0_DETAILED_TASK.md.

You are working in:
/mnt/c/Users/tajok/dev/dungeon-cleanup-inc

Implement only P0 for now.
Do not implement tactical combat yet.
Do not add art assets yet.
After implementation, report changed files and manual test steps.
```
