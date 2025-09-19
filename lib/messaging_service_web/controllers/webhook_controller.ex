defmodule MessagingServiceWeb.WebhookController do
  use MessagingServiceWeb, :controller

  alias MessagingService.Consumer
  alias MessagingService.Conversations
  alias MessagingService.Messages

  action_fallback MessagingServiceWeb.FallbackController

  @doc """
  Handles incoming email webhooks from email providers.

  This endpoint receives webhook calls from email providers when messages
  are received by the service (inbound emails).
  """
  def create(conn, params) do
    with {:ok, conversation} <- get_or_create_conversation(params),
         {:ok, message} <-
           Messages.create_message(
             Map.merge(params, %{
               "conversation_id" => conversation.id,
               "type" => get_type(conn)
             })
           ),
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

  defp get_or_create_conversation(params) do
    from = Map.get(params, "from")
    to = Map.get(params, "to")

    Conversations.create_conversation(%{participants: [from, to]})
  end

  defp get_type(conn) do
    List.last(conn.path_info) |> String.to_existing_atom()
  end
end
