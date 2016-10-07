defmodule Rageq.Post do
  use Rageq.Web, :model

  schema "posts" do
    field :title, :string
    field :body, :string
    belongs_to :user, Rageq.User
    has_many :comments, Rageq.Comment

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :body])
    |> validate_required([:title, :body])
  end
end
