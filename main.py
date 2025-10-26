"""
A Textual app.
"""

import json
from textual.app import App, ComposeResult
from textual.widgets import ListView, ListItem, Label


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
        # TODO: Load from library/index.json when it exists
        # For now, show dummy data
        route_list = self.query_one(ListView)
        dummy_routes = [
            "Morning Commute Route",
            "Weekend Gravel Adventure",
            "City Park Loop",
            "Coastal Scenic Ride",
            "Mountain Trail Challenge"
        ]
        for route_name in dummy_routes:
            route_list.append(ListItem(Label(route_name)))

    def on_list_view_selected(self, event: ListView.Selected) -> None:
        """Handle route selection to preview route details."""
        # TODO: Load and display the selected route
        pass


if __name__ == "__main__":
    app = RouteApp()
    app.run()