#! /usr/bin/env bash

# Assign variable one scope above the caller
# Usage: local "$1" && _upvar $1 "value(s)"
# Param: $1  Variable name to assign value to
# Param: $*  Value(s) to assign.  If multiple values, an array is
#            assigned, otherwise a single value is assigned.
# See: http://fvue.nl/wiki/Bash:_Passing_variables_by_reference
_upvar() {
    if unset -v "$1"; then
        if (( $# == 2 )); then
            eval $1=\"\$2\";
        else
            eval $1=\(\"\${@:2}\"\);
        fi;
    fi
}

declare -Ag _find_version_from_git_tags_cache=();

# Figure out correct version of a three part version number is not passed
_find_version_from_git_tags() {
    local variable_name="$1"
    local requested_version="${!variable_name}"
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository="$2"
    local prefix="${3:-"tags/v"}"
    local separator="${4:-"."}"
    local suffix="${5:-}"
    local last_part_optional="${6:-"false"}"
    local after_version="${7:-""}"
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator="${separator//./\\.}"
        local last_part=""
        if [ "${last_part_optional}" = "true" ]; then
            last_part+="(${escaped_separator}[0-9]+)?"
            last_part+="(${escaped_separator}[0-9]+)?"
            if [ -n "${suffix:+x}" ]; then
                last_part+="(${suffix})?"
            fi
        else
            last_part+="${escaped_separator}[0-9]+"
            last_part+="${escaped_separator}[0-9]+"
            if [ -n "${suffix:+x}" ]; then
                last_part+="(${suffix})"
            fi
        fi
        local regex="${prefix}\\K[0-9]+${last_part}$"

        if ! test -v _find_version_from_git_tags_cache["$variable_name"]; then
            local remote_upstream_fetch="$(git --no-pager config get remote.upstream.fetch)"
            if test -n "${remote_upstream_fetch:+x}"; then
                git config unset --global remote.upstream.fetch || true
            fi
            readarray -t version_list < <(
                git ls-remote --tags "${repository}" \
              | grep -oP "${regex}"                  \
              | tr -d ' '                            \
              | tr "${separator}" "."                \
              | sort -rV
            )
            if test -n "${remote_upstream_fetch:+x}"; then
                git config set --global remote.upstream.fetch "${remote_upstream_fetch}"
            fi
            _upvar _find_version_from_git_tags_cache["$variable_name"] "${version_list[*]}"
        else
            readarray -d' ' -t version_list <<< "${_find_version_from_git_tags_cache["$variable_name"]}"
        fi
        local version_list="$(IFS=$'\n'; echo "${version_list[*]}")"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            requested_version="$(head -n 1 <<< "${version_list}")"
        elif test -n "${after_version:+x}"; then
            set +e
            requested_version="$(grep -A 1 -m 1 "${after_version}" <<< "${version_list}" | tail -n 1)"
            set -e
        else
            set +e
            requested_version="$(grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)" <<< "${version_list}")"
            set -e
        fi
    fi
    if [ ! -n "${requested_version:+x}" ] || ! grep "^${requested_version//./\\.}$" <<< "${version_list}" > /dev/null 2>&1; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        return 1
    fi
    _upvar "${variable_name}" "${requested_version}"
    echo "${variable_name}=${requested_version}"
}

# Use semver logic to decrement a version number then look for the closest match
_find_prev_version_from_git_tags() {
    local variable_name="$1"
    local current_version="${!variable_name}"
    local repository="$2"
    # Normally a "v" is used before the version number, but support alternate cases
    local prefix="${3:-"tags/v"}"
    # Some repositories use "_" instead of "." for version number part separation, support that
    local separator="${4:-"."}"
    # Some repositories may have tags that include a suffix (e.g. actions/node-versions)
    local version_suffix_regex="${5:-}"
    # Some tools release versions that omit the last digit (e.g. go)
    local last_part_optional="${6:-"false"}"
    # Try one break fix version number less if we get a failure. Use "set +e" since "set -e" can cause failures in valid scenarios.
    set +e
    local major="$(echo "${current_version}" | grep -oE '^[0-9]+' || echo '')"
    local minor="$(echo "${current_version}" | grep -oP '^[0-9]+\.\K[0-9]+' || echo '')"
    local breakfix="$(echo "${current_version}" | grep -oP '^[0-9]+\.[0-9]+\.\K[0-9]+' 2>/dev/null || echo '')"

    if [ "${minor}" = "0" ] && [ "${breakfix}" = "0" ]; then
        ((major=major-1))
        _upvar "${variable_name}" "${major}"
        # Look for latest version from previous major release
        _find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${version_suffix_regex}" "${last_part_optional}"
    # Handle situations like Go's odd version pattern where "0" releases omit the last part
    elif [ "${breakfix}" = "" ] || [ "${breakfix}" = "0" ]; then
        ((minor=minor-1))
        _upvar "${variable_name}" "${major}.${minor}"
        # Look for latest version from previous minor release
        _find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${version_suffix_regex}" "${last_part_optional}"
    else
        ((breakfix=breakfix-1))
        if [ "${breakfix}" = "0" ] && [ "${last_part_optional}" = "true" ]; then
            _upvar "${variable_name}" "${major}.${minor}"
        else
            _upvar "${variable_name}" "${major}.${minor}.${breakfix}"
        fi
    fi
    set -e
}
