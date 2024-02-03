#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-clone-git-repo [OPTION]... [--] <repository> [<directory>]
#
# Clone a git repository, optionally checking out a branch or tag, and optionally setting the upstream remote.
#
# Boolean options:
#  -h,--help                    print this text
#  -q,--quiet                   Operate quietly. Progress is not reported to the standard error stream.
#
# Options that require values:
#  -b,--branch <branch_or_tag>  check the repo out to <branch_or_tag>
#  -j,--jobs,--parallel <num>   Clone <num> submodules in parallel
#  -u,--upstream <upstream>     set <upstream> as the `upstream` remote
#
# Positional arguments:
#  repository                   The (possibly remote) repository to clone
#  directory                    The name of a new directory to clone into

clone_git_repo() {
    local -;
    set -euo pipefail;

    # shellcheck disable=SC2154
    if test -n "${devcontainer_utils_debug:-}" \
    && { test -z "${devcontainer_utils_debug##*"*"*}" \
      || test -z "${devcontainer_utils_debug##*"clone"*}" \
      || test -z "${devcontainer_utils_debug##*"clone-git-repo"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    eval "$(devcontainer-utils-parse-args "$0" - <<< "${@@Q}")";

    if test "${REST[0]:-}" == --; then REST=("${REST[@]:1}"); fi;

    local origin;
    local directory;

    local nargs="${#REST[@]}";

    if test "${nargs}" -gt 1; then
        origin="${REST[0]:?"fatal: missing required positional argument <repository>"}";
        directory="${REST[1]:?"fatal: missing required positional argument <directory>"}";
    else
        if test "${nargs}" -eq 0; then
            if test -z "${upstream:-}"; then
                echo "fatal: missing required positional argument <repository>" 1>&2;
                exit 1;
            fi
            origin="${upstream}";
        elif test "${nargs}" -eq 1; then
            origin="${REST[0]:?"fatal: missing required positional argument <repository>"}";
        fi

        local re="(ssh:\/\/|https:\/\/)?(git@)?(.*\.com)[:\/](.*)";
        if [[ "${origin}" =~ ${re} ]]; then
            directory="$(basename "${BASH_REMATCH[4]//.git/}")";
        elif test -d "${origin}" && test -d "${origin}"/.git; then
            directory="$(basename "${origin}")";
        else
            echo "fatal: '${origin}' is not a git repository" 1>&2;
            exit 1;
        fi
    fi

    j="${j:+-j ${j}}";
    q="${q:+--quiet}";
    upstream="${upstream:-"${origin}"}";
    directory="$(realpath -m "${directory}")";

    # shellcheck disable=SC2086
    if ! test -d "${directory}"/.git; then
        git clone ${j} ${q} "${OPTS[@]}" -- "${origin}" "${directory}";
        git -C "${directory}" remote add upstream "${upstream}" || true;
        git -C "${directory}" remote set-url upstream "${upstream}" || true;
        git -C "${directory}" remote set-url --push upstream read_only || true;
        if test "${upstream}" == "${origin}"; then
            git -C "${directory}" remote set-url --push origin read_only || true;
        fi
        git -C "${directory}" fetch ${j} ${q} upstream;
    fi

    # shellcheck disable=SC2086
    if test -n "${branch:-}"; then
        local remote;
        for remote in upstream origin; do
            # if remote has branch
            if git -C "${directory}" ls-remote -q --exit-code -h "${remote}" "${branch}"; then
                # fetch, checkout, and track the remote branch
                git -C "${directory}" fetch ${j} ${q} "${remote}" "refs/heads/${branch}";
                if ! git -C "${directory}" checkout ${q} -b "${branch}" -t "${remote}/${branch}" 2>/dev/null; then
                    git -C "${directory}" checkout ${q} "${branch}";
                    git -C "${directory}" branch "${branch}" -u "${remote}/${branch}";
                fi
                git -C "${directory}" pull "${remote}" "${branch}";
                break;
            # if remote has tag
            elif git -C "${directory}" ls-remote -q --exit-code -t "${remote}" "${branch}"; then
                # make a local branch for the tag
                git -C "${directory}" checkout ${q} -m -b "${remote}/${branch}" "${branch}";
                break;
            fi
        done
    fi

    # shellcheck disable=SC2086
    git -C "${directory}" submodule update --init --recursive ${j} ${q};
}

clone_git_repo "$@";
