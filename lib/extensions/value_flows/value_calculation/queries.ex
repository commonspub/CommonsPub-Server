# SPDX-License-Identifier: AGPL-3.0-only
defmodule ValueFlows.ValueCalculation.Queries do
  alias ValueFlows.ValueCalculation
  import Ecto.Query

  def query(ValueCalculation) do
    from(vc in ValueCalculation, as: :value_calculation)
  end

  def query(q, filters), do: filter(query(q), filters)

  def join_to(q, spec, join_qualifier \\ :left)

  def join_to(q, specs, jq) when is_list(specs) do
    Enum.reduce(specs, q, &join_to(&2, &1, jq))
  end

  def join_to(q, :context, jq) do
    join(q, jq, [claim: c], c2 in assoc(c, :context), as: :context)
  end

  def filter(q, filters) when is_list(filters) do
    Enum.reduce(filters, q, &filter(&2, &1))
  end

  ## by field values

  def filter(q, {:id, id}) when is_binary(id) do
    where(q, [value_calculation: vc], vc.id == ^id)
  end

  def filter(q, {:id, ids}) when is_list(ids) do
    where(q, [value_calculation: vc], vc.id in ^ids)
  end

  def filter(q, {:context_id, id}) when is_binary(id) do
    where(q, [value_calculation: vc], vc.context_id == ^id)
  end

  def filter(q, {:context_id, ids}) when is_list(ids) do
    where(q, [value_calculation: vc], vc.context_id in ^ids)
  end

  ## preloading

  def filter(q, {:preload, :all}) do
    preload(q, [
      :creator,
      :context,
      :value_unit,
    ])
  end
end