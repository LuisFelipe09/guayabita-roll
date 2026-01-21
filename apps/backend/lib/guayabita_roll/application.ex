defmodule GuayabitaRoll.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GuayabitaRollWeb.Telemetry,
      GuayabitaRoll.Repo,
      {DNSCluster, query: Application.get_env(:backend, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GuayabitaRoll.PubSub},
      # Start a worker by calling: GuayabitaRoll.Worker.start_link(arg)
      # {GuayabitaRoll.Worker, arg},
      # Start to serve requests, typically the last entry
      GuayabitaRollWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GuayabitaRoll.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GuayabitaRollWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
