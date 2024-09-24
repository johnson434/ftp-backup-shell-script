# ftp-backup-shell-script

- 특정 디렉터리의 모든 하위 폴더 및 파일들을 NAS에 백업하는 셸 스크립트입니다.
- FTP 프로토콜을 사용하여 파일을 전송합니다.

## 사용법
1. SYNC_DIRECTORIES 파일에 백업할 디렉터리를 작성합니다.
```
/path/directory1
/path/directory2
```
2. FTP_SETTING에 백업할 서버의 정보를 입력합니다.
```
SERVER=local.server.co.kr
USER_NAME=username
PASSWORD=password
FTP_DIRECTORY=백업할서버의디렉터리경로
```
