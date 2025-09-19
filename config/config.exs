# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :messaging_service,
  ecto_repos: [MessagingService.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Messaging provider configuration
config :messaging_service,
  # IF you use the twilio or sendgrid adapters then you need these values set
  twilio_account_sid: System.get_env("TWILIO_ACCOUNT_SID", "ACtest"),
  twilio_auth_token: System.get_env("TWILIO_AUTH_TOKEN", "test"),
  sendgrid_api_key: System.get_env("SENDGRID_API_KEY", "test_key"),

  # Adapter configuration (can be overridden in runtime.exs)
  sms_adapter: MessagingService.Producer.SMSAdapterLocal,
  mms_adapter: MessagingService.Producer.MMSAdapterLocal,
  email_adapter: MessagingService.Producer.EmailAdapterLocal

# Configures the endpoint
config :messaging_service, MessagingServiceWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MessagingServiceWeb.ErrorHTML, json: MessagingServiceWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: MessagingService.PubSub,
  live_view: [signing_salt: "P7Fklj0y"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :messaging_service, MessagingService.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  messaging_service: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  messaging_service: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
