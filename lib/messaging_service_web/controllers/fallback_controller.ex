defmodule MessagingServiceWeb.FallbackController do
  use Phoenix.Controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{status: "error", message: "Not Found"})
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:forbidden)
    |> json(%{status: "error", message: "Unauthorized"})
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      status: "error",
      message: "Invalid data",
      errors: translate_errors(changeset)
    })
  end

  def call(conn, {:error, reason}) when is_binary(reason) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      status: "error",
      message: reason
    })
  end

  def call(conn, {:error, reason}) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{
      status: "error",
      message: "Failed to process request",
      error: to_string(reason)
    })
  end

  # Translates Ecto changeset errors to a more user-friendly format
  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        value_str =
          try do
            to_string(value)
          rescue
            _ -> inspect(value)
          end

        String.replace(acc, "%{#{key}}", value_str)
      end)
    end)
  end
end
