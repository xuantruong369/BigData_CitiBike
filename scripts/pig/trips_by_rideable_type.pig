-- 1. Load dữ liệu CitiBike từ HDFS
REGISTER '/opt/pig/lib/h3/commons-collections-3.2.2.jar';

trips = LOAD '/citibike/sqoop/citibike_trips/part-m-00000'
USING PigStorage(',')
AS (
    ride_id:chararray,
    rideable_type:chararray,
    started_at:chararray,
    ended_at:chararray,
    start_station_name:chararray,
    start_station_id:chararray,
    end_station_name:chararray,
    end_station_id:chararray,
    start_lat:double,
    start_lng:double,
    end_lat:double,
    end_lng:double,
    member_casual:chararray
);

-- 2. Nhóm dữ liệu theo loại xe
grouped_trips = GROUP trips BY rideable_type;

-- 3. Đếm số chuyến đi trong mỗi nhóm
ride_counts = FOREACH grouped_trips
    GENERATE
        group AS rideable_type,
        COUNT(trips) AS total_trips;

-- 4. Sắp xếp theo số chuyến giảm dần
ordered_counts = ORDER ride_counts BY total_trips DESC;

-- 5. Hiển thị kết quả
sample_trips = LIMIT trips 10;
STORE sample_trips INTO '/citibike/results/sample_trips' USING PigStorage(',');
STORE ride_counts INTO '/citibike/results/ride_counts' USING PigStorage(',');
STORE ordered_counts INTO '/citibike/results/ordered_counts' USING PigStorage(',');