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

    BINDINGS = [
        ("u", "add_bar('red')", "Add Red")
    ]

    def compose(self) -> ComposeResult:
        # Left: directory tree, Right: preview pane (currently empty placeholder)
        yield DirectoryTree("./library")
        yield Pretty("", id="preview")

    def action_TODO


if __name__ == "__main__":
    app = RouteApp()
    app.run()