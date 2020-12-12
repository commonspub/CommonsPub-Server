# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.ValueCalculation.ValueCalculations do
  import Bonfire.Common.Utils, only: [maybe_put: 3, maybe: 2]

  @repo CommonsPub.Repo
  alias CommonsPub.Users.User

  alias ValueFlows.ValueCalculation
  alias ValueFlows.ValueCalculation.Queries

  def one(filters), do: @repo.single(Queries.query(ValueCalculation, filters))

  def many(filters \\ []), do: {:ok, @repo.all(Queries.query(ValueCalculation, filters))}

  def preload_all(%ValueCalculation{} = calculation) do
    # should always succeed
    {:ok, calculation} = one(id: calculation.id, preload: :all)
    calculation
  end

  def create(%User{} = user, attrs) do
    attrs = prepare_attrs(attrs)

    @repo.transact_with(fn ->
      with {:ok, calculation} <- @repo.insert(ValueCalculation.create_changeset(user, attrs)) do
        {:ok, preload_all(calculation)}
      end
    end)
  end

  def update(%ValueCalculation{} = calculation, attrs) do
    attrs = prepare_attrs(attrs)

    @repo.transact_with(fn ->
      with {:ok, calculation} <- @repo.update(ValueCalculation.update_changeset(calculation, attrs)) do
        {:ok, preload_all(calculation)}
      end
    end)
  end

  def soft_delete(%ValueCalculation{} = calculation) do
    Bonfire.Repo.Delete.soft_delete(calculation)
  end

  defp prepare_attrs(attrs) do
    attrs
    |> maybe_put(:context_id,
      attrs |> Map.get(:in_scope_of) |> maybe(&List.first/1)
    )
    |> maybe_put(:value_unit_id, Map.get(attrs, :value_unit))
  end
end