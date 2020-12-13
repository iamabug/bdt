FROM ubuntu:18.04

RUN sed -i 's/security.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
RUN sed -i 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list

RUN apt-get update && apt-get install -y debconf-utils apt-utils

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y build-essential gcc \
    net-tools vim wget telnet iputils-ping tzdata
RUN apt-get update && apt-get install -y openjdk-8-jdk openssh-server openssh-client

RUN rm -rf /var/lib/apt/lists/*
RUN echo "Asia/Shanghai" > /etc/timezone && \
    rm -f /etc/localtime  && \
    dpkg-reconfigure -f noninteractive tzdata

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# 创建hadoop组和用户，生成公私钥
RUN addgroup hadoop && \
    adduser --ingroup hadoop --quiet --disabled-password hadoop && \
    su hadoop -c "ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && chmod 0600 ~/.ssh/authorized_keys"

# 添加Hadoop二进制包
ADD hadoop.tar.gz /usr/local
RUN mv /usr/local/hadoop-3.3.0 /usr/local/hadoop
# 创建数据目录和配置目录
RUN ln -s /usr/local/hadoop/etc/hadoop /etc/hadoop
RUN mkdir -p /usr/local/hadoop/data/{namenode,datanode} /etc/hadoop-httpfs/conf/ /usr/local/hadoop/logs
# 配置worker主机名和目录权限
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/hadoop/hadoop-env.sh && \
    echo "bigdata" > /etc/hadoop/workers && \
    chown -R hadoop:hadoop /usr/local/hadoop

# 拷贝配置文件
ADD conf /etc/hadoop

# PATH环境变量，这里设置了两次，ENV的方法只对root用户生效，/etc/environment对其它用户生效
ENV PATH=/usr/local/hadoop/bin:/usr/local/hadoop/sbin:${PATH}
RUN echo "PATH=/usr/local/hadoop/bin:/usr/local/hadoop/sbin:${PATH}" >> /etc/environment

# 拷贝启动脚本
COPY hadoop_init.sh wait_to_die.sh /run/

ENTRYPOINT ["bash", "-c", "/run/hadoop_init.sh && /run/wait_to_die.sh"]