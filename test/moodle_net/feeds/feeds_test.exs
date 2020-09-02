# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Test.FeedsTest do
  use MoodleNet.DataCase, async: true
  alias MoodleNet.Feeds

  describe "Creating and finding a feed" do
    test "works" do
      assert {:ok, feed} = Feeds.create()
      assert {:ok, feed2} = Feeds.one(id: feed.id)
    end
  end

  describe "Publishing to a feed" do
    test "works" do
      assert {:ok, feed} = Feeds.create()
    end
  end
end
