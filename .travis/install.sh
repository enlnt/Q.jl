#!/bin/bash

if [[ $TRAVIS_OS_NAME == 'osx' ]]; then
  # homebrew for mac
  brew install gcc
  QZIP=macosx.zip
else
  if [[ -n "$MARCH" ]]; then
    JULIA_SITE="julialang-s3.julialang.org"
    JULIA_PATH="bin/linux/x86/0.6/julia-0.6.0-linux-i686.tar.gz"
    JULIA_URL="https://${JULIA_SITE}/${JULIA_PATH}"
    JULIA_HOME="${HOME}/julia32"
    CURL_USER_AGENT="Travis-CI $(curl --version | head -n 1)"
    mkdir -p ${JULIA_HOME}
    curl -A "${CURL_USER_AGENT}" -s -L --retry 7 ${JULIA_URL} \
     | tar -C ${JULIA_HOME} -x -z --strip-components=1 -f -
    export PATH="${JULIA_HOME}/bin:${PATH}"
  fi
  QZIP=linuxx86.zip
fi

if [[ -n ${KDBURL} ]]; then
  curl -e https://kx.com "${KDBURL}/3.5/${QZIP}" \
       -o $HOME/kx.zip && unzip -d $HOME $HOME/kx.zip
  rm $HOME/q/q.q
fi
