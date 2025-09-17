defmodule MessagingService.Message do
  use Ecto.Schema

  schema "messages" do
    field :from, :string
    field :to, :string
    field :type, Ecto.Enum, values: [:sms, :mms]
    field :messaging_provider_id, :string
    field :body, :string
    field :attachments, {:array, :string}
    field :timestamp, :utc_datetime

    belongs_to :conversation, MessagingService.Conversation

    timestamps()
  end

  def changeset(schema, params) do
    schema
    |> Ecto.Changeset.cast(params, [
      :from,
      :to,
      :type,
      :messaging_provider_id,
      :body,
      :attachments,
      :timestamp,
      :conversation_id
    ])
    |> Ecto.Changeset.assoc_constraint(:conversation)
    |> Ecto.Changeset.validate_required([:from, :to, :type, :body])
    |> Ecto.Changeset.check_constraint(:messaging_provider_id,
      name: :messaging_provider_id_requires_timestamp
    )
  end
end
