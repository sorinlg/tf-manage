#!/usr/bin/env bash

# Copyright (c) 2017 - present Adobe Systems Incorporated. All rights reserved.

# Licensed under the MIT License (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# https://opensource.org/licenses/MIT

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

### Platform check
###############################################################################
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    *)          machine="UNKNOWN:${unameOut}"
esac

### Binary set
###############################################################################
case "${machine}" in
    Linux*)     BIN_READLINK="readlink";;
    Mac*)       BIN_READLINK="greadlink";;
    *)          BIN_READLINK="readlink";;
esac

### Framework boilerplate
###############################################################################
# calculate script root dir
ROOT_DIR="$( dirname $(${BIN_READLINK} -f ${BASH_SOURCE[0]}) )"

# import bash framework
source "${ROOT_DIR}/../vendor/bash-framework/lib/import.sh"

# import TF wrapper modules
source "${ROOT_DIR}/../lib/import.sh"

### Input validation
###############################################################################
function usage {
    cmd="${BASH_SOURCE[0]##*/} <product> <module> <env> <module_instance> <action> [workspace]"
    error "Usage: ${cmd}"
    exit -1
}

# number of arguments
( [ "$#" -lt 5 ] || [ "$#" -gt 6 ] ) && usage

# gather input vars
_PRODUCT=${1}
_MODULE=${2}
_ENV=${3}
_MODULE_INSTANCE=${4}
action_raw="${5}"
action="${action_raw%% *}"
action_flags="${action_raw//$action}"
_TF_ACTION=${action}
_TF_ACTION_FLAGS=${action_flags:-}
_WORKSPACE_OVERRIDE=${6:-workspace=}

### Load configuration
###############################################################################
__load_global_config
__load_project_config
# if we have a config error, stop and throw an error
if [ "${result}" -ne 0 ]; then
    # leave this line here to avoid printing error messages multiple times
    info "Exiting due to configuration error"
    exit 1
fi

# get global variables inferred by the wrapper
__compute_common_paths

# check if we're on a dev box or a jenkins slave
__detect_env

### Check folder structure is valid
###############################################################################
__validate_product
__validate_repo
__validate_module_dir
__validate_env_dir
__validate_config_path

### Check TF_ACTION is supported
###############################################################################
__validate_tf_action

### Switch to targeted module path
###############################################################################
cd "${TF_MODULE_PATH}"

### Build terraform action command
###############################################################################
__tf_controller
result=$?
exit $result
