defmodule Rageq.PageControllerTest do
  use Rageq.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Hello World"
  end
end
