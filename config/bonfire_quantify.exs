use Mix.Config

config :bonfire_quantify,
  web_module: CommonsPub.Web,
  repo_module: CommonsPub.Repo,
  user_schema: CommonsPub.Users.User,
  # templates_path: "lib",
  otp_app: :bonfire
