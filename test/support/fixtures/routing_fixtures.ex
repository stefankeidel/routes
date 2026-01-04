defmodule Routes.RoutingFixtures do
  @moduledoc false

  alias Routes.Routing

  def route_fixture(attrs \\ %{}) do
    {:ok, route} =
      attrs
      |> Enum.into(%{
        name: "Route #{System.unique_integer([:positive])}",
        description: "Fixture route description"
      })
      |> Routing.create_route()

    route
  end

  def route_version_fixture(route, attrs \\ %{}) do
    defaults = %{
      status: "draft",
      notes: "Fixture notes",
      reference_platform: "bikerouter",
      reference_url: "https://bikerouter.de/routes/#{System.unique_integer([:positive])}"
    }

    attrs =
      defaults
      |> Map.merge(attrs)
      |> stringify_keys()

    {:ok, route_version} = Routing.create_route_version(route, attrs)

    route_version
  end

  defp stringify_keys(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      pair -> pair
    end)
  end
end
