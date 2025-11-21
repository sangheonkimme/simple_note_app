# WorkLife Dashboard & Novita App - 기능 구현 및 동기화 계획

**버전**: 0.1
**작성일**: 2025-02-14
**작성자**: Codex (AI Pair)
**문서 목적**: 복잡도가 높아진 메모 작성/열람 경험과 백엔드 모델·라우트를 단계적으로 개선하고, 모바일 앱(Novita)과의 동기화를 위한 참조 계획을 정의한다.

---

## 1. 컨텍스트 및 문제 진단

### 1.1 UI 레이어 이슈 (Web Dashboard)
- `client/src/pages/NotesPage.tsx` 한 파일에서 데이터 패칭, 레이아웃, 작성 폼, 필터 드로어, 첨부/템플릿 모달 등 **500+라인**이 뒤섞여 있어 가독성과 재사용성이 떨어진다.
- 동일한 필터 UI가 데스크톱/모바일에서 Drawer, Sidebar로 중복 구현되어 유지보수 비용이 2배가 된다.
- 한 번에 모든 note 필드(본문, 첨부, 체크리스트)를 가져와 카드에 뿌리기 때문에 목록 스크롤 시 페이로드가 크고 성능 이슈가 발생한다.
- 단일 모달에서 note type별 UI를 분기하다 보니 state shape이 자주 바뀌고, 체크리스트 초안(`tempChecklistItems`)과 저장된 항목의 관리 방식이 다르다.
- Quick Note, 템플릿, 검색 등 부가 기능이 동일 mutation/쿼리를 직접 호출하고 있어 상태 동기화가 느슨하다.

### 1.2 서버/도메인 이슈
- `server/src/services/noteService.ts`가 모든 책임(필터링, 첨부 포함, 플래그 토글)을 떠안고 있으며, 반환 모델도 목록/상세 구분 없이 과도하게 크다.
- 리스트 API(`/api/notes`)가 summary만 필요한 경우에도 checklist, attachments, transactions를 포함해 네트워크 비용과 Prisma include 비용이 높다.
- 토글 엔드포인트(`/api/notes/:id/toggle`)가 flag 문자열에 따라 동적으로 동작하여 타입 안정성과 권한 로깅이 어렵다.
- Prisma schema가 단일 `Note` 테이블에 모든 정보를 저장하기 때문에 향후 버전 히스토리, content 타입별 인덱싱 등 확장성이 부족하다.
- 검색 서비스(`searchService`)가 메모 필터와 별도로 운영되어 필터 조합/정렬 옵션이 분리되어 있고, 공통 캐싱/페이징 전략이 없다.

---

## 2. 목표 및 비목표

### 2.1 목표
1. 메모 작성/열람 흐름을 **워크스페이스 단위 UI**로 세분화하여 사용자 피로도를 낮춘다.
2. 프론트-백엔드 계약을 명확히 나누어 **요약 데이터(카드)**와 **상세 데이터**를 구분하고, 필요 시에만 무거운 필드를 로드한다.
3. 노트 도메인을 `메타데이터/컨텐츠/연결 자원`으로 분리하여 Prisma/Express 계층의 유지보수성을 높인다.
4. 플래그 토글, 첨부, 체크리스트 등 **행위 기반 라우트**를 명확히 하고, OpenAPI 문서/테스트를 강화한다.
5. **Novita 앱**과의 원활한 동기화를 위한 데이터 구조 및 API 규격을 확립한다.

### 2.2 비목표
- 실시간 협업(동시 편집)이나 외부 공유 페이지 UI는 본 계획 범위에 포함하지 않는다.
- 데이터베이스 마이그레이션 자동화(blue-green)는 후속 인프라 계획으로 분리한다.

---

## 3. 타깃 아키텍처

### 3.1 UI/UX 구조 (Web)
| 레이어 | 역할 | 비고 |
| --- | --- | --- |
| `NotesWorkspace` shell | 그리드/드로어/헤더 등 전체 레이아웃, Suspense 경계 담당 | Mantine `AppShell` 기반 |
| `NoteListPanel` | 요약 카드/테이블/핀 섹션, 리스트 Virtualization | list API에서 summary만 사용 |
| `NoteInspectorPanel` | 선택한 노트의 상세 미리보기, read-only 모드 | detail API 이용 |
| `NoteComposer` | 작성/수정 폼. type별 블록(Editor, Checklist, Markdown) 컴포넌트화 | `react-hook-form` + `zod` |
| `NoteFiltersProvider` | URL/전역 상태 동기화, 데스크톱과 모바일에서 동일 훅 사용 | Drawer는 뷰만 달리한다 |

