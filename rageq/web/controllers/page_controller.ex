defmodule Rageq.PageController do
  use Rageq.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
