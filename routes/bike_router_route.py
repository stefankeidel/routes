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
        """
        Convert the route to a YAML representation.

        The output looks almost like a Kubernetes manifest or Backstage catalog entry.
        For example:

        ```yaml
        apiVersion: bikerouter.de/v1
        kind: Route
        metadata:
            name: example-route
            description: "An example bike router route"
            tags:
                - bike
                - gravel
        spec:
            layers:
                - standard
                - Waymarked_Trails-Cycling
                - gravel-overlay
            waypoints:
                - lon: 9.979776
                  lat: 53.681992
                - lon: 9.989163
                  lat: 53.682005
            profile: gravel
            pois:
                - lon: 10.012345
                  lat: 53.690123
                  description: "Nice cafe"
        ```
        """

        # Build the manifest to match the example in the docstring.
        # Metadata fields are optional on the class, so fall back to empty/defaults
        metadata = {
            "name": getattr(self, "name", ""),
            "description": getattr(self, "description", ""),
            "tags": getattr(self, "tags", []),
        }

        spec = {
            "layers": self.layers,
            "waypoints": [{"lon": lon, "lat": lat} for lon, lat in self.waypoints],
            "profile": self.profile,
            "pois": self.pois,
        }

        manifest = {
            "apiVersion": "bikerouter.de/v1",
            "kind": "Route",
            "metadata": metadata,
            "spec": spec,
        }

        return yaml.dump(manifest, sort_keys=False)

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
