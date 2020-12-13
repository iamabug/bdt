> Hadoop版本：3.3.0
>
> JDK：OpenJDK 8
>
> OS：Ubuntu 18.04

以Dockerfile的方式，在Ubuntu 18.04上安装单节点的Hadoop 3.3.0集群。

# 镜像获取

本文档中构建的镜像已经上传在至DockerHub，可以直接使用docker命令拉取并运行：

```bash
docker run -h bigdata -p 8088:8088 -it iamabug1128/hadoop bash 
```

> 注意：这里的-h bigdata是必须的，因为hadoop的配置文件依赖于这个特定的主机名。

8088端口的映射是为了方便在容器外访问YARN的Web UI。

这个镜像对应的Dockerfile可以通过查看，根据需要进行调整。

# 安装配置OpenJDK

Hadoop生态中的软件大都使用Java/Scala开发，Java运行环境是必需的。

```bash
RUN apt-get update && apt-get install -y openjdk-8-jdk
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
```

# 安装配置OpenSSH

在Hadoop常见的操作中，我们需要能够在一个节点（比如NameNode）上控制其余节点上的Hadoop服务，因此需要安装SSH服务，并且配置密钥登录的方式，简化操作。

安装：

```dockerfile
RUN apt-get install -y openssh-server openssh-client
```

配置：

```dockerfile
# 添加hadoop组和用户，使用hadoop用户管理hadoop服务
RUN addgroup hadoop
RUN adduser --ingroup hadoop --quiet --disabled-password hadoop
# 为hadoop用户生成公私钥
RUN su hadoop -c "ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && chmod 0600 ~/.ssh/authorized_keys"
```

# 安装配置Hadoop

从国内镜像下载Hadoop二进制包：

```bash
wget https://mirrors.tuna.tsinghua.edu.cn/apache/hadoop/common/hadoop-3.3.0/hadoop-3.3.0.tar.gz -O hadoop.tar.gz
```

添加到镜像中：

```dockerfile
# ADD 会自动进行解压
ADD hadoop.tar.gz /usr/local
RUN mv /usr/local/hadoop-3.3.0 /usr/local/hadoop
# 创建配置文件目录和数据目录
RUN ln -s /usr/local/hadoop/etc/hadoop /etc/hadoop
RUN mkdir -p /usr/local/hadoop/data/{namenode,datanode} /etc/hadoop-httpfs/conf/ /usr/local/hadoop/logs
```

修改配置和目录权限：

```dockerfile
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /etc/hadoop/hadoop-env.sh && \
		echo "bigdata" > /etc/hadoop/workers && \
		chown -R hadoop:hadoop /usr/local/hadoop
```

拷贝配置文件：

```dockerfile
COPY core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml /etc/hadoop/
```

设置环境变量：

```dockerfile
# PATH环境变量，这里设置了两次，ENV的方法只对root用户生效，/etc/environment对其它用户生效
ENV PATH=/usr/local/hadoop/bin:/usr/local/hadoop/sbin:${PATH}
RUN echo "PATH=/usr/local/hadoop/bin:/usr/local/hadoop/sbin:${PATH}" >> /etc/environment
```

# 配置文件说明

为了让HDFS、MapReduce和YARN可以正常运行，Hadoop的各个配置文件需要一些基础的配置项。

## core-site.xml

```xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
      	<!--这里假设容器主机名为bigdata-->
        <value>hdfs://bigdata:8020/</value>
        <description>NameNode URI</description>
    </property>
</configuration>
```

## hdfs-site.xml

```xml
<configuration>
  	<!--因为是单节点的集群，所以hdfs的副本数设为1-->
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
  	<!--指定namenode数据目录-->
    <property>
        <name>dfs.name.dir</name>
        <value>/usr/local/hadoop/data/namenode</value>
    </property>
  	<!--指定datanode数据模流-->
    <property>
        <name>dfs.data.dir</name>
        <value>/usr/local/hadoop/data/datanode</value>
    </property>
  	<!--启用webhdfs，可选-->
    <property>
        <name>dfs.webhdfs.enable</name>
        <value>true</value>
    </property>
</configuration>
```

## mapred-site.xml

```xml
<configuration>
  	<!--在YARN上运行MapReduce任务-->
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <!--下面三个配置项如果不设置，运行MR任务时会提示并报错-->
    <property>
        <name>yarn.app.mapreduce.am.env</name>
        <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
    </property>
    <property>
        <name>mapreduce.map.env</name>
        <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
    </property>
    <property>
        <name>mapreduce.reduce.env</name>
        <value>HADOOP_MAPRED_HOME=/usr/local/hadoop</value>
    </property>
</configuration>
```

## yarn-site.xml

yarn-site.xml暂没有需要额外指定的配置。

# 启动服务

先启动ssh服务：

```bash
service ssh start
```

然后以hadoop用户身份启动hadoop的所有服务：

```bash
su hadoop -c "hdfs namenode -format && start-all.sh"
```

启动后查看进程：

```bash
root@bigdata:/# jps
512 DataNode
401 NameNode
1667 Jps
1108 NodeManager
743 SecondaryNameNode
990 ResourceManager
```

可以看到，成功的启动了DataNode、NameNode、SecondaryNameNode、NodeManager、ResourceManager。

# 功能测试



#  参考文档

https://haadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html