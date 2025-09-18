defmodule MessagingServiceWeb.ConversationController do
  use MessagingServiceWeb, :controller

  alias MessagingService.Conversations
  alias MessagingService.Messages

  action_fallback MessagingServiceWeb.FallbackController

  @doc """
  Lists all conversations ordered by last message time.
  """
  def index(conn, _params) do
    conversations = Conversations.list_conversations_ordered()

    conn
    |> put_status(:ok)
    |> json(%{
      status: "success",
      data: conversations
    })
  end

  @doc """
  Gets messages for a specific conversation.
  """
  def show(conn, %{"id" => conversation_id}) do
    with {:ok, conversation} <- get_conversation(conversation_id),
         messages <- get_conversation_messages(conversation) do
      conn
      |> put_status(:ok)
      |> json(%{
        status: "success",
        data: %{
          conversation: conversation,
          messages: messages
        }
      })
    end
  end

  defp get_conversation(conversation_id) do
    case Conversations.get_conversation!(conversation_id) do
      nil -> {:error, :not_found}
      conversation -> {:ok, conversation}
    end
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  defp get_conversation_messages(conversation) do
    Messages.list_messages_for_conversation(conversation.id)
  end
end
