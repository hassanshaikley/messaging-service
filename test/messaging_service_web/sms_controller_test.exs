defmodule MessagingServiceWeb.SMSControllerTest do
  use MessagingServiceWeb.ConnCase

  alias MessagingService.Messages

  describe "POST /api/messages/sms" do
    test "creates a message with valid SMS data", %{conn: conn} do
      message_data = %{
        "from" => "+12016661234",
        "to" => "+18045551234",
        "type" => "sms",
        "body" => "Hello! This is a test SMS message.",
        "attachments" => nil,
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/messages/sms", message_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Message processed successfully"
             } = json_response(conn, 201)

      # Verify the message was created in the database
      message = Messages.get_message!(message_id)
      assert message.from == "+12016661234"
      assert message.to == "+18045551234"
      assert message.type == :sms
      assert message.body == "Hello! This is a test SMS message."
    end

    test "creates a message with MMS data including attachments", %{conn: conn} do
      message_data = %{
        "from" => "+12016661234",
        "to" => "+18045551234",
        "type" => "mms",
        "body" => "Check out this image!",
        "attachments" => ["https://example.com/image.jpg"],
        "messaging_provider_id" => "provider-123",
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/messages/sms", message_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Message processed successfully"
             } = json_response(conn, 201)

      # Verify the message was created in the database
      message = Messages.get_message!(message_id)
      assert message.from == "+12016661234"
      assert message.to == "+18045551234"
      assert message.type == :mms
      assert message.body == "Check out this image!"
      assert message.attachments == ["https://example.com/image.jpg"]
      assert message.messaging_provider_id == "provider-123"
    end

    test "handles missing required fields", %{conn: conn} do
      message_data = %{
        "from" => "+12016661234",
        "type" => "sms"
        # Missing 'to' and 'body' fields
      }

      conn = post(conn, ~p"/api/messages/sms", message_data)

      assert %{
               "message" => "Invalid data",
               "status" => "error",
               "errors" => %{"body" => ["can't be blank"], "to" => ["can't be blank"]}
             } = json_response(conn, 422)
    end

    test "handles invalid message data", %{conn: conn} do
      message_data = %{
        "from" => "",
        "to" => "",
        "type" => "invalid_type",
        "body" => ""
      }

      conn = post(conn, ~p"/api/messages/sms", message_data)

      assert %{
               "status" => "error",
               "message" => "Invalid data",
               "errors" => errors
             } = json_response(conn, 422)

      assert is_map(errors)
    end

    test "handles atom keys in parameters", %{conn: conn} do
      message_data = %{
        from: "+12016661234",
        to: "+18045551234",
        type: "sms",
        body: "Hello! This is a test SMS message."
      }

      conn = post(conn, ~p"/api/messages/sms", message_data)

      assert %{
               "status" => "success",
               "message_id" => _message_id,
               "message" => "Message processed successfully"
             } = json_response(conn, 201)
    end

    test "handles empty attachments array", %{conn: conn} do
      message_data = %{
        "from" => "+12016661234",
        "to" => "+18045551234",
        "type" => "mms",
        "body" => "No attachments",
        "attachments" => []
      }

      conn = post(conn, ~p"/api/messages/sms", message_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Message processed successfully"
             } = json_response(conn, 201)

      message = Messages.get_message!(message_id)
      assert message.attachments == []
    end
  end
end
