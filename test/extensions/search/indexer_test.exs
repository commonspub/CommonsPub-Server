# SPDX-License-Identifier: AGPL-3.0-only

defmodule CommonsPub.Search.IndexerTest do
  use CommonsPub.DataCase
  alias CommonsPub.Search.Indexer
  import CommonsPub.Test.Faking

  test "format community" do
    community = fake_user!() |> fake_community!()
    json = Indexer.indexing_object_format(community)
    assert json["index_mothership_object_id"] == community.id
    assert json["canonicalUrl"] == community.character.canonical_url
    # assert json["icon"] == community.icon
    # assert json["image"] == community.image
    assert json["preferredUsername"] == community.character.preferred_username
    assert json["summary"] == community.summary
    assert json["index_type"] == "Community"
  end

  test "format collection" do
    user = fake_user!()
    community = fake_community!(user)
    collection = fake_collection!(user, community)

    json = Indexer.indexing_object_format(collection)
    assert json["index_mothership_object_id"] == collection.id
    assert json["canonicalUrl"] == collection.character.canonical_url
    # assert json["icon"] == collection.icon
    assert json["preferredUsername"] == collection.character.preferred_username
    assert json["summary"] == collection.summary
    assert json["index_type"] == "Collection"
    assert is_map(json["community"])
  end

  test "format resource" do
    user = fake_user!()
    community = fake_community!(user)
    collection = fake_collection!(user, community)
    resource = fake_resource!(user, collection)

    json = Indexer.indexing_object_format(resource)
    assert String.starts_with?(json["url"], "http")
    assert json["index_mothership_object_id"] == resource.id
    assert json["canonicalUrl"] == resource.canonical_url
    # assert json["icon"] == resource.icon
    assert json["summary"] == resource.summary
    assert json["index_type"] == "Resource"
    assert is_map(json["collection"])
    assert is_map(json["collection"]["community"])
    assert is_binary(json["licence"])
  end
end