#!/bin/bash

PERL=${PREFIX}/bin/perl
declare -a _CONFIG_OPTS
_CONFIG_OPTS+=(--prefix=${PREFIX})
_CONFIG_OPTS+=(--libdir=lib)
_CONFIG_OPTS+=(shared)
_CONFIG_OPTS+=(threads)
_CONFIG_OPTS+=(enable-ssl2)
_CONFIG_OPTS+=(no-zlib)

# We are cross-compiling or using a specific compiler.
# do not allow config to make any guesses based on uname.
_CONFIGURATOR="perl ./Configure"
case "$target_platform" in
  linux-64)
    _CONFIG_OPTS+=(linux-x86_64)
    CFLAGS="${CFLAGS} -Wa,--noexecstack"
    ;;
  linux-aarch64)
    _CONFIG_OPTS+=(linux-aarch64)
    CFLAGS="${CFLAGS} -Wa,--noexecstack"
    ;;
  linux-ppc64le)
    _CONFIG_OPTS+=(linux-ppc64le)
    CFLAGS="${CFLAGS} -Wa,--noexecstack"
    ;;
  osx-64)
    _CONFIG_OPTS+=(darwin64-x86_64-cc)
    ;;
  osx-arm64)
    _CONFIG_OPTS+=(darwin64-arm64-cc)
    ;;
esac

CC=${CC}" ${CPPFLAGS} ${CFLAGS}" \
  ${_CONFIGURATOR} ${_CONFIG_OPTS[@]} ${LDFLAGS}

make -j${CPU_COUNT}

# replace 127.0.0.1 with whatever hostname is on azure CI so that cmp_http tests pass;
# see https://github.com/openssl/openssl/issues/16546
if [[ "$target_platform" = "linux-"* ]]; then
  HOST_IP=$(hostname -i)
else
  # WIP: to grep
  ifconfig
fi
if [[ -n ${HOST_IP+x} ]]; then
  echo "Replacing 127.0.0.1 with $HOST_IP"
  sed -i.bak "s/127.0.0.1/$HOST_IP/g" test/recipes/80-test_cmp_http.t test/recipes/80-test_cmp_http_data/Mock/test.cnf
else
  echo "Not applying workaround"
fi

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
  echo "Running tests"
  make test
fi
