# Novita Local Database Schema (Isar)

This document outlines the current local database schema used in the Novita app, implemented using **Isar Database**.

## 1. Overview
The local database is designed for an **Offline-First** architecture. It stores all user data locally on the device, ensuring the app works seamlessly without an internet connection.

## 2. Collections

### 2.1. Note
Represents a single note entry.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `Id` (int) | Auto-incrementing primary key. |
| `title` | `String` | Title of the note. |
| `body` | `String?` | Content of the note (for text notes). |
| `type` | `NoteType` | Enum: `text`, `checklist`. |
| `checklistItems` | `List<ChecklistItem>` | Embedded list of checklist items. |
| `pinned` | `bool` | Whether the note is pinned to the top. |
| `archived` | `bool` | Whether the note is archived. |
| `trashedAt` | `DateTime?` | Timestamp when the note was moved to trash. |
| `createdAt` | `DateTime` | Creation timestamp. |
| `updatedAt` | `DateTime` | Last modification timestamp. |
| `folder` | `IsarLink<Folder>` | Link to the parent folder. |
| `attachments` | `IsarLinks<Attachment>` | Backlink to attached files. |

### 2.2. Folder
Represents a container for notes.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `Id` (int) | Auto-incrementing primary key. |
| `name` | `String` | Name of the folder. |
| `isSystem` | `bool` | Whether it is a system folder (e.g., "All Notes"). |
| `sortOrder` | `int?` | Custom sort order index. |
| `createdAt` | `DateTime` | Creation timestamp. |
| `updatedAt` | `DateTime` | Last modification timestamp. |
| `notes` | `IsarLinks<Note>` | Backlink to notes in this folder. |

### 2.3. Attachment
Represents a file attached to a note.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `Id` (int) | Auto-incrementing primary key. |
| `filePath` | `String` | Local file path to the attachment. |
| `mimeType` | `String` | MIME type of the file. |
| `size` | `int?` | File size in bytes. |
| `createdAt` | `DateTime` | Creation timestamp. |
| `note` | `IsarLink<Note>` | Link to the parent note. |

## 3. Embedded Objects

### 3.1. ChecklistItem
Used within the `Note` collection for checklist type notes.

| Field | Type | Description |
| :--- | :--- | :--- |
| `text` | `String` | Content of the checklist item. |
| `done` | `bool` | Completion status. |
| `order` | `int?` | Display order index. |

## 4. Relationships
-   **Note <-> Folder**: Many-to-One (A note belongs to one folder).
-   **Note <-> Attachment**: One-to-Many (A note can have multiple attachments).
