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
           Messages.create_message(
             Map.merge(params, %{
               "conversation_id" => conversation.id,
               "type" => get_type(conn)
             })
           ),
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

  defp get_type(conn) do
    List.last(conn.path_info) |> String.to_existing_atom()
  end
end
