FROM apache/hadoop:3.5.0

# Sao chép các file cấu hình Hadoop
COPY --chown=hadoop:users config/core-site.xml /opt/hadoop/etc/hadoop/
COPY --chown=hadoop:users config/hdfs-site.xml /opt/hadoop/etc/hadoop/
COPY --chown=hadoop:users config/yarn-site.xml /opt/hadoop/etc/hadoop/
COPY --chown=hadoop:users config/mapred-site.xml /opt/hadoop/etc/hadoop/

# Sao chép script khởi động Hadoop
COPY --chown=hadoop:users scripts/start-single-node.sh /opt/hadoop/sbin/

# Cấp quyền thực thi cho script
USER root
RUN mkdir -p /opt/hadoop/data/namenode \
    /opt/hadoop/data/datanode \
    /opt/hadoop/data/tmp \
    /opt/hadoop/logs \
    && chown -R hadoop:users /opt/hadoop/data /opt/hadoop/logs \
    && chmod +x /opt/hadoop/sbin/start-single-node.sh

# Chạy Hadoop bằng user mặc định của image
USER hadoop

CMD ["/opt/hadoop/sbin/start-single-node.sh"]