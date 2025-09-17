defmodule MessagingService.ConversationTest do
  use MessagingService.DataCase

  alias MessagingService.Conversation

  describe "changeset/2" do
    test "valid changeset with valid participants" do
      attrs = %{
        participants: ["+12016661234", "+18045551234"]
      }

      changeset = Conversation.changeset(%Conversation{}, attrs)
      assert changeset.valid?
    end

    test "normalizes participants by sorting them" do
      attrs = %{
        participants: ["+18045551234", "+12016661234"]
      }

      changeset = Conversation.changeset(%Conversation{}, attrs)
      assert changeset.valid?
      assert changeset.changes.participants == ["+12016661234", "+18045551234"]
    end

    test "invalid changeset with duplicate participants" do
      attrs = %{
        participants: ["+12016661234", "+12016661234"]
      }

      changeset = Conversation.changeset(%Conversation{}, attrs)
      refute changeset.valid?
      assert "participants must be different" in errors_on(changeset).participants
    end

    test "invalid changeset with empty participants" do
      attrs = %{
        participants: ["+12016661234", ""]
      }

      changeset = Conversation.changeset(%Conversation{}, attrs)
      refute changeset.valid?
      assert "should have at least 2 item(s)" in errors_on(changeset).participants
    end

    test "invalid changeset with too few participants" do
      attrs = %{
        participants: ["+12016661234"]
      }

      changeset = Conversation.changeset(%Conversation{}, attrs)
      refute changeset.valid?
      assert "should have at least 2 item(s)" in errors_on(changeset).participants
    end

    test "invalid changeset with too many participants" do
      attrs = %{
        participants: ["+12016661234", "+18045551234", "+19035551234"]
      }

      changeset = Conversation.changeset(%Conversation{}, attrs)
      refute changeset.valid?
      assert "should have at most 2 item(s)" in errors_on(changeset).participants
    end

    test "invalid changeset without participants" do
      changeset = Conversation.changeset(%Conversation{}, %{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).participants
    end
  end

  describe "conversation_key/2" do
    test "generates consistent key regardless of parameter order" do
      key1 = Conversation.conversation_key("+12016661234", "+18045551234")
      key2 = Conversation.conversation_key("+18045551234", "+12016661234")

      assert key1 == key2
      assert key1 == "+12016661234|+18045551234"
    end
  end

  describe "extract_participants/1" do
    test "extracts participants from message with from and to fields" do
      message = %{from: "+12016661234", to: "+18045551234"}
      participants = Conversation.extract_participants(message)

      assert participants == ["+12016661234", "+18045551234"]
    end

    test "normalizes participants by sorting" do
      message = %{from: "+18045551234", to: "+12016661234"}
      participants = Conversation.extract_participants(message)

      assert participants == ["+12016661234", "+18045551234"]
    end

    test "returns nil for invalid message structure" do
      message = %{invalid: "structure"}
      participants = Conversation.extract_participants(message)

      assert participants == nil
    end
  end
end
