defmodule MessagingServiceWeb.SMSController do
  use MessagingServiceWeb, :controller

  def create(conn, _params) do
    json(conn, %{HEllo: "world"})
  end
end
