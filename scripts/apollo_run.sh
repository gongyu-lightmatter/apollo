#! /usr/bin/env bash

###############################################################################
# Copyright 2020 The Apollo Authors. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

set -e

TOP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "${TOP_DIR}/scripts/apollo.bashrc"
source "${TOP_DIR}/scripts/apollo_base.sh"

ARCH="$(uname -m)"

: ${USE_ESD_CAN:=false}
USE_GPU=-1

CMDLINE_OPTIONS=
SHORTHAND_TARGETS=

function _chk_n_set_gpu_arg() {
  local arg="$1"
  local use_gpu=-1
  if [ "${arg}" = "cpu" ]; then
    use_gpu=0
  elif [ "${arg}" = "gpu" ]; then
    use_gpu=1
  else
    # Do nothing
    return 0
  fi

  if [[ "${USE_GPU}" -lt 0 || "${USE_GPU}" = "${use_gpu}" ]]; then
    USE_GPU="${use_gpu}"
    return 0
  fi

  error "Mixed use of '--config=cpu' and '--config=gpu' may" \
    "lead to unexpected behavior. Exiting..."
  exit 1
}

function parse_cmdline_arguments() {
  local known_options=""
  local remained_args=""

  for ((pos = 1; pos <= $#; pos++)); do #do echo "$#" "$i" "${!i}"; done
    local opt="${!pos}"
    local optarg

    case "${opt}" in
      --config=*)
        optarg="${opt#*=}"
        known_options="${known_options} ${opt}"
        _chk_n_set_gpu_arg "${optarg}"
        ;;
      --config)
        ((++pos))
        optarg="${!pos}"
        known_options="${known_options} ${opt} ${optarg}"
        _chk_n_set_gpu_arg "${optarg}"
        ;;
      -c)
        ((++pos))
        optarg="${!pos}"
        known_options="${known_options} ${opt} ${optarg}"
        ;;
      *)
        remained_args="${remained_args} ${opt}"
        ;;
    esac
  done
  # Strip leading whitespaces
  known_options="$(echo "${known_options}" | sed -e 's/^[[:space:]]*//')"
  remained_args="$(echo "${remained_args}" | sed -e 's/^[[:space:]]*//')"

  CMDLINE_OPTIONS="${known_options}"
  SHORTHAND_TARGETS="${remained_args}"
}

function determine_cpu_or_gpu_test() {
  if [ "${USE_GPU}" -lt 0 ]; then
    if [ "${USE_GPU_TARGET}" -eq 0 ]; then
      CMDLINE_OPTIONS="--config=cpu ${CMDLINE_OPTIONS}"
    else
      CMDLINE_OPTIONS="--config=gpu ${CMDLINE_OPTIONS}"
    fi
    # USE_GPU unset, defaults to USE_GPU_TARGET
    USE_GPU="${USE_GPU_TARGET}"
  elif [ "${USE_GPU}" -gt "${USE_GPU_TARGET}" ]; then
    warning "USE_GPU=${USE_GPU} without GPU can't compile. Exiting ..."
    exit 1
  fi

  if [ "${USE_GPU}" -eq 1 ]; then
    ok "UnitTest run under GPU mode on ${ARCH} platform."
  else
    ok "UnitTest run under CPU mode on ${ARCH} platform."
  fi
}

function format_bazel_targets() {
  local targets_all
  if [ "$#" -eq 0 ]; then
    error "Must specify target(s) to run"
  fi

  for component in $@; do
    local test_targets
    test_targets="//modules/${component}"

    if [ -z "${targets_all}" ]; then
      targets_all="${test_targets}"
    else
      targets_all="${targets_all} union ${test_targets}"
    fi
  done
  echo "${targets_all}"
}

function run_bazel_target() {
  if ${USE_ESD_CAN}; then
    CMDLINE_OPTIONS="${CMDLINE_OPTIONS} --define USE_ESD_CAN=${USE_ESD_CAN}"
  fi

  CMDLINE_OPTIONS="$(echo ${CMDLINE_OPTIONS} | xargs)"

  local run_targets
  run_targets="$(format_bazel_targets ${SHORTHAND_TARGETS})"

  info "Test Overview: "
  info "${TAB}USE_GPU: ${USE_GPU}  [ 0 for CPU, 1 for GPU ]"
  info "${TAB}Test Options: ${GREEN}${CMDLINE_OPTIONS}${NO_COLOR}"
  info "${TAB}Test Targets: ${GREEN}${run_targets}${NO_COLOR}"
  info "${TAB}Disabled:     ${YELLOW}${disabled_targets}${NO_COLOR}"

  bazel run ${CMDLINE_OPTIONS} ${run_targets}
}

function main() {
  if ! "${APOLLO_IN_DOCKER}"; then
    error "This test operation must be run from within docker container"
    exit 1
  fi

  parse_cmdline_arguments "$@"
  determine_cpu_or_gpu_test

  run_bazel_target
  success "Done testing ${SHORTHAND_TARGETS:-Apollo}. Enjoy"
}

main "$@"
