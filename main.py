"""
A Textual app.
"""

import json
import yaml
from pathlib import Path
from textual.app import App, ComposeResult
from textual.widgets import DataTable, Static, Input
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
        ("d", "show_manifest", "Show manifest"),
        ("t", "edit_tags", "Edit tags")
    ]

    def compose(self) -> ComposeResult:
        # Route table
        yield DataTable(
            id="route_table",
            cursor_type="row",
        )

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
            # Use the manifest file path as the stable row key so we can
            # reference rows later by string key instead of numeric index.
            row_key = entry.get("__filepath") or f"route-{len(self._routes)}"
            table.add_row(name, profile, tags_text, key=row_key)
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

    class _TagsModal(ModalScreen):
        """A small modal that shows a single text input for editing tags.

        The provided save callback will be called with the new text when the
        user submits the input.
        """

        BINDINGS = [("escape", "dismiss", "Close"), ("q", "dismiss", "Close")]

        def __init__(self, initial_text: str, save_callback) -> None:
            super().__init__()
            self._initial_text = initial_text
            self._save_callback = save_callback

        def compose(self) -> ComposeResult:
            # Only an Input widget. Submitting the Input will trigger the save.
            yield Input(value=self._initial_text, id="tags_input")

        def on_mount(self) -> None:
            # Focus the input so Enter will submit immediately.
            try:
                self.query_one(Input).focus()
            except Exception:
                # If focus fails for any reason, ignore — input can still be used.
                pass

        def on_input_submitted(self, message: Input.Submitted) -> None:  # type: ignore[attr-defined]
            # Close this modal first so any modal/dialog pushed by the save
            # callback appears above it. Then call the save callback.
            try:
                self.app.pop_screen()
            except Exception:
                pass
            self._save_callback(message.value)

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

    def action_edit_tags(self) -> None:
        """Open a small modal with a single text box to edit tags for the
        currently highlighted route. The tags are comma-separated in the box.
        """
        table = self.query_one(DataTable)
        row = table.cursor_row

        if not hasattr(self, "_routes") or row is None or row < 0 or row >= len(self._routes):
            self.push_screen(self._ManifestModal("No route selected to edit tags."))
            return

        manifest = self._routes[row]
        current_tags = manifest.get("metadata", {}).get("tags", []) or []
        tags_text = ", ".join(current_tags)

        def _save_tags(new_text: str) -> None:
            # Parse comma-separated tags
            new_tags = [t.strip() for t in new_text.split(",") if t.strip()]

            filepath = manifest.get("__filepath")
            if not filepath:
                self.push_screen(self._ManifestModal("Cannot determine file path for this route."))
                return

            try:
                path = Path(filepath)
                data = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
                data.setdefault("metadata", {})["tags"] = new_tags
                path.write_text(yaml.safe_dump(data, sort_keys=False), encoding="utf-8")

                # Reload routes to reflect changes
                self._load_routes()
            except Exception as exc:
                self.push_screen(self._ManifestModal(f"Failed to save tags: {exc}"))

        # Push the tags modal with initial text and a save callback
        self.push_screen(self._TagsModal(tags_text, _save_tags))


if __name__ == "__main__":
    app = RouteApp()
    app.run()