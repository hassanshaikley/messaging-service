defmodule MessagingService.Emails do
  @moduledoc """
  The Emails context for managing Email data.
  """

  import Ecto.Query, warn: false
  alias MessagingService.Repo
  alias MessagingService.Email

  @doc """
  Creates a Email.

  ## Examples

      iex> create_email(%{field: value})
      {:ok, %Email{}}

      iex> create_email(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_email(attrs \\ %{}) do
    %Email{}
    |> Email.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a single Email.

  Raises `Ecto.NoResultsError` if the Email does not exist.

  ## Examples

      iex> get_email!(123)
      %Email{}

      iex> get_email!(456)
      ** (Ecto.NoResultsError)

  """
  def get_email!(id), do: Repo.get!(Email, id)

  @doc """
  Lists all Emails.

  ## Examples

      iex> list_Emails()
      [%Email{}, ...]

  """
  def list_Emails do
    Repo.all(Email)
  end

  @doc """
  Lists Emails by conversation participants.

  ## Examples

      iex> list_Emails_by_participants("+12016661234", "+18045551234")
      [%Email{}, ...]

  """
  def list_Emails_by_participants(from, to) do
    from(m in Email,
      where: (m.from == ^from and m.to == ^to) or (m.from == ^to and m.to == ^from),
      order_by: [asc: m.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Updates a Email.

  ## Examples

      iex> update_email(Email, %{field: new_value})
      {:ok, %Email{}}

      iex> update_email(Email, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_email(%Email{} = Email, attrs) do
    Email
    |> Email.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Email.

  ## Examples

      iex> delete_email(Email)
      {:ok, %Email{}}

      iex> delete_email(Email)
      {:error, %Ecto.Changeset{}}

  """
  def delete_email(%Email{} = Email) do
    Repo.delete(Email)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking Email changes.

  ## Examples

      iex> change_email(Email)
      %Ecto.Changeset{data: %Email{}}

  """
  def change_email(%Email{} = Email, attrs \\ %{}) do
    Email.changeset(Email, attrs)
  end
end
