# Novita

클라우드 동기화를 지원하는 Flutter 노트 앱입니다.

## 주요 기능

- **노트 작성 및 관리**: 폴더별로 노트를 구성하고 관리
- **검색**: 노트 내용 검색
- **클라우드 동기화**: Google 로그인을 통한 클라우드 동기화
- **오프라인 지원**: 인터넷 연결 없이도 사용 가능

## 기술 스택

| 분류 | 기술 |
|------|------|
| Framework | Flutter 3.10+ |
| 상태관리 | Riverpod |
| 로컬 DB | Isar |
| 네트워크 | Dio |
| 인증 | Google Sign-In, Firebase Auth |
| 분석 | Firebase Analytics, Crashlytics |

## 프로젝트 구조

```text
lib/
├── main.dart
└── src/
    ├── core/              # 핵심 유틸리티
    ├── data/
    │   ├── datasources/   # 로컬 DB, 토큰 저장소
    │   ├── models/        # 데이터 모델 (Note, Folder, Attachment 등)
    │   ├── network/       # API 클라이언트
    │   ├── repositories/  # 데이터 레포지토리
    │   └── services/      # 동기화, 분석, 저장소 서비스
    └── features/
        ├── auth/          # 인증 (로그인, 회원가입)
        ├── notes/         # 노트 목록, 편집기
        ├── search/        # 검색
        ├── settings/      # 설정
        └── common/        # 공통 위젯
```

## 시작하기

### 요구사항

- Flutter SDK 3.10.1 이상
- Dart SDK 3.10.1 이상

### 설치

```bash
# 의존성 설치
flutter pub get

# Isar 코드 생성
dart run build_runner build

# 앱 실행
flutter run
```

## 라이선스

이 프로젝트는 개인 프로젝트입니다.
