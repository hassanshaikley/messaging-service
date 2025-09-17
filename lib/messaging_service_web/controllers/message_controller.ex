defmodule MessagingServiceWeb.MessageController do
  use MessagingServiceWeb, :controller

  alias MessagingService.Consumer
  alias MessagingService.Emails
  alias MessagingService.Messages
  alias MessagingService.Conversations

  action_fallback MessagingServiceWeb.FallbackController

  @doc """
  Handles incoming SMS/MMS/Email messages from messaging providers.

  This endpoint receives webhook calls from SMS/MMS/Email providers when messages
  are sent to or received by the service.
  """
  def create(conn, params) do
    with {:ok, conversation} <- get_or_create_conversation(params),
         {:ok, message} <-
           create_entity(conn, Map.put(params, "conversation_id", conversation.id)),
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

  defp get_or_create_conversation(params) do
    from = Map.get(params, "from")
    to = Map.get(params, "to")

    Conversations.create_conversation(%{participants: [from, to]})
  end

  defp create_entity(conn, params) do
    case conn.path_info do
      ["api", "messages", "sms"] -> Messages.create_message(params)
      ["api", "messages", "mms"] -> Messages.create_message(params)
      ["api", "messages", "email"] -> Emails.create_email(params)
    end
  end
end
