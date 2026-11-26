## Lộ trình triển khai

1. Xác định vị trí log thực tế bên trong container Hadoop.
2. Xác định các file log nào có thể đọc được từ container Flume.
3. Hoàn thiện Dockerfile Flume và cài Flume 1.11.0.
4. Cấu hình Taildir Source, File Channel và HDFS Sink.
5. Tích hợp Flume vào Docker Compose.
6. Khởi chạy Flume Agent và kiểm tra log được ghi vào HDFS.
7. Tạo hoạt động MapReduce/YARN để phát sinh log mới và kiểm chứng Flume tiếp tục thu thập.
8. Viết tài liệu và lưu minh chứng.

## 1. Kiểm tra tiến trình Hadoop

```powershell
docker compose exec hadoop ps -ef
```

```text
PS D:\Dev\BigData_CitiBike> docker compose exec hadoop ps -ef
UID          PID    PPID  C STIME TTY          TIME CMD
hadoop         1       0  0 14:43 ?        00:00:00 /usr/local/bin/dumb-init
hadoop         7       1  0 14:43 ?        00:00:00 bash /opt/starter.sh /opt
hadoop        12       7  0 14:43 ?        00:00:00 bash /opt/starter.sh /opt
hadoop        45       1  5 14:43 ?        00:00:16 /opt/java/openjdk/bin/jav
hadoop       108       1  3 14:43 ?        00:00:09 /opt/java/openjdk/bin/jav
hadoop       211       1  9 14:43 ?        00:00:26 /opt/java/openjdk/bin/jav
hadoop       358       1  4 14:43 ?        00:00:12 /opt/java/openjdk/bin/jav
hadoop       507      12  0 14:43 ?        00:00:00 tail -F /opt/hadoop/logs/
hadoop       736       0 33 14:48 pts/0    00:00:00 ps -ef
```

## 2. Xác định dịch vụ và cơ chế ghi log

```powershell
docker compose exec hadoop bash -c "ps -ww -p 45,108,211,358 -o pid,ppid,args; echo '========== STARTER SCRIPT =========='; sed -n '1,240p' /opt/starter.sh; echo '========== LOG DIRECTORY =========='; ls -lah /opt/hadoop/logs"
```

Lệnh này kiểm tra:

- 4 tiến trình Java đang chạy là gì.
- Script /opt/starter.sh khởi động Hadoop như thế nào.
- Image Hadoop có cấu hình ghi log ra file hay không.

Hadoop thực tế đang ghi log vào `/var/log/hadoop`

```text
-Dhadoop.log.dir=/var/log/hadoop
-Dyarn.log.dir=/var/log/hadoop
```

## 3. Kiểm tra thư mục log thực tế

```powershell
docker compose exec hadoop bash -c "echo '========== /var/log/hadoop =========='; ls -lah /var/log/hadoop/; echo '========== LOG FILES =========='; find /var/log/hadoop -maxdepth 1 -type f -printf '%f %s bytes\n'"
```

Mục đích:

- Xác nhận các file log thực sự tồn tại.
- Xác định tên file để cấu hình Taildir Source.
- Kiểm tra log có đang tăng kích thước khi Hadoop hoạt động không.

```powershell
docker compose exec hadoop bash -c "echo '========== LOG DIRECTORY =========='; ls -lah /var/log/hadoop/; echo '========== LOG FILES =========='; find /var/log/hadoop -maxdepth 1 -type f -printf '%f %s bytes\n'"
```

