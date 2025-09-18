defmodule MessagingService.ProducerTest do
  use MessagingService.DataCase, async: true

  import ExUnit.CaptureLog

  test "error and log when adapter doesnt exist for specified type" do
    # TODO: Assertion for the log
    assert capture_log(fn ->
             MessagingService.Producer.process(%{type: "noexist"}) ==
               {:error, :no_adapter}
           end) =~
             "No adapter for type: noexist, full message: %{type: \"noexist\"}"
  end

  test "processes sms" do
    outbound_sms =
      build(:message,
        remote_id: nil,
        remote_id_type: "messaging_provider",
        timestamp: nil,
        type: :sms
      )

    assert MessagingService.Producer.process(outbound_sms) == :ok
  end

  test "processes mms" do
    outbound_mms =
      build(:message,
        remote_id: nil,
        remote_id_type: "messaging_provider",
        timestamp: nil,
        type: :mms
      )

    assert MessagingService.Producer.process(outbound_mms) == :ok
  end

  test "processes email" do
    outbound_email = build(:message, remote_id: "some-id", remote_id_type: :xillio)

    assert MessagingService.Producer.process(outbound_email) == :ok
  end
end
