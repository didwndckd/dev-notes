---
name: python-note
description: >-
  점프 투 파이썬(wikidocs.net) 학습 내용을 Python/ 문서로 정리할 때 사용한다. 사용자가
  Python/Source/*.py 예제 파일과 wikidocs URL을 주면서 "문서로 정리", "md로 정리",
  "문서 만들자" 등을 요청하면 이 스킬을 쓴다. 위키 원문을 브라우저로 확인하고, 기존 Python/*.md
  스타일에 맞춰 새 문서를 작성하며 README.md 목록에 추가한다.
argument-hint: [Source/xxx.py] [https://wikidocs.net/번호]
arguments: source_py wiki_url
allowed-tools: Read, Write, Edit, Bash, ToolSearch
---

# Python 학습 노트 문서화

`Python/Source/*.py`(공부하며 쳐본 예제)와 wikidocs 페이지를 바탕으로, 기존 문서 스타일에 맞는 한국어 학습 문서를 `Python/`에 만든다.

## 입력 (둘 다 필수)

이 스킬은 아래 두 입력을 **반드시** 받아야 동작한다. 하나라도 없으면 사용자에게 물어서 채운 뒤 진행한다.

- `$source_py` — 예제 코드 파일 경로: `Python/Source/<name>.py`
- `$wiki_url` — 위키 URL: `https://wikidocs.net/<번호>` (점프 투 파이썬)

인자로 전달되면 그대로 쓰고, 자연어로만 주어졌으면 그 안에서 두 값을 파악한다. 둘 중 하나라도 빠졌으면 **작업을 시작하지 말고 먼저 요청한다.**

## 절차

1. **예제 파일을 읽는다.** `Python/Source/<name>.py`. 이게 사용자가 실제로 공부한 내용이며, 문서 예제의 1차 소스다. 주석에 적힌 실행 결과·오타·학습 흔적을 파악한다.

2. **위키 원문을 확인한다. (필수)** `wikidocs.net`은 Cloudflare로 막혀 `WebFetch`/`curl`이 403·challenge를 받는다. **반드시 브라우저 자동화로 연다.**
   - `mcp__claude-in-chrome__*` 도구가 deferred면 한 번의 `ToolSearch`로 `tabs_context_mcp,tabs_create_mcp,navigate,get_page_text,tabs_close_mcp`를 로드한다.
   - `tabs_context_mcp{createIfEmpty:true}` → `navigate`(URL) → `get_page_text`로 본문을 읽는다.
   - 위키의 소제목 순서·설명·예제를 문서 구성의 뼈대로 삼는다. 코드 예제는 위키보다 사용자의 `.py` 파일을 우선한다(사용자가 실제로 친 값·이름 유지).
   - 다 읽었으면 `tabs_close_mcp`로 탭을 닫는다.

3. **문서를 작성한다.** `Python/<Name>.md` (PascalCase, 예: `Function.md`, `UserIO.md`). 스타일은 아래 규칙과 기존 문서(`Python/For.md`, `Python/While.md`, `Python/Function.md`)를 반드시 참고해 맞춘다.

4. **README.md에 목록을 추가한다.** `## Python` 섹션에서 관련 문서 바로 아래 줄에 추가한다. 형식: `  - [제목](Python/<Name>.md) — 짧은 키워드 나열`

5. **커밋은 사용자가 요청할 때만** 한다. 먼저 만들고, 다듬을 부분을 물은 뒤, 요청 시 커밋한다.

## 문서 스타일 규칙

기존 `Python/*.md`와 톤·구조를 일치시킨다.

- **맨 위**: `# 제목(영문키워드)` → 빈 줄 → `> 예제 코드: [Source/<name>.py](Source/<name>.py)`
- **목차**: `- [섹션명](#앵커)` 형태의 링크 목록. 앵커는 소문자, 공백은 `-`, 특수문자 제거(예: `(input/print)` → `#input으로-입력받기`). `*`·`**` 같은 문자는 목차 텍스트에서 `\*`로 escape.
- **섹션**: `## 소제목`. 각 섹션은 1~2문장 설명 → 코드블록 순서.
- **코드블록**: ```` ```python ````. 실행 결과는 코드 안에 `# 주석`으로 붙인다(별도 "실행 결과" 텍스트 대신). 여러 줄 결과도 `#`로.
- **하위 항목**: 한 섹션에 여러 소주제가 있으면 `- **소제목** — 설명` + 들여쓴 코드블록으로 묶는다.
- **문법 틀 제시**: 실제 예제 앞에 `def 함수_이름(매개변수):` 같은 한글 플레이스홀더 틀을 먼저 보여주면 이해가 쉽다.
- **팁/주의**: `>` 인용문으로. 주의점·함정·부연을 담는다.
- **원본 코드 정리**: `.py` 주석의 오타(예: `매개변후`→`매개변수`)나 어색한 표현은 문서에서 매끄럽게 고친다. 단 예제의 변수명·입력값은 사용자가 친 그대로 유지한다.
- 설명은 간결한 한국어 평서체(`~한다`, `~된다`)로.

## 참고: 커밋 메시지 형식

기존 커밋 컨벤션을 따른다: `Python: <문서> 문서(<Name>.md) 추가 및 README 목록 반영`
