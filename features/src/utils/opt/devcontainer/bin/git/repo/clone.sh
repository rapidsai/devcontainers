#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-clone-git-repo [OPTION]... <directory>
#
# Clone a GitLab repository for the logged in user (as reported by `glab auth status`).
#
# If the user doesn't have a fork of the repository, notify the user and ask whether they would like to fork it.
#
# Boolean options:
#  -h,--help,--usage            print this text
#  -q,--quiet                   Operate quietly. Progress is not reported to the standard error stream.
#  --no-fork                    don't prompt the user to fork the repo if a user fork isn't found
#                               (default: false)
#  --no-update-env              don't update the Python env with the repo's dependencies after cloning
#                               (default: false)
#  --clone-upstream             always clone the upstream, not the user's fork
#                               (default: false)
#
# Options that require values:
#  -b,--branch <branch_or_tag>  check the repo out to <branch_or_tag>
#                               (default: `${NAME}.git.tag` in manifest.yaml)
#  -j,--parallel <num>          Clone <num> submodules in parallel
#  -u,--upstream <upstream>     set <upstream> as the `upstream` remote
#
# Positional arguments:
#  directory                    clone the repo into <directory>

clone_git_repo() {
    set -Eeuo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" --passthrough '
        -q,--quiet
        -j,--parallel
    ' - <<< "${@@Q}")";

    local quiet="${q:-${quiet:-}}";
    quiet=${quiet:+--quiet};

    local branch="${b:-"${branch:-}"}";
    local parallel="${j:-${parallel:-1}}";
    parallel="${parallel:+-j "${parallel}"}";

    local upstream="${u:-"${upstream:-}"}";

    local nargs="${#REST[@]}";
    local origin="${REST[$((nargs - 2))]}";
    origin="${origin:?origin is required}";

    local directory="${REST[$((nargs - 1))]}";
    directory="${directory:?directory is required}";

    upstream="${upstream:-"${origin}"}";

    if [ ! -d "${directory}"/.git ]; then
        git clone "${OPTS[@]}" -- "${origin}" "${directory}";
        git -C "${directory}" remote add upstream "${upstream}" || true;
        # shellcheck disable=SC2086
        git -C "${directory}" fetch ${quiet} ${parallel} upstream || true;
        git -C "${directory}" remote set-url --push upstream read_only || true;

        if [ "${upstream}" != "${origin}" ]; then
            git -C "${directory}" remote set-url origin "${origin}";
        else
            git -C "${directory}" remote set-url --push origin read_only;
        fi
    fi

    if [ -n "${branch:-}" ]; then

        local -r upstream_has_branch="$(git -C "${directory}" ls-remote -q --exit-code -h upstream "${branch}" && echo 1 || echo)";
        local -r upstream_has_tag="$(git -C "${directory}" ls-remote -q --exit-code -t upstream "${branch}" && echo 1 || echo)";
        local -r origin_has_branch="$(git -C "${directory}" ls-remote -q --exit-code -h origin "${branch}" && echo 1 || echo)";
        local -r origin_has_tag="$(git -C "${directory}" ls-remote -q --exit-code -t origin "${branch}" && echo 1 || echo)";

        # shellcheck disable=SC2086
        if false; then exit 1;
        elif test -n "${upstream_has_branch}"; then
            git -C "${directory}" fetch ${quiet} upstream "refs/heads/${branch}";
            if ! git -C "${directory}" checkout ${quiet} -b "${branch}" -t "upstream/${branch}" 2>/dev/null; then
                git -C "${directory}" checkout ${quiet} "${branch}";
                git -C "${directory}" branch "${branch}" -u "upstream/${branch}";
            fi
        elif test -n "${upstream_has_tag}"; then
            git -C "${directory}" checkout ${quiet} -m -b "upstream/${branch}" "${branch}";
        elif test -n "${origin_has_branch}"; then
            git -C "${directory}" fetch ${quiet} origin "refs/heads/${branch}";
            if ! git -C "${directory}" checkout ${quiet} -b "${branch}" -t "origin/${branch}" 2>/dev/null; then
                git -C "${directory}" checkout ${quiet} "${branch}";
                git -C "${directory}" branch "${branch}" -u "origin/${branch}";
            fi
        elif test -n "${origin_has_tag}"; then
            git -C "${directory}" checkout ${quiet} -f -b "origin/${branch}" "${branch}";
        fi

        if test -n "${origin_has_branch}"; then
            git -C "${directory}" pull origin "${branch}";
        fi

        if test -n "${upstream_has_branch}"; then
            git -C "${directory}" pull upstream "${branch}";
        fi
    fi

    # shellcheck disable=SC2086
    git -C "${directory}" submodule update --init --recursive ${parallel} ${quiet};
}

if test -n "${devcontainer_utils_debug:-}" \
&& { test -z "${devcontainer_utils_debug##*"*"*}" \
  || test -z "${devcontainer_utils_debug##*"clone"*}" \
  || test -z "${devcontainer_utils_debug##*"clone-git-repo"*}"; }; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clone_git_repo "$@";
