# Don't prepend an empty string to sys.path in interactive Python REPLs
# https://docs.python.org/3.11/using/cmdline.html#envvar-PYTHONSAFEPATH
export PYTHONSAFEPATH="${PYTHONSAFEPATH:-1}";

# Append history lines as soon as they're entered
export PROMPT_COMMAND="${PROMPT_COMMAND:-history -a}";

if test -n "${PROMPT_COMMAND##*"history -a"*}"; then
    export PROMPT_COMMAND="history -a; $PROMPT_COMMAND";
fi

# Define XDG_CACHE_HOME
if ! test -n "${XDG_CACHE_HOME:+x}"; then
    export XDG_CACHE_HOME="${HOME}/.cache";
fi

# Define XDG_CONFIG_HOME
if ! test -n "${XDG_CONFIG_HOME:+x}"; then
    export XDG_CONFIG_HOME="${HOME}/.config";
fi

# Define XDG_STATE_HOME
if ! test -n "${XDG_STATE_HOME:+x}"; then
    export XDG_STATE_HOME="${HOME}/.local/state";
fi

# Define HISTFILE
if ! test -n "${HISTFILE:+x}"; then
    export HISTFILE="${XDG_STATE_HOME}/._bash_history";
fi

# Default python history to ~/.local/state/.python_history
if ! test -n "${PYTHONHISTFILE:+x}"; then
    export PYTHONHISTFILE="${XDG_STATE_HOME}/.python_history";
fi

# Default python startup file to `devcontainer-utils-python-repl-startup` script.
if ! test -n "${PYTHONSTARTUP:+x}"; then
    export PYTHONSTARTUP="/usr/bin/devcontainer-utils-python-repl-startup";
fi
