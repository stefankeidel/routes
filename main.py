"""
A Textual app.
"""

import json
from pathlib import Path
from textual.app import App, ComposeResult
from textual.widgets import ListView, ListItem, Label
from glom import glom

# Use the RouteIndex to load route manifests from the library directory
from routes.route_index import RouteIndex


class RouteApp(App):
    CSS = """
    ListView {
        width: 100%;
    }
    """

    BINDINGS = [
        ("u", "add_bar('red')", "Add Red")
    ]

    def compose(self) -> ComposeResult:
        # Route list
        yield ListView()

    def on_mount(self) -> None:
        """Load routes from index on mount."""
        self._load_routes()

    def _load_routes(self) -> None:
        """Load routes from the library index."""
        route_list = self.query_one(ListView)

        # Instantiate RouteIndex pointing to the repository's library directory (relative to this file)
        project_root = Path(__file__).resolve().parent
        library_path = project_root / "library"
        index = RouteIndex(library_path)

        # If loading failed, show an error entry instead of dummy data
        if index.errors:
            for err in index.errors:
                route_list.append(ListItem(Label(f"Error: {err}")))
            return

        # Populate the ListView with route names from the index
        for entry in index.all():
            name = glom(entry, "metadata.name")
            route_list.append(ListItem(Label(name)))

    def on_list_view_selected(self, event: ListView.Selected) -> None:
        """Handle route selection to preview route details."""
        # TODO: Load and display the selected route
        pass


if __name__ == "__main__":
    app = RouteApp()
    app.run()