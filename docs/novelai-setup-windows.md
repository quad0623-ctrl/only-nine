# NovelAI × Cursor (Windows, 2대 PC)

## 1. 보안 (필수)

- API 토큰(`pst-...`)은 **채팅·GitHub·코드에 넣지 마세요.**
- 유출 시 NovelAI → Settings → **Persistent Token 재발급/폐기.**

## 2. 두 PC 공통 설정 (집 랩탑 + 노트북)

같은 NovelAI 계정이면 **토큰 하나**로 두 대 모두 사용 가능합니다.

### A. Windows 사용자 환경 변수 (각 PC에서 1회)

1. `Win + R` → `sysdm.cpl` → **고급** → **환경 변수**
2. **사용자 변수** → **새로 만들기**
   - 이름: `NOVELAI_API_KEY`
   - 값: `pst-...(새로 발급한 토큰)`
3. **Cursor 완전 종료 후 재실행** (환경 변수 반영)

PowerShell (현재 사용자, 재로그인 후 적용):

```powershell
[Environment]::SetEnvironmentVariable('NOVELAI_API_KEY', 'pst-여기에-새-토큰', 'User')
```

### B. MCP 설정 파일 (각 PC에 동일)

경로: `C:\Users\<사용자명>\.cursor\mcp.json`

이 PC 예시는 이미 `C:\Users\USER\.cursor\mcp.json` 에 있습니다.  
집 랩탑에도 **같은 파일**을 복사하세요. (API 키는 파일에 넣지 않음)

### C. 필수 프로그램 (각 PC)

```powershell
winget install Python.Python.3.12
winget install astral-sh.uv
```

설치 후 **새 터미널**에서:

```powershell
uvx novelai-mcp --help
```

### D. Cursor에서 확인

1. **Settings → Tools & MCP**
2. `novelai` 서버가 **Connected** 인지 확인
3. Agent에게: `check_subscription` 또는 이미지 생성 요청

## 3. PC 간 동기화 팁

| 항목 | 방법 |
|------|------|
| MCP 설정 | `~/.cursor/mcp.json` 수동 복사 또는 클라우드 동기화 |
| API 토큰 | 환경 변수로 각 PC에 동일하게 설정 |
| 생성 이미지 | `NOVELAI_SAVE_DIR` (선택) — PC마다 경로만 맞추기 |

프로젝트 `.cursor/mcp.json` 에 토큰을 넣으면 Git에 올라갈 수 있으므로 **사용하지 마세요.**
