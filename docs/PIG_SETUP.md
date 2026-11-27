Trước khi bắt đầu, cần hiểu vai trò của Pig trong kiến trúc:

- HDFS: Lưu trữ dữ liệu.
- Sqoop: Đưa dữ liệu từ PostgreSQL sang HDFS.
- Flume: Thu thập log và đưa vào HDFS.
- Hive: Truy vấn dữ liệu bằng SQL.
- Pig: Xử lý và biến đổi dữ liệu bằng ngôn ngữ Pig Latin.

## 1. Tạo file Dockerfile.pig

## 2. Build Docker image Pig

```powershell
docker build -f Dockerfile.pig -t citibike-pig:0.18.0 .
```

Lệnh này sẽ:

1. Sử dụng image nền apache/hadoop:3.5.0.
2. Tải Apache Pig 0.18.0.
3. Giải nén vào /opt/pig.
4. Cấu hình PATH để gọi được lệnh pig.
5. Chạy mặc định bằng user hadoop.

Build xong, chạy

```powershell
docker images citibike-pig
```

## 3. Kiểm tra phiên bản Pig

```powershell
docker run --rm citibike-pig:0.18.0 pig -version
```

## 4. Thêm service Pig vào docker-compose.yml

## 5. Kiểm tra cấu hình Compose

```powershell
docker compose config
```

## 6. Khởi động Pig

```powershell
docker compose up -d pig
```

## 7. Thêm file cấu hình Pig

## 8. Áp dụng cấu hình mới cho Pig

```powershell
docker compose up -d --force-recreate pig
```

## 9. Kiểm tra cấu hình Pig đã được mount

```powershell
docker compose exec pig cat /opt/hadoop/etc/hadoop/core-site.xml
```

## 10. Kiểm tra HDFS từ Pig

```powershell
docker compose exec pig hdfs dfs -ls /
```

## 11. Kiểm tra dữ liệu CitiBike do Sqoop đưa lên HDFS

```powershell
docker compose exec pig hdfs dfs -ls /citibike/sqoop/citibike_trips
```

## 12. Kiểm tra dữ liệu đầu vào

```powershell
docker compose exec pig hdfs dfs -cat /citibike/sqoop/citibike_trips/part-m-00000 | Select-Object -First 5
```

## 13. Tạo chương trình Pig Latin đầu tiên

```text
scripts/pig/trips_by_rideable_type.pig
```

## 14. Đưa script Pig vào container

```powershell
docker compose cp .\scripts\pig\trips_by_rideable_type.pig pig:/tmp/trips_by_rideable_type.pig
```

## 15. Kiểm tra YARN trước khi chạy Pig

```powershell
docker compose exec hadoop yarn node -list
```

## 16. Chạy chương trình Pig bằng MapReduce

```powershell
docker compose exec pig pig -x mapreduce /tmp/trips_by_rideable_type.pig
```

Xem kết quả

```powershell
docker compose exec pig hdfs dfs -cat /citibike/results/sample_trips/part*
```

```powershell
docker compose exec pig hdfs dfs -cat /citibike/results/ride_counts/part*
```

```powershell
docker compose exec pig hdfs dfs -cat /citibike/results/ordered_counts/part*
```
