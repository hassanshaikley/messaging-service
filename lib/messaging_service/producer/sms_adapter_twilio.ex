defmodule MessagingService.Producer.SMSAdapterTwilio do
  require Logger

  def process(%{type: :sms} = message) do
    case send_sms(message) do
      {:ok, _response} ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to send SMS via Twilio for #{message.id} #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp send_sms(message) do
    url = twilio_url()
    auth = twilio_auth()

    payload = %{
      From: message.from,
      To: message.to,
      Body: message.body
    }

    case Req.post(url,
           auth: auth,
           json: payload,
           receive_timeout: 30_000,
           retry: [max_retries: 3, backoff: &backoff/1]
         ) do
      {:ok, %{status: 201, body: body}} ->
        {:ok, body}

      {:ok, %{status: 429}} ->
        Logger.warning("Twilio rate limit exceeded, message queued for retry")
        {:error, :rate_limited}

      {:ok, %{status: status} = resp} when status >= 500 ->
        Logger.error("Twilio server error #{inspect(resp)}")
        {:error, :provider_error}

      {:ok, resp} ->
        Logger.error("Twilio API error #{inspect(resp)}")
        {:error, :api_error}

      {:error, reason} ->
        Logger.error("Twilio request failed #{inspect(reason)}")
        {:error, :network_error}
    end
  end

  defp twilio_url do
    account_sid = Application.get_env(:messaging_service, :twilio_account_sid, "ACtest")
    "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages.json"
  end

  defp twilio_auth do
    account_sid = Application.get_env(:messaging_service, :twilio_account_sid, "ACtest")
    auth_token = Application.get_env(:messaging_service, :twilio_auth_token, "test")
    {account_sid, auth_token}
  end

  defp backoff(attempt) do
    # Exponential backoff: 1s, 2s, 4s
    :timer.sleep(1000 * :math.pow(2, attempt - 1))
  end
end
