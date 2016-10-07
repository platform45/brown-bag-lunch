defmodule Rageq.PostController do
  use Rageq.Web, :controller
  alias Rageq.Post
  alias Rageq.User
  alias Plug.Conn
  alias Rageq.Comment
  import Rageq.Router.Helpers

  def index conn, _params do
    posts = Repo.all(Post) |> Repo.preload(:comments)
    render conn, "index.html", posts: posts
  end

  def show(conn, %{"id" => id}) do
    post = Repo.get(Post, id) |> Repo.preload([:comments, comments: :user])
    render conn, "show.html", post: post, current_user: current_user(conn).id
  end

  def new conn, _params do
    changeset =
      conn
      |> current_user
      |> build_assoc(:posts)
      |> Post.changeset()
    render conn, "new.html", changeset: changeset
  end

  def create conn, %{"post" => post_params} do
    changeset =
      conn
      |> current_user
      |> build_assoc(:posts)
      |> Post.changeset(post_params)

    case Repo.insert(changeset) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post Created")
        |> redirect(to: post_path(conn, :show, post))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    post      = Repo.get(Post, id)
    changeset = Post.changeset(post)

    case authorize_post_access(conn, post) do
      {:ok, _post} -> render(conn, "edit.html", post: post, changeset: changeset)
      {:error}     -> redirect(conn, to: post_path(conn, :index))
    end
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    post      = Repo.get!(Post, id)
    changeset = Post.changeset(post, post_params)

    case authorize_post_access(conn, post) do
      {:ok, _post} -> update_post(conn, changeset, post)
      {:error}     -> redirect(conn, to: post_path(conn, :index))
    end
  end

  def delete(conn, %{"id" => id}) do
    post = Repo.get(Post, id)

    case authorize_post_access(conn, post) do
      {:ok, _post} ->
        Repo.delete!(post)
        conn
        |> put_flash(:info, "Post Deleted")
        |> redirect(to: post_path(conn, :index))

      {:error}     -> redirect(conn, to: post_path(conn, :index))
    end
  end

  defp current_user(conn) do
    Repo.get!(User, Plug.Conn.get_session(conn, :current_user).id)
  end

  defp update_post(conn, changeset, post) do
    case Repo.update(changeset) do
      {:ok, _post} ->
        conn
        |> put_flash(:info, "Updated Post")
        |> redirect(to: post_path(conn, :show, post))
      {:error, changeset} ->
        render(conn, "edit.html", post: post, changeset: changeset)
    end
  end

  defp authorize_post_access(conn, post) do
    user = current_user(conn)
    if user && user.id == post.user_id do
      conn
      {:ok, post: post}
    else
      conn
        |> put_flash(:error, "You are trying to access a post you didn't create. You have no power here.")
      {:error}
    end
  end
end
