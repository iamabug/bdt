#!/usr/bin/env bash
service ssh start
su hadoop -c "hdfs namenode -format && start-all.sh"