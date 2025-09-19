defmodule MessagingServiceWeb.TwilioWebhookController do
  @moduledoc """
  Handles incoming webhooks from Twilio for SMS/MMS messages.

  Twilio sends webhook data as form-encoded data, not JSON.
  This controller processes the webhook and creates messages in our system.
  """

  use MessagingServiceWeb, :controller

  alias MessagingService.Messages
  alias MessagingService.Conversations
  alias MessagingService.Consumer

  action_fallback MessagingServiceWeb.FallbackController

  @doc """
  Handles incoming SMS/MMS webhooks from Twilio.
  """
  def create(conn, params) do
    with {:ok, message_params} <- parse_twilio_params(params),
         {:ok, conversation} <- get_or_create_conversation(message_params),
         {:ok, message} <- create_message_with_conversation(message_params, conversation),
         :ok <- Consumer.process(message) do
      # Twilio expects a TwiML response
      conn
      |> put_resp_content_type("text/xml")
      |> text("<?xml version=\"1.0\" encoding=\"UTF-8\"?><Response></Response>")
    end
  end

  defp parse_twilio_params(params) do
    # Twilio sends form-encoded data, so we need to extract the relevant fields
    from = params["From"]
    to = params["To"]
    body = params["Body"] || ""
    message_sid = params["MessageSid"]
    num_media = String.to_integer(params["NumMedia"] || "0")

    if from && to && message_sid do
      attachments = extract_media_urls(params, num_media)
      message_type = if num_media > 0, do: :mms, else: :sms

      {:ok,
       %{
         from: from,
         to: to,
         body: body,
         type: message_type,
         attachments: attachments,
         messaging_provider_id: message_sid,
         timestamp: DateTime.utc_now()
       }}
    else
      {:error, "Missing required Twilio webhook parameters"}
    end
  end

  defp extract_media_urls(params, num_media) when num_media > 0 do
    for i <- 0..(num_media - 1) do
      params["MediaUrl#{i}"]
    end
    |> Enum.filter(& &1)
  end

  defp extract_media_urls(_params, 0), do: []

  defp get_or_create_conversation(%{from: from, to: to}) do
    Conversations.get_or_create_conversation(from, to)
  end

  defp create_message_with_conversation(message_params, conversation) do
    message_params
    |> Map.put(:conversation_id, conversation.id)
    |> Messages.create_message()
  end
end
