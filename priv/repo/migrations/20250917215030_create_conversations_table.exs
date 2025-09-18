defmodule MessagingService.Repo.Migrations.CreateConversationsTable do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      add :participants, {:array, :string}, null: false

      timestamps()
    end

    alter table(:messages) do
      add :conversation_id,
          references(:conversations),
          null: false
    end

    create index(:messages, [:conversation_id])

    # Ensure participants are unique and properly indexed
    # They are ordered in the changeset but it would probably bet better to order them at the database level
    # Same goes for massaging the information so that there aren't duplicates
    create unique_index(:conversations, [:participants], name: :conversations_participants_unique)

    # Index for efficient querying by participant
    create index(:conversations, :participants, using: :gin)
  end
end
