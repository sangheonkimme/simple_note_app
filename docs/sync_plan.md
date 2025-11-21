# Novita & WorkLife Dashboard 동기화 기획서 (Final)

## 1. 개요
본 문서는 **Novita 앱(Local-First)** 과 **WorkLife Dashboard 서버(Prisma + PostgreSQL)** 간의 데이터 동기화 설계를 정의합니다.
사용자가 제공한 Prisma 스키마를 기준으로, 모바일 앱이 오프라인 상태에서도 완벽하게 동작하며 네트워크 연결 시 서버와 데이터를 동기화하는 **Local-First** 전략을 채택합니다.

## 2. 아키텍처: Local-First & Sync

### 2.1. 핵심 전략
1.  **App Environment First**: 앱은 로컬 DB(`Isar`)를 신뢰할 수 있는 유일한 소스(Single Source of Truth)로 취급하여 동작합니다. 서버는 데이터 백업 및 멀티 디바이스 공유를 위한 저장소 역할을 합니다.
2.  **Lazy Sync**: 데이터 변경 즉시 네트워크 요청을 보내지 않고, 백그라운드 큐에 작업을 쌓아두었다가 효율적인 시점에 배치(Batch)로 처리합니다.
3.  **Soft Delete**: 데이터 삭제 시 로컬에서 즉시 지우지 않고 `deletedAt` 필드를 마킹하여, 동기화 시 서버에도 삭제 사실을 전파합니다.

## 3. 데이터 모델 매핑 (Isar vs Prisma)

서버의 Prisma 모델이 다소 복잡하므로(Heavy), 모바일에서는 **필요한 핵심 데이터만 경량화하여 저장**하되, 동기화에 필요한 메타데이터는 유지합니다.

### 3.1. Folder (폴더)
| Isar (Local) | Prisma (Server) | 타입 | 비고 |
| :--- | :--- | :--- | :--- |
| `id` (int) | - | - | 로컬 전용 ID |
| `remoteId` | `id` | String (CUID) | **매핑 키** |
| `name` | `name` | String | |
| `color` | `color` | String? | |
| `icon` | `icon` | String? | |
| `parentRemoteId` | `parentId` | String? | 중첩 폴더 지원 |
| `updatedAt` | `updatedAt` | DateTime | 충돌 해결 기준 |
| `deletedAt` | - | DateTime? | 로컬 Soft Delete용 |

### 3.2. Note (메모)
서버의 `Note` 모델이 방대하므로, 앱에서는 핵심 필드 위주로 관리합니다.

| Isar (Local) | Prisma (Server) | 타입 | 비고 |
| :--- | :--- | :--- | :--- |
| `id` (int) | - | - | 로컬 전용 ID |
| `remoteId` | `id` | String (CUID) | **매핑 키** |
| `title` | `title` | String | |
| `body` | `content` | String | 서버의 `content`와 매핑 |
| `type` | `type` | Enum | TEXT, CHECKLIST |
| `pinned` | `isPinned` | Boolean | |
| `archived` | `isArchived` | Boolean | |
| `deletedAt` | `deletedAt` | DateTime? | 서버/로컬 모두 존재 |
| `folderRemoteId`| `folderId` | String? | |
| `updatedAt` | `updatedAt` | DateTime | |
| `deviceRevision`| `deviceRevision`| Int | (옵션) 충돌 감지용 |

*참고: `visibility`, `password`, `publishedUrl` 등은 모바일 앱 초기 버전에서 사용하지 않는다면 로컬 DB 스키마에서 제외하거나 Nullable로 두어 향후 확장에 대비합니다.*

### 3.3. ChecklistItem (체크리스트)
Isar에서는 `Note` 내부의 객체 리스트(`Embedded`)로 관리하는 것이 성능상 유리할 수 있으나, 서버 모델이 별도 테이블이므로 동기화 시 변환이 필요합니다.

-   **App**: `Note` 객체 내 `List<ChecklistItem> checklistItems`
-   **Server**: 별도 `ChecklistItem` 테이블
-   **Sync**: 노트 동기화 시 체크리스트 아이템들을 JSON 등으로 변환하거나, 별도 엔드포인트로 동기화. (단순화를 위해 노트 본문에 JSON으로 저장하거나, 서버가 `Note` 조회 시 `include`로 내려주는 것을 권장)

### 3.4. Attachment (첨부파일)
-   **App**: 로컬 파일 경로(`filePath`) 저장.
-   **Server**: S3/GCS 등에 업로드된 URL(`url`) 저장.
-   **Sync**:
    1.  이미지 추가 시 로컬에 임시 저장.
    2.  동기화 시 파일 업로드 API 호출 -> URL 획득.
    3.  `Attachment` 메타데이터(URL 포함)를 서버 DB에 저장.

## 4. 동기화 프로세스 (Sync Process)

### 4.1. Pull (서버 -> 앱)
앱 실행 시 또는 당겨서 새로고침 시 수행합니다.

1.  **GET /api/v1/sync?lastSyncedAt={timestamp}** 요청.
2.  서버는 해당 타임스탬프 이후 변경된 `Folder`, `Note`(삭제된 항목 포함)를 JSON으로 반환.
3.  앱은 로컬 DB를 갱신:
    -   `remoteId`가 없으면 생성.
    -   있으면 `updatedAt` 비교 후 최신이면 덮어쓰기.
    -   `deletedAt`이 있으면 로컬에서도 삭제(또는 휴지통 이동).

### 4.2. Push (앱 -> 서버)
로컬 데이터 변경 시 수행합니다.

1.  로컬 DB에서 `isDirty = true`인 항목 조회.
2.  **POST /api/v1/sync/batch** 요청 (변경분 전송).
    ```json
    {
      "notes": [{ "id": "uuid...", "title": "...", "updatedAt": "..." }],
      "deletedNoteIds": ["uuid..."]
    }
    ```
3.  성공 시 로컬의 `isDirty` 해제 및 `lastSyncedAt` 갱신.

## 5. 향후 로드맵
1.  **Isar 스키마 마이그레이션**: `remoteId`, `deletedAt`, `isDirty` 필드 추가.
2.  **Sync Manager 구현**: 백그라운드 동기화 로직 개발.
3.  **API 연동**: Node.js 서버의 `/api/v1` 엔드포인트와 통신 테스트.
