defmodule MessagingService.Producer.EmailAdapterSendGrid do
  require Logger

  def process(%{type: :email} = message) do
    case send_email(message) do
      {:ok, _response} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to send email via SendGrid for #{message.id} #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp send_email(message) do
    url = sendgrid_url()
    headers = sendgrid_headers()

    payload = build_email_payload(message)

    case Req.post(url,
           headers: headers,
           json: payload,
           receive_timeout: 30_000,
           retry: [max_retries: 3, backoff: &backoff/1]
         ) do
      {:ok, %{status: 202, body: body}} ->
        {:ok, body}

      {:ok, %{status: 429}} ->
        Logger.warning("SendGrid rate limit exceeded, message queued for retry")
        {:error, :rate_limited}

      {:ok, %{status: status} = resp} when status >= 500 ->
        Logger.error("SendGrid server error #{inspect(resp)}")
        {:error, :provider_error}

      {:ok, resp} ->
        Logger.error("SendGrid API error #{inspect(resp)}")
        {:error, :api_error}

      {:error, reason} ->
        Logger.error("SendGrid request failed #{inspect(reason)}")
        {:error, :network_error}
    end
  end

  defp build_email_payload(message) do
    base_payload = %{
      personalizations: [
        %{
          to: [%{email: message.to}],
          subject: extract_subject(message.body) || "Message from #{message.from}"
        }
      ],
      from: %{email: message.from},
      content: [
        %{
          type: detect_content_type(message.body),
          value: message.body
        }
      ]
    }

    # Add attachments if present
    if message.attachments && length(message.attachments) > 0 do
      attachments =
        Enum.map(message.attachments, fn url ->
          %{
            content: Base.encode64("mock_content_for_#{url}"),
            filename: extract_filename(url),
            type: detect_attachment_type(url),
            disposition: "attachment"
          }
        end)

      Map.put(base_payload, :attachments, attachments)
    else
      base_payload
    end
  end

  defp extract_subject(body) do
    # Try to extract subject from HTML if it's an HTML email
    case Regex.run(~r/<title[^>]*>(.*?)<\/title>/i, body) do
      [_, subject] -> String.trim(subject)
      _ -> nil
    end
  end

  defp detect_content_type(body) do
    if String.contains?(body, "<html") or String.contains?(body, "<HTML") do
      "text/html"
    else
      "text/plain"
    end
  end

  defp extract_filename(url) do
    url
    |> String.split("/")
    |> List.last()
    |> case do
      "" -> "attachment"
      filename -> filename
    end
  end

  defp detect_attachment_type(url) do
    extension =
      url
      |> String.split(".")
      |> List.last()
      |> String.downcase()

    case extension do
      "pdf" -> "application/pdf"
      "jpg" -> "image/jpeg"
      "jpeg" -> "image/jpeg"
      "png" -> "image/png"
      "gif" -> "image/gif"
      "doc" -> "application/msword"
      "docx" -> "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      _ -> "application/octet-stream"
    end
  end

  defp sendgrid_url do
    "https://api.sendgrid.com/v3/mail/send"
  end

  defp sendgrid_headers do
    api_key = Application.get_env(:messaging_service, :sendgrid_api_key, "test_key")

    [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]
  end

  defp backoff(attempt) do
    # Exponential backoff: 1s, 2s, 4s
    :timer.sleep(1000 * :math.pow(2, attempt - 1))
  end
end
