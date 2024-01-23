#!/usr/bin/env bash

# Usage:
#  clean-all [OPTION]...
#
# Runs clean-<repo> for each repo in "${NAMES}".
#
# Forwards all arguments to each underlying script.
#
# Boolean options:
#  -h,--help,--usage                      print this text
#
# Options that require values:
#  -j,--parallel <num>          Clone <num> repos in parallel

. devcontainer-utils-parse-args-from-docstring;

clean_all() {
    set -Eeuo pipefail;

    parse_args_or_show_help - <<< "$@";

    eval "$(                                    \
        rapids-get-num-archs-jobs-and-load "$@" \
      | xargs -r -d'\n' -I% echo -n local %\;   \
    )";

    echo "${NAMES}" \
  | tr '[:space:]' '\0' \
  | xargs -r -0 -P${n_jobs} -I% bash -c "
    if type clean-% >/dev/null 2>&1; then
        clean-% '$@';
    fi
    ";
}

if test -n "${rapids_clean_utils_debug:-}" \
&& ( test -z "${rapids_clean_utils_debug##*"all"*}" \
  || test -z "${rapids_clean_utils_debug##*"clean-all"*}" ); then
    PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
fi

clean_all "$@";
