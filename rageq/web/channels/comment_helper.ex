defmodule Rageq.CommentHelper do
  alias Rageq.Comment
  alias Rageq.Post
  alias Rageq.User
  alias Rageq.Repo

  import Ecto, only: [build_assoc: 3]

  def create(%{"post_id" => post_id, "user_id" => user_id, "body" => body}, _socket) do
    post = Repo.get!(Post, post_id) |> Repo.preload([:user, :comments])
    changeset =
      post
      |> build_assoc(:comments, user_id: user_id)
      |> Comment.changeset(%{body: body})

    Repo.insert(changeset)
  end

  def get(comment_id) do
    Repo.get!(Comment, comment_id) |> Repo.preload([:user])
  end

  defp authorized_user(user) do
    user
  end

  defp get_user(user_id) do
    Repo.get!(User, user_id)
  end
end
