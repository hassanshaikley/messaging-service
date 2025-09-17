defmodule MessagingServiceWeb.WebhookController do
  use MessagingServiceWeb, :controller

  alias MessagingService.Messages
  alias MessagingService.Emails
  alias MessagingService.Consumer

  action_fallback MessagingServiceWeb.FallbackController

  @doc """
  Handles incoming email webhooks from email providers.

  This endpoint receives webhook calls from email providers when messages
  are received by the service (inbound emails).
  """
  def create(conn, params) do
    with {:ok, message} <- create_entity(conn, params),
         :ok <- Consumer.process(message) do
      conn
      |> put_status(:ok)
      |> json(%{
        status: "success",
        message_id: message.id,
        message: "Webhook processed successfully"
      })
    end
  end

  defp create_entity(conn, params) do
    case conn.path_info do
      ["api", "webhooks", "sms"] -> Messages.create_message(params)
      ["api", "webhooks", "mms"] -> Messages.create_message(params)
      ["api", "webhooks", "email"] -> Emails.create_email(params)
    end
  end
end
