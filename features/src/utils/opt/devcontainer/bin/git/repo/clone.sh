#! /usr/bin/env bash

clone_git_repo() {

    set -euo pipefail;

    local branch="";
    local upstream="";

    eval "$(                                  \
        devcontainer-utils-parse-args --names '
            b|branch                          |
            u|upstream                        |
        ' - <<< "$@"                          \
      | xargs -r -d'\n' -I% echo -n local %\; \
    )";

    branch="${b:-"${branch:-}"}";
    upstream="${u:-"${upstream:-}"}";

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

    git -C "${directory}" submodule update --init --recursive;
}

if test -n "${devcontainer_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clone_git_repo "$@";
