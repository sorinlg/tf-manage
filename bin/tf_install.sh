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
_script_file="${BASH_SOURCE[0]}"
_script_file_abs=$(${BIN_READLINK} -f "${_script_file}")
_root_dir_path="$(dirname "${_script_file_abs}")/.."
_root_dir_path_abs=$(${BIN_READLINK} -f "${_root_dir_path}")
export ROOT_DIR="${_root_dir_path_abs}"

# import bash framework
source "${ROOT_DIR}/vendor/bash-framework/lib/import.sh"

function usage {
    cmd="${BASH_SOURCE[0]##*/} [<TF_VERSION>]"
    echo "Usage: ${cmd}"
    exit -1
}

## -- Setup
# gather input vars
# set TF version
version=${1:-1.8.0}

# generic folder logic
install_dir='/opt/terraform'
install_dir_wrapper='/opt/terraform/tf-manage'
plugin_cache_dir="$HOME/.terraform.d/${version}/plugin-cache"
tf_config_path="${HOME}/.terraformrc"
tf_wrapper_repo=$(git --git-dir=${ROOT_DIR}/.git remote get-url origin)

# input validation
[ "$#" -lt 0 ] || [ "$#" -ge 2 ] && usage

# gather platform info
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    *)          machine="UNKNOWN:${unameOut}"
esac
info "Detected platform: ${machine}"

# Sudo password notice
info "This will install/upgrade Terraform to version ${version}"
_message="Sudo credentials are required. Please insert your password below:"
_cmd="sudo echo \"Thank you! Continuing installation...\""
_flags=(${_DEFAULT_CMD_FLAGS[@]})
_flags[0]="strict"
_flags[5]="no_print_status"
run_cmd "${_cmd}" "${_message}" "${_flags[@]}"

# prepare install dir
_message="Preparing install dir \"${install_dir}\""
_cmd="sudo mkdir -m 0775 -p \"${install_dir}\" && sudo chown $(whoami): \"${install_dir}\""
_flags=(${_DEFAULT_CMD_FLAGS[@]})
_flags[0]="strict"
_flags[4]="no_print_message"
_flags[6]="no_print_outcome"
run_cmd "${_cmd}" "${_message}" "${_flags[@]}"

# install terraform
tfswitch ${version}

# install terraform config
_message="Installing default TF configuration at \"${tf_config_path}\""
_cmd="echo 'plugin_cache_dir   = \"${plugin_cache_dir}\"' > \"${tf_config_path}\""
_flags=(${_DEFAULT_CMD_FLAGS[@]})
_flags[0]="strict"
_flags[4]="no_print_message"
_flags[6]="no_print_outcome"
run_cmd "${_cmd}" "${_message}" "${_flags[@]}"

# setup terraform plugin cache directory
_message="Preparing TF plugin cache directory at \"${plugin_cache_dir}\""
_cmd="mkdir -p ${plugin_cache_dir}"
_flags=(${_DEFAULT_CMD_FLAGS[@]})
_flags[0]="strict"
_flags[4]="no_print_message"
_flags[6]="no_print_outcome"
run_cmd "${_cmd}" "${_message}" "${_flags[@]}"

# test installation
_message="Checking installation by printing the version"
_cmd="terraform version"
_flags=(${_DEFAULT_CMD_FLAGS[@]})
_flags[0]="strict"
_flags[6]="no_print_outcome"
run_cmd "${_cmd}" "${_message}" "${_flags[@]}"

# check for old installation method
_message="Checking for old installations of \"${install_dir_wrapper}\""
_cmd="test -h \"${install_dir_wrapper}\" || (! test -h /opt/terraform/tf-manage && test -d \"${install_dir_wrapper}\" && echo \"Previous installation found at ${install_dir_wrapper}. Please remove it manually.\" && false) || (! test -d \"${install_dir_wrapper}\")"
_flags=(${_DEFAULT_CMD_FLAGS[@]})
_flags[0]="strict"
_flags[4]="no_print_message"
_flags[6]="no_print_outcome"
run_cmd "${_cmd}" "${_message}" "${_flags[@]}"

# install wrapper
_message="Installing tf-manage terraform wrapper at \"${install_dir_wrapper}\""
_cmd="test -h \"${install_dir_wrapper}\" || ln -s \"${ROOT_DIR}\" \"${install_dir_wrapper}\""
_flags=(${_DEFAULT_CMD_FLAGS[@]})
_flags[0]="strict"
_flags[4]="no_print_message"
_flags[6]="no_print_outcome"
run_cmd "${_cmd}" "${_message}" "${_flags[@]}"

# add wrapper to PATH
_message="Adding tf wrapper to PATH"
_cmd="sudo ln -s -f \"${install_dir_wrapper}/bin/tf.sh\" \"/usr/local/bin/tf\""
_flags=(${_DEFAULT_CMD_FLAGS[@]})
_flags[0]="strict"
_flags[4]="no_print_message"
_flags[6]="no_print_outcome"
run_cmd "${_cmd}" "${_message}" "${_flags[@]}"

# add wrapper installer to PATH
_message="Adding tf wrapper installer to PATH"
_cmd="sudo ln -s -f \"${install_dir_wrapper}/bin/tf_install.sh\" \"/usr/local/bin/tf_install\""
_flags=(${_DEFAULT_CMD_FLAGS[@]})
_flags[0]="strict"
_flags[4]="no_print_message"
_flags[6]="no_print_outcome"
run_cmd "${_cmd}" "${_message}" "${_flags[@]}"

# install wrapper bash completion support for mac
if [ "${machine}" = 'Mac' ]; then
    if [ -d "$(brew --prefix)/etc/bash_completion.d" ]; then
        _message="Installing bash completion for wrapper"
        _cmd="ln -fs \"${install_dir_wrapper}/bin/tf_complete.sh\" \"$(brew --prefix)/etc/bash_completion.d/tf\""
        _flags=(${_DEFAULT_CMD_FLAGS[@]})
        _flags[0]="strict"
        _flags[4]="no_print_message"
        run_cmd "${_cmd}" "${_message}" "${_flags[@]}"
        info "The \"tf\" command will have bash completion support in new shells"
    else
        info "You don't seem to have bash completion installed"
        info "The terraform wrapper also has bash completion support"
        info "Run \"brew install bash-completion@2 && brew tap homebrew/completions\" to install it"
        info "Add \". \$(brew --prefix)/etc/bash_completion.d/tf\" to your ~/.bash_profile"
        info "Then, you can re-run this script to install completion support"
        info "You will, of course, also need homebrew for this to work"
    fi
elif [ "${machine}" = 'Linux' ]; then
    if [ -e "/etc/bash_completion.d/" ]; then
        _message="Installing bash completion for wrapper. The \"tf\" command will have bash completion support in new shells"
        _cmd="ln -fs \"${install_dir_wrapper}/bin/tf_complete.sh\" \"/etc/bash_completion.d/tf\""
        _flags=(${_DEFAULT_CMD_FLAGS[@]})
        _flags[0]="strict"
        _flags[4]="no_print_message"
        run_cmd "${_cmd}" "${_message}" "${_flags[@]}"
    else
        info "You don't seem to have bash completion installed"
        info "The terraform wrapper also has bash completion support"
        info "Run \"yum -y install bash-completion\" to install it and restart your shell"
        info "Then, you can re-run this script to install completion support"
    fi
fi
