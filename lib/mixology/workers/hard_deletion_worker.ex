# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.Workers.HardDeletionWorker do
  use Oban.Worker, queue: "mn_hard_deletion", max_attempts: 1

  # import Ecto.Query
  # alias CommonsPub.{
  #   Actors,
  #   Collections,
  #   Communities,
  #   Features,
  #   Feeds,
  #   Resources,
  #   Threads,
  # }
  # alias CommonsPub.Feeds.{FeedActivities, FeedSubscriptions}
  # alias CommonsPub.Threads.Comments

  @impl Worker
  def perform(_, _job) do
    # Uploads.hard_delete() # Collection, Community, User
    # FeedActivities.hard_delete() # Feed, Activity
    # FeedSubscriptions.hard_delete() # Feed, User
    # Feeds.hard_delete() # Community, Collection, User
    # Features.hard_delete() # Collection, Community
    # Resources.hard_delete() # Collection
    # Collections.hard_delete() # Community, Actor
    # Communities.hard_delete() # Actor
    # Users.hard_delete() # Actors
    # Characters.hard_delete()
    :ok
  end
end
