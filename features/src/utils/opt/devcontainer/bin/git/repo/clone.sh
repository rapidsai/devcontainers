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

. devcontainer-utils-parse-args-from-docstring;

clone_git_repo() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    local branch="${b:-"${branch:-}"}";
    local parallel="${j:-${parallel:-1}}";
    local upstream="${u:-"${upstream:-}"}";

    local nargs="${#__rest__[@]}";
    local origin="${__rest__[$((nargs - 2))]}";
    origin="${origin:?origin is required}";

    local directory="${__rest__[$((nargs - 1))]}";
    directory="${directory:?directory is required}";

    __rest__=("${__rest__[@]/"${origin}"}");
    __rest__=("${__rest__[@]/"${directory}"}");

    upstream="${upstream:-"${origin}"}";

    if [ ! -d "${directory}"/.git ]; then
        git clone ${__rest__[@]} "${origin}" "${directory}";
        git -C "${directory}" remote add -f upstream "${upstream}" || true;
        git -C "${directory}" remote set-url upstream "${upstream}" || true;
        git -C "${directory}" remote set-url --push upstream read_only || true;

        if [ "${upstream}" != "${origin}" ]; then
            git -C "${directory}" remote set-url origin "${origin}";
        else
            git -C "${directory}" remote set-url --push origin read_only;
        fi
    fi

    if [ -n "${branch:-}" ]; then

        local origin_has_tag="$(git -C "${directory}" ls-remote -t origin "${branch}")";
        local origin_has_branch="$(git -C "${directory}" ls-remote -h origin "${branch}")";
        local upstream_has_tag="$(git -C "${directory}" ls-remote -t upstream "${branch}")";
        local upstream_has_branch="$(git -C "${directory}" ls-remote -h upstream "${branch}")";

        if false; then exit 1;
        elif test -n "${upstream_has_branch}"; then
            if ! git -C "${directory}" checkout -b "${branch}" -t "upstream/${branch}" 2>/dev/null; then
                git -C "${directory}" checkout "${branch}";
                git -C "${directory}" branch "${branch}" -u "upstream/${branch}";
            fi
        elif test -n "${upstream_has_tag}"; then
            git -C "${directory}" checkout -m -b "upstream/${branch}" "${branch}";
        elif test -n "${origin_has_branch}"; then
            if ! git -C "${directory}" checkout -b "${branch}" -t "origin/${branch}" 2>/dev/null; then
                git -C "${directory}" checkout "${branch}";
                git -C "${directory}" branch "${branch}" -u "origin/${branch}";
            fi
        elif test -n "${origin_has_tag}"; then
            git -C "${directory}" checkout -f -b "origin/${branch}" "${branch}";
        fi

        if test -n "${origin_has_branch}"; then
            git -C "${directory}" pull origin "${branch}";
        fi

        if test -n "${upstream_has_branch}"; then
            git -C "${directory}" pull upstream "${branch}";
        fi
    fi

    git -C "${directory}" submodule update --init --recursive -j ${parallel};
}

if test -n "${devcontainer_utils_debug:-}" \
&& ( test -z "${devcontainer_utils_debug##*"all"*}" \
  || test -z "${devcontainer_utils_debug##*"clone"*}" \
  || test -z "${devcontainer_utils_debug##*"clone-git-repo"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clone_git_repo "$@";
