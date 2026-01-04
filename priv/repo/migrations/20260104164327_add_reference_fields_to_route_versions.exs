defmodule Routes.Repo.Migrations.AddReferenceFieldsToRouteVersions do
  use Ecto.Migration

  def change do
    alter table(:route_versions) do
      remove :definition
      add :reference_platform, :string
      add :reference_url, :string
    end
  end
end
