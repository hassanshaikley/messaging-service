defmodule MessagingService.EmailTest do
  use MessagingService.DataCase, async: true

  alias MessagingService.Email

  test "valid message is inserted" do
    assert %{valid?: true} =
             changeset =
             Email.changeset(%Email{}, %{
               from: "Me",
               to: "You",
               xillio_id: "!23",
               body: "Hello world",
               attachments: ["123"],
               timestamp: DateTime.utc_now()
             })

    assert {:ok, _} = MessagingService.Repo.insert(changeset)
  end

  # test "xillio_id and timestamp are both nil is ok" do
  #   assert %{valid?: true} =
  #            changeset =
  #            Email.changeset(%Email{}, %{
  #              from: "Me",
  #              to: "You",
  #              xillio_id: nil,
  #              body: "Hello world",
  #              attachments: ["123"],
  #              timestamp: nil
  #            })

  #   assert {:ok, _} = MessagingService.Repo.insert(changeset)
  # end
end
