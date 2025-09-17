defmodule MessagingService.Conversations do
  @moduledoc """
  The Conversations context for managing conversation data.
  """

  import Ecto.Query, warn: false
  alias MessagingService.Repo
  alias MessagingService.Conversation

  @doc """
  Creates a conversation.

  ## Examples

      iex> create_conversation(%{field: value})
      {:ok, %Conversation{}}

      iex> create_conversation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_conversation(attrs \\ %{}) do
    %Conversation{}
    |> Conversation.changeset(attrs)
    |> Repo.insert(on_conflict: :nothing, returning: true)
  end

  @doc """
  Gets a single conversation.

  Raises `Ecto.NoResultsError` if the Conversation does not exist.

  ## Examples

      iex> get_conversation!(123)
      %Conversation{}

      iex> get_conversation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_conversation!(id), do: Repo.get!(Conversation, id)

  @doc """
  Gets a conversation by participants.

  ## Examples

      iex> get_conversation_by_participants("+12016661234", "+18045551234")
      %Conversation{}

      iex> get_conversation_by_participants("user@example.com", "other@example.com")
      %Conversation{}

  """
  def get_conversation_by_participants(from, to) do
    participants = [from, to] |> Enum.sort()

    from(c in Conversation,
      where: c.participants == ^participants
    )
    |> Repo.one()
  end

  @doc """
  Gets or creates a conversation for the given participants.

  ## Examples

      iex> get_or_create_conversation("+12016661234", "+18045551234")
      {:ok, %Conversation{}}

  """
  def get_or_create_conversation(from, to) do
    case get_conversation_by_participants(from, to) do
      nil ->
        participants = [from, to] |> Enum.sort()
        create_conversation(%{participants: participants})

      conversation ->
        {:ok, conversation}
    end
  end

  @doc """
  Lists all conversations.

  ## Examples

      iex> list_conversations()
      [%Conversation{}, ...]

  """
  def list_conversations do
    Repo.all(Conversation)
  end

  @doc """
  Lists conversations ordered by last message time (most recent first).

  ## Examples

      iex> list_conversations_ordered()
      [%Conversation{}, ...]

  """
  def list_conversations_ordered do
    from(c in Conversation,
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Lists conversations for a specific participant.

  ## Examples

      iex> list_conversations_for_participant("+12016661234")
      [%Conversation{}, ...]

  """
  def list_conversations_for_participant(participant) do
    from(c in Conversation,
      where: ^participant in c.participants,
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Updates a conversation.

  ## Examples

      iex> update_conversation(conversation, %{field: new_value})
      {:ok, %Conversation{}}

      iex> update_conversation(conversation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_conversation(%Conversation{} = conversation, attrs) do
    conversation
    |> Conversation.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a conversation with new message data.

  ## Examples

      iex> add_message_to_conversation(conversation, message)
      {:ok, %Conversation{}}

  """
  def add_message_to_conversation(%Conversation{} = conversation, message) do
    message_time = message.timestamp || message.inserted_at

    conversation
    |> Conversation.update_changeset(%{})
    |> Repo.update()
  end

  @doc """
  Adds a message to the appropriate conversation, creating it if necessary.

  ## Examples

      iex> add_message_to_conversation_by_participants(message)
      {:ok, %Conversation{}}

  """
  def add_message_to_conversation_by_participants(message) do
    participants = Conversation.extract_participants(message)

    case participants do
      [from, to] ->
        with {:ok, conversation} <- get_or_create_conversation(from, to),
             {:ok, updated_conversation} <- add_message_to_conversation(conversation, message) do
          {:ok, updated_conversation}
        end

      _ ->
        {:error, :invalid_participants}
    end
  end

  @doc """
  Deletes a conversation.

  ## Examples

      iex> delete_conversation(conversation)
      {:ok, %Conversation{}}

      iex> delete_conversation(conversation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_conversation(%Conversation{} = conversation) do
    Repo.delete(conversation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking conversation changes.

  ## Examples

      iex> change_conversation(conversation)
      %Ecto.Changeset{data: %Conversation{}}

  """
  def change_conversation(%Conversation{} = conversation, attrs \\ %{}) do
    Conversation.changeset(conversation, attrs)
  end
end
