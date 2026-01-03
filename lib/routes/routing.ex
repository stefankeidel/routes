defmodule Routes.Routing do
  @moduledoc """
  The Routing context.
  """

  import Ecto.Query, warn: false

  alias Routes.Repo
  alias Routes.Routing.{Route, RouteVersion}

  def list_routes do
    Repo.all(from route in Route, order_by: [asc: route.name])
  end

  def get_route!(id), do: Repo.get!(Route, id)

  def create_route(attrs) do
    %Route{}
    |> Route.changeset(attrs)
    |> Repo.insert()
  end

  def update_route(route, attrs) do
    route
    |> Route.changeset(attrs)
    |> Repo.update()
  end

  def delete_route(route), do: Repo.delete(route)

  def change_route(route, attrs \\ %{}) do
    Route.changeset(route, attrs)
  end

  def list_route_versions(route_id) do
    Repo.all(
      from route_version in RouteVersion,
        where: route_version.route_id == ^route_id,
        order_by: [desc: route_version.version_number]
    )
  end

  def get_route_version!(id), do: Repo.get!(RouteVersion, id)

  def create_route_version(route, attrs) do
    route
    |> Ecto.build_assoc(:route_versions)
    |> RouteVersion.changeset(attrs)
    |> Repo.insert()
  end

  def update_route_version(route_version, attrs) do
    route_version
    |> RouteVersion.changeset(attrs)
    |> Repo.update()
  end

  def delete_route_version(route_version), do: Repo.delete(route_version)

  def change_route_version(route_version, attrs \\ %{}) do
    RouteVersion.changeset(route_version, attrs)
  end
end
