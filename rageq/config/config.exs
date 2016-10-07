# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :rageq,
  ecto_repos: [Rageq.Repo]

# Configures the endpoint
config :rageq, Rageq.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "OV1w1MuoEP0QiOpIO/Th+UmnMslX+2gCdAM1KBs+4qgUxLsSKUt0+O+snlG6cJi4",
  render_errors: [view: Rageq.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Rageq.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :template_engines,
    slim: PhoenixSlime.Engine,
    slime: PhoenixSlime.Engin

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