**주요 변화**
- 모달 중심 UX → **우측 패널 + 슬라이드오버** 조합으로 변경하여 context switching 감소.
- 카드 목록은 `NoteSummary` 타입만 받도록 하고, 카드 클릭 시 detail fetch (prefetch + Suspense).
- 첨부, 체크리스트, 템플릿 모듈은 lazy load하여 초기에 JS 번들이 가벼워지도록 code-splitting 적용.
- Quick Note, Template Modal, Search Bar는 `NotesWorkspaceContext`에서 공통 mutation dispatcher를 가져와 optimistic update와 invalidation을 한곳에서 처리.

### 3.2 서버/모델 구조
| 계층 | 제안 내용 |
| --- | --- |
| Prisma 모델 | `NoteMeta`(title, type, flags, folder), `NoteContent`(markdown/plain text, JSON checklist), `NoteShare`(publishedUrl, visibility) 등으로 분리.<br/>Checklist는 별도 테이블 대신 JSONB + `ChecklistItem` view를 혼합해 읽기 최적화. |
| 서비스 계층 | `noteRepository` (Prisma 호출) ↔ `noteService` (비즈니스 규칙) ↔ `notePresenter` (list/detail view model) 구조로 분리, include 전략을 뷰 모델에서 명시. |
| 라우트 설계 | `/api/notes` (summary), `/api/notes/:id` (detail), `/api/notes/:id/content`, `/api/notes/:id/flags/pin`, `/api/notes/:id/checklist` 등 행위 기반 endpoint 추가. |
| DTO/검증 | `zod` 스키마를 client와 공유(`@/schemas/note`)하여 일관된 validation 메시지 유지, flag route는 enum 기반으로 분기. |
| 검색 | `/api/notes/search`를 query builder 형태로 재작성하여 list API와 동일 pagination 객체 반환. Elastic 등 외부 의존은 추후로 미루되, Prisma `tsvector` 인덱스를 고려. |

---

## 4. 단계별 실행 계획

### Phase 0 – 진단 및 가드레일 (1주)
1. 노트 API 호출 로그/메트릭 수집 (payload size, latency, error rate) → `scripts/api-profiler.ts`로 자동화.
2. `NotesPage`를 Storybook에 snapshot 등록, 현재 상호작용 플로우 문서화.
3. Prisma schema 리디자인 초안 작성 후 샘플 마이그레이션 스크립트(`prisma/migrations/prototype`) 생성.
4. OpenAPI 문서에 note 관련 항목을 추출하여 baseline 정합성 확인.

### Phase 1 – UI 파운데이션 (2주)
1. `NotesWorkspace`/`NoteListPanel`/`NoteInspectorPanel` skeleton 컴포넌트 생성, 라우팅/URL 파라미터 연결.
2. `useNoteFilters`를 `NoteFiltersProvider`와 `useNoteFilterStore`(zustand or context reducer)로 대체하고 Desk/Mobile 공유.
3. `noteApi.getNotes`에 `view=summary` 파라미터 추가, 카드 목록에서 checklist/attachments/transactions 필드를 제거.
4. `NoteComposer`를 `react-hook-form + zodResolver`로 교체, 타입별 editor 블록을 lazy import.
5. Quick Note/Template/Search 컴포넌트를 context-aware action으로 마이그레이션, optimistic 리스트 업데이트.

### Phase 2 – 서버 모델/라우트 개선 (2~3주)
1. Prisma schema 분리(`NoteMeta`, `NoteContent`, `NoteShare`, `NoteAttachment`) 및 migration 계획 수립 → feature flag로 두 스키마 병행 운영.
2. `/api/notes` response를 `NoteSummaryView`로 축소, detail fetch는 `/api/notes/:id`에서만 attachments/checklist를 포함.
3. Flag 토글 API를 `/api/notes/:id/pin|favorite|archive`(PATCH)로 분리하여 middlewares/logger에서 개별 추적.
4. Checklist/Attachment/Transaction 연결 라우트를 `/api/notes/:id/checklist-items`, `/api/notes/:id/attachments` 등 REST 규약으로 재배치.
5. noteService를 repository + service + presenter 계층으로 쪼개고, integration test( Jest + supertest ) 작성.

