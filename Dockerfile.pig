FROM apache/hadoop:3.5.0

USER root

ENV PIG_VERSION=0.18.0
ENV PIG_HOME=/opt/pig
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop

# Install Apache Pig
RUN mkdir -p ${PIG_HOME} && \
    curl -fL \
    https://downloads.apache.org/pig/pig-0.18.0/pig-0.18.0.tar.gz \
    -o /tmp/pig.tar.gz && \
    tar -xzf /tmp/pig.tar.gz \
    -C ${PIG_HOME} \
    --strip-components=1 && \
    rm /tmp/pig.tar.gz

# Add Commons Collections 3.x for Hadoop MapReduce execution
RUN cp ${PIG_HOME}/lib/hadoop3-runtime/commons-collections-3.2.2.jar \
       ${PIG_HOME}/lib/h3/

# Configure environment
ENV PATH="${PIG_HOME}/bin:${HADOOP_HOME}/bin:${PATH}"

# Set permissions
RUN chown -R hadoop:users ${PIG_HOME}

USER hadoop

WORKDIR /opt/pig