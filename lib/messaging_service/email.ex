defmodule MessagingService.Email do
  use Ecto.Schema

  schema "emails" do
    field :from, :string
    field :to, :string
    field :xillio_id, :string
    field :body, :string
    field :attachments, {:array, :string}
    field :timestamp, :utc_datetime

    timestamps()
  end

  def changeset(schema, params) do
    schema
    # TODO: Validate the format of the from and to, and possibly even the body
    |> Ecto.Changeset.cast(params, [
      :from,
      :to,
      :xillio_id,
      :body,
      :attachments,
      :timestamp
    ])
  end
end
