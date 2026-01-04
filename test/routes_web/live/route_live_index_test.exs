defmodule RoutesWeb.RouteLiveIndexTest do
  use RoutesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Routes.RoutingFixtures

  test "shows link to latest published version", %{conn: conn} do
    route = route_fixture()
    version = route_version_fixture(route, %{status: "published"})

    {:ok, view, _html} = live(conn, ~p"/routes")

    assert render(view) =~ "Latest v#{version.version_number}"
    assert has_element?(view, "a[href=\"#{version.reference_url}\"]")
  end

  test "shows fallback message when no published version exists", %{conn: conn} do
    route = route_fixture()
    route_version_fixture(route, %{status: "draft"})

    {:ok, view, _html} = live(conn, ~p"/routes")

    assert render(view) =~ "No published version"
  end
end
