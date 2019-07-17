defmodule MoodleNet.Repo.Migrations.AddObjectsTable do
  use Ecto.Migration

  def change do
    create table("objects", primary_key: false) do
      add :id, :uuid, primary_key: true
      add :data, :map
      add :local, :boolean

      timestamps()
    end
  end
end
