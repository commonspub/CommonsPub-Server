# SPDX-License-Identifier: AGPL-3.0-only
defmodule CommonsPub.ResourcesTest do
  use CommonsPub.DataCase
  import Bonfire.Common.Simulation
  import CommonsPub.Utils.Simulate
  alias CommonsPub.{Resources, Repo}
  alias CommonsPub.Utils.Simulation

  setup do
    user = fake_user!()
    community = fake_community!(user)
    collection = fake_collection!(user, community)
    resource = fake_resource!(user, collection)
    {:ok, %{user: user, collection: collection, resource: resource}}
  end

  describe "one" do
    test "fetches an existing resource", %{resource: resource} do
      assert {:ok, resource} = Resources.one(id: resource.id)
      assert resource.creator
    end

    test "returns not found if the resource is missing" do
      assert {:error, :not_found} = Resources.one(id: ulid())
    end
  end

  describe "create" do
    test "creates a new resource given valid attributes", context do
      Repo.transaction(fn ->
        content = fake_content!(context.user)
        attrs = Simulate.resource() |> Map.put(:content_id, content.id)

        assert {:ok, resource} =
                 Resources.create(
                   context.user,
                   context.collection,
                   attrs
                 )

        assert resource.name == attrs[:name]
        assert resource.content_id == content.id
      end)
    end

    test "fails given invalid attributes", context do
      Repo.transaction(fn ->
        assert {:error, changeset} =
                 Resources.create(
                   context.user,
                   context.collection,
                   %{}
                 )

        assert Keyword.get(changeset.errors, :name)
      end)
    end
  end

  describe "update" do
    test "updates a resource given valid attributes", context do
      attrs = Simulate.resource()
      resource = fake_resource!(context.user, context.collection)

      assert {:ok, updated_resource} = Resources.update(context.user, resource, attrs)
      assert updated_resource != resource
      assert updated_resource.name == attrs[:name]
    end
  end
end
