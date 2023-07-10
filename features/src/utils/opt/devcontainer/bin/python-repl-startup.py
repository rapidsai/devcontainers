def on_python_repl_startup():

    import os
    import sys
    import tempfile

    def remove_unsafe_paths():
        # https://docs.python.org/3.11/using/cmdline.html#cmdoption-P
        while '' in sys.path:
            sys.path.remove('')


    # Backport Python 3.11 feature to remove '' from `sys.path`
    # https://docs.python.org/3.11/using/cmdline.html#envvar-PYTHONSAFEPATH
    if os.getenv('PYTHONSAFEPATH', '') != '':
        remove_unsafe_paths()


    def use_custom_histfile(histfile):
        import atexit
        import readline
        import time
        from pathlib import Path

        try:
            Path(histfile).touch(exist_ok=True)
        except FileNotFoundError: # Probably the parent directory doesn't exist
            Path(histfile).parent.mkdir(parents=True, exist_ok=True)

        try:
            readline.read_history_file(histfile)
        except IOError:
            pass

        readline.set_history_length(-1) # unlimited

        # Prevents creation of default history if custom histfile is empty
        if readline.get_current_history_length() == 0:
            readline.add_history(f'# {time.asctime()}')

        atexit.register(readline.write_history_file, histfile)


    # Attempt to use the following paths (in order) for the python REPL history file:
    # * $PYTHONHISTFILE
    # * $XDG_STATE_HOME/.python_history
    # * $XDG_CACHE_HOME/.python_history
    # * $HOME/.python_history
    use_custom_histfile(os.path.realpath(os.getenv(
        'PYTHONHISTFILE', os.path.join(os.getenv(
            'XDG_STATE_HOME', os.getenv('XDG_CACHE_HOME',
                os.path.expanduser('~') or tempfile.gettempdir()
            )), '.python_history'
        )
    )))

on_python_repl_startup()

del on_python_repl_startup
