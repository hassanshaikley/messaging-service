defmodule MessagingService.MessageTest do
  use MessagingService.DataCase, async: true

  alias MessagingService.Message

  test "valid message is inserted" do
    assert %{valid?: true} =
             changeset =
             Message.changeset(%Message{}, %{
               from: "Me",
               to: "You",
               type: "sms",
               messaging_provider_id: "!23",
               body: "Hello world",
               attachments: ["123"],
               timestamp: DateTime.utc_now()
             })

    assert {:ok, _} = MessagingService.Repo.insert(changeset)
  end

  test "messaging_provider_id and timestamp are both nil is ok" do
    assert %{valid?: true} =
             changeset =
             Message.changeset(%Message{}, %{
               from: "Me",
               to: "You",
               type: "sms",
               messaging_provider_id: nil,
               body: "Hello world",
               attachments: ["123"],
               timestamp: nil
             })

    assert {:ok, _} = MessagingService.Repo.insert(changeset)
  end

  test "messaging_provider_id not nil and timestamp is nil is not ok" do
    assert %{valid?: true} =
             changeset =
             Message.changeset(%Message{}, %{
               from: "Me",
               to: "You",
               type: "sms",
               messaging_provider_id: generate_messaging_provider_id(),
               body: "Hello world",
               attachments: ["123"],
               timestamp: nil
             })

    assert {:error, _} =
             MessagingService.Repo.insert(changeset)
  end

  test "messaging_provider_id  nil and timestamp not nil is not ok" do
    assert %{valid?: true} =
             changeset =
             Message.changeset(%Message{}, %{
               from: "Me",
               to: "You",
               type: "sms",
               messaging_provider_id: nil,
               body: "Hello world",
               attachments: ["123"],
               timestamp: DateTime.utc_now()
             })

    assert {:ok, _} = MessagingService.Repo.insert(changeset)
  end

  test "both messaging_provider_id  and timestamp are nil is ok" do
    assert %{valid?: true} =
             changeset =
             Message.changeset(%Message{}, %{
               from: "Me",
               to: "You",
               type: "sms",
               messaging_provider_id: nil,
               body: "Hello world",
               attachments: ["123"],
               timestamp: nil
             })

    assert {:ok, _} = MessagingService.Repo.insert(changeset)
  end
end