```text
PS D:\Dev\BigData_CitiBike> docker compose exec hadoop bash -c "echo '========== /var/log/hadoop =========='; ls -lah /var/log/hadoop/; echo '========== LOG FILES =========='; find /var/log/hadoop -maxdepth 1 -type f -printf '%f %s bytes\n'"
========== /var/log/hadoop ==========
total 1.8M
drwxrwxrwt 1 root   root  4.0K Nov 25 14:43 .
drwxr-xr-x 1 root   root  4.0K Apr 17  2026 ..
-rw-r--r-- 1 hadoop users 222K Nov 25 14:43 hadoop-hadoop-datanode-hadoop.out
-rw-r--r-- 1 hadoop users 223K Nov 25 09:15 hadoop-hadoop-datanode-hadoop.out.1
-rw-r--r-- 1 hadoop users 468K Nov 24 13:49 hadoop-hadoop-datanode-hadoop.out.2
-rw-r--r-- 1 hadoop users  40K Nov 25 14:44 hadoop-hadoop-namenode-hadoop.out
-rw-r--r-- 1 hadoop users  40K Nov 25 09:15 hadoop-hadoop-namenode-hadoop.out.1
-rw-r--r-- 1 hadoop users 409K Nov 24 13:53 hadoop-hadoop-namenode-hadoop.out.2
-rw-r--r-- 1 hadoop users  37K Nov 25 14:43 hadoop-hadoop-nodemanager-hadoop.out
-rw-r--r-- 1 hadoop users  37K Nov 25 09:25 hadoop-hadoop-nodemanager-hadoop.out.1
-rw-r--r-- 1 hadoop users 106K Nov 24 13:54 hadoop-hadoop-nodemanager-hadoop.out.2
-rw-r--r-- 1 hadoop users  42K Nov 25 14:43 hadoop-hadoop-resourcemanager-hadoop.out
-rw-r--r-- 1 hadoop users  42K Nov 25 09:25 hadoop-hadoop-resourcemanager-hadoop.out.1
-rw-r--r-- 1 hadoop users  91K Nov 24 13:49 hadoop-hadoop-resourcemanager-hadoop.out.2
drwxr-xr-x 2 hadoop users 4.0K Nov 25 09:15 userlogs
========== LOG FILES ==========
hadoop-hadoop-namenode-hadoop.out 40158 bytes
hadoop-hadoop-nodemanager-hadoop.out.2 107638 bytes
hadoop-hadoop-nodemanager-hadoop.out.1 37574 bytes
hadoop-hadoop-datanode-hadoop.out 227149 bytes
hadoop-hadoop-datanode-hadoop.out.1 227360 bytes
hadoop-hadoop-namenode-hadoop.out.2 417837 bytes
hadoop-hadoop-resourcemanager-hadoop.out.2 92932 bytes
hadoop-hadoop-resourcemanager-hadoop.out 42728 bytes
hadoop-hadoop-namenode-hadoop.out.1 40146 bytes
hadoop-hadoop-resourcemanager-hadoop.out.1 42817 bytes
hadoop-hadoop-nodemanager-hadoop.out 36893 bytes
hadoop-hadoop-datanode-hadoop.out.2 478408 bytes
PS D:\Dev\BigData_CitiBike> docker compose exec hadoop bash -c "echo '========== LOG DIRECTORY =========='; ls -lah /var/log/hadoop/; echo '========== LOG FILES =========='; find /var/log/hadoop -maxdepth 1 -type f -printf '%f %s bytes\n'"
========== LOG DIRECTORY ==========
total 1.8M
drwxrwxrwt 1 root   root  4.0K Nov 25 14:43 .
drwxr-xr-x 1 root   root  4.0K Apr 17  2026 ..
-rw-r--r-- 1 hadoop users 222K Nov 25 14:43 hadoop-hadoop-datanode-hadoop.out
-rw-r--r-- 1 hadoop users 223K Nov 25 09:15 hadoop-hadoop-datanode-hadoop.out.1
-rw-r--r-- 1 hadoop users 468K Nov 24 13:49 hadoop-hadoop-datanode-hadoop.out.2
-rw-r--r-- 1 hadoop users  40K Nov 25 14:44 hadoop-hadoop-namenode-hadoop.out
-rw-r--r-- 1 hadoop users  40K Nov 25 09:15 hadoop-hadoop-namenode-hadoop.out.1
-rw-r--r-- 1 hadoop users 409K Nov 24 13:53 hadoop-hadoop-namenode-hadoop.out.2
-rw-r--r-- 1 hadoop users  37K Nov 25 14:43 hadoop-hadoop-nodemanager-hadoop.out
-rw-r--r-- 1 hadoop users  37K Nov 25 09:25 hadoop-hadoop-nodemanager-hadoop.out.1
-rw-r--r-- 1 hadoop users 106K Nov 24 13:54 hadoop-hadoop-nodemanager-hadoop.out.2
-rw-r--r-- 1 hadoop users  42K Nov 25 14:43 hadoop-hadoop-resourcemanager-hadoop.out
-rw-r--r-- 1 hadoop users  42K Nov 25 09:25 hadoop-hadoop-resourcemanager-hadoop.out.1
-rw-r--r-- 1 hadoop users  91K Nov 24 13:49 hadoop-hadoop-resourcemanager-hadoop.out.2
drwxr-xr-x 2 hadoop users 4.0K Nov 25 09:15 userlogs
========== LOG FILES ==========
hadoop-hadoop-namenode-hadoop.out 40158 bytes
hadoop-hadoop-nodemanager-hadoop.out.2 107638 bytes
hadoop-hadoop-nodemanager-hadoop.out.1 37574 bytes
hadoop-hadoop-datanode-hadoop.out 227149 bytes
hadoop-hadoop-datanode-hadoop.out.1 227360 bytes
hadoop-hadoop-namenode-hadoop.out.2 417837 bytes
hadoop-hadoop-resourcemanager-hadoop.out.2 92932 bytes
hadoop-hadoop-resourcemanager-hadoop.out 42728 bytes
hadoop-hadoop-namenode-hadoop.out.1 40146 bytes
hadoop-hadoop-resourcemanager-hadoop.out.1 42817 bytes
hadoop-hadoop-nodemanager-hadoop.out 36893 bytes
hadoop-hadoop-datanode-hadoop.out.2 478408 bytes
```

