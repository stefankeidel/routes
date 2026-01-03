defmodule Routes.Repo.Migrations.CreateRoutesAndRouteVersions do
  use Ecto.Migration

  def change do
    create table(:routes) do
      add :name, :string, null: false
      add :description, :string

      timestamps()
    end

    create table(:route_versions) do
      add :route_id, references(:routes, on_delete: :delete_all), null: false
      add :version_number, :integer, null: false
      add :status, :string, null: false
      add :notes, :string
      add :definition, :string

      timestamps()
    end

    create index(:route_versions, [:route_id])
    create unique_index(:route_versions, [:route_id, :version_number])
  end
end
