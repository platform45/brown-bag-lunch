defmodule Rageq.User do
  use Rageq.Web, :model
  import Comeonin.Bcrypt, only: [hashpwsalt: 1]

  schema "users" do
    field :name,            :string
    field :email,           :string
    field :username,        :string
    field :password_digest, :string
    has_many :posts, Rageq.Post
    has_many :comments, Rageq.Comment

    timestamps()

    field :password,              :string, virtual: true
    field :password_confirmation, :string, virtual: true
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :email, :username, :password, :password_confirmation])
    |> validate_required([:name, :email, :username, :password, :password_confirmation])
    |> hash_password
  end

  defp hash_password(changeset) do
    if password = get_change(changeset, :password) do
      changeset
      |> put_change(:password_digest, hashpwsalt(password))
    else
      changeset
    end
  end
end
