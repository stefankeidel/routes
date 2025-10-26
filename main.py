"""
A Textual app.
"""

import json
import yaml
from pathlib import Path
from textual.app import App, ComposeResult
from textual.widgets import DataTable, Static
from textual.screen import ModalScreen
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
        ("d", "show_manifest", "Show manifest")
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

        # Keep an in-memory parallel list of route manifests so we can show
        # the full manifest for the selected row later.
        self._routes: list[dict] = []

        # Prepare the table columns
        table.clear(columns=True)
        table.add_column("Name")
        table.add_column("Profile")
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
            profile = glom(entry, "spec.profile")
            tags = glom(entry, "metadata.tags", default=[])
            tags_text = ", ".join(tags) if tags else ""
            table.add_row(name, profile, tags_text)
            # Keep the manifest in the same order as table rows
            self._routes.append(entry)

    # Selection handling for DataTable can be added here if needed.

    class _ManifestModal(ModalScreen):
        """A simple modal that renders pre-formatted JSON for a manifest."""

        BINDINGS = [("escape", "dismiss", "Close"), ("q", "dismiss", "Close")]

        def __init__(self, json_text: str) -> None:
            super().__init__()
            self._json_text = json_text

        def compose(self) -> ComposeResult:
            yield Static(self._json_text, id="manifest_content")

    def action_show_manifest(self) -> None:
        """Show the manifest for the currently highlighted table row in a popup."""
        table = self.query_one(DataTable)
        # DataTable.cursor_row is the current highlighted row index
        row = table.cursor_row

        if not hasattr(self, "_routes") or row is None or row < 0 or row >= len(self._routes):
            # No valid selection; show a tiny modal informing the user
            self.push_screen(self._ManifestModal("No manifest available for the selected row."))
            return

        manifest = self._routes[row]
        # Pretty-print manifest as YAML
        # use safe_dump to avoid executing arbitrary tags; preserve key order and unicode
        manifest_yaml = yaml.safe_dump(manifest, sort_keys=False, allow_unicode=True)
        self.push_screen(self._ManifestModal(manifest_yaml))


if __name__ == "__main__":
    app = RouteApp()
    app.run()