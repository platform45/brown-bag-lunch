defmodule Rageq.CommentControllerTest do
  use Rageq.ConnCase

  import Rageq.Router.Helpers

  alias Rageq.Post
  alias Rageq.User
  alias Rageq.Comment

  @valid_attrs   %{body: "World"}
  @invalid_attrs %{}

  setup do
    user        = create_user()
    conn        = build_conn() |> login_user(user)
    {:ok, conn: conn, user: user}
  end

  defp login_user(conn, user) do
    post conn, session_path(conn, :create), user: %{username: user.username, password: user.password}
  end

  defp build_post do
    changeset = Post.changeset(%Post{}, %{title: "Epic Post", body: "This is a post"})

    Repo.insert!(changeset)
  end

  defp create_user do
    user_changeset = User.changeset %User{}, %{name: "harry", email: "harry@gmail.com", username: "Harry", password: "123", password_confirmation: "123"}
    Repo.insert!(user_changeset)
  end

  test "CREATE has to add a given comment to the database", %{conn: conn, user: user} do
    post = build_post
    conn = post conn, post_comment_path(conn, :create, post), comment: @valid_attrs
    assert redirected_to(conn) == post_path(conn, :show, post)

    comment = Repo.get_by!(assoc(post, :comments), @valid_attrs)
    assert comment.user_id == user.id
    assert comment.post_id == post.id
  end
end
