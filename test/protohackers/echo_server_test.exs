defmodule Protohackers.EchoServerTest do
  use ExUnit.Case

  test "echoes anything back" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5005, mode: :binary, active: false)
    assert :gen_tcp.send(socket, "hello") == :ok
    assert :gen_tcp.send(socket, "world") == :ok
    :gen_tcp.shutdown(socket, :write)
    assert :gen_tcp.recv(socket, 0, 5_000) == {:ok, "helloworld"}
  end

  test "echo server has a max buffer size" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5005, mode: :binary, active: false)
    assert :gen_tcp.send(socket, :binary.copy("a", 1024 * 100 + 1)) == :ok
    assert :gen_tcp.recv(socket, 0) == {:error, :closed}
  end

  test "handles multiple concurrent connections" do
    tasks =
      for n <- 1..10 do
        Task.async(fn ->
          {:ok, socket} = :gen_tcp.connect(~c"localhost", 5005, mode: :binary, active: false)
          assert :gen_tcp.send(socket, "hello") == :ok
          assert :gen_tcp.send(socket, Integer.to_string(n)) == :ok
          :gen_tcp.shutdown(socket, :write)
          assert :gen_tcp.recv(socket, 0, 5_000) == {:ok, "hello#{n}"}
        end)
      end

    Enum.each(tasks, &Task.await/1)
  end
end
