defmodule MessagingServiceWeb.SMSControllerTest do
  use MessagingServiceWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn =
      post(conn, ~p"/api/messages/sms",
        post: %{
          from: "+12016661234",
          to: "+18045551234",
          type: "sms",
          body: "Hello! This is a test SMS message.",
          attachments: nil,
          timestamp: "2024-11-01T14:00:00Z"
        }
      )
      |> IO.inspect()
  end
end
