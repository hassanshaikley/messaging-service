defmodule MessagingService.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [
             :id,
             :from,
             :to,
             :type,
             :body,
             :attachments,
             :timestamp,
             :conversation_id,
             :inserted_at,
             :updated_at
           ]}
  schema "messages" do
    field :from, :string
    field :to, :string
    field :type, Ecto.Enum, values: [:sms, :mms, :email]
    field :remote_id, :string
    field :remote_id_type, Ecto.Enum, values: [:messaging_provider, :xillio]
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
      :remote_id,
      :body,
      :attachments,
      :timestamp,
      :conversation_id
    ])
    |> Ecto.Changeset.assoc_constraint(:conversation)
    |> set_remote_id_and_remote_id_type(params)
    |> Ecto.Changeset.validate_required([:from, :to, :type, :body])

    # if messaging_provider_id then set remote_id and message
    # |> Ecto.Changeset.check_constraint(:remote_id,
    #   name: :remote_id_requires_timestamp
    # )
  end

  defp set_remote_id_and_remote_id_type(changeset, params) do
    case Map.get(params, :xillio_id) do
      nil ->
        case Map.get(params, "messaging_provider_id") do
          nil ->
            changeset

          messaging_provider_id ->
            changeset
            |> put_change(:remote_id, messaging_provider_id)
            |> put_change(:remote_id_type, :messaging_provider)
        end

      xillio_id ->
        changeset
        |> put_change(:remote_id, xillio_id)
        |> put_change(:remote_id_type, :xillio)
        |> put_change(:type, :email)
    end
  end
end
