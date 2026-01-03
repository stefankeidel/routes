defmodule Routes.Repo do
  use Ecto.Repo,
    otp_app: :routes,
    adapter: Ecto.Adapters.Postgres
end
