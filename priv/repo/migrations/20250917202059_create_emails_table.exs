defmodule MessagingService.Repo.Migrations.CreateEmailsTable do
  use Ecto.Migration

  def change do
    create table(:emails) do
      add :from, :string, null: false
      add :to, :string, null: false
      add :xillio_id, :string
      add :body, :text, null: false
      add :attachments, {:array, :string}
      add :timestamp, :utc_datetime

      # Can make an argument for exluding updated_at as they should not be updated here as well
      timestamps()
    end

    # Probably want these
    create index(:emails, [:from])
    create index(:emails, [:to])
  end
end
