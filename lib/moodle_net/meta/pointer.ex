# MoodleNet: Connecting and empowering educators worldwide
# Copyright © 2018-2019 Moodle Pty Ltd <https://moodle.com/moodlenet/>
# SPDX-License-Identifier: AGPL-3.0-only
defmodule MoodleNet.Meta.Pointer do
  @moduledoc """
  The Pointer is a reference to an entry in any table participating in
  the Meta abstraction. It enforces referential integrity by requiring
  the primary keys of all such tables to be foreign keys for entries
  in this table, having the side effect of enforcing UUID uniqueness.
  This uniqueness is not a problem for us since they are all version 4
  (random) UUIDs generated by us.
  """
  
  use MoodleNet.Common.Schema
  alias Ecto.Changeset
  alias MoodleNet.Meta.{Pointer, Table}

  standalone_schema "mn_meta_pointer" do
    belongs_to :table, Table, type: :integer
  end

  @spec changeset(integer()) :: Changeset.t()
  def changeset(table_id) when is_integer(table_id) do
    %Pointer{}
    |> Changeset.change(table_id: table_id)
    |> Changeset.foreign_key_constraint(:table_id)
  end
end
