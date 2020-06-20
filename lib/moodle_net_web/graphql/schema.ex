# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2020 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNetWeb.GraphQL.Schema do
  @moduledoc "Root GraphQL Schema"
  use Absinthe.Schema
  alias MoodleNetWeb.GraphQL.{
    AccessSchema,
    ActivitiesSchema,
    AdminSchema,
    BlocksSchema,
    CollectionsSchema,
    CommentsSchema,
    CommonSchema,
    CommunitiesSchema,
    Cursor,
    JSON,
    FeaturesSchema,
    FlagsSchema,
    FollowsSchema,
    InstanceSchema,
    LikesSchema,
    # LocalisationSchema,
    MiscSchema,
    MoodleverseSchema,
    ResourcesSchema,
    ThreadsSchema,
    UsersSchema,
    UploadSchema,
  }

  require Logger

  alias MoodleNetWeb.GraphQL.Middleware.CollapseErrors
  alias Absinthe.Middleware.{Async, Batch}

  # @pipeline_modifier OverridePhase

  def plugins, do: [Async, Batch]

  def middleware(middleware, _field, _object) do
    # [{MoodleNetWeb.GraphQL.Middleware.Debug, :start}] ++
    middleware ++ [CollapseErrors]
  end

  import_types AccessSchema
  import_types ActivitiesSchema
  import_types AdminSchema
  import_types BlocksSchema
  import_types CollectionsSchema
  import_types CommentsSchema
  import_types CommonSchema
  import_types CommunitiesSchema
  import_types Cursor
  import_types FeaturesSchema
  import_types FlagsSchema
  import_types FollowsSchema
  import_types InstanceSchema
  import_types JSON
  import_types LikesSchema
  # import_types LocalisationSchema
  import_types MiscSchema
  import_types MoodleverseSchema
  import_types ResourcesSchema
  import_types ThreadsSchema
  import_types UsersSchema
  import_types UploadSchema

  # optional modules:
  # import_types Organisation.GraphQL.Schema
  import_types Locales.GraphQL.Schema
  import_types Taxonomy.GraphQL.TagsSchema
  import_types Measurement.Unit.GraphQL
  import_types Geolocation.GraphQL

  import_types ValueFlows.Schema

  query do
    import_fields :access_queries
    import_fields :activities_queries
    import_fields :blocks_queries
    import_fields :collections_queries
    import_fields :comments_queries
    import_fields :common_queries
    import_fields :communities_queries
    import_fields :features_queries
    import_fields :flags_queries
    import_fields :follows_queries
    import_fields :instance_queries
    import_fields :likes_queries
    # import_fields :localisation_queries
    import_fields :moodleverse_queries
    import_fields :resources_queries
    import_fields :threads_queries
    import_fields :users_queries

    # import_fields :organisations_queries

    # Taxonomy
    import_fields :locales_queries
    import_fields :taxonomy_queries

    import_fields :measurement_query
    import_fields :geolocation_query

    # ValueFlows
    import_fields :value_flows_query
    import_fields :value_flows_extra_queries

  end

  mutation do
    import_fields :access_mutations
    import_fields :admin_mutations
    import_fields :blocks_mutations
    import_fields :collections_mutations
    import_fields :comments_mutations
    import_fields :common_mutations
    import_fields :communities_mutations
    import_fields :features_mutations
    import_fields :flags_mutations
    import_fields :follows_mutations
    import_fields :likes_mutations
    import_fields :resources_mutations
    import_fields :threads_mutations
    import_fields :users_mutations

    # import_fields :organisations_mutations

    import_fields :geolocation_mutation
    import_fields :measurement_mutation

    # ValueFlows
    import_fields :value_flows_mutation

    @desc "Fetch metadata from webpage"
    field :fetch_web_metadata, :web_metadata do
      arg :url, non_null(:string)
      resolve &MiscSchema.fetch_web_metadata/2
    end

    # for debugging purposes only:
    # @desc "Fetch an AS2 object from URL"
    # field :fetch_object, type: :fetched_object do
    #   arg :url, non_null(:string)
    #   resolve &MiscSchema.fetch_object/2
    # end

  end


  # hydrate SDL schema with resolvers

  # def hydrate(%Absinthe.Blueprint{}, _) do
  #   hydrated = %Absinthe.Blueprint{}
  #   hydrated = Geolocation.GraphQL.Hydration.hydrate(blueprint: hydrated)
  #   hydrated = Measurement.Hydration.hydrate(blueprint: hydrated)
  #   IO.inspect(hydrated) # only contains hydrations for Measurement
  #   hydrated = ValueFlows.Hydrations.hydrate(blueprint: hydrated)
  #   IO.inspect(hydrated)
  #   hydrated # FIXME: only the last of ValueFlows hydrations above actually works
  # end

  def hydrate(%Absinthe.Blueprint{}, _) do
    hydrated = %{}
    hydrated = hydrate_merge(hydrated, Geolocation.GraphQL.Hydration.hydrate()) # FIXME: the hydration seems to run, because commenting line 14 in lib/geolocation/hydration.ex results in `Interface type "testing_hydrations" either: * Does not have a `resolve_type` function.` error, but the Geolocation queries/mutations all return null
    hydrated = hydrate_merge(hydrated, Measurement.Hydration.hydrate()) # FIXME: Measurement queries/mutations also return null
    hydrated = hydrate_merge(hydrated, ValueFlows.Hydrations.hydrate()) # FIXME: only the ValueFlows queries/mutations actually works
    IO.inspect(merged_hydrations: hydrated) # this does output a merged map of all three hydrations above
    hydrated
  end

  defp hydrate_merge(a, b) do
    Map.merge(a, b, fn _, a, b -> Map.merge(a, b) end)
  end

  # hydrations fallback
  def hydrate(_node, _ancestors) do
    []
  end


end
