# Only Nine — Godot

Steam(Windows) + Android 배포를 목표로 한 Godot 4 포트입니다.
기준 해상도는 **1280×720 가로(landscape)** 고정입니다.

## 실행

1. Godot 4.7+ 로 `godot/` 폴더를 Import / Open
2. F5 또는 Play

CLI:

```bat
Godot_v4.7.1-stable_win64_console.exe --path . --main-pack
```

## Export

- **Windows Steam**: Project → Export → `Windows Steam` → `export/windows/OnlyNine.exe`
- **Android (Play Console)**: Export Template 설치 후 아래 **Android AAB (signed)** 절차 참고

### Android AAB (signed) — Google Play

Play Console은 **서명된 AAB**만 받습니다. unsigned APK를 올리면 *"업로드된 모든 번들에 서명해야 합니다"* 오류가 납니다.

1. Godot에서 **Project → Export → Android** preset 선택
2. **Export Format** = `AAB` (APK 아님). 이 프로젝트 preset은 `export/android/OnlyNine.aab`로 설정됨
3. **Package → Signed** 체크 (`package/signed=true`)
4. Release 키스토어가 연결되어 있는지 확인:
   - Editor → Editor Settings → Export → Android, 또는 Export 창의 Keystore 필드
   - Release keystore / alias / passwords는 로컬 `godot/.godot/export_credentials.cfg`에만 저장됨 (git에 커밋되지 않음)
5. 모드를 **Release**로 두고 **Export Project** → `export/android/OnlyNine.aab` 저장
6. Play Console → 출시 → App Bundle 업로드

**Play App Signing:** Google이 최종 배포 서명을 관리해도, 업로드하는 AAB는 **업로드 키(upload key)**로 서명되어 있어야 합니다. Godot Release 키스토어가 그 업로드 키입니다.

CLI (Godot 실행 파일 경로를 맞게 바꿔서):

```bat
Godot_v4.7.1-stable_win64_console.exe --path . --headless --export-release "Android" export/android/OnlyNine.aab
```

키스토어 파일(`.jks`)과 비밀번호는 절대 git에 커밋하지 마세요.
