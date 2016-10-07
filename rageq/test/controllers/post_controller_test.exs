defmodule Rageq.PostControllerTest do
  use Rageq.ConnCase

  alias Rageq.Post
  alias Rageq.User

  import Rageq.Router.Helpers

  @valid_attrs   %{title: "Hello", body: "World"}
  @invalid_attrs %{}

  setup do
    user        = create_user()
    unauth_user = create_unauth_user()
    conn        = build_conn() |> login_user(user)
    {:ok, conn: conn, user: user, unauth_user: unauth_user}
  end

  defp login_user(conn, user) do
    post conn, session_path(conn, :create), user: %{username: user.username, password: user.password}
  end

  defp build_post(user) do
    changeset =
      user
      |> build_assoc(:posts)
      |> Post.changeset(@valid_attrs)

    Repo.insert!(changeset)
  end

  defp create_user do
    user_changeset = User.changeset %User{}, %{name: "harry", email: "harry@gmail.com", username: "Harry", password: "123", password_confirmation: "123"}
    Repo.insert!(user_changeset)
  end

  defp create_unauth_user do
    unauth_user_changeset = User.changeset(%User{}, %{name: "not harry", email: "notharry@gmail.com", username: "NotHarry", password: "123", password_confirmation: "123"})
    Repo.insert!(unauth_user_changeset)
  end

  test "list all entries on post index", %{conn: conn} do
    conn = get conn, post_path(conn, :index)
    assert Repo.all(Post)
  end

  test "shows chosen resource", %{conn: conn} do
    post = Repo.insert! %Post{}
    conn = get conn, post_path(conn, :show, post)
    assert html_response(conn, 200) =~ post.body
  end
  #
  # test "renders page not found when id doesn't exist", %{conn: conn} do
  #   assert_error_sent 404, fn ->
  #     get conn, post_path(conn, :show, -1)
  #   end
  # end
  #
  test "renders form for new resources", %{conn: conn} do
    conn = get conn, post_path(conn, :new)
    assert html_response(conn, 200) =~ "New Post"
  end

  test "creates resources and redirects when data is valid", %{conn: conn, user: user} do
    conn = post conn, post_path(conn, :create), post: @valid_attrs
    post = Repo.get_by!(Post, @valid_attrs)
    assert post.user_id == user.id
    assert redirected_to(conn) == post_path(conn, :show, post)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, post_path(conn, :create), post: @invalid_attrs
    assert html_response(conn, 200) =~ "New Post"
  end

  test "renders edit page", %{conn: conn, user: user} do
    post = build_post(user)
    conn = get conn, post_path(conn, :edit, post)
    assert post.user_id == user.id
    assert html_response(conn, 200) =~ "Edit Post"
  end

  test "redirects to posts index when user cannot edit post", %{conn: conn, user: user, unauth_user: unauth_user} do
    conn = login_user(conn, unauth_user)

    post = build_post(user)
    conn = get conn, post_path(conn, :edit, post)
    refute post.user_id == unauth_user.id
    assert redirected_to(conn) == post_path(conn, :index)
  end

  test "updates the post with valid data", %{conn: conn, user: user} do
    post = build_post(user)
    conn = put conn, post_path(conn, :update, post), post: @valid_attrs
    assert redirected_to(conn) == post_path(conn, :show, post)
    assert Repo.get_by(Post, @valid_attrs)
  end

  test "redirects to posts index when user cannot update post - fail safe if user does PUT directly to path", %{conn: conn, user: user, unauth_user: unauth_user} do
    conn = login_user(conn, unauth_user)

    post = build_post(user)
    conn = put conn, post_path(conn, :update, post), post: @valid_attrs
    refute post.user_id == unauth_user.id
    assert redirected_to(conn) == post_path(conn, :index)
  end

  test "deletes chosen resources", %{conn: conn, user: user} do
    post = build_post(user)
    conn = delete conn, post_path(conn, :delete, post)
    assert redirected_to(conn) == post_path(conn, :index)
    refute Repo.get(Post, post.id)
  end

  test "redirects to post index when user cannot delete post", %{conn: conn, user: user, unauth_user: unauth_user} do
    conn = login_user(conn, unauth_user)

    post = build_post(user)
    conn = delete conn, post_path(conn, :delete, post)
    refute post.user_id == unauth_user.id
    assert redirected_to(conn) == post_path(conn, :index)
    assert Repo.get(Post, post.id)
  end
end
