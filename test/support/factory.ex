defmodule MessagingService.Factory do
  use ExMachina.Ecto, repo: MessagingService.Repo

  def phone_us() do
    "+1#{Faker.Phone.EnUs.area_code()}#{Faker.Phone.EnUs.exchange_code()}#{Faker.Phone.EnUs.subscriber_number()}"
  end

  def email_mailto() do
    email_address = Faker.Internet.email()

    "[#{email_address}](mailto:#{email_address})"
  end

  # TODO: This is a hack, find a better way to deal with this
  def conversation_factory() do
    %MessagingService.Conversation{
      participants: [Faker.String.base64()]
    }
  end

  def message_factory do
    %MessagingService.Message{
      from: phone_us(),
      to: phone_us(),
      type: Enum.random([:mms, :sms]),
      messaging_provider_id:
        Enum.random([MessagingService.DataCase.generate_messaging_provider_id(), nil]),
      body: Faker.Lorem.paragraph(),
      attachments: fn
        %{type: :mms} ->
          Enum.random([["attachment-url"], [], nil])

        %{type: :sms} ->
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

  def email_factory() do
    %MessagingService.Email{
      from: email_mailto(),
      to: email_mailto(),
      xillio_id: "message-2",
      body: "<html><body>html is <b>allowed</b> here </body></html>",
      attachments: Enum.random([["attachment-url"] | []]),
      timestamp: "2024-11-01T14:00:00Z"
    }
  end
end
