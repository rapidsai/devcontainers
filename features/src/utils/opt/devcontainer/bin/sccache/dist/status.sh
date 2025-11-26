#!/usr/bin/env bash

# Usage:
#  devcontainer-utils-sccache-dist-status [OPTION]...
#
# Print and optionally format `sccache --dist-status`.
#
# Boolean options:
#  -h,--help      Print this text.
#  --no-procs     Don't print the number of sccache processes
#  --no-stats     Don't print the sccache stats
#  --no-temps     Don't print the number of sccache tempfiles
#
# Options that require values:
#  -c|--col-width <num>         Max column width in number of characters.
#                               String columns wider than this will be truncated with "...".
#                               (default: $COLUMNS)
#  -f|--format (csv|tsv|json)   The `sccache --dist-status` output format.
#                               (default: "tsv")
#  -w,--watch <num>             Watch status every <num> seconds (or 1s if <num> is unspecified).
#

_sccache_dist_status() {

    local -;
    set -euo pipefail;

    eval "$(devcontainer-utils-parse-args "$0" "$@" <&0)";

    # shellcheck disable=SC1091
    . devcontainer-utils-debug-output 'devcontainer_utils_debug' 'sccache sccache-dist-status';

    if test ${#w[@]} -gt 0 && ! test -n "${w:+x}"; then
        w="1";
    fi

    if ! test -n "${__SKIP_WATCH:+x}" && test -n "${w:+x}"; then
        __SKIP_WATCH=1 watch -n "$w" devcontainer-utils-sccache-dist-status "${@}";
    else

        f="${f:-${format:-tsv}}";
        c="${c:-${col_width:-${COLUMNS:-1000000000}}}";

        if [[ "$f" != json ]] && ! test -n "${no_procs:+x}"; then
            echo "open fds: $(lsof -a -p $(cat /tmp/sccache.*.pid) | wc -l)"
            echo "sccache procs: $(pgrep sccache | wc -l)"
        fi


        if [[ "$f" != json ]] &&  ! test -n "${no_temps:+x}"; then
            echo -n "preprocessed tempfiles: "
            echo -n "$(ls -All /tmp/.sccache_temp/.tmp* 2>/dev/null | wc -l) "
            echo " ($(du -ch /tmp/.sccache_temp/.tmp* 2>/dev/null | tail -n1 | cut -f1))"

            echo -n "nvcc internal tempfiles: "
            echo -n "$(ls -All /tmp/.sccache_temp/nvcc/*/* 2>/dev/null | wc -l)"
            echo " ($(du -ch /tmp/.sccache_temp/nvcc/* 2>/dev/null | tail -n1 | cut -f1))"
            echo
        fi

        if ! test -n "${no_stats:+x}"; then
            if test "$f" = json; then
                sccache --show-stats --stats-format json
            else
                sccache --show-stats
            fi
            echo
        fi

        # Print current dist status to verify we're connected
        sccache 2>/dev/null --dist-status \
      | {
            # Passthrough if the format is json
            if test "$f" = json; then
                cat - <(echo)
            else

                cat - | jq -r -f <(cat <<EOF
  def truncate_val: (
    . as \$x
    | \$x | length as \$l
    | if (\$x | type == "string") and (\$l > $c)
      then \$x[0:$((c-3))] + "..."
      else \$x
      end
  );
  def info_to_row: {
    time: now | strflocaltime("%X"),
    type: (.type // "server"),
    id: .id,
    servers: (if .servers == null then "-" else (.servers | length) end),
    cpus: .info.occupancy,
    util: ((.info.cpu_usage // 0) * 100 | floor | . / 100 | tostring | . + "%"),
    jobs: (.jobs.loading + .jobs.pending + .jobs.running),
    loading: .jobs.loading,
    pending: .jobs.pending,
    running: .jobs.running,
    oldest: ((.max_job_age // 0) | tostring | . + "s"),
    accepted: .jobs.accepted,
    finished: .jobs.finished,
    seen: ((.u_time // 0) | tostring | . + "s"),
  };

  .SchedulerStatus as [\$x, \$y] | [
    (\$y + { id: \$x, type: "scheduler", u_time: (\$y.servers // {} | map(.u_time) | min | . // "-" | tostring), max_job_age: (\$y.servers // {} | map(.max_job_age) | max | . // "-" | tostring) }),
    (\$y.servers // [] | sort_by(.id)[])
  ]
  | map(info_to_row) as \$rows
  | (\$rows[0] | keys_unsorted) as \$cols
  | (\$rows | map(. as \$row | \$cols | map(\$row[.] | truncate_val))) as \$rows
  | (\$cols | map(truncate_val)), \$rows[] | @csv
EOF
    )
            fi
        } \
      | {
            # Passthrough if the format is csv or json
            # Otherwise, transform the csv into a tsv.
            if test "$f" = tsv; then
                if [[ "$(grep DISTRIB_RELEASE= /etc/lsb-release | cut -d= -f2)" > "20.04" ]]; then
                    cat - | sed 's/\"//g' | column -t -s, -R $(seq -s, 1 14)
                else
                    cat - | sed 's/\"//g' | column -t -s,
                fi
            else
                cat -
            fi
        }
    fi
}

_sccache_dist_status "$@" <&0;
