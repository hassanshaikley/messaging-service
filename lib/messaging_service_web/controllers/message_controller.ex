defmodule MessagingServiceWeb.MessageController do
  use MessagingServiceWeb, :controller

  alias MessagingService.Consumer
  alias MessagingService.Emails
  alias MessagingService.Messages

  action_fallback MessagingServiceWeb.FallbackController

  @doc """
  Handles incoming SMS/MMS/Email messages from messaging providers.

  This endpoint receives webhook calls from SMS/MMS/Email providers when messages
  are sent to or received by the service.
  """
  def create(conn, params) do
    with {:ok, message} <- create_entity(conn, params),
         :ok <- Consumer.process(message) do
      conn
      |> put_status(:created)
      |> json(%{
        status: "success",
        message_id: message.id,
        message: "Message processed successfully"
      })
    end
  end

  defp create_entity(conn, params) do
    case conn.path_info do
      ["api", "messages", "sms"] -> Messages.create_message(params)
      ["api", "messages", "mms"] -> Messages.create_message(params)
      ["api", "messages", "email"] -> Emails.create_email(params)
    end
  end
end