## 4. Kiểm tra nội dung log

Trước khi cấu hình Taildir Source, ta cần xem nội dung log thực tế để xác định định dạng và cách đọc.

```powershell
docker compose exec hadoop head -n 8 /var/log/hadoop/hadoop-hadoop-namenode-hadoop.out
```

Ta thấy log có các thông tin thực tế:

- Thời gian khởi động: 2026-11-25 14:43:39.
- Dịch vụ: NameNode.
- Phiên bản Hadoop: 3.5.0.
- Host: hadoop/172.18.0.2.
  Như vậy, /var/log/hadoop/ có log Hadoop thực tế và chúng ta có thể dùng Flume để thu thập chúng.

Kiểm tra định dạng log của cả bốn dịch vụ

```powershell
docker compose exec hadoop head -n 5 /var/log/hadoop/hadoop-hadoop-datanode-hadoop.out
```

```powershell
docker compose exec hadoop head -n 5 /var/log/hadoop/hadoop-hadoop-resourcemanager-hadoop.out
```

```powershell
docker compose exec hadoop head -n 5 /var/log/hadoop/hadoop-hadoop-nodemanager-hadoop.out
```

```text
PS D:\Dev\BigData_CitiBike> docker compose exec hadoop head -n 5 /var/log/hadoop/hadoop-hadoop-datanode-hadoop.out
2026-11-25 14:43:41 INFO  DataNode:809 - STARTUP_MSG:
/************************************************************
STARTUP_MSG: Starting DataNode
STARTUP_MSG:   host = hadoop/172.18.0.2
STARTUP_MSG:   args = []
PS D:\Dev\BigData_CitiBike> docker compose exec hadoop head -n 5 /var/log/hadoop/hadoop-hadoop-resourcemanager-hadoop.out
2026-11-25 14:43:43 INFO  ResourceManager:809 - STARTUP_MSG:
/************************************************************
STARTUP_MSG: Starting ResourceManager
STARTUP_MSG:   host = hadoop/172.18.0.2
STARTUP_MSG:   args = []
PS D:\Dev\BigData_CitiBike> docker compose exec hadoop head -n 5 /var/log/hadoop/hadoop-hadoop-nodemanager-hadoop.out
2026-11-25 14:43:45 INFO  NodeManager:809 - STARTUP_MSG:
/************************************************************
STARTUP_MSG: Starting NodeManager
STARTUP_MSG:   host = hadoop/172.18.0.2
STARTUP_MSG:   args = []
```

## 3. Sao lưu log Hadoop ra máy Windows

```powershell
New-Item -ItemType Directory -Force .\logs\hadoop | Out-Null

docker cp hadoop-single-node:/var/log/hadoop/. .\logs\hadoop\

Get-ChildItem .\logs\hadoop
```

```text
PS D:\Dev\BigData_CitiBike> New-Item -ItemType Directory -Force .\logs\hadoop | Out-Null
PS D:\Dev\BigData_CitiBike> docker cp hadoop-single-node:/var/log/hadoop/. .\logs\hadoop\
Successfully copied 1.8MB to D:\Dev\BigData_CitiBike\logs\hadoop\
PS D:\Dev\BigData_CitiBike> Get-ChildItem .\logs\hadoop


    Directory: D:\Dev\BigData_CitiBike\logs\hadoop


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        11/25/2026   4:15 PM                userlogs
-a----        11/25/2026   9:43 PM         227149 hadoop-hadoop-datanode-had
                                                  oop.out
-a----        11/25/2026   4:15 PM         227360 hadoop-hadoop-datanode-had
                                                  oop.out.1
-a----        11/24/2026   8:49 PM         478408 hadoop-hadoop-datanode-had
                                                  oop.out.2
-a----        11/25/2026   9:44 PM          40158 hadoop-hadoop-namenode-had
                                                  oop.out
```

## 4. Gắn thư mục log vào container Hadoop

```yaml
volumes:
  - ./datasets/raw/citibike/2024:/data/citibike/2024:ro
  - namenode_data:/opt/hadoop/data/namenode
  - datanode_data:/opt/hadoop/data/datanode
  - ./logs/hadoop:/var/log/hadoop
```

## 5. Khởi động lại riêng Hadoop

Bây giờ cần tạo lại container Hadoop để áp dụng bind mount mới.

```powershell
docker compose up -d hadoop
```

Kiểm tra

```powershell
docker compose ps
```

