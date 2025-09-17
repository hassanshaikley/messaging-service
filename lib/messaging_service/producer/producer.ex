defmodule MessagingService.Producer do
  require Logger

  @adapters %{
    "mms" =>
      Application.get_env(
        :messaging_service,
        :mms_adapter,
        MessagingService.Producer.MMSAdapterLocal
      ),
    "sms" =>
      Application.get_env(
        :messaging_service,
        :sms_adapter,
        MessagingService.Producer.SMSAdapterLocal
      )
  }

  def process(message) do
    case @adapters[message.type] do
      nil ->
        Logger.error("No adapter for type: #{message.type}, full message: #{inspect(message)}")
        {:error, :no_adapter}

      adapter ->
        adapter.process(message)
    end
  end
end
