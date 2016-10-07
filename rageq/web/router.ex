defmodule Rageq.Router do
  use Rageq.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Rageq do
    pipe_through :browser # Use the default browser stack

    get       "/",         PostController,    :index
    resources "/posts",    PostController,    except: [:index] do
      resources "/comments", CommentController, only: [:create, :delete]
    end
    resources "/users",    UserController
    resources "/sessions", SessionController, only: [:new, :create, :delete]
  end

  # Other scopes may use custom stacks.
  # scope "/api", Rageq do
  #   pipe_through :api
  # end
end