## 6. Kiểm tra log sau khi khởi động lại

```powershell
Get-ChildItem .\logs\hadoop -File | Select-Object Name, LastWriteTime, Length
```

## 7. Xác nhận log trong container và Windows là cung một file

```powershell
docker compose exec hadoop ls -l /var/log/hadoop
```

```text
Hadoop services
      |
      | Ghi log
      v
/var/log/hadoop (Hadoop container)
      |
      | Bind mount
      v
./logs/hadoop (Windows)
      |
      | Flume Taildir Source đọc
      v
Flume File Channel
      |
      | HDFS Sink
      v
HDFS: /citibike/flume/logs/
```

## 8. Kiểm tra cấu hình kết nối HDFS

```powershell
docker compose exec hadoop cat /opt/hadoop/etc/hadoop/core-site.xml
```

```powershell
docker compose exec hadoop cat /opt/hadoop/etc/hadoop/hdfs-site.xml
```

```powershell
docker compose exec hadoop hdfs getconf -confKey dfs.client.use.datanode.hostname
```

## 9. Kiểm tra Docker DNS

```powershell
docker compose exec postgres getent hosts hadoop
```

```text
PS D:\Dev\BigData_CitiBike> docker compose exec postgres getent hosts hadoop
172.18.0.2      hadoop
```

## 10. Chuẩn bị Dockerfile cài Apache Flume

- FROM apache/hadoop:3.5.0: dùng cùng phiên bản Hadoop với container hiện tại để giảm nguy cơ xung đột thư viện.
- FLUME_HOME: thư mục cài đặt Flume.
- HADOOP_HOME: giúp Flume tìm thư viện Hadoop.
- checkpoint: lưu trạng thái File Channel.
- data: lưu dữ liệu của File Channel.
- taildir: lưu vị trí Flume đã đọc trong các file log.
- USER hadoop: chạy Flume bằng user Hadoop thay vì root.

## 11. Build Flume image

```powershell
docker build -f Dockerfile.flume -t citibike-flume:1.11.0 .
```

Lệnh này sẽ:

1. Sử dụng Hadoop 3.5.0 làm base image.
2. Tải Apache Flume 1.11.0.
3. Cài Flume vào `/opt/flume`.
4. Tạo các thư mục lưu trạng thái và dữ liệu.
5. Tạo image `citibike-flume:1.11.0`.

```text
PS D:\Dev\BigData_CitiBike> docker build -f Dockerfile.flume -t citibike-flume:1.11.0 .
[+] Building 48.7s (7/7) FINISHED                        docker:desktop-linux
 => [internal] load build definition from Dockerfile.flume               0.0s
 => => transferring dockerfile: 871B                                     0.0s
 => [internal] load metadata for docker.io/apache/hadoop:3.5.0           0.0s
 => [internal] load .dockerignore                                        0.0s
 => => transferring context: 2B                                          0.0s
 => CACHED [1/3] FROM docker.io/apache/hadoop:3.5.0@sha256:46980ea1653e  0.0s
 => => resolve docker.io/apache/hadoop:3.5.0@sha256:46980ea1653eb3453d9  0.0s
 => [2/3] RUN mkdir -p /opt/flume &&     curl -fL     https://download  37.6s
 => [3/3] RUN mkdir -p     /var/lib/flume/checkpoint     /var/lib/flume  5.8s
 => exporting to image                                                   5.0s
 => => exporting layers                                                  3.2s
 => => exporting manifest sha256:b6056a8c03808c1e9e95c21407285e5225193d  0.0s
 => => exporting config sha256:56998179a83a7a10879397c6d4606999a6b132d1  0.0s
 => => exporting attestation manifest sha256:de01f054eb3971055fb16d2f98  0.0s
 => => exporting manifest list sha256:904cf250748946d7c9863aabf8af45ba9  0.0s
 => => naming to docker.io/library/citibike-flume:1.11.0                 0.0s
 => => unpacking to docker.io/library/citibike-flume:1.11.0              1.6s

View build details: docker-desktop://dashboard/build/desktop-linux/desktop-linux/kcet7pafas8xehfdavf303uca
```

## 12. Kiểm tra phiên bản Flume

```powershell
docker run --rm --entrypoint flume-ng citibike-flume:1.11.0 version
```

Mục đích:

- Xác nhận Flume executable hoạt động.
- Kiểm tra phiên bản thực tế.
- Phát hiện sớm vấn đề Java hoặc thư viện trước khi đưa Flume vào Docker Compose.

```text
PS D:\Dev\BigData_CitiBike> docker run --rm --entrypoint flume-ng citibike-flume:1.11.0 version
Flume 1.11.0
Source code repository: https://git.apache.org/repos/asf/flume.git
Revision: 1a15927e594fd0d05a59d804b90a9c31ec93f5e1
Compiled by rgoers on Sun Oct 16 14:44:15 MST 2022
From source with checksum bbbca682177262aac3a89defde369a37
```

