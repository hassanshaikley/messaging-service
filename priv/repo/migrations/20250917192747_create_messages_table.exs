defmodule MessagingService.Repo.Migrations.CreateMessagesTable do
  use Ecto.Migration

  # TODO: May also want length constraints for SMS vs MMS

  def change do
    create table(:messages) do
      add :from, :string, null: false
      add :to, :string, null: false
      add :type, :string, null: false
      add :messaging_provider_id, :string
      add :body, :text, null: false
      add :attachments, {:array, :string}
      add :timestamp, :utc_datetime

      # Can make an argument for exluding updated_at as they should not be updated
      timestamps()
    end

    # Can do something like this, or use an enum
    # create constraint(:messages, :type_must_be_sms_or_mms, check: "type IN ('sms', 'mms')")

    # Nice to check this at the DB level to create a definition for inbound/outbound at DB level, could be useful to index as well
    # As will likely filter by the presence of both or the opposite.
    create constraint(:messages, :messaging_provider_id_requires_timestamp,
             check: "timestamp IS NOT NULL OR messaging_provider_id IS NULL"
           )

    # Probably want these
    create index(:messages, [:from])
    create index(:messages, [:to])
  end
end
