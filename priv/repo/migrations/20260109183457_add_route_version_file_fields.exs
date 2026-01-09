defmodule Routes.Repo.Migrations.AddRouteVersionFileFields do
  use Ecto.Migration

  def change do
    alter table(:route_versions) do
      add :file_path, :string
      add :file_name, :string
      add :file_type, :string
    end
  end
end
