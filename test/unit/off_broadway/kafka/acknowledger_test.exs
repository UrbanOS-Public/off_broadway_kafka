defmodule OffBroadway.Kafka.AcknowledgerTest do
  use ExUnit.Case

  import Mock

  alias OffBroadway.Kafka.Acknowledger

  @connection :connection
  @topic "topic-1"
  @partition 0
  @generation_id 7

  setup_with_mocks([
    {Elsa.Group.Acknowledger, [], [ack: fn(_, _, _, _, _) -> :ok end]}
  ]) do
    {:ok, pid} =
      Acknowledger.start_link(
        connection: @connection,
        topic: @topic,
        partition: @partition,
        generation_id: @generation_id
      )

    [
      pid: pid,
      ack_ref: %{pid: pid, topic: @topic, partition: @partition, generation_id: @generation_id}
    ]
  end
  test "should ack offsets as acknowledged", %{pid: pid, ack_ref: ack_ref} do
    Acknowledger.add_offsets(pid, 1..100)

    Acknowledger.ack(ack_ref, [broadway_message(1)], [])

    Patiently.wait_for!(
      fn ->
        is_nil(assert_called(Elsa.Group.Acknowledger.ack(@connection, @topic, @partition, @generation_id, 1)))
      end,
      dwell: 200,
      max_tries: 10
    )
  end

  test "should not ack offset if all previous offsets have not been acked", %{pid: pid, ack_ref: ack_ref} do
    Acknowledger.add_offsets(pid, 1..100)

    Acknowledger.ack(ack_ref, [broadway_message(3)], [])

    Process.sleep(1_000)
    assert_not_called Elsa.Group.Acknowledger.ack(@connection, @topic, @partition, @generation_id, :_)
  end

  test "should ack all messages up to the latest that have been processed", %{pid: pid, ack_ref: ack_ref} do
    Acknowledger.add_offsets(pid, 1..100)

    Acknowledger.ack(ack_ref, broadway_messages(1..3), [])

    Patiently.wait_for!(
      fn ->
        assert_called_exactly Elsa.Group.Acknowledger.ack(@connection, @topic, @partition, @generation_id, :_), 1
        is_nil(assert_called(Elsa.Group.Acknowledger.ack(@connection, @topic, @partition, @generation_id, 3)))
      end,
      dwell: 200,
      max_tries: 10
    )
  end

  test "failed messages are also acked", %{pid: pid, ack_ref: ack_ref} do
    Acknowledger.add_offsets(pid, 1..100)

    Acknowledger.ack(ack_ref, broadway_messages(1..27), broadway_messages(28..41))

    Patiently.wait_for!(
      fn ->
        assert_called_exactly Elsa.Group.Acknowledger.ack(@connection, @topic, @partition, @generation_id, :_), 1
        is_nil(assert_called(Elsa.Group.Acknowledger.ack(@connection, @topic, @partition, @generation_id, 41)))
      end,
      dwell: 200,
      max_tries: 10
    )
  end

  defp broadway_messages(range) do
    Enum.map(range, &broadway_message/1)
  end

  defp broadway_message(offset) do
    %Broadway.Message{
      data: nil,
      acknowledger: {:module, :ack_ref, %{offset: offset}}
    }
  end
end
