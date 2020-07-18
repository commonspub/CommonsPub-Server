# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Knowledge.Action.GraphQL do
  use Absinthe.Schema.Notation
  alias MoodleNetWeb.GraphQL.{CommonResolver}
  alias ValueFlows.Simulate
  require Logger

  # import_sdl path: "lib/value_flows/graphql/schemas/knowledge.gql"

  def action(%{id: id}, info) do
    {:ok, Simulate.action()}
  end

  def all_actions(_, _) do
    {:ok, Simulate.long_list(&Simulate.action/0)}
  end
end
