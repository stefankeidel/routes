defmodule Routes.Routing.RouteVersion do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "route_versions" do
    field :version_number, :integer
    field :status, :string, default: "draft"
    field :notes, :string
    field :definition, :string

    belongs_to :route, Routes.Routing.Route

    timestamps()
  end

  def changeset(route_version, attrs) do
    route_version
    |> cast(attrs, [:version_number, :status, :notes, :definition])
    |> validate_required([:version_number, :status])
    |> validate_number(:version_number, greater_than: 0)
    |> validate_inclusion(:status, ["draft", "published", "archived"])
    |> validate_length(:notes, max: 600)
    |> validate_length(:definition, max: 2000)
    |> unique_constraint(:version_number,
      name: :route_versions_route_id_version_number_index
    )
  end
end
