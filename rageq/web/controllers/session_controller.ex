defmodule Rageq.SessionController do
  use Rageq.Web, :controller
  alias Rageq.User
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]

  # Scrubs user input, converts '' to nil values
  plug :scrub_params, "user" when action in [:create]

  def new(conn, _params) do
    render conn, "new.html", changeset: User.changeset(%User{})
  end

  def create(conn, %{"user" => %{"username" => username, "password" => password}}) when not is_nil(username) and not is_nil(password) do
    Repo.get_by(User, username: username)
    |> sign_in(password, conn)
  end

  def create(conn, _) do
    failed_login(conn)
  end

  def delete(conn, _params) do
    conn
    |> delete_session(:current_user)
    |> put_flash(:info, "Logged out.")
    |> redirect(to: session_path(conn, :new))
  end

  # Important to note the order of the methods
  # The first method is essentially a guard clause
  # This will be evaluated first,
  # if it doesn't match it will skip to the next method
  defp sign_in(user, _password, conn) when is_nil(user) do
    failed_login(conn)
  end

  defp sign_in(user, password, conn) do
    if checkpw(password, user.password_digest) do
      conn
      |> put_session(:current_user, %{id: user.id, username: user.username})
      |> put_flash(:info, "Sign in success.")
      |> redirect(to: post_path(conn, :index))
    else
      failed_login(conn)
    end
  end

  defp failed_login(conn) do
    dummy_checkpw()
    conn
    |> put_session(:current_user, nil)
    |> put_flash(:error, "Invalid username/password combination")
    |> redirect(to: session_path(conn, :new))
    |> halt()
  end
end
