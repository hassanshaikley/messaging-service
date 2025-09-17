defmodule MessagingServiceWeb.SMSController do
  use MessagingServiceWeb, :controller

  alias MessagingService.Messages
  alias MessagingService.Consumer

  action_fallback MessagingServiceWeb.FallbackController

  @doc """
  Handles incoming SMS/MMS messages from messaging providers.

  This endpoint receives webhook calls from SMS/MMS providers when messages
  are sent to or received by the service.
  """
  def create(conn, params) do
    with {:ok, message} <- Messages.create_message(params),
         :ok <- Consumer.process(message) do
      conn
      |> put_status(:created)
      |> json(%{
        status: "success",
        message_id: message.id,
        message: "Message processed successfully"
      })
    end
  end
end
