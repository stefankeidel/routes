import pytest
from routes.bike_router_route import BikeRouterRoute


class TestBikeRouterRoute:
    """Test cases for BikeRouterRoute class."""

    def test_from_url_basic_functionality(self):
        """Test basic parsing of a BikeRouter URL."""
        # Test URL with query parameters
        url = "https://bikerouter.de/#map=14/53.5404/10.0176/standard,Waymarked_Trails-Cycling,gravel-overlay&lonlats=10.007622%2C53.552037%7C10.000498%2C53.55103%7C9.966831%2C53.554375&pois=10.00082%2C53.549386%2CTest+Point&profile=cxb-gravel"

        route = BikeRouterRoute.from_url(url)

        assert isinstance(route, BikeRouterRoute)
        assert route.layers == ["standard", "Waymarked_Trails-Cycling", "gravel-overlay"]
        assert route.waypoints == [
            (10.007622, 53.552037),
            (10.000498, 53.55103),
            (9.966831, 53.554375)
        ]
        assert route.profile == "cxb-gravel"
        assert route.pois == [
            {"lon": 10.00082, "lat": 53.549386, "description": "Test+Point"}
        ]
