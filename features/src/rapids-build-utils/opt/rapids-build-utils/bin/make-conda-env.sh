#!/usr/bin/env bash

# Usage:
#  rapids-make-conda-env [OPTION]...
#
# Make a combined conda environment for all repos.
#
# Boolean options:
#  -h,--help,--usage     print this text
#  -f,--force            Delete the existing conda env and recreate it from scratch.
#
# Options that require values:
#  -k,--key <key>        Only include the key(s)
#  -m,--manifest <file>  Use a specific manifest.json
#                        (default: ${PROJECT_MANIFEST_YML:-"/opt/rapids-build-utils/manifest.yaml"})
#  -o,--omit <repo>      Omit dependencies for repo(s).
#                        (default: none)
#  --repo <repo>         Only include dependencies for repo(s).
#                        (default: all repositories)

make_conda_env() {
    local -;
    set -Eeuo pipefail;

    # shellcheck disable=SC2154
    if test -n "${rapids_build_utils_debug:-}" \
    && { test -z "${rapids_build_utils_debug##*"*"*}" \
      || test -z "${rapids_build_utils_debug##*"make-conda-env"*}"; }; then
        PS4="+ ${BASH_SOURCE[0]}:\${LINENO} "; set -x;
    fi

    local env_name="${1}"; shift;
    local env_file_name="${env_name}.yml";

    eval "$(devcontainer-utils-parse-args "$0" --passthrough '
        -k,--key
        -m,--manifest
        -o,--omit
        --repo
    ' - <<< "${@@Q}")";

    # Remove the current conda env if called with `-f|--force`
    if test -n "${f:-${force:-}}"; then
        rm -rf "${HOME}/.conda/envs/${env_name}" \
               "${HOME}/.conda/envs/${env_file_name}";
    fi

    local -r new_env_path="$(realpath -m "/tmp/${env_file_name}")";
    local -r old_env_path="$(realpath -m "${HOME}/.conda/envs/${env_file_name}")";

    rapids-make-conda-dependencies "${OPTS[@]}" > "${new_env_path}";

    if test -f "${new_env_path}"; then

        # If the conda env doesn't exist, make one
        if ! conda info -e | grep -qE "^${env_name} "; then
            echo -e "Creating '${env_name}' conda environment\n" 1>&2;
            echo -e "Environment (${env_file_name}):\n" 1>&2;
            cat "${new_env_path}";
            echo "";

            mamba env create -n "${env_name}" -f "${new_env_path}";
        # If the conda env does exist but it's different from the generated one,
        # print the diff between the envs and update it
        elif ! diff -BNqw "${old_env_path}" "${new_env_path}" >/dev/null 2>&1; then
            echo -e "Updating '${env_name}' conda environment\n" 1>&2;
            echo -e "Environment (${env_file_name}):\n" 1>&2;

            # Print the diff to the console for debugging
            [ ! -f "${old_env_path}" ]                         \
             && cat "${new_env_path}"                          \
             || diff -BNyw "${old_env_path}" "${new_env_path}" \
             || true                                           \
             && echo "";

            # Update the current conda env + prune libs that were removed
            # Use conda instead of mamba due to https://github.com/mamba-org/mamba/issues/3059
            conda env update -n "${env_name}" -f "${new_env_path}" --prune --solver=libmamba
        fi

        cp -a "${new_env_path}" "${old_env_path}";
    fi
}

# shellcheck disable=SC1091
. /opt/conda/etc/profile.d/conda.sh;
# shellcheck disable=SC1091
. /opt/conda/etc/profile.d/mamba.sh;

make_conda_env "${DEFAULT_CONDA_ENV:-rapids}" "$@";

# shellcheck disable=SC1090
. /etc/profile.d/*-mambaforge.sh;
