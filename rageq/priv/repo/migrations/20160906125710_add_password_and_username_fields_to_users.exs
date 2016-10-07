defmodule Rageq.Repo.Migrations.AddPasswordAndUsernameFieldsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string
      add :password_digest, :string
    end
  end
end