## 13. Cấu hình Hadoop client riêng cho Flume

`core-site.xml`, `flume.conf`, `hdfs-site.xml`, `Dockerfile.flume`

## 14. Thêm Flume service vào Docker Compose

Kiểm tra Compose

```powershell
docker compose config
```

## 15. Tạo và khởi chạy Flume container

```powershell
docker compose up -d --build --no-deps flume
```

Ý nghĩa:

- up -d: tạo và chạy container nền.
- --build: build lại image theo Dockerfile hiện tại.
- --no-deps: không khởi động lại hoặc tác động đến Hadoop và PostgreSQL.

```text
PS D:\Dev\BigData_CitiBike> docker compose up -d --build --no-deps flume
[+] Building 1.0s (9/9) FINISHED
 => [internal] load local bake definitions                              0.0s
 => => reading from stdin 522B                                          0.0s
 => [internal] load build definition from Dockerfile.flume              0.0s
 => => transferring dockerfile: 871B                                    0.0s
 => [internal] load metadata for docker.io/apache/hadoop:3.5.0          0.1s
 => [internal] load .dockerignore                                       0.0s
 => => transferring context: 2B                                         0.0s
 => [1/3] FROM docker.io/apache/hadoop:3.5.0@sha256:46980ea1653eb3453d  0.0s
 => => resolve docker.io/apache/hadoop:3.5.0@sha256:46980ea1653eb3453d  0.0s
 => CACHED [2/3] RUN mkdir -p /opt/flume &&     curl -fL     https://d  0.0s
 => CACHED [3/3] RUN mkdir -p     /var/lib/flume/checkpoint     /var/l  0.0s
 => exporting to image                                                  0.2s
 => => exporting layers                                                 0.0s
 => => exporting manifest sha256:fd2c0480d0d7d0aa50335b7bd182e4be42253  0.0s
 => => exporting config sha256:77728fe1ede685da8de9fd4ac4dacf9e66dbc4b  0.0s
 => => exporting attestation manifest sha256:614effa06a483fc4d208c9d6f  0.0s
 => => exporting manifest list sha256:3ddf77d5cd19115cd33e3aa43dea57fb  0.0s
 => => naming to docker.io/library/citibike-flume:1.11.0                0.0s
 => => unpacking to docker.io/library/citibike-flume:1.11.0             0.0s
 => resolving provenance for metadata file                              0.0s
[+] up 3/3
 ✔ Image citibike-flume:1.11.0        Built                              1.3s
 ✔ Volume bigdata_citibike_flume_data Created                            0.0s
 ✔ Container citibike-flume           Started                            0.3s
```

## 16. Kiểm tra Flume container và các mount

```powershell
docker compose exec flume ls -lah /var/log/hadoop
```

Chúng ta cần xác nhận:

1. Flume nhìn thấy đủ 4 file log Hadoop.
2. Các file .out có kích thước tương ứng với Windows.
3. Flume truy cập được thư mục log ở chế độ chỉ đọc.

```powershell
docker compose exec flume ls -lah /opt/flume/conf
```

