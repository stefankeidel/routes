defmodule Routes.Routing.Route do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "routes" do
    field :name, :string
    field :description, :string
    field :latest_version, :map, virtual: true

    has_many :route_versions, Routes.Routing.RouteVersion

    timestamps()
  end

  def changeset(route, attrs) do
    route
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 120)
    |> validate_length(:description, max: 500)
  end
end
