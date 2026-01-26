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
      # Game Process Registry
      {Registry, keys: :unique, name: GuayabitaRoll.Game.Registry},
      # Game Dynamic Supervisor
      GuayabitaRoll.Game.Supervisor,
      # gRPC Client Supervisor for EigenDA connections
      {DynamicSupervisor, strategy: :one_for_one, name: GRPC.Client.Supervisor},
      # Start a worker by calling: GuayabitaRoll.Worker.start_link(arg)
      # {GuayabitaRoll.Worker, arg},
      # Start to serve requests, typically the last entry
      GuayabitaRollWeb.Endpoint,
      # Entropy background worker (only in non-test env)
      if Application.get_env(:backend, :start_entropy_worker, true) do
        {GuayabitaRoll.Entropy.Worker, []}
      else
        :ignore
      end
    ] |> Enum.reject(&(&1 == :ignore))

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
