# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.Planning.Intent.IntentsTest do
  use MoodleNetWeb.ConnCase, async: true

  import MoodleNet.Test.Faking

  import Measurement.Simulate
  import Measurement.Test.Faking

  import ValueFlows.Simulate
  import ValueFlows.Test.Faking

  alias ValueFlows.Planning.Intent.Intents

  describe "one" do
    test "fetches an existing intent by ID" do
      user = fake_user!()
      unit = fake_unit!(user)
      intent = fake_intent!(user, unit)

      assert {:ok, fetched} = Intents.one(id: intent.id)
      assert_intent(intent, fetched)
      assert {:ok, fetched} = Intents.one(user: user)
      assert_intent(intent, fetched)
      # TODO
      # assert {:ok, fetched} = Intents.one(context: comm)
    end
  end

  describe "create" do
    test "can create an intent" do
      user = fake_user!()
      unit = fake_unit!(user)

      measures = %{
        resource_quantity: measure(%{unit_id: unit.id}),
        effort_quantity: measure(%{unit_id: unit.id}),
        available_quantity: measure(%{unit_id: unit.id})
      }

      assert {:ok, intent} = Intents.create(user, action(), intent(measures))
      assert_intent(intent)
    end

    test "can create an intent with a context" do
      user = fake_user!()
      unit = fake_unit!(user)
      another_user = fake_user!()

      measures = %{
        resource_quantity: measure(%{unit_id: unit.id}),
        effort_quantity: measure(%{unit_id: unit.id}),
        available_quantity: measure(%{unit_id: unit.id})
      }

      assert {:ok, intent} = Intents.create(user, action(), another_user, intent(measures))
      assert_intent(intent)
      assert intent.context_id == another_user.id
    end
  end

  describe "update" do
    test "updates an existing intent" do
      user = fake_user!()
      unit = fake_unit!(user)
      intent = fake_intent!(user, unit)

      measures = %{
        resource_quantity: measure(%{unit_id: unit.id}),
        # don't update one of them
        # effort_quantity: measure(%{unit_id: unit.id}),
        available_quantity: measure(%{unit_id: unit.id})
      }

      assert {:ok, updated} = Intents.update(intent, intent(measures))
      assert_intent(updated)
      assert intent != updated
      assert intent.effort_quantity_id == updated.effort_quantity_id
      assert intent.resource_quantity_id != updated.resource_quantity_id
      assert intent.available_quantity_id != updated.available_quantity_id
    end
  end
end
