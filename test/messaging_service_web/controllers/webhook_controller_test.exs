defmodule MessagingServiceWeb.WebhookControllerTest do
  use MessagingServiceWeb.ConnCase

  alias MessagingService.Messages

  describe "POST /api/webhooks/sms" do
    test "processes incoming SMS webhook", %{conn: conn} do
      webhook_data = %{
        "from" => "+18045551234",
        "to" => "+12016661234",
        "type" => "sms",
        "messaging_provider_id" => "message-1",
        "body" => "This is an incoming SMS message",
        "attachments" => nil,
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/webhooks/sms", webhook_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Webhook processed successfully"
             } = json_response(conn, 200)

      # Verify the message was created in the database
      message = Messages.get_message!(message_id)
      assert message.from == "+18045551234"
      assert message.to == "+12016661234"
      assert message.type == :sms
      assert message.body == "This is an incoming SMS message"
      assert message.remote_id == "message-1"
      assert message.attachments == nil
    end

    test "processes incoming SMS webhook with attachments", %{conn: conn} do
      webhook_data = %{
        "from" => "+18045551234",
        "to" => "+12016661234",
        "type" => "mms",
        "messaging_provider_id" => "message-2",
        "body" => "Check out this image!",
        "attachments" => ["https://example.com/image.jpg"],
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/webhooks/sms", webhook_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Webhook processed successfully"
             } = json_response(conn, 200)

      # Verify the message was created in the database
      message = Messages.get_message!(message_id)
      assert message.from == "+18045551234"
      assert message.to == "+12016661234"
      assert message.type == :sms
      assert message.body == "Check out this image!"
      assert message.remote_id == "message-2"
      assert message.attachments == ["https://example.com/image.jpg"]
    end

    test "handles missing required fields in webhook", %{conn: conn} do
      webhook_data = %{
        "from" => "+18045551234",
        "type" => "sms"
        # Missing 'to' and 'body' fields
      }

      conn = post(conn, ~p"/api/webhooks/sms", webhook_data)

      assert %{
               "message" => "Invalid data",
               "status" => "error",
               "errors" => %{"body" => ["can't be blank"], "to" => ["can't be blank"]}
             } = json_response(conn, 422)
    end

    test "handles invalid webhook data", %{conn: conn} do
      webhook_data = %{
        "from" => "",
        "to" => "",
        "type" => "invalid_type",
        "body" => ""
      }

      conn = post(conn, ~p"/api/webhooks/sms", webhook_data)

      assert %{
               "status" => "error",
               "message" => "Invalid data",
               "errors" => errors
             } = json_response(conn, 422)

      assert is_map(errors)
    end

    test "handles atom keys in webhook parameters", %{conn: conn} do
      webhook_data = %{
        from: "+18045551234",
        to: "+12016661234",
        type: "sms",
        body: "This is an incoming SMS with atom keys",
        messaging_provider_id: "message-3",
        timestamp: DateTime.utc_now()
      }

      conn = post(conn, ~p"/api/webhooks/sms", webhook_data)

      assert %{
               "status" => "success",
               "message_id" => _message_id,
               "message" => "Webhook processed successfully"
             } = json_response(conn, 200)
    end

    test "handles webhook without messaging_provider_id", %{conn: conn} do
      webhook_data = %{
        "from" => "+18045551234",
        "to" => "+12016661234",
        "type" => "sms",
        "body" => "SMS without provider ID"
      }

      conn = post(conn, ~p"/api/webhooks/sms", webhook_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Webhook processed successfully"
             } = json_response(conn, 200)

      # Verify the message was created without messaging_provider_id
      message = Messages.get_message!(message_id)
      assert message.remote_id == nil
    end

    test "handles webhook with empty attachments", %{conn: conn} do
      webhook_data = %{
        "from" => "+18045551234",
        "to" => "+12016661234",
        "type" => "mms",
        "body" => "MMS with empty attachments",
        "attachments" => [],
        "messaging_provider_id" => "message-4",
        "timestamp" => DateTime.utc_now()
      }

      conn = post(conn, ~p"/api/webhooks/sms", webhook_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Webhook processed successfully"
             } = json_response(conn, 200)

      message = Messages.get_message!(message_id)
      assert message.attachments == []
    end
  end

  describe "POST /api/webhooks/email" do
    test "processes incoming email webhook", %{conn: conn} do
      webhook_data = %{
        "from" => "sender@example.com",
        "to" => "recipient@example.com",
        "xillio_id" => "email-123",
        "body" => "This is an incoming email message with <b>HTML</b> content.",
        "attachments" => ["https://example.com/document.pdf"],
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/webhooks/email", webhook_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Webhook processed successfully"
             } = json_response(conn, 200)

      # Verify the message was created in the database
      email = Messages.get_message!(message_id)
      assert email.from == "sender@example.com"
      assert email.to == "recipient@example.com"
      assert email.body == "This is an incoming email message with <b>HTML</b> content."
      assert email.attachments == ["https://example.com/document.pdf"]
    end

    test "processes incoming email webhook without attachments", %{conn: conn} do
      webhook_data = %{
        "from" => "simple@example.com",
        "to" => "recipient@example.com",
        "xillio_id" => "email-456",
        "body" => "Simple email without attachments",
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/webhooks/email", webhook_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Webhook processed successfully"
             } = json_response(conn, 200)

      # Verify the message was created in the database
      email = Messages.get_message!(message_id)
      assert email.from == "simple@example.com"
      assert email.to == "recipient@example.com"
      assert email.body == "Simple email without attachments"
      assert email.attachments == nil
    end

    test "handles missing required fields in email webhook", %{conn: conn} do
      webhook_data = %{
        "from" => "sender@example.com"
        # Missing 'to' and 'body' fields
      }

      conn = post(conn, ~p"/api/webhooks/email", webhook_data)

      assert %{
               "message" => "Invalid data",
               "status" => "error",
               "errors" => %{"body" => ["can't be blank"], "to" => ["can't be blank"]}
             } = json_response(conn, 422)
    end

    test "handles email webhook with multiple attachments", %{conn: conn} do
      webhook_data = %{
        "from" => "sender@company.com",
        "to" => "recipient@company.com",
        "xillio_id" => "email-789",
        "body" => "Email with multiple attachments",
        "attachments" => [
          "https://example.com/doc1.pdf",
          "https://example.com/doc2.docx",
          "https://example.com/image.png"
        ],
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/webhooks/email", webhook_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Webhook processed successfully"
             } = json_response(conn, 200)

      # Verify the message was created in the database
      email = Messages.get_message!(message_id)
      assert email.from == "sender@company.com"
      assert email.to == "recipient@company.com"
      assert email.body == "Email with multiple attachments"
      assert length(email.attachments) == 3
      assert "https://example.com/doc1.pdf" in email.attachments
      assert "https://example.com/doc2.docx" in email.attachments
      assert "https://example.com/image.png" in email.attachments
    end

    test "handles email webhook without xillio_id", %{conn: conn} do
      webhook_data = %{
        "from" => "sender@example.com",
        "to" => "recipient@example.com",
        "body" => "Email without xillio_id"
      }

      conn = post(conn, ~p"/api/webhooks/email", webhook_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Webhook processed successfully"
             } = json_response(conn, 200)

      # Verify the message was created without xillio_id
      email = Messages.get_message!(message_id)
      assert email.remote_id == nil
    end

    test "handles invalid email webhook data", %{conn: conn} do
      webhook_data = %{
        "from" => "",
        "to" => "",
        "body" => ""
      }

      conn = post(conn, ~p"/api/webhooks/email", webhook_data)

      assert %{
               "status" => "error",
               "message" => "Invalid data",
               "errors" => errors
             } = json_response(conn, 422)

      assert is_map(errors)
    end
  end

  describe "POST /api/webhooks/mms" do
    test "processes incoming MMS webhook with attachments", %{conn: conn} do
      webhook_data = %{
        "from" => "+18045551234",
        "to" => "+12016661234",
        "type" => "mms",
        "messaging_provider_id" => "mms-message-1",
        "body" => "Check out this image!",
        "attachments" => ["https://example.com/image.jpg", "https://example.com/video.mp4"],
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/webhooks/mms", webhook_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Webhook processed successfully"
             } = json_response(conn, 200)

      # Verify the message was created in the database
      message = Messages.get_message!(message_id)
      assert message.from == "+18045551234"
      assert message.to == "+12016661234"
      assert message.type == :mms
      assert message.body == "Check out this image!"
      assert message.remote_id == "mms-message-1"

      assert message.attachments == [
               "https://example.com/image.jpg",
               "https://example.com/video.mp4"
             ]
    end

    test "processes incoming MMS webhook without attachments", %{conn: conn} do
      webhook_data = %{
        "from" => "+18045551234",
        "to" => "+12016661234",
        "type" => "mms",
        "messaging_provider_id" => "mms-message-2",
        "body" => "This is an MMS without attachments",
        "attachments" => [],
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/webhooks/mms", webhook_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Webhook processed successfully"
             } = json_response(conn, 200)

      # Verify the message was created in the database
      message = Messages.get_message!(message_id)
      assert message.from == "+18045551234"
      assert message.to == "+12016661234"
      assert message.type == :mms
      assert message.body == "This is an MMS without attachments"
      assert message.remote_id == "mms-message-2"
      assert message.attachments == []
    end

    test "processes incoming MMS webhook with null attachments", %{conn: conn} do
      webhook_data = %{
        "from" => "+18045551234",
        "to" => "+12016661234",
        "type" => "mms",
        "messaging_provider_id" => "mms-message-3",
        "body" => "This is an MMS with null attachments",
        "attachments" => nil,
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/webhooks/mms", webhook_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Webhook processed successfully"
             } = json_response(conn, 200)

      # Verify the message was created in the database
      message = Messages.get_message!(message_id)
      assert message.from == "+18045551234"
      assert message.to == "+12016661234"
      assert message.type == :mms
      assert message.body == "This is an MMS with null attachments"
      assert message.remote_id == "mms-message-3"
      assert message.attachments == nil
    end

    test "handles missing required fields in MMS webhook", %{conn: conn} do
      webhook_data = %{
        "from" => "+18045551234",
        "type" => "mms"
        # Missing 'to' and 'body' fields
      }

      conn = post(conn, ~p"/api/webhooks/mms", webhook_data)

      assert %{
               "message" => "Invalid data",
               "status" => "error",
               "errors" => %{"body" => ["can't be blank"], "to" => ["can't be blank"]}
             } = json_response(conn, 422)
    end

    test "handles invalid MMS webhook data", %{conn: conn} do
      webhook_data = %{
        "from" => "",
        "to" => "",
        "type" => "invalid_type",
        "body" => ""
      }

      conn = post(conn, ~p"/api/webhooks/mms", webhook_data)

      assert %{
               "status" => "error",
               "message" => "Invalid data",
               "errors" => errors
             } = json_response(conn, 422)

      assert is_map(errors)
    end

    test "handles atom keys in MMS webhook parameters", %{conn: conn} do
      webhook_data = %{
        from: "+18045551234",
        to: "+12016661234",
        type: "mms",
        body: "This is an incoming MMS with atom keys",
        messaging_provider_id: "mms-message-4",
        attachments: ["https://example.com/image.jpg"],
        timestamp: DateTime.utc_now()
      }

      conn = post(conn, ~p"/api/webhooks/mms", webhook_data)

      assert %{
               "status" => "success",
               "message_id" => _message_id,
               "message" => "Webhook processed successfully"
             } = json_response(conn, 200)
    end

    test "handles MMS webhook without messaging_provider_id", %{conn: conn} do
      webhook_data = %{
        "from" => "+18045551234",
        "to" => "+12016661234",
        "type" => "mms",
        "body" => "MMS without provider ID",
        "attachments" => ["https://example.com/image.jpg"]
      }

      conn = post(conn, ~p"/api/webhooks/mms", webhook_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Webhook processed successfully"
             } = json_response(conn, 200)

      # Verify the message was created without messaging_provider_id
      message = Messages.get_message!(message_id)
      assert message.remote_id == nil
    end

    test "handles MMS webhook with large attachment arrays", %{conn: conn} do
      attachments = for i <- 1..5, do: "https://example.com/image#{i}.jpg"

      webhook_data = %{
        "from" => "+18045551234",
        "to" => "+12016661234",
        "type" => "mms",
        "messaging_provider_id" => "mms-message-5",
        "body" => "Check out these multiple images!",
        "attachments" => attachments,
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/webhooks/mms", webhook_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Webhook processed successfully"
             } = json_response(conn, 200)

      # Verify the message was created in the database
      message = Messages.get_message!(message_id)
      assert message.from == "+18045551234"
      assert message.to == "+12016661234"
      assert message.type == :mms
      assert message.body == "Check out these multiple images!"
      assert length(message.attachments) == 5
      assert Enum.all?(message.attachments, &String.starts_with?(&1, "https://example.com/image"))
    end

    test "handles MMS webhook with empty body", %{conn: conn} do
      webhook_data = %{
        "from" => "+18045551234",
        "to" => "+12016661234",
        "type" => "mms",
        "body" => "",
        "attachments" => ["https://example.com/image.jpg"],
        "messaging_provider_id" => "mms-message-6"
      }

      conn = post(conn, ~p"/api/webhooks/mms", webhook_data)

      assert %{
               "status" => "error",
               "message" => "Invalid data",
               "errors" => %{"body" => ["can't be blank"]}
             } = json_response(conn, 422)
    end
  end
end
