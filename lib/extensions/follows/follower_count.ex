# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Follows.FollowerCount do
  use MoodleNet.Common.Schema
  alias Pointers.Pointer

  view_schema "mn_follower_count" do
    belongs_to(:context, Pointer, primary_key: true)
    field(:count, :integer)
  end
end