### Phase 3 – UX/도메인 폴리시 마감 (1주)
1. Inspector Panel에서 history, flag 변경, transaction 링크를 inline 편집 가능하게 개선.
2. 검색/필터 모듈을 Suspense compatible하게 만들고, 글로벌 Spotlight와 공유.
3. Lighthouse + Web Vitals 측정, before/after 리포트 정리 후 문서/릴리즈 노트 작성.
4. 마이그레이션 완료 후 구 스키마/엔드포인트 feature-flag 제거.

---

## 5. 고려 사항
- **마이그레이션 호환성**: Note 모델 분리 시, 구 스키마를 읽어오는 fallback 뷰(view)나 SQL migration script를 병행 배포해야 함.
- **국제화**: 새 컴포넌트에서 사용되는 신규 i18n 키는 `i18n-key-reference.md`에 등록하고, `client/src/locales/{ko,en}/notes.json`에 추가.
- **접근성**: Drawer/슬라이드오버 변경 시 focus trap, keyboard shortcut을 재검토한다.
- **성능**: 리스트 카드에는 React Window(virtualized grid)를 고려, Suspense prefetch는 React Query `prefetchQuery` 사용.
- **테스팅**: Phase별로 Cypress component test, Playwright E2E, Jest integration test를 병렬로 작성하여 회귀 방지.

---

## 6. 별도 메모 앱(Novita) 동기화 전략

### 6.1 아키텍처 가이드
- **싱글 소스 API**: 대시보드와 독립 메모 앱 모두 동일 REST/GraphQL 계약을 사용하도록 하여 프론트 간 로직을 공유한다. 필요 시 `/api/notes-sync` 같은 endpoint를 만들어 앱별 delta sync를 처리한다.
- **디바이스 리비전 관리**: Prisma `NoteMeta.deviceRevision` 필드를 활용해 클라이언트가 마지막 동기화 포인트를 전달(`?sinceRevision=xxx`)하면 서버가 변경된 note만 반환하도록 delta query를 추가한다.
- **오프라인/낙관적 업데이트**: 독립 메모 앱은 IndexedDB/Cache Storage(또는 Isar)에 notes를 저장하고, `deviceRevision` + conflict resolution 정책(최신 수정 우선, 또는 사용자에게 병합 UI 제공)을 따라 대시보드와 동일 상태를 유지한다.
- **이벤트 브로커**: 장기적으로는 Webhook or WebSocket(예: `/api/notes/events`)을 통해 다른 클라이언트에게 note 변경 이벤트를 push하여 새 앱과 대시보드 간 실시간 감지를 지원한다.

### 6.2 Phase 반영 포인트
- Phase 1에서 `NoteSummary`/`NoteDetail` 타입을 정의할 때, 독립 앱과 공유 가능한 TypeScript 패키지(`packages/note-schema`)를 준비한다.
- Phase 2에서 API 리디자인 시 `sinceRevision`, `syncToken`, `conflictPolicy` 파라미터를 스펙에 포함시키고, integration test로 앱 간 동기화 시나리오(동일 note 동시 수정 등)를 검증한다.
- Phase 3에서 Inspector Panel 인라인 편집 시, 동일 endpoint를 별도 앱도 사용하므로 optimistic update, 충돌 메시지를 공통 컴포넌트로 추출한다.

---

## 7. Novita 로컬 DB 스키마 (Isar)

**Novita**는 오프라인 우선(Offline-First) 전략을 위해 모든 데이터를 기기 로컬의 Isar DB에 저장한다. 아래 스키마를 참고하면 대시보드 서버와 동기화 시 변환 규칙을 쉽게 정의할 수 있다.

### 7.1 개요
- 앱은 네트워크가 없을 때도 동작하도록 로컬 DB를 단일 소스로 사용한다.
- 서버 동기화 시 `deviceRevision` 또는 타임스탬프 기반으로 변경분을 업로드/다운로드한다.

### 7.2 컬렉션 구조

#### Note
| 필드 | 타입 | 설명 |
| :--- | :--- | :--- |
| `id` | `Id` (int) | 자동 증가 기본 키 |
| `title` | `String` | 메모 제목 |
| `body` | `String?` | 텍스트 메모 본문 |
| `type` | `NoteType` | `text`, `checklist` 등 Enum |
| `checklistItems` | `List<ChecklistItem>` | 내장 체크리스트 항목 |
| `pinned` | `bool` | 상단 고정 여부 |
| `archived` | `bool` | 보관함 이동 여부 |
| `trashedAt` | `DateTime?` | 휴지통으로 이동한 시각 |
| `createdAt` | `DateTime` | 생성 일시 |
| `updatedAt` | `DateTime` | 마지막 수정 일시 |
| `folder` | `IsarLink<Folder>` | 상위 폴더 링크 |
| `attachments` | `IsarLinks<Attachment>` | 첨부파일 링크 |

