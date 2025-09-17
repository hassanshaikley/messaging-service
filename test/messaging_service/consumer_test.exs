defmodule MessagingService.ConsumerTest do
  use MessagingService.DataCase, async: true

  import ExUnit.CaptureLog

  test "error and log when adapter doesnt exist for specified type" do
    # TODO: Assertion for the log
    assert capture_log(fn ->
             MessagingService.Consumer.process(%{type: "noexist"}) ==
               {:error, :no_adapter}
           end) =~
             "No adapter for type: noexist, full message: %{type: \"noexist\"}"
  end

  test "processes sms" do
    inbound_sms =
      build(:message, type: :sms, messaging_provider_id: generate_messaging_provider_id())

    assert MessagingService.Consumer.process(inbound_sms) == :ok
  end

  test "processes mms" do
    inbound_mms =
      build(:message, type: :mms, messaging_provider_id: generate_messaging_provider_id())

    assert MessagingService.Consumer.process(inbound_mms) == :ok
  end

  test "processes email" do
    inbound_email =
      build(:email, xillio_id: "some-id")

    assert MessagingService.Consumer.process(inbound_email) == :ok
  end
end
