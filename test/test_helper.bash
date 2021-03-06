unset JLENV_VERSION
unset JLENV_DIR

#####################################################################
#
# Helper functions
#
# These are set up in very test file (that $(load test_helper)) 
# and available in every test.
#
#####################################################################


teardown() {
  rm -rf "$JLENV_TEST_DIR"
}

# Output a modified PATH that ensures that the given executable is not present,
# but in which system utils necessary for jlenv operation are still available.
path_without() {
  local exe="$1"
  local path=":${PATH}:"
  local found alt util
  for found in $(which -a "$exe"); do
    found="${found%/*}"
    if [ "$found" != "${JLENV_ROOT}/shims" ]; then
      alt="${JLENV_TEST_DIR}/$(echo "${found#/}" | tr '/' '-')"
      mkdir -p "$alt"
      for util in bash head cut readlink greadlink; do
        if [ -x "${found}/$util" ]; then
          ln -s "${found}/$util" "${alt}/$util"
        fi
      done
      path="${path/:${found}:/:${alt}:}"
    fi
  done
  path="${path#:}"
  echo "${path%:}"
}

create_hook() {
  mkdir -p "${JLENV_HOOK_PATH}/$1"
  touch "${JLENV_HOOK_PATH}/$1/$2"
  if [ ! -t 0 ]; then
    cat > "${JLENV_HOOK_PATH}/$1/$2"
  fi
}

#####################################################################
#
# Main
#
#####################################################################

# guard against executing this block twice due to bats internals
if [ "${JLENV_ROOT:=/}" != "${JLENV_TEST_DIR:=/}/root" ]
then

  JLENV_TEST_DIR="${BATS_TMPDIR}/libs/jlenv"
  PLUGIN="${JLENV_TEST_DIR}/root/plugins/jlenv-each"
  JLENV_TEST_DIR="${BATS_TMPDIR}/jlenv"
  export JLENV_TEST_DIR="$(mktemp -d "${JLENV_TEST_DIR}.XXX" 2>/dev/null || echo "${JLENV_TEST_DIR}")"

  export JLENV_ROOT="${JLENV_TEST_DIR}/root"
  export HOME="${JLENV_TEST_DIR}/home"
  export JLENV_HOOK_PATH="${JLENV_ROOT}/jlenv.d"

  # Install bats to the test location. This is next added to path.
  # These files are in .gitignore
  pushd "${BATS_TEST_DIRNAME}/libs/bats"
    ./install.sh "${BATS_TEST_DIRNAME}/libexec"
  popd

  PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin
  PATH="${JLENV_TEST_DIR}/bin:$PATH"
  PATH="${BATS_TEST_DIRNAME}/libexec:$PATH"
  PATH="${BATS_TEST_DIRNAME}/../libexec:$PATH"
  PATH="${JLENV_ROOT}/shims:$PATH"
  export PATH

  for xdg_var in $(env 2>/dev/null | grep ^XDG_ | cut -d= -f1)
  do 
    unset "$xdg_var"
  done
  unset xdg_var
fi
