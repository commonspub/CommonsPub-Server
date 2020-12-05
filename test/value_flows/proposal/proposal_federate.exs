defmodule ValueFlows.Proposal.FederateTest do
  use CommonsPub.DataCase, async: false

  import CommonsPub.Utils.Trendy, only: [some: 2]
  import CommonsPub.Utils.Simulation

  import Geolocation.Simulate

  import Bonfire.Quantities.Simulate

  import ValueFlows.Simulate
  import ValueFlows.Test.Faking

  @debug false
  @schema CommonsPub.Web.GraphQL.Schema

  describe "proposal" do
    test "federates/publishes a proposal" do
      user = fake_user!()

      unit = fake_unit!(user)

      parent = fake_user!()

      location = fake_geolocation!(user)

      proposal = fake_proposal!(user, parent, %{eligible_location_id: location.id})

      intent = fake_intent!(user, unit)

      fake_proposed_intent!(proposal, intent)

      fake_proposed_to!(fake_agent!(), proposal)

      # IO.inspect(pre_fed: proposal)

      assert {:ok, activity} = CommonsPub.ActivityPub.Publisher.publish("create", proposal)
      # IO.inspect(published: activity) ########

      assert activity.object.pointer_id == proposal.id
      assert activity.local == true
      assert activity.object.local == true

      assert activity.object.data["name"] == proposal.name
    end
  end
end
