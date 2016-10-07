defmodule Rageq.UserControllerTest do
  use Rageq.ConnCase

  alias Rageq.User

  @valid_create_attrs %{
    email: "some content",
    name: "some content",
    username: "epicname",
    password: "123",
    password_confirmation: "123"
  }
  @valid_attrs %{
    email: "some content",
    name: "some content",
    username: "epicname"
  }
  @invalid_attrs %{}

  test "shows a list of users", %{conn: conn} do
    get conn, user_path(conn, :index)
    assert Repo.all(User)
  end

  test "show a single user", %{conn: conn} do
    user = Repo.insert!(%User{})
    conn = get conn, user_path(conn, :show, user)
    assert html_response(conn, 200) =~ "Show User"
  end

  test "create user with redirect to list page", %{conn: conn} do
    conn = post conn, user_path(conn, :create), user: @valid_create_attrs
    assert redirected_to(conn) == user_path(conn, :index)
    assert Repo.get_by(User, @valid_attrs)
  end

  test "edit page renders current user", %{conn: conn} do
    user = Repo.insert! %User{}
    conn = get conn, user_path(conn, :edit, user)
    assert html_response(conn, 200) =~ "Edit User"
  end

  test "updates chosen resource with redirect when data valid", %{conn: conn} do
    user = Repo.insert! %User{}
    conn = put conn, user_path(conn, :update, user), user: @valid_create_attrs
    assert redirected_to(conn) == user_path(conn, :show, user)
    assert Repo.get_by(User, @valid_attrs)
  end

  test "renders edit when update fails", %{conn: conn} do
    user = Repo.insert!(%User{})
    conn = put conn, user_path(conn, :update, user), user: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit User"
  end

  test "delete user record", %{conn: conn} do
    user = Repo.insert!(%User{})
    conn = delete conn, user_path(conn, :delete, user)
    assert redirected_to(conn) == user_path(conn, :index)
    assert get_flash(conn, :info) == "User has been deleted."
    refute Repo.get(User, user.id)
  end
end
