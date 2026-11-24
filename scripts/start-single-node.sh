
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

echo "======================================"
echo " Hadoop services started"
echo "======================================"

# Giữ container hoạt động và theo dõi log
tail -F /opt/hadoop/logs/*.log
