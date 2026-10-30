"""Entry point: prints the version, the packaged data file and a dynamically imported plugin.

The data file needs --add-data and the plugin needs --hidden-import, so a build
missing either flag produces an exe that crashes here.
"""

import importlib
import sys
from importlib import resources

from hello_app import __version__


def main() -> int:
    greeting = resources.files("hello_app").joinpath("data/greeting.txt").read_text()
    plugin = importlib.import_module("hello_app.plugin")
    print(f"hello-app {__version__}")
    print(greeting.strip())
    print(f"plugin: {plugin.NAME}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
