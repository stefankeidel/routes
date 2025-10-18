from __future__ import annotations
from urllib.parse import urlparse, unquote
import yaml


class BikeRouterRoute:
    """
    A class representing a bike router route.

    Basically a representation of a link like this one

    https://bikerouter.de/#map=13/53.6459/10.0068/standard,Waymarked_Trails-Cycling,gravel-overlay&lonlats=9.979776%2C53.681992%7C9.989163%2C53.682005%7C9.987656%2C53.684045%7C9.988101%2C53.685195%7C10.000284%2C53.686285%7C10.000525%2
    """
    def __init__(
            self,
            layers: list[str],
            waypoints: list[tuple[float, float]],
            profile: str,
            pois: list[dict[str, float]],
    ):
        self.layers = layers
        self.waypoints = waypoints
        self.profile = profile
        self.pois = pois

    def to_yaml(self) -> str:
        """Convert the route to a YAML representation."""

        data = {
            "layers": self.layers,
            "waypoints": [{"lon": lon, "lat": lat} for lon, lat in self.waypoints],
            "profile": self.profile,
            "pois": self.pois,
        }
        return yaml.dump(data, sort_keys=False)

    def to_json_file(self, filepath: str) -> None:
        """Write the JSON representation to a file."""
        import json

        data = {
            "layers": self.layers,
            "waypoints": [{"lon": lon, "lat": lat} for lon, lat in self.waypoints],
            "profile": self.profile,
            "pois": self.pois,
        }
        with open(filepath, "w") as f:
            json.dump(data, f, indent=4)

    @classmethod
    def from_url(cls, url: str) -> BikeRouterRoute:
        """
        Create a BikeRouterRoute instance from a BikeRouter URL.
        Sorry for this mess, it was ChatGPT, was too lazy.

        Unit tests say it does work tho :shrug:
        """

        # --- Step 1: Separate fragment (after '#') and parse like querystring
        fragment = urlparse(url).fragment
        parts = fragment.split("&")

        params = {}
        for part in parts:
            if "=" in part:
                key, value = part.split("=", 1)
                params[key] = unquote(value)

        # --- Step 2: Extract data

        # Layers are in "map=zoom/lat/lon/layer1,layer2,..."
        map_parts = params.get("map", "").split("/")
        layers = []
        if len(map_parts) >= 4:
            layers = map_parts[3].split(",")

        # Waypoints (lonlats)
        lonlats_raw = params.get("lonlats", "")
        lonlats = [tuple(map(float, ll.split(","))) for ll in lonlats_raw.split("|") if ll]

        # POIs (lon, lat, description)
        pois_raw = params.get("pois", "")
        pois = []
        if pois_raw:
            poi_parts = pois_raw.split("|")
            # POIs can appear as lon,lat,desc repeated
            for p in poi_parts:
                sub = p.split(",")
                if len(sub) >= 3:
                    lon, lat = map(float, sub[:2])
                    desc = ",".join(sub[2:])
                    # decode URL-encoded description
                    desc = unquote(desc)
                    pois.append({"lon": lon, "lat": lat, "description": desc})

        # Profile
        profile = params.get("profile", "")

        return cls(layers, lonlats, profile, pois)  # type: ignore
