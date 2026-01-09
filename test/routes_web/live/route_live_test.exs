defmodule RoutesWeb.RouteLiveTest do
  use RoutesWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Routes.RoutingFixtures

  describe "route show" do
    test "renders route details and existing versions", %{conn: conn} do
      route = route_fixture()
      version = route_version_fixture(route, %{notes: "Initial version"})

      {:ok, _view, html} = live(conn, ~p"/routes/#{route}")

      assert html =~ route.name
      assert html =~ "Initial version"
      assert html =~ "v#{version.version_number}"
    end

    test "creates a new version from the sidebar form", %{conn: conn} do
      route = route_fixture()
      _existing = route_version_fixture(route, %{notes: "Existing"})
      new_url = "https://bikerouter.de/routes/#{System.unique_integer([:positive])}"

      {:ok, view, _html} = live(conn, ~p"/routes/#{route}")

      view
      |> form("#route-version-form",
        route_version: %{
          status: "draft",
          notes: "From test form",
          reference_platform: "bikerouter",
          reference_url: new_url
        }
      )
      |> render_submit()

      assert render(view) =~ "From test form"
      assert has_element?(view, "a[href=\"#{new_url}\"]")
    end

    test "edits a version inline and updates status", %{conn: conn} do
      route = route_fixture()
      version = route_version_fixture(route, %{notes: "Needs polish", status: "draft"})

      {:ok, view, _html} = live(conn, ~p"/routes/#{route}")

      view
      |> element("button[phx-click=\"edit_version\"][phx-value-id=\"#{version.id}\"]")
      |> render_click()

      assert has_element?(view, "#route-version-edit-form-#{version.id}")

      view
      |> form("#route-version-edit-form-#{version.id}",
        route_version: %{
          status: "published",
          notes: "Ready to share"
        }
      )
      |> render_submit()

      html = render(view)
      assert html =~ "Published"
      assert html =~ "Ready to share"
    end
  end
end
