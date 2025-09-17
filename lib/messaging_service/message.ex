defmodule Message do
  use Ecto.Schema

  schema "messages" do
    field :from, :string
    field :to, :string
    field :type, Ecto.Enum, values: [:sms, :mms]
    field :messaging_provider_id, :string
    field :body, :string
    field :attachments, {:array, :string}
    field :timestamp, :utc_datetime
  end
end