```text
PS D:\Dev\BigData_CitiBike> docker compose exec flume ls -lah /var/log/hadoop

total 2.7M
drwxrwxrwx 1 root   root  4.0K Nov 26 07:56 .
drwxr-xr-x 1 root   root  4.0K Apr 17  2026 ..
-rw-r--r-- 1 hadoop users 222K Nov 26 07:56 hadoop-hadoop-datanode-hadoop.out
-rw-r--r-- 1 hadoop users 223K Nov 25 15:22 hadoop-hadoop-datanode-hadoop.out.1
-rwxrwxrwx 1 root   root  222K Nov 25 14:43 hadoop-hadoop-datanode-hadoop.out.2
-rwxrwxrwx 1 root   root  223K Nov 25 09:15 hadoop-hadoop-datanode-hadoop.out.3
-rwxrwxrwx 1 root   root  468K Nov 24 13:49 hadoop-hadoop-datanode-hadoop.out.4
-rw-r--r-- 1 hadoop users  40K Nov 26 07:56 hadoop-hadoop-namenode-hadoop.out
-rw-r--r-- 1 hadoop users  39K Nov 25 15:22 hadoop-hadoop-namenode-hadoop.out.1
-rwxrwxrwx 1 root   root   40K Nov 25 14:44 hadoop-hadoop-namenode-hadoop.out.2
-rwxrwxrwx 1 root   root   40K Nov 25 09:15 hadoop-hadoop-namenode-hadoop.out.3
-rwxrwxrwx 1 root   root  409K Nov 24 13:53 hadoop-hadoop-namenode-hadoop.out.4
-rw-r--r-- 1 hadoop users  37K Nov 26 08:16 hadoop-hadoop-nodemanager-hadoop.out
-rw-r--r-- 1 hadoop users  37K Nov 25 15:29 hadoop-hadoop-nodemanager-hadoop.out.1
-rwxrwxrwx 1 root   root   37K Nov 25 15:03 hadoop-hadoop-nodemanager-hadoop.out.2
-rwxrwxrwx 1 root   root   37K Nov 25 09:25 hadoop-hadoop-nodemanager-hadoop.out.3
-rwxrwxrwx 1 root   root  106K Nov 24 13:54 hadoop-hadoop-nodemanager-hadoop.out.4
-rw-r--r-- 1 hadoop users  42K Nov 26 08:06 hadoop-hadoop-resourcemanager-hadoop.out
-rw-r--r-- 1 hadoop users  42K Nov 25 15:19 hadoop-hadoop-resourcemanager-hadoop.out.1
-rwxrwxrwx 1 root   root   42K Nov 25 14:53 hadoop-hadoop-resourcemanager-hadoop.out.2
-rwxrwxrwx 1 root   root   42K Nov 25 09:25 hadoop-hadoop-resourcemanager-hadoop.out.3
-rwxrwxrwx 1 root   root   91K Nov 24 13:49 hadoop-hadoop-resourcemanager-hadoop.out.4
drwxrwxrwx 1 root   root  4.0K Nov 25 09:15 userlogs
PS D:\Dev\BigData_CitiBike> docker compose exec flume ls -lah /opt/flume/conf

total 32K
drwxr-xr-x 1 hadoop users 4.0K Nov 26 08:14 .
drwxr-xr-x 1 hadoop users 4.0K Nov 26 08:01 ..
-rwxrwxrwx 1 root   root  2.1K Nov 26 08:06 flume.conf
-rw-r--r-- 1 hadoop users 1.7K Jan 20  2022 flume-conf.properties.template
-rw-r--r-- 1 hadoop users 1.5K Jan 20  2022 flume-env.ps1.template
-rw-r--r-- 1 hadoop users 1.6K Jan 20  2022 flume-env.sh.template
-rw-r--r-- 1 hadoop users 2.4K Oct  8  2022 log4j2.xml
```

## 17. Kiểm tra Flume kiết nối HDFS

Đây là bước quan trọng trước khi chạy Agent. Ta cần xác nhận Flume có thể truy cập NameNode thông qua hadoop:9000.

```powershell
docker compose exec flume hdfs dfs -ls /
```

```text
PS D:\Dev\BigData_CitiBike> docker compose exec flume hdfs dfs -ls /
Found 2 items
drwxr-xr-x   - hadoop supergroup          0 2026-11-24 13:30 /citibike
drwxr-xr-x   - hadoop supergroup          0 2026-11-24 13:20 /tmp
```

## 18. Kiểm tra ghi và đọc HDFS

```powershell
docker compose exec flume bash -lc "if hdfs dfs -test -e /tmp/flume-connectivity-test-20261126.txt; then echo 'File already exists; aborting.'; exit 1; fi; printf 'Flume HDFS connectivity test\n' | hdfs dfs -put - /tmp/flume-connectivity-test-20261126.txt && hdfs dfs -cat /tmp/flume-connectivity-test-20261126.txt && hdfs dfs -rm /tmp/flume-connectivity-test-20261126.txt"
```

Lệnh thực hiện 4 việc:

1. Kiểm tra file thử nghiệm chưa tồn tại để tránh ghi đè.
2. Ghi một dòng dữ liệu từ Flume container lên HDFS.
3. Đọc lại nội dung vừa ghi.
4. Xóa file thử nghiệm.

```text
PS D:\Dev\BigData_CitiBike> docker compose exec flume bash -lc "if hdfs dfs -test -e /tmp/flume-connectivity-test-20261126.txt; then echo 'File already exists; aborting.'; exit 1; fi; printf 'Flume HDFS connectivity test\n' | hdfs dfs -put - /tmp/flume-connectivity-test-20261126.txt && hdfs dfs -cat /tmp/flume-connectivity-test-20261126.txt && hdfs dfs -rm /tmp/flume-connectivity-test-20261126.txt"
Flume HDFS connectivity test
Deleted /tmp/flume-connectivity-test-20261126.txt
```

## 19. Khởi chạy Flume Agent

Hiện tại container Flume vẫn chạy sleep infinity. Chúng ta sẽ chạy Agent ở chế độ foreground trước để quan sát log và phát hiện lỗi cấu hình nếu có.

