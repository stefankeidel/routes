"""
A Textual app.
"""

from textual.app import App, ComposeResult
from textual.widgets import DirectoryTree, Pretty


class RouteApp(App):
    CSS = """
    Screen {
        layout: horizontal;
    }
    DirectoryTree {
        width: 50%;
        min-width: 30;
    }
    #preview {
        width: 1fr;
    }
    """

    def compose(self) -> ComposeResult:
        # Left: directory tree, Right: preview pane (currently empty placeholder)
        yield DirectoryTree("./library")
        yield Pretty("", id="preview")


if __name__ == "__main__":
    app = RouteApp()
    app.run()