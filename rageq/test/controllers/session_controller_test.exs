defmodule Rageq.SessionControllerTest do
  use Rageq.ConnCase
  alias Rageq.User

  setup do
    User.changeset(%User{}, %{name: "tester", username: "test", password: "123", password_confirmation: "123", email: "hello@world.foo"})
    |> Repo.insert!
    {:ok, conn: build_conn()}
  end

  test "shows the login form", %{conn: conn} do
    conn = get conn, session_path(conn, :new)
    assert html_response(conn, 200) =~ "Login"
  end

  test "creates a new session if user is valid", %{conn: conn} do
    conn = post conn, session_path(conn, :create), user: %{username: "test", password: "123"}
    assert get_session(conn, :current_user)
    assert get_flash(conn, :info) == "Sign in success."
    assert redirected_to(conn) == post_path(conn, :index)
  end

  test "does not create session if bad login", %{conn: conn} do
    conn = post conn, session_path(conn, :create), user: %{username: "test", password: "bacon"}
    refute get_session(conn, :current_user)
    assert get_flash(conn, :error) == "Invalid username/password combination"
    assert redirected_to(conn) == session_path(conn, :new)
  end

  test "does not create session if user doesn't exist", %{conn: conn} do
    conn = post conn, session_path(conn, :create), user: %{username: "cake", password: "bacon"}
    assert get_flash(conn, :error) == "Invalid username/password combination"
    assert redirected_to(conn) == session_path(conn, :new)
  end

  test "Deletes user session", %{conn: conn} do
    user = Repo.insert!(%User{})
    conn = delete conn, session_path(conn, :delete, user.id)
    refute get_session(conn, :current_user)
    assert get_flash(conn, :info) == "Logged out."
    assert redirected_to(conn) == session_path(conn, :new)
  end
end