```powershell
docker compose exec flume flume-ng agent --conf /opt/flume/conf --conf-file /opt/flume/conf/flume.conf --name citibike -Dflume.root.logger=INFO,console
```

Lưu ý:

- Lần này chưa chạy nền.
- Giữ cửa sổ terminal để theo dõi log.
- Nếu Agent khởi động thành công, bạn sẽ thấy các thông báo về Source, Channel và Sink.
- Nhấn Ctrl + C để dừng Agent khi cần.

## 20. Kiểm tra Agent có thực sự chạy không

Mở một cửa sổ PowerShell thứ hai, giữ nguyên cửa sổ đang chạy Flume.

```powershell
docker compose exec flume bash -lc "ps -eo pid,etime,args | grep '[o]rg.apache.flume.node.Application'"
```

Lệnh này kiểm tra tiến trình Java của Flume Agent:

- Nếu xuất hiện org.apache.flume.node.Application: Agent vẫn đang chạy.
- Nếu không có kết quả: Agent đã kết thúc hoặc không khởi tạo được.

Kiểm tra Flume đã tạo dữ liệu trên HDFS chưa:

```powershell
docker compose exec flume hdfs dfs -ls -R /citibike/flume
```

## 21. Kiểm tra cả 4 loại log

Hiện tại ta mới nhìn thấy log ResourceManager. Cần xác nhận Flume thu thập được log từ cả bốn tiến trình:

- NameNode
- DataNode
- ResourceManager
- NodeManager

```powershell
docker compose exec flume bash -lc "echo '========== NAMENODE =========='; tail -n 3 /var/log/hadoop/hadoop-hadoop-namenode-hadoop.out; echo '========== DATANODE =========='; tail -n 3 /var/log/hadoop/hadoop-hadoop-datanode-hadoop.out; echo '========== RESOURCEMANAGER =========='; tail -n 3 /var/log/hadoop/hadoop-hadoop-resourcemanager-hadoop.out; echo '========== NODEMANAGER =========='; tail -n 3 /var/log/hadoop/hadoop-hadoop-nodemanager-hadoop.out"
```

```text
PS D:\Dev\BigData_CitiBike> docker compose exec flume bash -lc "echo '========== NAMENODE =========='; tail -n 3 /var/log/hadoop/hadoop-hadoop-namenode-hadoop.out; echo '========== DATANODE =========='; tail -n 3 /var/log/hadoop/hadoop-hadoop-datanode-hadoop.out; echo '========== RESOURCEMANAGER =========='; tail -n 3 /var/log/hadoop/hadoop-hadoop-resourcemanager-hadoop.out; echo '========== NODEMANAGER =========='; tail -n 3 /var/log/hadoop/hadoop-hadoop-nodemanager-hadoop.out"
========== NAMENODE ==========
2026-11-26 08:35:24 INFO  FSEditLog:801 - Number of transactions: 68 Total time for transactions(ms): 20 Number of transactions batched in Syncs: 1269 Number of syncs: 55 SyncTimes(ms): 84
2026-11-26 08:35:24 INFO  audit:9055 - allowed=true     ugi=hadoop (auth:SIMPLE)     ip=/172.18.0.4  cmd=getfileinfo src=/citibike/flume/logs/2026/11/26/FlumeData.1795682063902.tmp  dst=null perm=null       proto=rpc
2026-11-26 08:35:24 INFO  audit:9055 - allowed=true     ugi=hadoop (auth:SIMPLE)     ip=/172.18.0.4  cmd=rename      src=/citibike/flume/logs/2026/11/26/FlumeData.1795682063902.tmp  dst=/citibike/flume/logs/2026/11/26/FlumeData.1795682063902  perm=hadoop:supergroup:rw-r--r-- proto=rpc
========== DATANODE ==========
2026-11-26 08:34:24 INFO  DataNode:759 - Receiving BP-1313422828-172.18.0.2-1795513462842:blk_1073742032_1208 src: /172.18.0.4:52040 dest: /172.18.0.2:9866
2026-11-26 08:35:24 INFO  clienttrace:1577 - src: /172.18.0.4:52040, dest: /172.18.0.2:9866, volume: /opt/hadoop/data/datanode, bytes: 2174, op: HDFS_WRITE, cliID: DFSClient_NONMAPREDUCE_904102239_33, offset: 0, srvID: cf884e5c-2e36-4498-98eb-4bccbbd56108, blockid: BP-1313422828-172.18.0.2-1795513462842:blk_1073742032_1208, duration(ns): 59993938278
2026-11-26 08:35:24 INFO  DataNode:1550 - PacketResponder: BP-1313422828-172.18.0.2-1795513462842:blk_1073742032_1208, type=LAST_IN_PIPELINE terminating
========== RESOURCEMANAGER ==========
2026-11-26 07:56:10 INFO  CapacityScheduler:2266 - Added node hadoop:46249 clusterResource: <memory:2048, vCores:2>
2026-11-26 07:56:10 INFO  AbstractLeafQueue:2487 - LeafQueue: root.default update max app related, maxApplications=10000, maxApplicationsPerUser=10000, Abs Cap:1.0, Cap: 1.0, MaxCap : 1.0
2026-11-26 08:06:08 INFO  AbstractYarnScheduler:802 - Release request cache is cleaned up
========== NODEMANAGER ==========
2026-11-26 08:06:08 INFO  ResourceLocalizationService:551 - Cache Size Before Clean: 0, Total Deleted: 0, Public Deleted: 0, Private Deleted: 0
2026-11-26 08:16:08 INFO  ResourceLocalizationService:551 - Cache Size Before Clean: 0, Total Deleted: 0, Public Deleted: 0, Private Deleted: 0
2026-11-26 08:26:08 INFO  ResourceLocalizationService:551 - Cache Size Before Clean: 0, Total Deleted: 0, Public Deleted: 0, Private Deleted: 0
```

