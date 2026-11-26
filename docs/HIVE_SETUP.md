Xác định rõ Hive sẽ đóng vai trò gì trong kiến trúc hiện tại:

- HDFS: lưu trữ dữ liệu CitiBike đã được Sqoop import và log Hadoop do Flume thu thập.
- Hive: cung cấp lớp Data Warehouse, cho phép truy vấn dữ liệu trên HDFS bằng HiveQL (gần giống SQL).
- Metastore: lưu metadata như database, table, column, partition và vị trí dữ liệu. Chúng ta sẽ dùng PostgreSQL làm Metastore.
- Hadoop/YARN: cung cấp hạ tầng xử lý dữ liệu.

## 1. Kiểm tra Java của Hadoop

```powershell
docker compose exec hadoop java -version
```

## 2. Môi trường hiện tại

| Thành phần                   | Cấu hình                 |
| :--------------------------- | :----------------------- |
| Hadoop                       | 3.5.0                    |
| Java                         | OpenJDK 17.0.18          |
| PostgreSQL                   | 16                       |
| PostgreSQL database hiện tại | citibike                 |
| PostgreSQL user              | citibike                 |
| Docker network               | bigdata_citibike_default |

## 3. Kiểm tra database PostgreSQL

```powershell
docker compose exec postgres psql -U citibike -d citibike -c "\l"
```

## 4. Tạo database `hive_metastore`

```powershell
docker compose exec postgres psql -U citibike -d citibike -c "CREATE DATABASE hive_metastore;"
```

```text
PS D:\Dev\BigData_CitiBike> docker compose exec postgres psql -U citibike -d citibike -c "CREATE DATABASE hive_metastore;"

CREATE DATABASE
```

## 5. Chuẩn bị Dockerfile cho Hive

## 6. Build Hive image

```powershell
docker build -f Dockerfile.hive -t citibike-hive:4.1.0 .
```

Giải thích:

- -f Dockerfile.hive: sử dụng Dockerfile dành cho Hive.
- -t citibike-hive:4.1.0: đặt tên và tag cho image.
- .: sử dụng thư mục hiện tại làm build context.

## 7. Kiểm tra Hive image

```powershell
docker run --rm --entrypoint bash citibike-hive:4.1.0 -lc "echo '========== JAVA =========='; java -version; echo '========== HIVE =========='; hive --version; echo '========== POSTGRES JDBC =========='; ls -lh /opt/hive/lib/postgresql-*.jar"
```

Lệnh này kiểm tra 3 thứ:

1. Java bên trong image có phải Java 17 không.
2. Hive có nhận đúng phiên bản 4.1.0 không.
3. PostgreSQL JDBC Driver đã nằm trong thư mục thư viện Hive chưa.

| Thành phần      | Kết quả |
| :-------------- | :------ |
| Java            | 17.0.18 |
| Apache Hive     | 4.1.0   |
| PostgreSQL JDBC | 42.7.14 |

## 8. Tạo thư mục cấu hình Hive

## 9. Thêm service Hive Metastore vào Docker Compose

## 10. Khởi tạo Hive Metastore schema

```powershell
docker compose run --rm --no-deps hive-metastore schematool -dbType postgres -initSchema
```

Giải thích:

- docker compose run: tạo container tạm thời để thực hiện lệnh.
- --rm: tự xóa container sau khi hoàn thành.
- --no-deps: không tự khởi động các service phụ thuộc.
- schematool: công cụ quản lý schema của Hive.
- -dbType postgres: sử dụng PostgreSQL.
- -initSchema: tạo các bảng metadata cần thiết trong database hive_metastore.

## 11. Xác minh schema

```powershell
docker compose run --rm --no-deps hive-metastore schematool -dbType postgres -info
```

## 12. Khởi động Hive Metastore

```powershell
docker compose up -d hive-metastore
```

Kiểm tra trạng thái

```powershell
docker compose ps hive-metastore
```

Kết quả mong đợi:

- Container `citibike-hive-metastore` ở trạng thái Up.
- Cổng `9083` được publish.

Nếu container không chạy, lấy log bằng:

```powershell
docker compose logs --tail=100 hive-metastore
```

## 13. Kiểm tra cổng Metastore 9083

