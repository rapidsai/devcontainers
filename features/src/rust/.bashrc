export CARGO_HOME="${CARGO_HOME}";
export RUSTUP_HOME="${RUSTUP_HOME}";

if [ -n "${PATH##*"${CARGO_HOME}/bin"*}" ]; then
    export PATH="${CARGO_HOME}/bin:${PATH}";
fi