Kiểm tra log trên HDFS

```powershell
docker compose exec flume hdfs dfs -ls -R /citibike/flume/logs/2026/11/26
```

```text
PS D:\Dev\BigData_CitiBike> docker compose exec flume hdfs dfs -ls -R /citibike/flume/logs/2026/11/26
-rw-r--r--   1 hadoop supergroup     352417 2026-11-26 08:27 /citibike/flume/logs/2026/11/26/FlumeData.1795681612935
-rw-r--r--   1 hadoop supergroup       3159 2026-11-26 08:29 /citibike/flume/logs/2026/11/26/FlumeData.1795681680227
-rw-r--r--   1 hadoop supergroup       2174 2026-11-26 08:30 /citibike/flume/logs/2026/11/26/FlumeData.1795681744344
-rw-r--r--   1 hadoop supergroup       2561 2026-11-26 08:31 /citibike/flume/logs/2026/11/26/FlumeData.1795681805463
-rw-r--r--   1 hadoop supergroup       2174 2026-11-26 08:32 /citibike/flume/logs/2026/11/26/FlumeData.1795681868593
-rw-r--r--   1 hadoop supergroup       2174 2026-11-26 08:33 /citibike/flume/logs/2026/11/26/FlumeData.1795681934692
-rw-r--r--   1 hadoop supergroup       2174 2026-11-26 08:34 /citibike/flume/logs/2026/11/26/FlumeData.1795682000794
-rw-r--r--   1 hadoop supergroup       2174 2026-11-26 08:35 /citibike/flume/logs/2026/11/26/FlumeData.1795682063902
-rw-r--r--   1 hadoop supergroup       2318 2026-11-26 08:36 /citibike/flume/logs/2026/11/26/FlumeData.1795682130028
```

```powershell
docker compose exec flume bash -lc "hdfs dfs -cat /citibike/flume/logs/2026/11/26/FlumeData.* 2>/dev/null | grep -E 'NameNode:|DataNode:|ResourceManager:|NodeManager:' | cut -d' ' -f4 | sort | uniq -c"
```

```text
PS D:\Dev\BigData_CitiBike> docker compose exec flume bash -lc "hdfs dfs -cat /citibike/flume/logs/2026/11/26/FlumeData.* 2>/dev/null | grep -E 'NameNode:|DataNode:|ResourceManager:|NodeManager:' | cut -d' ' -f4 | sort | uniq -c"
     57
```

```powershell
docker compose exec flume bash -lc "hdfs dfs -cat /citibike/flume/logs/2026/11/26/FlumeData.* 2>/dev/null | grep -oE '(NameNode|DataNode|ResourceManager|NodeManager):' | sort | uniq -c"
```

```text
     41 DataNode:
      8 NameNode:
      2 NodeManager:
      6 ResourceManager:
```

## khởi động lại riêng container Flume và xác nhận nó tiếp tục đọc từ vị trí cũ

## 1. Kiểm tra vị trí đọc log của Taildir

```powershell
docker compose exec flume bash -lc "cat /var/lib/flume/taildir/position.json"
```

## 2. Kiểm tra số lượng file trên HDFS

```powershell
docker compose exec flume hdfs dfs -count /citibike/flume/logs/2026/11/26
```

## 3. Restart riêng container Flume

```powershell
docker compose restart flume
```

## 4. Kiểm tra vị trí đọc log của Taildir

```powershell
docker compose exec flume bash -lc "cat /var/lib/flume/taildir/position.json"
```

## 5. Kiểm tra số lượng file trên HDFS

```powershell
docker compose exec flume hdfs dfs -count /citibike/flume/logs/2026/11/26
```