```powershell
docker compose exec hive-metastore bash -lc "bash -c '</dev/tcp/127.0.0.1/9083' && echo 'Metastore port 9083 is listening' || echo 'Metastore port 9083 is NOT listening'"
```

```text
PS D:\Dev\BigData_CitiBike> docker compose exec hive-metastore bash -lc "bash -c '</dev/tcp/127.0.0.1/9083' && echo 'Metastore port 9083 is listening' || echo 'Metastore port 9083 is NOT listening'"
Metastore port 9083 is listening
```

Đến đây, chúng ta đã hoàn thành:

- Cài Hive 4.1.0.
- Kết nối Hive với PostgreSQL.
- Khởi tạo và xác minh Metastore schema.
- Khởi động Hive Metastore trên Docker.

## 14. Chuẩn bị thư mục Warehouse trên HDFS

```text
/user/hive/warehouse
```

Đây là nơi Hive lưu dữ liệu của các bảng được quản lý (managed tables), không phải nơi lưu metadata PostgreSQL.

## 15. Tạo thư mục Warehouse trên HDFS

```powershell
docker compose exec hadoop hdfs dfs -mkdir -p /user/hive/warehouse
```

Sau đó kiểm tra

```powershell
docker compose exec hadoop hdfs dfs -ls -R /user
```

```text
PS D:\Dev\BigData_CitiBike> docker compose exec hadoop hdfs dfs -mkdir -p /user/hive/warehouse
PS D:\Dev\BigData_CitiBike> docker compose exec hadoop hdfs dfs -ls -R /user
drwxr-xr-x   - hadoop supergroup          0 2026-11-26 14:03 /user/hive
drwxr-xr-x   - hadoop supergroup          0 2026-11-26 14:03 /user/hive/warehouse
PS D:\Dev\BigData_CitiBike>
```

## 16. Kiểm tra user chạy Hive Metastore

```powershell
docker compose exec hive-metastore whoami
```

```text
PS D:\Dev\BigData_CitiBike> docker compose exec hive-metastore whoami
hadoop
```

## 17. Cài đặt HiveServer2

Hiện tại chúng ta đã có:

- HDFS: Lưu trữ dữ liệu CitiBike.
- PostgreSQL: Lưu metadata của Hive thông qua Hive Metastore.
- Hive Metastore: Đang chạy tại cổng 9083.
- Warehouse: /user/hive/warehouse đã được tạo.

HiveServer2 là thành phần tiếp theo, cung cấp giao diện JDBC để chúng ta kết nối bằng Beeline và thực hiện truy vấn SQL trên dữ liệu trong HDFS.

sửa file `docker-compose.yml`

## 18. Khởi chạy HiveServer2

```powershell
docker compose up -d hiveserver2
```

Kiểm tra:

```powershell
docker compose ps hiveserver2
```

## 19. Kiểm tra log HiveServer2

```powershell
docker compose logs --tail=100 hiveserver2
```

## 20. Kiểm tra cổng JDBC 10000

```powershell
docker compose exec hiveserver2 bash -lc "bash -c '</dev/tcp/127.0.0.1/10000' && echo 'HiveServer2 JDBC port 10000 is listening' || echo 'HiveServer2 JDBC port 10000 is NOT listening'"
```

```text
PS D:\Dev\BigData_CitiBike> docker compose exec hiveserver2 bash -lc "bash -c '</dev/tcp/127.0.0.1/10000' && echo 'HiveServer2 JDBC port 10000 is listening' || echo 'HiveServer2 JDBC port 10000 is NOT listening'"
HiveServer2 JDBC port 10000 is listening
```

## 21. Kiểm tra kết nối JDBC bằng Beeline.

```powershell
docker compose exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000/default" -n hadoop
```

```text
0: jdbc:hive2://localhost:10000/default>
```

```powershell
0: jdbc:hive2://localhost:10000/default> CREATE DATABASE citibike;
```

```powershell
0: jdbc:hive2://localhost:10000/default> SHOW DATABASES;
```

Thoát

```text
!quit
```

## 22. Kiểm tra cấu trúc bảng PostgreSQL gốc

```powershell
docker compose exec postgres psql -U citibike -d citibike -c "\d+ public.citibike_trips"
```

