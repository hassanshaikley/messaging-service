defmodule MessagingServiceWeb.PageControllerTest do
  use MessagingServiceWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Hello"
  end
end
