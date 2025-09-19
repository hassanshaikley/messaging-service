defmodule MessagingServiceWeb.SendGridWebhookController do
  use MessagingServiceWeb, :controller

  require Logger

  alias MessagingService.Messages
  alias MessagingService.Conversations
  alias MessagingService.Consumer

  action_fallback MessagingServiceWeb.FallbackController

  def create(conn, %{"_json" => events}) when is_list(events) do
    # Process each event in the webhook payload
    results = Enum.map(events, &process_sendgrid_event/1)

    # Check if any events were processed successfully
    if Enum.any?(results, &match?({:ok, _}, &1)) do
      conn
      |> put_status(:ok)
      |> json(%{status: "success", message: "Webhook processed"})
    else
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{status: "error", message: "No valid events processed"})
    end
  end

  def create(conn, params) do
    # Handle single event or malformed payload
    case process_sendgrid_event(params) do
      {:ok, _message} ->
        conn
        |> put_status(:ok)
        |> json(%{status: "success", message: "Webhook processed"})

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{status: "error", message: reason})
    end
  end

  defp process_sendgrid_event(%{"event" => "inbound"} = event) do
    with {:ok, message_params} <- parse_sendgrid_event(event),
         {:ok, conversation} <- get_or_create_conversation(message_params),
         {:ok, message} <- create_message(message_params, conversation),
         :ok <- Consumer.process(message) do
      {:ok, message}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp process_sendgrid_event(event) do
    Logger.error("Unsupported event type #{inspect(event)}")
    {:error, "Unsupported event type"}
  end

  defp parse_sendgrid_event(event) do
    from = event["from"]
    # SendGrid uses "email" for recipient
    to = event["email"]
    subject = event["subject"] || ""
    text_content = event["text"] || ""
    html_content = event["html"] || ""
    sg_message_id = event["sg_message_id"]

    if from && to && sg_message_id do
      # Use HTML content if available, otherwise use text
      body = if html_content != "", do: html_content, else: text_content

      # Add subject to body if present
      full_body =
        if subject != "" do
          "Subject: #{subject}\n\n#{body}"
        else
          body
        end

      attachments = extract_sendgrid_attachments(event)

      {:ok,
       %{
         from: from,
         to: to,
         body: full_body,
         type: :email,
         attachments: attachments,
         xillio_id: sg_message_id,
         timestamp: DateTime.utc_now()
       }}
    else
      {:error, "Missing required SendGrid webhook parameters"}
    end
  end

  defp extract_sendgrid_attachments(event) do
    case event["attachments"] do
      attachments when is_list(attachments) ->
        Enum.map(attachments, fn attachment ->
          attachment["url"] || attachment["content_id"]
        end)
        |> Enum.filter(& &1)

      _ ->
        []
    end
  end

  defp get_or_create_conversation(%{from: from, to: to}) do
    Conversations.get_or_create_conversation(from, to)
  end

  defp create_message(message_params, conversation) do
    message_params
    |> Map.put(:conversation_id, conversation.id)
    |> Messages.create_message()
  end
end
