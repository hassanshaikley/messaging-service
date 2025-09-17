defmodule MessagingService.Conversation do
  @moduledoc """
  Conversation schema for grouping messages by participants.

  Conversations are automatically created and managed based on the participants
  (from/to addresses) of messages. Each conversation represents a thread of
  communication between specific participants across all message types.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "conversations" do
    field :participants, {:array, :string}

    has_many :messages, MessagingService.Message

    timestamps()
  end

  @doc """
  Creates a changeset for conversation.
  """
  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:participants])
    |> validate_required([:participants])
    |> validate_length(:participants, min: 2, max: 2)
    |> validate_unique_participants()
    |> normalize_participants()
    |> unique_constraint([:participants], name: :conversations_participants_unique)
  end

  @doc """
  Creates a changeset for a new conversation from message participants.
  """
  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
  end

  @doc """
  Updates a conversation with new message data.
  """
  def update_changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [])
    |> validate_required([])
  end

  # Validates that participants are unique and not empty
  defp validate_unique_participants(changeset) do
    case get_field(changeset, :participants) do
      [participant1, participant2] when participant1 == participant2 ->
        add_error(changeset, :participants, "participants must be different")

      [participant1, participant2] when participant1 == "" or participant2 == "" ->
        add_error(changeset, :participants, "participants cannot be empty")

      _ ->
        changeset
    end
  end

  # Normalizes participants by sorting them to ensure consistent conversation grouping
  defp normalize_participants(changeset) do
    case get_field(changeset, :participants) do
      [participant1, participant2] ->
        normalized = [participant1, participant2] |> Enum.sort()
        put_change(changeset, :participants, normalized)

      _ ->
        changeset
    end
  end

  @doc """
  Generates a conversation key for consistent grouping.
  """
  def conversation_key(from, to) do
    [from, to] |> Enum.sort() |> Enum.join("|")
  end

  @doc """
  Extracts participants from a message (handles both Message and Email schemas).
  """
  def extract_participants(%{from: from, to: to}) do
    [from, to] |> Enum.sort()
  end

  def extract_participants(_), do: nil
end
