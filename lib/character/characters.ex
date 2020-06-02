#  MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule Character.Characters do
  alias MoodleNet.{Activities, Actors, Common, Feeds, Follows, Repo}
  alias MoodleNet.GraphQL.{Fields, Page}
  alias MoodleNet.Common.Contexts
  alias Character
  alias Character.Queries
  alias MoodleNet.Feeds.FeedActivities
  alias MoodleNet.Users.User
  alias MoodleNet.Workers.APPublishWorker

  def cursor(:followers), do: &[&1.follower_count, &1.id]
  def test_cursor(:followers), do: &[&1["followerCount"], &1["id"]]

  @doc """
  Retrieves a single character by arbitrary filters.
  Used by:
  * GraphQL Item queries
  * ActivityPub integration
  * Various parts of the codebase that need to query for characters (inc. tests)
  """
  def one(filters), do: Repo.single(Queries.query(Character, filters))

  @doc """
  Retrieves a list of characters by arbitrary filters.
  Used by:
  * Various parts of the codebase that need to query for characters (inc. tests)
  """
  def many(filters \\ []), do: {:ok, Repo.all(Queries.query(Character, filters))}

  def fields(group_fn, filters \\ [])
  when is_function(group_fn, 1) do
    {:ok, fields} = many(filters)
    {:ok, Fields.new(fields, group_fn)}
  end

  @doc """
  Retrieves an Page of characters according to various filters

  Used by:
  * GraphQL resolver single-parent resolution
  """
  def page(cursor_fn, page_opts, base_filters \\ [], data_filters \\ [], count_filters \\ [])
  def page(cursor_fn, %{}=page_opts, base_filters, data_filters, count_filters) do
    base_q = Queries.query(Character, base_filters)
    data_q = Queries.filter(base_q, data_filters)
    count_q = Queries.filter(base_q, count_filters)
    with {:ok, [data, counts]} <- Repo.transact_many(all: data_q, count: count_q) do
      {:ok, Page.new(data, counts, cursor_fn, page_opts)}
    end
  end

  @doc """
  Retrieves an Pages of characters according to various filters

  Used by:
  * GraphQL resolver bulk resolution
  """
  def pages(cursor_fn, group_fn, page_opts, base_filters \\ [], data_filters \\ [], count_filters \\ [])
  def pages(cursor_fn, group_fn, page_opts, base_filters, data_filters, count_filters) do
    Contexts.pages Queries, Character,
      cursor_fn, group_fn, page_opts, base_filters, data_filters, count_filters
  end



  ## mutations

  @spec create(User.t(), attrs :: map) :: {:ok, Character.t()} | {:error, Changeset.t()}
  def create(%User{} = creator, attrs) when is_map(attrs) do

    attrs = Actors.prepare_username(attrs)

    Repo.transact_with(fn ->
      with {:ok, actor} <- Actors.create(attrs),
           {:ok, character_attrs} <- create_boxes(actor, attrs),
           {:ok, character} <- insert_character(creator, actor, character_attrs),
           act_attrs = %{verb: "created", is_local: true},
           {:ok, activity} <- Activities.create(creator, character, act_attrs),
           :ok <- publish(creator, character, activity, :created),
           :ok <- index(character), # add to search index
           {:ok, _follow} <- Follows.create(creator, character, %{is_local: true}) do
        {:ok, character}
      end
    end)
  end


  @spec create_with_characteristic(User.t(), characteristic :: any, attrs :: map) :: {:ok, Character.t()} | {:error, Changeset.t()}
  def create_with_characteristic(%User{} = creator, characteristic, attrs) when is_map(attrs) do

    attrs = Actors.prepare_username(attrs)

    Repo.transact_with(fn ->
      with {:ok, actor} <- Actors.create(attrs),
           {:ok, character_attrs} <- create_boxes(actor, attrs),
           {:ok, character} <- insert_character_with_characteristic(creator, characteristic, actor, character_attrs),
           act_attrs = %{verb: "created", is_local: true},
           {:ok, activity} <- Activities.create(creator, character, act_attrs),
           :ok <- publish(creator, character, activity, :created),
           :ok <- index(character), # add to search index
           {:ok, _follow} <- Follows.create(creator, character, %{is_local: true}) do
        {:ok, character}
      end
    end)
  end

  @spec create_with_context(User.t(), context :: any, attrs :: map) :: {:ok, Character.t()} | {:error, Changeset.t()}
  def create_with_context(%User{} = creator, context, attrs) when is_map(attrs) do
    Repo.transact_with(fn ->

      attrs = Actors.prepare_username(attrs)

      with {:ok, actor} <- Actors.create(attrs),
           {:ok, character_attrs} <- create_boxes(actor, attrs),
           {:ok, character} <- insert_character_with_context(creator, context, actor, character_attrs),
           act_attrs = %{verb: "created", is_local: true},
           {:ok, activity} <- Activities.create(creator, character, act_attrs),
           :ok <- publish(creator, context, character, activity, :created),
           :ok <- index(character), # add to search index
           {:ok, _follow} <- Follows.create(creator, character, %{is_local: true}) do
        {:ok, character}
      end
    end)
  end

  @spec create(User.t(), characteristic :: any, context :: any, attrs :: map) :: {:ok, Character.t()} | {:error, Changeset.t()}
  def create(%User{} = creator, characteristic, context, attrs) when is_map(attrs) do
    Repo.transact_with(fn ->

      attrs = Actors.prepare_username(attrs)

      with {:ok, actor} <- Actors.create(attrs),
           {:ok, character_attrs} <- create_boxes(actor, attrs),
           {:ok, character} <- insert_character(creator, characteristic, context, actor, character_attrs),
           act_attrs = %{verb: "created", is_local: true},
           {:ok, activity} <- Activities.create(creator, character, act_attrs),
           :ok <- publish(creator, context, character, activity, :created),
           :ok <- index(character), # add to search index
           {:ok, _follow} <- Follows.create(creator, character, %{is_local: true}) do
        {:ok, character}
      end
    end)
  end

  defp create_boxes(%{peer_id: nil}, attrs), do: create_local_boxes(attrs)
  defp create_boxes(%{peer_id: _}, attrs), do: create_remote_boxes(attrs)

  defp create_local_boxes(attrs) do
    with {:ok, inbox} <- Feeds.create(),
         {:ok, outbox} <- Feeds.create() do
      extra = %{inbox_id: inbox.id, outbox_id: outbox.id}
      {:ok, Map.merge(attrs, extra)}
    end
  end

  defp create_remote_boxes(attrs) do
    with {:ok, outbox} <- Feeds.create() do
      {:ok, Map.put(attrs, :outbox_id, outbox.id)}
    end
  end

  defp insert_character(creator, actor, attrs) do
    cs = Character.create_changeset(creator, nil, nil, actor, attrs)
    with {:ok, character} <- Repo.insert(cs), do: {:ok, %{ character | actor: actor }}
  end

  defp insert_character_with_characteristic(creator, characteristic, actor, attrs) do
    cs = Character.create_changeset(creator, characteristic, actor, nil, attrs)
    with {:ok, character} <- Repo.insert(cs), do: {:ok, %{ character | actor: actor, characteristic: characteristic }}
  end

  defp insert_character_with_context(creator, context, actor, attrs) do
    cs = Character.create_changeset(creator, nil, actor, context, attrs)
    with {:ok, character} <- Repo.insert(cs), do: {:ok, %{ character | actor: actor, context: context }}
  end

  defp insert_character(creator, characteristic, context, actor, attrs) do
    cs = Character.create_changeset(creator, characteristic, actor, context, attrs)
    with {:ok, character} <- Repo.insert(cs), do: {:ok, %{ character | actor: actor, context: context, characteristic: characteristic }}
  end

  defp publish(creator, character, activity, :created) do
    feeds = [
      creator.outbox_id,
      character.outbox_id, Feeds.instance_outbox_id(),
    ]
    with :ok <- FeedActivities.publish(activity, feeds),
         {:ok, _} <- ap_publish("create", character.id, creator.id, character.actor.peer_id),
      do: :ok
  end

  defp publish(creator, character, character, activity, :created) do
    feeds = [
      character.outbox_id, creator.outbox_id,
      character.outbox_id, Feeds.instance_outbox_id(),
    ]
    with :ok <- FeedActivities.publish(activity, feeds),
         {:ok, _} <- ap_publish("create", character.id, creator.id, character.actor.peer_id),
      do: :ok
  end

  defp publish(character, :updated) do
    # TODO: wrong if edited by admin
    with {:ok, _} <- ap_publish("update", character.id, character.creator_id, character.actor.peer_id),
      do: :ok
  end
  defp publish(character, :deleted) do
    # TODO: wrong if edited by admin
    with {:ok, _} <- ap_publish("delete", character.id, character.creator_id, character.actor.peer_id),
      do: :ok
  end

  defp ap_publish(verb, context_id, user_id, nil) do
    APPublishWorker.enqueue(verb, %{
      "context_id" => context_id,
      "user_id" => user_id,
    })
  end
  defp ap_publish(_, _, _), do: :ok

  # TODO: take the user who is performing the update
  @spec update(User.t(), Character.t(), attrs :: map) :: {:ok, Character.t()} | {:error, Changeset.t()}
  def update(%User{} = user, %Character{} = character, attrs) do
    Repo.transact_with(fn ->
      with {:ok, character} <- Repo.update(Character.update_changeset(character, attrs)),
           {:ok, actor} <- Actors.update(user, character.actor, attrs),
           :ok <- publish(character, :updated) do
        {:ok, %{ character | actor: actor }}
      end
    end)
  end

  def soft_delete(%Character{} = character) do
    Repo.transact_with(fn ->
      with {:ok, character} <- Common.soft_delete(character),
           :ok <- publish(character, :deleted) do
        {:ok, character}
      end
    end)
  end

  defp index(character) do

    follower_count =
      case MoodleNet.Follows.FollowerCounts.one(context: character.id) do
        {:ok, struct} -> struct.count
        {:error, _} -> nil
      end

    icon = MoodleNet.Uploads.remote_url_from_id(character.icon_id)
    # image = MoodleNet.Uploads.remote_url_from_id(character.image_id)

    canonical_url = MoodleNet.ActivityPub.Utils.get_actor_canonical_url(character)

    object = %{
      "index_type" => "Character",
      "id" => character.id,
      "canonicalUrl" => canonical_url,
      "followers" => %{
        "totalCount" => follower_count
      },
      "icon" => icon,
      # "image" => image,
      "name" => character.name,
      "preferredUsername" => character.actor.preferred_username,
      "summary" => Map.get(character, :summary),
      "createdAt" => character.published_at,
      "index_instance" => URI.parse(canonical_url).host, # home instance of object
    }

    Search.Indexing.maybe_index_object(object)

    :ok

  end

end
