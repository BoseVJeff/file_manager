# file_manager

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Database Structure

### System Table

Stores the names of all systems/PCs that are known alongside this OS.

This name is obtained by querying the `COMPUTERNAME` system variable on Windows systems and by querying `hostnamectl hostname` on Linux and Unix systems.

#### Table Structure

| Field | SQL Notes | Description|
|-------|-----------|------------|
| System ID | Primary Key Autoincrement | Internal autoimncrementing ID |
| System Name | String | Name of the system as defined above |
| System OS | String | Name of the operating system |

## Files

This table is responsible for stroing all the files encountered by the application.

#### Table Structure

| Field | SQL Notes | Description|
|-------|-----------|------------|
| File ID | Primary Key Autoincrement | Internal ID for file tracking and deduplication |
| System ID | Referenced from System Table | |
| Drive Root Folder | String | Is the folder not the drive letter as it only works on Windows |
| File Path | String | Full path to file including filename and extension |
| Filename | String | Including the file extension |
| Mime type | String | Stored as this may be require reading the entire file bytes |
| File hash | String | Stored as this is hard to compute |

Note that the name `file_name` is misleading as it can also refer to a directory. In that case, the `file_mime_type` is `directory`.

## SQL

```sql
CREATE TABLE tbl_system (
system_id INTEGER PRIMARY KEY AUTOINCREMENT,
system_name TEXT,
system_os TEXT
);

CREATE TABLE tbl_file (
file_id INTEGER PRIMARY KEY AUTOINCREMENT,
system_id INTEGER REFERENCES tbl_system,
file_drive_root TEXT,
file_full_path TEXT,
file_name TEXT,
file_mime_type TEXT,
file_hash TEXT
);
```