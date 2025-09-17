defmodule MessagingService.Consumer do
  require Logger

  @adapters %{
    "mms" =>
      Application.get_env(
        :messaging_service,
        :mms_adapter,
        MessagingService.Consumer.MMSAdapterLocal
      ),
    "sms" =>
      Application.get_env(
        :messaging_service,
        :sms_adapter,
        MessagingService.Consumer.SMSAdapterLocal
      ),
    "email" =>
      Application.get_env(
        :messaging_service,
        :sms_adapter,
        MessagingService.Consumer.EmailAdapterLocal
      )
  }

  def process(message) do
    case get_message_type(message) do
      nil ->
        Logger.error("No adapter for type: #{message.type}, full message: #{inspect(message)}")
        {:error, :no_adapter}

      adapter ->
        @adapters[adapter].process(message)
    end
  end

  defp get_message_type(%{type: :sms}), do: "sms"
  defp get_message_type(%{type: :mms}), do: "mms"
  defp get_message_type(%{xillio_id: _some_xillio_id}), do: "email"
  defp get_message_type(_), do: nil
end
