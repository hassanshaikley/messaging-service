defmodule MessagingServiceWeb.MessageControllerTest do
  use MessagingServiceWeb.ConnCase

  alias MessagingService.Messages
  alias MessagingService.Emails

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

    test "creates a message with SMS data including attachments", %{conn: conn} do
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
      assert message.type == :sms
      assert message.body == "Check out this image!"
      assert message.attachments == ["https://example.com/image.jpg"]
      assert message.remote_id == "provider-123"
      assert message.remote_id_type == :messaging_provider
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

  describe "POST /api/messages/mms" do
    test "sends MMS with attachments", %{conn: conn} do
      message_data = %{
        "from" => "+12016661234",
        "to" => "+18045551234",
        "type" => "mms",
        "body" => "Hello! This is a test MMS message with attachment.",
        "attachments" => ["https://example.com/image.jpg"],
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/messages/mms", message_data)

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
      assert message.body == "Hello! This is a test MMS message with attachment."
      assert message.attachments == ["https://example.com/image.jpg"]
    end

    test "creates a message with valid MMS data", %{conn: conn} do
      message_data = %{
        "from" => "+12016661234",
        "to" => "+18045551234",
        "type" => "mms",
        "body" => "Check out this image!",
        "attachments" => ["https://example.com/image.jpg", "https://example.com/video.mp4"],
        "messaging_provider_id" => "provider-123",
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/messages/mms", message_data)

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

      assert message.attachments == [
               "https://example.com/image.jpg",
               "https://example.com/video.mp4"
             ]

      assert message.remote_id == "provider-123"
    end

    test "creates a message with MMS data and no attachments", %{conn: conn} do
      message_data = %{
        "from" => "+12016661234",
        "to" => "+18045551234",
        "type" => "mms",
        "body" => "This is an MMS without attachments",
        "attachments" => [],
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/messages/mms", message_data)

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
      assert message.body == "This is an MMS without attachments"
      assert message.attachments == []
    end

    test "creates a message with MMS data and null attachments", %{conn: conn} do
      message_data = %{
        "from" => "+12016661234",
        "to" => "+18045551234",
        "type" => "mms",
        "body" => "This is an MMS with null attachments",
        "attachments" => nil,
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/messages/mms", message_data)

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
      assert message.body == "This is an MMS with null attachments"
      assert message.attachments == nil
    end

    test "handles missing required fields", %{conn: conn} do
      message_data = %{
        "from" => "+12016661234",
        "type" => "mms"
        # Missing 'to' and 'body' fields
      }

      conn = post(conn, ~p"/api/messages/mms", message_data)

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

      conn = post(conn, ~p"/api/messages/mms", message_data)

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
        type: "mms",
        body: "Hello! This is a test MMS message.",
        attachments: ["https://example.com/image.jpg"]
      }

      conn = post(conn, ~p"/api/messages/mms", message_data)

      assert %{
               "status" => "success",
               "message_id" => _message_id,
               "message" => "Message processed successfully"
             } = json_response(conn, 201)
    end

    test "handles large attachment arrays", %{conn: conn} do
      attachments = for i <- 1..10, do: "https://example.com/image#{i}.jpg"

      message_data = %{
        "from" => "+12016661234",
        "to" => "+18045551234",
        "type" => "mms",
        "body" => "Check out these multiple images!",
        "attachments" => attachments,
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/messages/mms", message_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Message processed successfully"
             } = json_response(conn, 201)

      # Verify the message was created in the database
      message = Messages.get_message!(message_id)
      assert length(message.attachments) == 10
      assert Enum.all?(message.attachments, &String.starts_with?(&1, "https://example.com/image"))
    end

    test "handles empty body for MMS", %{conn: conn} do
      message_data = %{
        "from" => "+12016661234",
        "to" => "+18045551234",
        "type" => "mms",
        "body" => "",
        "attachments" => ["https://example.com/image.jpg"]
      }

      conn = post(conn, ~p"/api/messages/mms", message_data)

      assert %{
               "status" => "error",
               "message" => "Invalid data",
               "errors" => %{"body" => ["can't be blank"]}
             } = json_response(conn, 422)
    end

    test "handles missing messaging_provider_id", %{conn: conn} do
      message_data = %{
        "from" => "+12016661234",
        "to" => "+18045551234",
        "type" => "mms",
        "body" => "Test message without provider ID",
        "attachments" => ["https://example.com/image.jpg"]
      }

      conn = post(conn, ~p"/api/messages/mms", message_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Message processed successfully"
             } = json_response(conn, 201)

      # Verify the message was created without messaging_provider_id
      message = Messages.get_message!(message_id)
      assert message.remote_id == nil
    end
  end

  describe "POST /api/messages/email" do
    test "sends email with HTML content and attachments", %{conn: conn} do
      message_data = %{
        "from" => "user@usehatchapp.com",
        "to" => "contact@gmail.com",
        "body" => "Hello! This is a test email message with <b>HTML</b> formatting.",
        "attachments" => ["https://example.com/document.pdf"],
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/messages/email", message_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Message processed successfully"
             } = json_response(conn, 201)

      # Verify the message was created in the database
      message = Messages.get_message!(message_id)
      assert message.from == "user@usehatchapp.com"
      assert message.to == "contact@gmail.com"
      assert message.body == "Hello! This is a test email message with <b>HTML</b> formatting."
      assert message.attachments == ["https://example.com/document.pdf"]
    end

    test "creates email message with xillio_id", %{conn: conn} do
      message_data = %{
        "from" => "user@example.com",
        "to" => "recipient@example.com",
        "xillio_id" => "email-123",
        "body" => "This is an email with xillio_id",
        "attachments" => ["https://example.com/file.pdf"],
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/messages/email", message_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Message processed successfully"
             } = json_response(conn, 201)

      # Verify the message was created in the database
      message = Messages.get_message!(message_id)
      assert message.from == "user@example.com"
      assert message.to == "recipient@example.com"
      assert message.body == "This is an email with xillio_id"
      assert message.attachments == ["https://example.com/file.pdf"]
    end

    test "handles email with multiple attachments", %{conn: conn} do
      message_data = %{
        "from" => "sender@company.com",
        "to" => "recipient@company.com",
        "body" => "Please find the attached documents.",
        "attachments" => [
          "https://example.com/document1.pdf",
          "https://example.com/document2.docx",
          "https://example.com/image.png"
        ],
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/messages/email", message_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Message processed successfully"
             } = json_response(conn, 201)

      # Verify the message was created in the database
      message = Messages.get_message!(message_id)
      assert message.from == "sender@company.com"
      assert message.to == "recipient@company.com"
      assert message.body == "Please find the attached documents."
      assert length(message.attachments) == 3
      assert "https://example.com/document1.pdf" in message.attachments
      assert "https://example.com/document2.docx" in message.attachments
      assert "https://example.com/image.png" in message.attachments
    end

    test "handles email without attachments", %{conn: conn} do
      message_data = %{
        "from" => "simple@example.com",
        "to" => "recipient@example.com",
        "body" => "This is a simple email without attachments.",
        "timestamp" => "2024-11-01T14:00:00Z"
      }

      conn = post(conn, ~p"/api/messages/email", message_data)

      assert %{
               "status" => "success",
               "message_id" => message_id,
               "message" => "Message processed successfully"
             } = json_response(conn, 201)

      # Verify the message was created in the database
      message = Messages.get_message!(message_id)
      assert message.from == "simple@example.com"
      assert message.to == "recipient@example.com"
      assert message.body == "This is a simple email without attachments."
      assert message.attachments == nil
    end

    test "handles missing required fields for email", %{conn: conn} do
      message_data = %{
        "from" => "user@example.com"
        # Missing 'to' and 'body' fields
      }

      conn = post(conn, ~p"/api/messages/email", message_data)

      assert %{
               "message" => "Invalid data",
               "status" => "error",
               "errors" => %{"body" => ["can't be blank"], "to" => ["can't be blank"]}
             } = json_response(conn, 422)
    end

    test "handles invalid email data", %{conn: conn} do
      message_data = %{
        "from" => "",
        "to" => "",
        "body" => ""
      }

      conn = post(conn, ~p"/api/messages/email", message_data)

      assert %{
               "status" => "error",
               "message" => "Invalid data",
               "errors" => errors
             } = json_response(conn, 422)

      assert is_map(errors)
    end
  end
end
