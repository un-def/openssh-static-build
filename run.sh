#!/bin/sh
set -eu

if [ ${#} -lt 1 ]; then
    echo "usage: ${0} PORT [PREFIX]"
    exit 1
fi

port=${1}

prefix=${2:-.}
case ${prefix} in
    /*)
        ;;
    .)
        prefix=$(pwd)
        ;;
    ./*)
        prefix=$(pwd)/${prefix#./}
        ;;
    *)
        prefix=$(pwd)/${prefix}
esac

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"

echo "prefix=${prefix}"
echo "runtime_dir=${runtime_dir}"

exec "${prefix}/sbin/sshd" \
    -f "${prefix}/etc/sshd_config" \
    -h "${prefix}/etc/ssh_host_ed25519_key" \
    -o SshdSessionPath="${prefix}/libexec/sshd-session" \
    -o PidFile="${runtime_dir}/sshd-static.pid" \
    -E /dev/stderr \
    -D -p "${port}"
