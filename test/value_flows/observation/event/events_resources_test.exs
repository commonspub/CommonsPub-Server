defmodule ValueFlows.Observation.EconomicEvent.EconomicEventsResourcesTest do
  use CommonsPub.Web.ConnCase, async: true

  import CommonsPub.Utils.Simulation
  import Bonfire.Quantities.Test.Faking
  import CommonsPub.Tag.Simulate

  import CommonsPub.Utils.{Trendy, Simulation}
  import ValueFlows.Simulate
  import Bonfire.Quantities.Simulate
  import Geolocation.Simulate

  import ValueFlows.Test.Faking

  alias ValueFlows.Observation.EconomicEvent.EconomicEvents
  alias ValueFlows.Observation.EconomicEvent.EventSideEffects

  def assert_maybe(assert_fn, params) do
    if not Enum.all?(params, &is_nil/1) do
      apply(assert_fn, params)
    end
  end

  describe "noEffect" do
    test "passing an action with noEffect does not modify quantities" do
      user = fake_user!()
      unit = fake_unit!(user)
      resource_inventoried_as = fake_economic_resource!(user)
      to_resource_inventoried_as = fake_economic_resource!(user)

      event =
        fake_economic_event!(user, %{
          resource_inventoried_as: resource_inventoried_as.id,
          to_resource_inventoried_as: to_resource_inventoried_as.id,
          action: "dropoff"
        })

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)

      assert_maybe(&assert_measure/2, [
        new_event.resource_inventoried_as.onhand_quantity,
        event.resource_inventoried_as.onhand_quantity
      ])

      assert_maybe(&assert_measure/2, [
        new_event.to_resource_inventoried_as.onhand_quantity,
        event.to_resource_inventoried_as.onhand_quantity
      ])

      assert_maybe(&assert_measure/2, [
        new_event.resource_inventoried_as.accounting_quantity,
        event.resource_inventoried_as.accounting_quantity
      ])

      assert_maybe(&assert_measure/2, [
        new_event.to_resource_inventoried_as.accounting_quantity,
        event.to_resource_inventoried_as.accounting_quantity
      ])
    end
  end

  describe "Increment or decrement" do
    test "If resource inventoried as is not set, measures are not decremented" do
      user = fake_user!()
      unit = fake_unit!(user)
      to_resource_inventoried_as = fake_economic_resource!(user)

      event =
        fake_economic_event!(user, %{
          to_resource_inventoried_as: to_resource_inventoried_as.id,
          action: "consume"
        })

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)

      assert_maybe(&assert_measure/2, [
        new_event.to_resource_inventoried_as.onhand_quantity,
        event.to_resource_inventoried_as.onhand_quantity
      ])

      assert_maybe(&assert_measure/2, [
        new_event.to_resource_inventoried_as.accounting_quantity,
        event.to_resource_inventoried_as.accounting_quantity
      ])
    end

    test "If resource inventoried as is not set, measures are not incremented" do
      user = fake_user!()
      unit = fake_unit!(user)
      to_resource_inventoried_as = fake_economic_resource!(user)

      event =
        fake_economic_event!(user, %{
          to_resource_inventoried_as: to_resource_inventoried_as.id,
          action: "raise"
        })

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)

      assert_maybe(&assert_measure/2, [
        new_event.to_resource_inventoried_as.onhand_quantity,
        event.to_resource_inventoried_as.onhand_quantity
      ])

      assert_maybe(&assert_measure/2, [
        new_event.to_resource_inventoried_as.accounting_quantity,
        event.to_resource_inventoried_as.accounting_quantity
      ])
    end

    test "If resource inventoried is set, measures are incremented as expected" do
      user = fake_user!()
      unit = fake_unit!(user)
      resource_inventoried_as = fake_economic_resource!(user, %{}, unit)
      to_resource_inventoried_as = fake_economic_resource!(user, %{}, unit)

      event =
        fake_economic_event!(
          user,
          %{
            resource_inventoried_as: resource_inventoried_as.id,
            to_resource_inventoried_as: to_resource_inventoried_as.id,
            action: "raise"
          },
          unit
        )

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)

      assert_maybe(&assert_measure/2, [
        new_event.to_resource_inventoried_as.accounting_quantity,
        event.to_resource_inventoried_as.accounting_quantity
      ])

      assert event.resource_inventoried_as.accounting_quantity.has_numerical_value +
               event.resource_quantity.has_numerical_value ==
               new_event.resource_inventoried_as.accounting_quantity.has_numerical_value

      assert event.resource_inventoried_as.onhand_quantity.has_numerical_value +
               event.resource_quantity.has_numerical_value ==
               new_event.resource_inventoried_as.onhand_quantity.has_numerical_value
    end

    test "If resource inventoried is set, measures are decremented as expected" do
      user = fake_user!()
      unit = fake_unit!(user)
      resource_inventoried_as = fake_economic_resource!(user, %{}, unit)
      to_resource_inventoried_as = fake_economic_resource!(user, %{}, unit)

      event =
        fake_economic_event!(
          user,
          %{
            resource_inventoried_as: resource_inventoried_as.id,
            to_resource_inventoried_as: to_resource_inventoried_as.id,
            action: "consume"
          },
          unit
        )

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)

      assert_maybe(&assert_measure/2, [
        new_event.to_resource_inventoried_as.accounting_quantity,
        event.to_resource_inventoried_as.accounting_quantity
      ])

      assert event.resource_inventoried_as.accounting_quantity.has_numerical_value -
               event.resource_quantity.has_numerical_value ==
               new_event.resource_inventoried_as.accounting_quantity.has_numerical_value

      assert event.resource_inventoried_as.onhand_quantity.has_numerical_value -
               event.resource_quantity.has_numerical_value ==
               new_event.resource_inventoried_as.onhand_quantity.has_numerical_value
    end
  end

  describe "DecrementIncrement with transfer/move" do
    test "if resources are not set, the measures should not change" do
      user = fake_user!()
      unit = fake_unit!(user)

      event =
        fake_economic_event!(
          user,
          %{
            action: "transfer"
          },
          unit
        )

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)
      assert event.resource_inventoried_as == new_event.resource_inventoried_as
      assert event.to_resource_inventoried_as == new_event.to_resource_inventoried_as
    end

    test "if to_resource_inventoried_as is not set, resource inventoried as decrement as expected" do
      user = fake_user!()
      unit = fake_unit!(user)
      resource_inventoried_as = fake_economic_resource!(user, %{}, unit)

      event =
        fake_economic_event!(
          user,
          %{
            resource_inventoried_as: resource_inventoried_as.id,
            action: "transfer"
          },
          unit
        )

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)

      assert event.resource_inventoried_as.accounting_quantity.has_numerical_value -
               event.resource_quantity.has_numerical_value ==
               new_event.resource_inventoried_as.accounting_quantity.has_numerical_value

      assert event.resource_inventoried_as.onhand_quantity.has_numerical_value -
               event.resource_quantity.has_numerical_value ==
               new_event.resource_inventoried_as.onhand_quantity.has_numerical_value
    end

    test "if resource_inventoried_as is not set, to resource inventoried as should increment as expected" do
      user = fake_user!()
      unit = fake_unit!(user)
      to_resource_inventoried_as = fake_economic_resource!(user, %{}, unit)

      event =
        fake_economic_event!(
          user,
          %{
            to_resource_inventoried_as: to_resource_inventoried_as.id,
            action: "transfer"
          },
          unit
        )

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)

      assert event.to_resource_inventoried_as.accounting_quantity.has_numerical_value +
               event.resource_quantity.has_numerical_value ==
               new_event.to_resource_inventoried_as.accounting_quantity.has_numerical_value

      assert event.to_resource_inventoried_as.onhand_quantity.has_numerical_value +
               event.resource_quantity.has_numerical_value ==
               new_event.to_resource_inventoried_as.onhand_quantity.has_numerical_value
    end

    test "if both resources are set, the measures should change accordingly" do
      user = fake_user!()
      unit = fake_unit!(user)
      to_resource_inventoried_as = fake_economic_resource!(user, %{}, unit)
      resource_inventoried_as = fake_economic_resource!(user, %{}, unit)

      event =
        fake_economic_event!(
          user,
          %{
            to_resource_inventoried_as: to_resource_inventoried_as.id,
            resource_inventoried_as: resource_inventoried_as.id,
            action: "transfer"
          },
          unit
        )

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)

      assert event.resource_inventoried_as.accounting_quantity.has_numerical_value -
               event.resource_quantity.has_numerical_value ==
               new_event.resource_inventoried_as.accounting_quantity.has_numerical_value

      assert event.resource_inventoried_as.onhand_quantity.has_numerical_value -
               event.resource_quantity.has_numerical_value ==
               new_event.resource_inventoried_as.onhand_quantity.has_numerical_value

      assert event.to_resource_inventoried_as.accounting_quantity.has_numerical_value +
               event.resource_quantity.has_numerical_value ==
               new_event.to_resource_inventoried_as.accounting_quantity.has_numerical_value

      assert event.to_resource_inventoried_as.onhand_quantity.has_numerical_value +
               event.resource_quantity.has_numerical_value ==
               new_event.to_resource_inventoried_as.onhand_quantity.has_numerical_value
    end
  end

  describe "DecrementIncrement with transfer-custody" do
    test "if resources are not set, the measures should not change" do
      user = fake_user!()
      unit = fake_unit!(user)

      event =
        fake_economic_event!(
          user,
          %{
            action: "transfer-custody"
          },
          unit
        )

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)
      assert event.resource_inventoried_as == new_event.resource_inventoried_as
      assert event.to_resource_inventoried_as == new_event.to_resource_inventoried_as
    end

    test "if to_resource_inventoried_as is not set, resource inventoried as decrement as expected" do
      user = fake_user!()
      unit = fake_unit!(user)
      resource_inventoried_as = fake_economic_resource!(user, %{}, unit)

      event =
        fake_economic_event!(
          user,
          %{
            resource_inventoried_as: resource_inventoried_as.id,
            action: "transfer-custody"
          },
          unit
        )

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)

      assert_measure(
        event.resource_inventoried_as.accounting_quantity,
        new_event.resource_inventoried_as.accounting_quantity
      )

      assert event.resource_inventoried_as.onhand_quantity.has_numerical_value -
               event.resource_quantity.has_numerical_value ==
               new_event.resource_inventoried_as.onhand_quantity.has_numerical_value
    end

    test "if resource_inventoried_as is not set, to resource inventoried as should increment as expected" do
      user = fake_user!()
      unit = fake_unit!(user)
      to_resource_inventoried_as = fake_economic_resource!(user, %{}, unit)

      event =
        fake_economic_event!(
          user,
          %{
            to_resource_inventoried_as: to_resource_inventoried_as.id,
            action: "transfer-custody"
          },
          unit
        )

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)

      assert event.to_resource_inventoried_as.onhand_quantity.has_numerical_value +
               event.resource_quantity.has_numerical_value ==
               new_event.to_resource_inventoried_as.onhand_quantity.has_numerical_value
    end

    test "if both resources are set, the measures should change accordingly" do
      user = fake_user!()
      unit = fake_unit!(user)

      resource_inventoried_as = fake_economic_resource!(user, %{}, unit)
      to_resource_inventoried_as = fake_economic_resource!(user, %{}, unit)

      event =
        fake_economic_event!(
          user,
          %{
            to_resource_inventoried_as: to_resource_inventoried_as.id,
            resource_inventoried_as: resource_inventoried_as.id,
            action: "transfer-custody"
          },
          unit
        )

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)

      assert_measure(
        event.resource_inventoried_as.accounting_quantity,
        new_event.resource_inventoried_as.accounting_quantity
      )

      assert_measure(
        event.to_resource_inventoried_as.accounting_quantity,
        new_event.to_resource_inventoried_as.accounting_quantity
      )

      assert event.resource_inventoried_as.onhand_quantity.has_numerical_value -
               event.resource_quantity.has_numerical_value ==
               new_event.resource_inventoried_as.onhand_quantity.has_numerical_value

      assert event.to_resource_inventoried_as.onhand_quantity.has_numerical_value +
               event.resource_quantity.has_numerical_value ==
               new_event.to_resource_inventoried_as.onhand_quantity.has_numerical_value
    end

    test "if both resources are set, but with different measures, it should refuse to go ahead" do
      user = fake_user!()
      unit = fake_unit!(user)
      unit2 = fake_unit!(user)

      resource_inventoried_as = fake_economic_resource!(user, %{}, unit)
      to_resource_inventoried_as = fake_economic_resource!(user, %{}, unit2)

      assert {:error, e} =
               fake_economic_event(
                 user,
                 %{
                   to_resource_inventoried_as: to_resource_inventoried_as.id,
                   resource_inventoried_as: resource_inventoried_as.id,
                   action: "transfer-custody"
                 },
                 unit
               )
    end

    test "if a third party tries transfering a resource without consent, stop" do
      alice = fake_user!()
      bob = fake_user!()
      conan = fake_user!()

      unit = fake_unit!(alice)

      resource_inventoried_as = fake_economic_resource!(alice, %{}, unit)
      # IO.inspect(resource_inventoried_as: resource_inventoried_as)
      to_resource_inventoried_as = fake_economic_resource!(bob, %{}, unit)

      assert {:error, _e} =
               fake_economic_event(
                 conan,
                 %{
                   resource_inventoried_as: resource_inventoried_as.id,
                   to_resource_inventoried_as: to_resource_inventoried_as.id,
                   action: "transfer-custody",
                   receiver: conan
                 },
                 unit
               )
    end

    test "if a receiver tries transfering a resource to themselves without consent, stop" do
      alice = fake_user!()
      bob = fake_user!()

      unit = fake_unit!(alice)

      resource_inventoried_as = fake_economic_resource!(alice, %{}, unit)
      to_resource_inventoried_as = fake_economic_resource!(bob, %{}, unit)

      assert {:error, _e} =
               fake_economic_event(
                 bob,
                 %{
                   resource_inventoried_as: resource_inventoried_as.id,
                   to_resource_inventoried_as: to_resource_inventoried_as.id,
                   action: "transfer-custody",
                   receiver: bob
                 },
                 unit
               )
    end

    test "if a provider tries transfering a resource, succeed" do
      alice = fake_user!()
      bob = fake_user!()

      unit = fake_unit!(alice)

      resource_inventoried_as = fake_economic_resource!(alice, %{}, unit)
      to_resource_inventoried_as = fake_economic_resource!(bob, %{}, unit)

      assert {:ok, _event} =
               fake_economic_event(
                 alice,
                 %{
                   resource_inventoried_as: resource_inventoried_as.id,
                   to_resource_inventoried_as: to_resource_inventoried_as.id,
                   action: "transfer-custody",
                   receiver: bob
                 },
                 unit
               )
    end
  end

  describe "DecrementIncrement with transfer-all-rights" do
    test "if resources are not set, the measures should not change" do
      user = fake_user!()
      unit = fake_unit!(user)

      event =
        fake_economic_event!(
          user,
          %{
            action: "transfer-all-rights"
          },
          unit
        )

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)
      assert event.resource_inventoried_as == new_event.resource_inventoried_as
      assert event.to_resource_inventoried_as == new_event.to_resource_inventoried_as
    end

    test "if to_resource_inventoried_as is not set, resource inventoried as decrement as expected" do
      user = fake_user!()
      unit = fake_unit!(user)
      resource_inventoried_as = fake_economic_resource!(user, %{}, unit)

      event =
        fake_economic_event!(
          user,
          %{
            resource_inventoried_as: resource_inventoried_as.id,
            action: "transfer-all-rights"
          },
          unit
        )

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)

      assert_measure(
        event.resource_inventoried_as.onhand_quantity,
        new_event.resource_inventoried_as.onhand_quantity
      )

      assert event.resource_inventoried_as.accounting_quantity.has_numerical_value -
               event.resource_quantity.has_numerical_value ==
               new_event.resource_inventoried_as.accounting_quantity.has_numerical_value
    end

    test "if resource_inventoried_as is not set, to resource inventoried as should increment as expected" do
      user = fake_user!()
      unit = fake_unit!(user)
      to_resource_inventoried_as = fake_economic_resource!(user, %{}, unit)

      event =
        fake_economic_event!(
          user,
          %{
            to_resource_inventoried_as: to_resource_inventoried_as.id,
            action: "transfer-all-rights"
          },
          unit
        )

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)

      assert event.to_resource_inventoried_as.accounting_quantity.has_numerical_value +
               event.resource_quantity.has_numerical_value ==
               new_event.to_resource_inventoried_as.accounting_quantity.has_numerical_value
    end

    test "if both resources are set, the measures should change accordingly" do
      user = fake_user!()
      unit = fake_unit!(user)
      to_resource_inventoried_as = fake_economic_resource!(user, %{}, unit)
      resource_inventoried_as = fake_economic_resource!(user, %{}, unit)

      event =
        fake_economic_event!(
          user,
          %{
            to_resource_inventoried_as: to_resource_inventoried_as.id,
            resource_inventoried_as: resource_inventoried_as.id,
            action: "transfer-all-rights"
          },
          unit
        )

      assert {:ok, new_event} = EventSideEffects.event_side_effects(event)

      assert_measure(
        event.resource_inventoried_as.onhand_quantity,
        new_event.resource_inventoried_as.onhand_quantity
      )

      assert_measure(
        event.to_resource_inventoried_as.onhand_quantity,
        new_event.to_resource_inventoried_as.onhand_quantity
      )

      assert event.resource_inventoried_as.accounting_quantity.has_numerical_value -
               event.resource_quantity.has_numerical_value ==
               new_event.resource_inventoried_as.accounting_quantity.has_numerical_value

      assert event.to_resource_inventoried_as.accounting_quantity.has_numerical_value +
               event.resource_quantity.has_numerical_value ==
               new_event.to_resource_inventoried_as.accounting_quantity.has_numerical_value
    end
  end
end
