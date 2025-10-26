"""
A Textual app.
"""

import json
from pathlib import Path
from textual.app import App, ComposeResult
from textual.widgets import DataTable
from glom import glom

# Use the RouteIndex to load route manifests from the library directory
from routes.route_index import RouteIndex


class RouteApp(App):
    CSS = """
    DataTable {
        width: 100%;
    }
    """

    BINDINGS = [
        ("u", "add_bar('red')", "Add Red")
    ]

    def compose(self) -> ComposeResult:
        # Route table
        yield DataTable(id="route_table")

    def on_mount(self) -> None:
        """Load routes from index on mount."""
        self._load_routes()

    def _load_routes(self) -> None:
        """Load routes from the library index."""
        table = self.query_one(DataTable)

        # Prepare the table columns
        table.clear(columns=True)
        table.add_column("Name")
        table.add_column("Tags")

        # Instantiate RouteIndex pointing to the repository's library directory (relative to this file)
        project_root = Path(__file__).resolve().parent
        library_path = project_root / "library"
        index = RouteIndex(library_path)

        # If loading failed, show an error row instead
        if index.errors:
            for err in index.errors:
                table.add_row(f"Error: {err}", "")
            return

        # Populate the DataTable with route names and tags from the index
        for entry in index.all():
            name = glom(entry, "metadata.name")
            tags = glom(entry, "metadata.tags", default=[])
            tags_text = ", ".join(tags) if tags else ""

            table.add_row(name, tags_text)

    # Selection handling for DataTable can be added here if needed.


if __name__ == "__main__":
    app = RouteApp()
    app.run()