"""
A Textual app.
"""

import json
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

    def on_directory_tree_file_selected(self, event: DirectoryTree.FileSelected) -> None:
        """Handle file selection to preview JSON content."""
        try:
            with open(event.path, 'r') as f:
                content = json.load(f)
            self.query_one("#preview", Pretty).update(content)
        except Exception as e:
            self.query_one("#preview", Pretty).update(f"Error loading file: {e}")


if __name__ == "__main__":
    app = RouteApp()
    app.run()