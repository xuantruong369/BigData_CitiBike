## 1. Khởi động lại Hadoop

```powershell
docker compose up -d
```

## 2. Kiểm tra container

```powershell
docker compose ps
```

## 3. Kiểm tra Hadoop nhìn thấy dữ liệu

```powershell
docker compose exec hadoop ls /data/citibike/2024
```

## 4. Đếm số file CSV bên trong container

```powershell
docker compose exec hadoop bash -c "find /data/citibike/2024 -maxdepth 1 -type f -name '*.csv' | wc -l"
```

## 5. Tạo thư mục trên HDFS

```powershell
docker compose exec hadoop hdfs dfs -mkdir -p /citibike/raw/2024
```

## 6. Nạp 50 file CSV vào HDFS

```powershell
docker compose exec hadoop bash -c "hdfs dfs -put /data/citibike/2024/*.csv /citibike/raw/2024/"
```

## 7. Kiểm tra số file trong HDFS

```powershell
docker compose exec hadoop hdfs dfs -count /citibike/raw/2024
```

## 8. Kiểm tra dung lượng

```powershell
docker compose exec hadoop hdfs dfs -du -s -h /citibike/raw/2024
```

## 9. Kiểm tra dữ liệu thực tế trong HDFS

```powershell
docker compose exec hadoop bash -c "hdfs dfs -cat /citibike/raw/2024/202401-citibike-tripdata_1.csv | head -n 3"
```

## 10. Kiểm tra danh sách file

```powershell
docker compose exec hadoop hdfs dfs -ls /citibike/raw/2024
```

## 11. Xóa dữ liệu file cũ trên HDFS

```powershell
docker compose exec hadoop hdfs dfs -rm -r /citibike/raw/2024
```

## 12. Dừng Hadoop và xóa môi trường cũ

```powershell
docker compose down -v
```

## 13. Build lại image và khởi động Hadoop

```powershell
docker compose up -d --build
```

## 14. Kiểm tra các tiến trình Hadoop

```powershell
docker compose exec hadoop jps
```

## 15. Kiểm tra Safe Mode

```powershell
docker compose exec hadoop hdfs dfsadmin -safemode get
```

## 15. Nạp 5 file CSV tháng 1 và tháng 2

```powershell
docker compose exec hadoop bash -c "hdfs dfs -put /data/citibike/2024/202401*.csv /data/citibike/2024/202402*.csv /citibike/raw/2024/"
```
