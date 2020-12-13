#!/usr/bin/bash
service ssh start
su hadoop -c "hdfs namenode -format && start-all.sh"