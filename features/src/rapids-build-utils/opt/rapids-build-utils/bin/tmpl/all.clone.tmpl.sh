#!/usr/bin/env bash

# Usage:
#  clone-all [OPTION]...
#
# Runs clone-<repo> for each repo in ${NAMES}.
#
# Boolean options:
# @_include_bool_options /usr/bin/devcontainer-utils-clone-github-repo -h | tail -n+2 | head -n-1;
#  --no-update-env              Don't update the Python env with the repo's dependencies after cloning.
#                               (default: false)
#
# Options that require values:
#  -b,--branch <branch_or_tag>  Check the repos out to <branch_or_tag>.
#  -j,--parallel <num>          Clone <num> repos in parallel.
#                               (default: 1)

# shellcheck disable=SC1091
. rapids-generate-docstring;

clone_all() {
    local -;
    set -euo pipefail;

    eval "$(_parse_args --take '-b,--branch -j,--parallel -v,--verbose --no-update-env' "$@" <&0)";

    eval "$(rapids-get-num-archs-jobs-and-load --archs 1 --max-device-obj-memory-usage 1 "$@")";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'rapids_build_utils_debug' 'clone-all';

    local _o=;
    if devcontainer-utils-shell-is-interactive; then
        _o="-o";
    fi

    echo ${NAMES} \
  | tr '[:space:]' '\0' \
  | xargs ${v:+-t} ${_o} -r -0 -P${n_jobs} -I% bash -c \
  '
    repo="$1";
    branch="$2";
    n_arch="$3";
    shift 3;
    branch_args=();
    if test -n "${branch:+x}"; then
        if [[ "${repo}" == "ucxx" ]]; then
            branch="$(rapids-convert-ucxx-branch "${branch}")";
        fi;
        branch_args=(--branch "${branch}");
    fi;
    if command -V "clone-${repo}" >/dev/null 2>&1; then
        if ! "clone-${repo}" -j "${n_arch}" --no-update-env "${branch_args[@]}" "$@"; then exit 255; fi;
    fi
  ' _ % "${branch[0]:-}" "${n_arch}" "${OPTS[@]}" "${v[@]}";

    if ! test -n "${no_update_env:+x}"; then
        rapids-post-start-command;
    fi
}

clone_all "$@" <&0;
