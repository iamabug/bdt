set -e
MIRROR_PREFIX="https://mirrors.tuna.tsinghua.edu.cn"

function log() {
    msg=$@
    echo -e "[$(date +'%Y-%m-%d %H:%M:%S')]"${msg}
}

function warn() {
    msg=$@
    log "[WARN]" ${msg}
}

function info() {
    msg=$1
    log "[INFO]" ${msg}
}

function download() {
    name=$1
    url=$2
    target=$3
    if [ -f "$target" ]; then
        warn "Target file already exists, skipping it."
    else
        info "Start downloading $1 ..."
        wget ${url} -q --show-progress -O ${target} 
        info "$name downloaded successfully, saving to $target"
    fi
}
