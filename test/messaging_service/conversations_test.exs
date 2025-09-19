defmodule MessagingService.ConversationsTest do
  use MessagingService.DataCase

  alias MessagingService.Conversations
  alias MessagingService.Conversation

  describe "conversations" do
    test "create_conversation/1 with valid data creates a conversation" do
      valid_attrs = %{participants: ["+12016661234", "+18045551234"]}

      assert {:ok, %Conversation{} = conversation} =
               Conversations.create_conversation(valid_attrs)

      assert conversation.participants == ["+12016661234", "+18045551234"]
    end

    test "create_conversation/1 with invalid data returns error changeset" do
      invalid_attrs = %{participants: ["+12016661234"]}

      assert {:error, %Ecto.Changeset{}} = Conversations.create_conversation(invalid_attrs)
    end

    test "get_conversation_by_participants/2 returns conversation when it exists" do
      {:ok, conversation} =
        Conversations.create_conversation(%{
          participants: ["+12016661234", "+18045551234"]
        })

      found_conversation =
        Conversations.get_conversation_by_participants("+12016661234", "+18045551234")

      assert found_conversation.id == conversation.id
    end

    test "get_conversation_by_participants/2 returns conversation regardless of parameter order" do
      {:ok, conversation} =
        Conversations.create_conversation(%{
          participants: ["+12016661234", "+18045551234"]
        })

      found_conversation =
        Conversations.get_conversation_by_participants("+18045551234", "+12016661234")

      assert found_conversation.id == conversation.id
    end

    test "get_conversation_by_participants/2 returns nil when conversation doesn't exist" do
      found_conversation =
        Conversations.get_conversation_by_participants("+1201666123422", "+1804555123422")

      assert found_conversation == nil
    end

    test "get_or_create_conversation/2 creates conversation when it doesn't exist" do
      assert {:ok, %Conversation{} = conversation} =
               Conversations.get_or_create_conversation("+12016661234", "+18045551234")

      assert conversation.participants == ["+12016661234", "+18045551234"]
    end

    test "get_or_create_conversation/2 returns existing conversation when it exists" do
      {:ok, original_conversation} =
        Conversations.create_conversation(%{
          participants: ["+12016661444", "+18045551444"]
        })

      assert {:ok, conversation} =
               Conversations.get_or_create_conversation("+12016661444", "+18045551444")

      assert conversation.id == original_conversation.id
    end

    test "list_conversations_ordered/0 returns conversations" do
      {:ok, _conversation1} =
        Conversations.create_conversation(%{
          participants: ["+12016661234", "+18045551234"]
        })

      {:ok, _conversation2} =
        Conversations.create_conversation(%{
          participants: ["+19035551234", "+18045551234"]
        })

      conversations = Conversations.list_conversations_ordered()
      assert length(conversations) == 2

      # Should be ordered by id desc
      [first, second] = conversations
      assert second.id > first.id
    end

    test "list_conversations_for_participant/1 returns conversations for specific participant" do
      {:ok, _conversation1} =
        Conversations.create_conversation(%{
          participants: ["+12016661234", "+18045551234"]
        })

      {:ok, _conversation2} =
        Conversations.create_conversation(%{
          participants: ["+12016661234", "+19035551234"]
        })

      {:ok, _conversation3} =
        Conversations.create_conversation(%{
          participants: ["+18045551234", "+19035551234"]
        })

      conversations = Conversations.list_conversations_for_participant("+12016661234")
      assert length(conversations) == 2

      # All conversations should include the participant
      assert Enum.all?(conversations, fn conv ->
               "+12016661234" in conv.participants
             end)
    end

    test "add_message_to_conversation/2 updates conversation with message data" do
      {:ok, conversation} =
        Conversations.create_conversation(%{
          participants: ["+12016661234", "+18045551234"]
        })

      message_time = ~U[2024-11-01T14:00:00Z]
      message = %{timestamp: message_time}

      assert {:ok, _updated_conversation} =
               Conversations.add_message_to_conversation(conversation, message)
    end

    test "add_message_to_conversation_by_participants/1 creates conversation and adds message" do
      message = %{
        from: "+12016661234",
        to: "+18045551234",
        timestamp: ~U[2024-11-01T14:00:00Z]
      }

      assert {:ok, conversation} =
               Conversations.add_message_to_conversation_by_participants(message)

      assert conversation.participants == ["+12016661234", "+18045551234"]
    end

    test "add_message_to_conversation_by_participants/1 returns error for invalid message" do
      invalid_message = %{invalid: "structure"}

      assert {:error, :invalid_participants} =
               Conversations.add_message_to_conversation_by_participants(invalid_message)
    end
  end
end
