# DirectDLX_CLI - Direct Media Downloader

**Developer:** [Lakshan Rukantha](https://github.com/LakshanRukantha)  
**Version:** 2.0

DirectDLX_CLI is a PowerShell-based command-line tool for downloading media files directly from URLs. It supports a wide range of media types including videos, images, audio, and documents, automatically detecting MIME types and assigning proper file extensions. The tool features an interactive interface with a real-time download progress bar, speed monitoring, and file size display. Downloads are organized in a dedicated folder, and filename conflicts are managed with user prompts.

**New in v2.0:** DirectDLX_CLI now supports **resuming interrupted downloads**, making it reliable for unstable network connections. Partial downloads are saved with `.part` extension, and users can resume them without restarting from scratch.

DirectDLX_CLI is lightweight, reliable, and ideal for users who prefer terminal-based media downloading without relying on browsers or third-party GUI applications.

## Supported File Types

**Videos:** `.mp4`, `.webm`, `.mkv`, `.mov`, `.avi`, `.flv`  
**Images:** `.jpg`, `.png`, `.gif`, `.webp`, `.bmp`, `.svg`  
**Audio:** `.mp3`, `.wav`, `.ogg`, `.weba`, `.aac`, `.flac`  
**Documents & Archives:** `.pdf`, `.zip`, `.rar`, `.txt`

## Features

- Download files directly from URLs.
- Auto-detect MIME types and assign proper file extensions.
- Real-time download progress with percentage, speed, and size display.
- Resume interrupted or crashed downloads.
- Interactive prompts for filename conflicts and partial downloads.
- Organized downloads in a dedicated folder.
- Lightweight and terminal-based – no browser required.

## Changelog

<details>
<summary>v2.0 - Resume Support & Improved Stability</summary>

- Added **resume support** for interrupted or failed downloads.
- Improved file naming to automatically detect MIME type extensions.
- Enhanced progress bar with download speed and percentage.
- Automatic cleanup of old partial files.
- Bug fixes and performance improvements.

</details>

<details>
<summary>v1.0 - Initial Release</summary>

- Basic downloading of media files via URL.
- Supports multiple file types including videos, images, audio, and documents.
- Interactive interface with download progress display.
- Downloads organized in a dedicated folder.

</details>
