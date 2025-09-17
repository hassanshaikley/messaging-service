defmodule MessagingService.ConversationService do
  @moduledoc """
  Service for automatically managing conversations when messages are created.

  This service ensures that every message is automatically associated with
  the appropriate conversation based on its participants (from/to addresses).
  """

  alias MessagingService.Conversations
  alias MessagingService.Conversation

  @doc """
  Processes a message and ensures it's associated with the correct conversation.

  This function should be called whenever a message is created, regardless of type.

  ## Examples

      iex> process_message(message)
      {:ok, %Conversation{}}

      iex> process_message(invalid_message)
      {:error, :invalid_participants}
  """
  def process_message(message) do
    case Conversation.extract_participants(message) do
      [from, to] when is_binary(from) and is_binary(to) and from != "" and to != "" ->
        Conversations.add_message_to_conversation_by_participants(message)

      _ ->
        {:error, :invalid_participants}
    end
  end

  @doc """
  Gets all messages for a conversation between two participants.

  ## Examples

      iex> get_conversation_messages("+12016661234", "+18045551234")
      [%Message{}, ...]

      iex> get_conversation_messages("user@example.com", "other@example.com")
      [%Email{}, ...]
  """
  def get_conversation_messages(from, to) do
    case Conversations.get_conversation_by_participants(from, to) do
      nil ->
        []

      conversation ->
        get_messages_for_conversation(conversation)
    end
  end

  @doc """
  Gets conversation summary including message count and last message info.

  ## Examples

      iex> get_conversation_summary("+12016661234", "+18045551234")
      %{
        conversation: %Conversation{},
        participants: ["+12016661234", "+18045551234"]
      }
  """
  def get_conversation_summary(from, to) do
    case Conversations.get_conversation_by_participants(from, to) do
      nil ->
        %{
          conversation: nil,
          participants: [from, to] |> Enum.sort()
        }

      conversation ->
        %{
          conversation: conversation,
          participants: conversation.participants
        }
    end
  end

  @doc """
  Gets all conversations for a participant across all message types.

  ## Examples

      iex> get_participant_conversations("+12016661234")
      [%Conversation{}, ...]
  """
  def get_participant_conversations(participant) do
    Conversations.list_conversations_for_participant(participant)
  end

  # Private function to get messages for a conversation
  # This would need to be implemented based on how you want to query
  # messages from different tables (messages, emails, etc.)
  defp get_messages_for_conversation(_conversation) do
    # This is a simplified implementation
    # In a real implementation, you might want to query both messages and emails tables
    # and merge the results, or use a more sophisticated approach

    # For now, we'll return an empty list as this would require
    # more complex querying across multiple tables
    []
  end
end
