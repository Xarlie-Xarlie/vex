defmodule Streaming.Repo do
  use Ecto.Repo,
    otp_app: :streaming,
    adapter: Ecto.Adapters.Postgres
end
