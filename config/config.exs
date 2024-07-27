import Config

config :logger, :default_formatter,
  format: "\n$time $metadata[$level] $message\n",
  metadata: [:pid]

config :http_server, directory: "./web"
