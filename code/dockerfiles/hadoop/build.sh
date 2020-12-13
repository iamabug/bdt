source ../common/helper.sh

VERSION=3.3.0
URL="${MIRROR_PREFIX}/apache/hadoop/common/hadoop-${VERSION}/hadoop-${VERSION}.tar.gz"

download "hadoop" "${URL}" "hadoop.tar.gz"

docker build -t iamabug1128/hadoop .