#### Folder
| 필드 | 타입 | 설명 |
| :--- | :--- | :--- |
| `id` | `Id` (int) | 자동 증가 기본 키 |
| `name` | `String` | 폴더 이름 |
| `isSystem` | `bool` | 시스템 폴더 여부(예: 전체 메모) |
| `sortOrder` | `int?` | 사용자 지정 정렬 순서 |
| `createdAt` | `DateTime` | 생성 일시 |
| `updatedAt` | `DateTime` | 수정 일시 |
| `notes` | `IsarLinks<Note>` | 해당 폴더 내 메모 참조 |

#### Attachment
| 필드 | 타입 | 설명 |
| :--- | :--- | :--- |
| `id` | `Id` (int) | 자동 증가 기본 키 |
| `filePath` | `String` | 로컬 파일 경로 |
| `mimeType` | `String` | 파일 MIME 타입 |
| `size` | `int?` | 파일 크기(byte) |
| `createdAt` | `DateTime` | 생성 일시 |
| `note` | `IsarLink<Note>` | 소속 메모 링크 |

### 7.3 임베디드 객체
#### ChecklistItem
| 필드 | 타입 | 설명 |
| :--- | :--- | :--- |
| `text` | `String` | 체크 항목 내용 |
| `done` | `bool` | 완료 여부 |
| `order` | `int?` | 표시 순서 |

### 7.4 관계 요약
- **Note ↔ Folder**: 다대일 (메모는 하나의 폴더에 속함)
- **Note ↔ Attachment**: 일대다 (메모 하나에 여러 첨부 파일)

---

## 8. Novita ↔ 서버 DTO 매핑표

동기화 시 필드명을 일치시키기 위해 Novita(Isar) 스키마와 서버 DTO(`NoteSummary`, `NoteDetail`, `CreateNoteDto`, `UpdateNoteDto`)의 매핑을 정의한다.

| Novita 컬렉션/필드 | 서버 DTO 필드 | 변환 규칙 |
| :--- | :--- | :--- |
| `Note.id (int)` | `NoteSummary.id` / `NoteDetail.id` (string) | 서버는 `cuid()` 문자열 사용 → 로컬 동기화 시 `externalId` 필드 추가 or `id`를 string으로 저장 후 변환 |
| `Note.title` | `title` | 그대로 매핑 |
| `Note.body` | `content` | 체크리스트 타입은 JSON 직렬화, 텍스트 타입은 문자열 그대로 |
| `Note.type (text/checklist)` | `type` (`TEXT`/`CHECKLIST`) | 문자열 매핑 테이블 필요 (`text`→`TEXT`, `checklist`→`CHECKLIST`) |
| `Note.checklistItems` | `checklistItems` | 서버 detail API가 제공하는 배열과 동일 구조로 직렬화/역직렬화 |
| `Note.pinned` | `isPinned` | boolean 그대로 |
| `Note.archived` | `isArchived` | boolean 그대로 |
| `Note.trashedAt` | `deletedAt` | `null` ↔ `undefined` 처리, 동기화 시 Date string ↔ DateTime 변환 |
| `Note.createdAt` | `createdAt` | ISO 문자열 ↔ DateTime 변환 |
| `Note.updatedAt` | `updatedAt` | ISO 문자열 ↔ DateTime 변환, `deviceRevision` 증가 조건 |
| `Note.folder (Folder link)` | `folderId` | 서버는 string ID → Novita는 Folder.id(int)와 매핑 테이블 필요 |
| `Note.attachments` | `attachments[]` | 서버 detail에서 제공되는 Attachment DTO와 동일 구조; 로컬 파일 경로는 서버 업로드 후 URL 매핑 필요 |
| `Folder.id` | `Folder.id` | 서버 Folder도 string ID → 로컬에서 string 유지 or 별도 매핑 |
| `Folder.name` | `Folder.name` | 동일 |
| `Folder.isSystem` | 서버에는 별도 필드 없음 | 시스템 폴더 여부를 `isDefault` flag 등으로 매핑 |
| `Attachment.filePath` | `Attachment.url` | 업로드 후 서버 URL 저장. 로컬 경로는 메타데이터 필드(`localPath`)로 별도 보관 |
| `Attachment.mimeType`, `size` | `mimeType`, `fileSize` | 타입/단위 일치 |
| `ChecklistItem.text/done/order` | `content/isCompleted/order` | 필드명만 변환 |

