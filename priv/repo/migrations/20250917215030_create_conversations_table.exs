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

    # Ensure participants are unique and properly indexed
    create unique_index(:conversations, [:participants], name: :conversations_participants_unique)

    # Index for efficient querying by participant
    create index(:conversations, :participants, using: :gin)
  end
end
