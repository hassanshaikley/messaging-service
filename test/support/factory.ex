defmodule MessagingService.Factory do
  use ExMachina.Ecto, repo: MessagingService.Repo

  def phone_us() do
    "+1#{Faker.Phone.EnUs.area_code()}#{Faker.Phone.EnUs.exchange_code()}#{Faker.Phone.EnUs.subscriber_number()}"
  end

  def message_factory do
    %Message{
      from: phone_us(),
      to: phone_us(),
      type: Enum.random(["mms", "sms"]),
      messaging_provider_id: Enum.random(["message-2", nil]),
      body: Faker.Lorem.paragraph(),
      attachments: fn
        %{type: "mms"} ->
          Enum.random([["attachment-url"], [], nil])

        %{type: "sms"} ->
          nil
      end,
      timestamp: fn
        # Outbound messages lack a messaging_provider_id and timestamp
        %{messaging_provider_id: nil} ->
          nil

        %{} ->
          Faker.DateTime.backward(1_000)
      end
    }
  end
end
