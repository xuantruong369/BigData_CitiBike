#!/usr/bin/env bash
set -e

HADOOP_HOME=/opt/hadoop
export HADOOP_HOME
export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH"

echo "======================================"
echo " Starting Hadoop Single Node"
echo "======================================"

# Tạo các thư mục dữ liệu
mkdir -p /opt/hadoop/data/namenode
mkdir -p /opt/hadoop/data/datanode
mkdir -p /opt/hadoop/logs

# Format NameNode lần đầu tiên
# Không format lại nếu NameNode đã được khởi tạo
if [ ! -f /opt/hadoop/data/namenode/current/VERSION ]; then
    echo "Formatting NameNode..."
    hdfs namenode -format -force -nonInteractive
fi

# Khởi động HDFS
echo "Starting HDFS..."
hdfs --daemon start namenode
hdfs --daemon start datanode

# Khởi động YARN
echo "Starting YARN..."
yarn --daemon start resourcemanager
yarn --daemon start nodemanager

# Khởi động MapReduce JobHistoryServer
echo "Starting MapReduce JobHistoryServer..."
mapred --daemon start historyserver

echo "======================================"
echo " Hadoop services started"
echo "======================================"
echo " NameNode UI:       http://localhost:9870"
echo " YARN UI:           http://localhost:8088"
echo " JobHistoryServer:  http://localhost:19888"
echo " JobHistory RPC:    hadoop:10020"
echo "======================================"

# Giữ container hoạt động và theo dõi log
tail -F /opt/hadoop/logs/*.log