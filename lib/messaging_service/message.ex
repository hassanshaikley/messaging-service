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
      :timestamp
    ])
    |> Ecto.Changeset.check_constraint(:messaging_provider_id,
      name: :messaging_provider_id_requires_timestamp
    )
  end
end