**추가 메타 필드**
- Novita에는 `deviceRevision`, `syncStatus`, `pendingOperations` 같은 로컬 전용 필드를 추가해 서버 DTO 변환 시 포함하지 않는다.
- 서버에서 제공하는 `visibility`, `isFavorite`, `publishedUrl`, `noteTransactions` 등은 Novita MVP 스키마에는 없으므로 동기화 정책을 정의하거나 로컬 스키마 확장을 고려한다.

---

## 9. Novita App 인증 구현 전략 (Authentication)

동기화를 위해서는 사용자 식별이 필수적이므로, 모바일 앱 내에 로그인 기능을 구현해야 합니다.

### 9.1 기능 요구사항
-   **일반 로그인 (Email/Password)**:
    -   회원가입 (`POST /api/auth/register`)
    -   로그인 (`POST /api/auth/login`)
    -   로그아웃 (`POST /api/auth/logout`)
-   **소셜 로그인 (Google)**:
    -   Google Sign-In 패키지 연동 (`google_sign_in`)
    -   ID Token 서버 검증 (`POST /api/auth/google`)
-   **토큰 관리**:
    -   `flutter_secure_storage`를 사용한 Access/Refresh Token 안전 저장.
    -   API 요청 시 `Dio` Interceptor를 통해 Access Token 자동 첨부.
    -   401 에러 발생 시 Refresh Token으로 자동 갱신 로직 구현.

### 9.2 UI 구성
-   **로그인 화면**: 이메일 입력 폼, 비밀번호 입력 폼, "Google로 계속하기" 버튼.
-   **회원가입 화면**: 닉네임, 이메일, 비밀번호 입력.
-   **프로필/설정 화면**: 현재 로그인 정보 표시 및 로그아웃 버튼.

---


## Phase Checklist

### Phase 0: 진단 및 가드레일 (Common)
- [x] API payload/latency baseline 캡처
- [x] Storybook 플로우/상호작용 문서화
- [x] Prisma 분리 스키마 초안 + 프로토타입 migration
- [x] Note 관련 OpenAPI 스펙 검증 완료

### Phase 1: UI 파운데이션 (App Focus)
#### Mobile App (Novita)
- [x] 로그인/회원가입 UI 구현
- [x] Google Sign-In 연동 및 토큰 관리 로직 구현
- [x] Pinned Notes 화면 구현
- [x] Calendar 화면 구현 (table_calendar)
- [x] Home/Scaffold 네비게이션 연결

#### Web Dashboard
- [ ] NotesWorkspace 레이아웃 + Suspense 경계 구축
- [ ] 공유 필터 스토어 마이그레이션
- [ ] Summary 전용 리스트 API 적용
- [ ] NoteComposer 리팩터 + lazy editor 블록
- [ ] Quick Note/Template/Search 공통 dispatcher 연결

### Phase 2: 서버 모델 및 동기화 준비
#### Server / Common
- [ ] Prisma Note 도메인 분리 + feature flag 배포
- [ ] Summary/Detail API 응답 분리
- [ ] Flag/Checklist/Attachment 라우트 REST 재설계
- [ ] noteService 계층화 + 통합 테스트
- [ ] 검색/필터 API 정합성 재검증

#### Mobile App (Novita)
- [x] Isar 로컬 DB 스키마 확정 (서버 DTO 매핑 고려)
- [x] 데이터 동기화 로직 설계 (Delta Sync)
- [x] 오프라인 지원 검증 (Mock)

### Phase 3: UX 고도화 및 폴리시 마감
#### Mobile App (Novita)
- [ ] 노트 작성/편집 UX 고도화 (Rich Text Editor 등)
- [ ] 검색 기능 강화
- [ ] 앱 배포 준비 (Store Listing 등)

#### Web Dashboard
- [ ] Inspector Panel 인라인 편집 기능
- [ ] Suspense 기반 필터/Spotlight 재사용
- [ ] 성능 리포트/릴리즈 노트 정리
- [ ] Legacy 스키마/엔드포인트 제거 확인
