defmodule Rageq.CommentController do
  use Rageq.Web, :controller
  alias Rageq.Comment
  alias Rageq.Post
  alias Rageq.User
  alias Plug.Conn

  import Rageq.Router.Helpers
  import IEx

  def create(conn, %{"comment" => comment_params, "post_id" => post_id}) do
    post = Repo.get(Post, post_id)

    changeset =
      post
      |> build_assoc(:comments, user_id: current_user(conn).id)
      |> Comment.changeset(comment_params)

    case Repo.insert(changeset) do
      {:ok, comment} ->
        conn
        |> put_flash(:info, "Comment Created")
        |> redirect(to: post_path(conn, :show, post))
      {:error, changeset} ->
        conn
        |> put_flash(:info, "Comment Could Not Be Created")
        |> redirect(to: post_path(conn, :show, post))
    end
  end

  defp current_user(conn) do
    Repo.get!(User, Plug.Conn.get_session(conn, :current_user).id)
  end
end
