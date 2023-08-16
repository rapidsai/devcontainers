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
        has_branch() {
            local b="${branch}";
            for x in '\\' '\/' '.' '+' '^' '$' '*' '?' '!' '|' '=' '-' '[' ']' '(' ')' '{' '}'; do
                b="${b//"$x"/\\"$x"}";
            done
            # git ls-remote exits with code 141, so compare the grep output and not just the exit code
            if [ "$(git ls-remote "${1}" | grep -P "^[0-9a-z]{40}\s+refs\/heads\/${b}$" || echo "")" = "" ];
            then echo "";
            else echo "1";
            fi
        }

        local origin_has_branch="$(has_branch "${origin}")";
        local upstream_has_branch="$(has_branch "${upstream}")";

        if false; then exit 1;
        elif [ -n "${upstream_has_branch}" ]; then
            git -C "${directory}" checkout "${branch}" \
         || git -C "${directory}" checkout "${branch}" -t "upstream/${branch}";
        elif [ -n "${origin_has_branch}" ]; then
            git -C "${directory}" checkout "${branch}" \
         || git -C "${directory}" checkout "${branch}" -t "origin/${branch}";
        fi

        if [ -n "${origin_has_branch}" ]; then
            git -C "${directory}" pull origin "${branch}";
        fi

        if [ -n "${upstream_has_branch}" ]; then
            git -C "${directory}" pull upstream "${branch}";
        fi
    fi

    git -C "${directory}" submodule update --init --recursive;
}

if test -n "${devcontainer_utils_debug:-}"; then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clone_git_repo "$@";
