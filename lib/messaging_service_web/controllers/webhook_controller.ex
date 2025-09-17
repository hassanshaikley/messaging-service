defmodule MessagingServiceWeb.WebhookController do
  use MessagingServiceWeb, :controller

  alias MessagingService.Messages
  alias MessagingService.Emails
  alias MessagingService.Consumer

  action_fallback MessagingServiceWeb.FallbackController

  @doc """
  Handles incoming SMS/MMS webhooks from messaging providers.

  This endpoint receives webhook calls from SMS/MMS providers when messages
  are received by the service (inbound messages).
  """
  def sms(conn, params) do
    with {:ok, message} <- Messages.create_message(params),
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

  @doc """
  Handles incoming email webhooks from email providers.

  This endpoint receives webhook calls from email providers when messages
  are received by the service (inbound emails).
  """
  def email(conn, params) do
    with {:ok, message} <- Emails.create_email(params),
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
end
