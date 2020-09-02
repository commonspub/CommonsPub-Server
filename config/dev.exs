import Config

# config :logger, level: :warn
config :logger, level: :debug
config :moodle_net, MoodleNet.Repo, log: :debug

port = String.to_integer(System.get_env("PORT", "4000"))

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with webpack to recompile .js and .css sources.
config :moodle_net, MoodleNetWeb.Endpoint,
  http: [port: port],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../assets", __DIR__)
    ]
  ]

config :moodle_net, MoodleNetWeb.Endpoint,
  http: [
    port: port,
    protocol_options: [
      max_request_line_length: 8192,
      max_header_value_length: 8192,
      max_header_name_length: 128,
      max_headers: 120
    ]
  ],
  protocol: "http",
  debug_errors: true,
  code_reloader: true,
  check_origin: false

config :cors_plug,
  origin: ["*"],
  max_age: 86400,
  methods: ["GET", "POST"]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :moodle_net, MoodleNetWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r{priv/static/.*(js|css|png|jpeg|jpg|gif|svg|ico|html)$},
      ~r{priv/gettext/.*(po)$},
      ~r{lib/.*(leex|eex|scss|css)$},
      ~r{lib/.*(view|live|templates|layout).*ex$}
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n", truncate: :infinity, level: :debug

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Configure your database
config :moodle_net, MoodleNet.Repo,
  adapter: Ecto.Adapters.Postgres,
  # types: Forkable.PostgresTypes,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  database: System.get_env("POSTGRES_DB", "commonspub_dev"),
  hostname: System.get_env("DATABASE_HOST", "localhost"),
  pool_size: 10

base_url = System.get_env("BASE_URL", "http://localhost:4000")

config :moodle_net, :base_url, base_url

config :moodle_net, :ap_base_path, System.get_env("AP_BASE_PATH", "/pub")

config :moodle_net,
       :frontend_base_url,
       System.get_env("FRONTEND_BASE_URL", base_url)

config :moodle_net, MoodleNet.Users,
  # enable open signups in dev
  public_registration: true

config :moodle_net, MoodleNet.Mail.Checker, mx: false

config :moodle_net, MoodleNet.Mail.MailService, adapter: Bamboo.LocalAdapter

config :moodle_net, MoodleNet.OAuth,
  client_name: "CommonsPub",
  client_id: "CommonsPUB",
  redirect_uri: "https://commonspub.dev.local/",
  website: "https://commonspub.dev.local/",
  scopes: "read,write,follow"

{:ok, cwd} = File.cwd()
uploads_dir = "/uploads"

config :moodle_net, MoodleNet.Uploads,
  directory: cwd <> uploads_dir,
  path: uploads_dir,
  uploads_base_url: base_url <> uploads_dir <> "/"

config :moodle_net, MoodleNet.Workers.ActivityWorker, log_level: :warn
