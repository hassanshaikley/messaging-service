defmodule MessagingServiceWeb.ConversationControllerTest do
  use MessagingServiceWeb.ConnCase

  alias MessagingService.Conversations
  alias MessagingService.Messages

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "GET /api/conversations" do
    test "lists all conversations", %{conn: conn} do
      # Create some test conversations
      {:ok, conversation1} =
        Conversations.create_conversation(%{
          participants: ["+19016661234", "+18949551234"]
        })

      {:ok, conversation2} =
        Conversations.create_conversation(%{
          participants: ["+19035551234", "+18949551234"]
        })

      conn = get(conn, ~p"/api/conversations")

      assert %{
               "status" => "success",
               "data" => conversations
             } = json_response(conn, 200)

      assert length(conversations) == 2
      assert Enum.any?(conversations, &(&1["id"] == conversation1.id))
      assert Enum.any?(conversations, &(&1["id"] == conversation2.id))
    end

    test "returns empty list when no conversations exist", %{conn: conn} do
      MessagingService.Repo.all(MessagingService.Conversation)

      conn = get(conn, ~p"/api/conversations")

      assert %{
               "status" => "success",
               "data" => []
             } = json_response(conn, 200)
    end
  end

  describe "GET /api/conversations/:id/messages" do
    test "gets messages for a specific conversation", %{conn: conn} do
      # Create a conversation
      {:ok, conversation} =
        Conversations.create_conversation(%{
          participants: ["+12556661234", "+18045551234"]
        })

      # Create some messages for this conversation
      {:ok, message1} =
        Messages.create_message(%{
          from: "+12556661234",
          to: "+18045551234",
          type: :sms,
          body: "Hello there!",
          conversation_id: conversation.id
        })

      {:ok, message2} =
        Messages.create_message(%{
          from: "+18045551234",
          to: "+12556661234",
          type: :sms,
          body: "Hi back!",
          conversation_id: conversation.id
        })

      conn = get(conn, ~p"/api/conversations/#{conversation.id}/messages")

      assert %{
               "status" => "success",
               "data" => %{
                 "conversation" => conversation_data,
                 "messages" => messages
               }
             } = json_response(conn, 200)

      assert conversation_data["id"] == conversation.id
      assert conversation_data["participants"] == ["+12556661234", "+18045551234"]

      assert length(messages) == 2
      assert Enum.any?(messages, &(&1["id"] == message1.id))
      assert Enum.any?(messages, &(&1["id"] == message2.id))
    end

    test "returns 404 for non-existent conversation", %{conn: conn} do
      conn = get(conn, ~p"/api/conversations/999999/messages")

      assert %{
               "status" => "error",
               "message" => "Not Found"
             } = json_response(conn, 404)
    end

    test "returns empty messages list for conversation with no messages", %{conn: conn} do
      {:ok, conversation} =
        Conversations.create_conversation(%{
          participants: ["+12016661234", "+18045551234"]
        })

      conn = get(conn, ~p"/api/conversations/#{conversation.id}/messages")

      assert %{
               "status" => "success",
               "data" => %{
                 "conversation" => conversation_data,
                 "messages" => []
               }
             } = json_response(conn, 200)

      assert conversation_data["id"] == conversation.id
    end
  end
end
