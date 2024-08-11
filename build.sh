#!/bin/sh
set -eu


# configuration

ZLIB_VERSION=1.3.1
OPENSSL_VERSION=3.3.1
OPENSSH_VERSION=9.8p1

ZLIB_URL=https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz
OPENSSL_URL=https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz
OPENSSH_URL=https://cloudflare.cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz


# common helpers

print_header() {
    printf '\n<<<<<<<<<< %s >>>>>>>>>>\n\n' "${1}"
}


# root tasks

create_user() {
    # args: uid gid username
    user=${3}
    addgroup -g "${2}" "${user}"
    adduser -DH -u "${1}" -G "${user}" "${user}"
}

install_build_deps() {
    apk add -U \
        gcc \
        make \
        perl \
        musl-dev \
        linux-headers
}


# non-root tasks

build() {
    fetch() {
        wget -qO- "${1}" | tar -xzf-
        echo "$(pwd)/$(ls -d "${2}"*)"
    }

    prefix_dir=$(pwd)/prefix
    mkdir -p "${prefix_dir}"
    build_dir=$(pwd)/build
    mkdir -p "${build_dir}"
    cd "${build_dir}"

    export CPPFLAGS="-I${prefix_dir}/include"
    export CFLAGS="${CPPFLAGS}"
    export LDFLAGS="-L${prefix_dir}/lib -L${prefix_dir}/lib64 -static"

    print_header "building zlib ${ZLIB_VERSION}"
    zlib_dir=$(fetch ${ZLIB_URL} zlib) && \
        cd "${zlib_dir}" && \
        ./configure \
            --static \
            --prefix="${prefix_dir}" \
        && \
        make && \
        make install && \
        cd -

    print_header "building OpenSSL ${OPENSSL_VERSION}"
    openssl_dir=$(fetch ${OPENSSL_URL} openssl) && \
        cd "${openssl_dir}" && \
        ./config \
            -static \
            --prefix="${prefix_dir}" \
            --openssldir="${prefix_dir}" \
        && \
        make && \
        make install && \
        cd -

    print_header "building OpenSSH ${OPENSSH_VERSION}"
    openssh_dir=$(fetch ${OPENSSH_URL} openssh) && \
        cd "${openssh_dir}" && \
        ./configure \
            --prefix="${prefix_dir}" \
            --with-privsep-user=nobody \
        && \
        make && \
        make install && \
        cd -

    print_header 'done'
}


# main

if [ "$(id -u)" -eq 0 ]; then
    print_header '(as root)'
    print_header 'installing build dependencies'
    install_build_deps
    host_uid=${1}
    host_gid=${2}
    username=nonroot
    create_user "${host_uid}" "${host_gid}" "${username}"

    print_header '(as non-root)'
    su "${username}" -c "${0}"
else
    build
fi
