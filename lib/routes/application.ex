defmodule Routes.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RoutesWeb.Telemetry,
      Routes.Repo,
      {DNSCluster, query: Application.get_env(:routes, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Routes.PubSub},
      # Start a worker by calling: Routes.Worker.start_link(arg)
      # {Routes.Worker, arg},
      # Start to serve requests, typically the last entry
      RoutesWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Routes.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RoutesWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
