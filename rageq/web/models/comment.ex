defmodule Rageq.Comment do
  use Rageq.Web, :model

  schema "comments" do
    field :body, :string
    belongs_to :post, Rageq.Post
    belongs_to :user, Rageq.User

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:body])
    |> validate_required([:body])
  end
end