```text
PS D:\Dev\BigData_CitiBike> docker compose exec postgres psql -U citibike -d citibike -P pager=off -c "\d+ public.citibike_trips"
                                                      Table "public.citibike_trips"
       Column       |            Type             | Collation | Nullable | Default | Storage  | Compression | Stats target | Description
--------------------+-----------------------------+-----------+----------+---------+----------+-------------+--------------+-------------
 ride_id            | character varying(64)       |           | not null |         | extended |             |              |
 rideable_type      | character varying(32)       |           |          |         | extended |             |              |
 started_at         | timestamp without time zone |           |          |         | plain    |             |              |
 ended_at           | timestamp without time zone |           |          |         | plain    |             |              |
 start_station_name | text                        |           |          |         | extended |             |              |
 start_station_id   | character varying(64)       |           |          |         | extended |             |              |
 end_station_name   | text                        |           |          |         | extended |             |              |
 end_station_id     | character varying(64)       |           |          |         | extended |             |              |
 start_lat          | double precision            |           |          |         | plain    |             |              |
 start_lng          | double precision            |           |          |         | plain    |             |              |
 end_lat            | double precision            |           |          |         | plain    |             |              |
 end_lng            | double precision            |           |          |         | plain    |             |              |
 member_casual      | character varying(16)       |           |          |         | extended |             |              |
Indexes:
    "citibike_trips_pkey" PRIMARY KEY, btree (ride_id)
Access method: heap
```

## 23. Xác định định dạng file Sqoop trên HDFS

```powershell
docker compose exec hadoop bash -c "hdfs dfs -text /citibike/sqoop/citibike_trips/part-m-00000 | head -n 3"
```

## 24. Tạo bảng Hive trỏ đến dữ liệu HDFS

```powershell
docker compose exec hiveserver2 beeline -u "jdbc:hive2://localhost:10000/default" -n hadoop
```

Tạo External Table

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS citibike.citibike_trips (
    ride_id STRING,
    rideable_type STRING,
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    start_station_name STRING,
    start_station_id STRING,
    end_station_name STRING,
    end_station_id STRING,
    start_lat DOUBLE,
    start_lng DOUBLE,
    end_lat DOUBLE,
    end_lng DOUBLE,
    member_casual STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/citibike/sqoop/citibike_trips'
TBLPROPERTIES ('serialization.null.format'='null');
```

Giải thích những phần quan trọng:

- EXTERNAL TABLE: Tạo bảng Hive bên ngoài, không quản lý vòng đời file dữ liệu gốc.
- 13 cột: Khớp với cấu trúc PostgreSQL và thứ tự các trường trong file Sqoop.
- FIELDS TERMINATED BY ',': Phân tách các cột bằng dấu phẩy.
- STORED AS TEXTFILE: Dữ liệu được lưu dưới dạng file văn bản.
- LOCATION: Trỏ trực tiếp đến thư mục HDFS hiện có.
- serialization.null.format: Khai báo chuỗi null mà Sqoop mặc định dùng để biểu diễn giá trị NULL.

Kiểm tra metadata của bảng

```sql
DESCRIBE FORMATTED citibike.citibike_trips;
```

Truy vấn dữ liệu thật bằng Hive

```sql
SELECT
    ride_id,
    rideable_type,
    started_at,
    ended_at,
    member_casual
FROM citibike.citibike_trips
LIMIT 5;
```

Lấy thử 5 chuyến đi từ file HDFS mà không cần import dữ liệu lại từ PostgreSQL.

Kiểm tra tổng số bản ghi

```sql
SELECT COUNT(*)
FROM citibike.citibike_trips;
```

Bây giờ chúng ta thử một truy vấn có ý nghĩa phân tích hơn: so sánh số chuyến đi giữa khách vãng lai (casual) và thành viên (member).

```sql
SELECT
    member_casual,
    COUNT(*) AS total_trips
FROM citibike.citibike_trips
GROUP BY member_casual
ORDER BY total_trips DESC;
```

Bây giờ ta sẽ tìm hiểu loại xe nào được sử dụng nhiều nhất: electric_bike hay classic_bike.

```sql
SELECT
    rideable_type,
    COUNT(*) AS total_trips
FROM citibike.citibike_trips
GROUP BY rideable_type
ORDER BY total_trips DESC;
```
