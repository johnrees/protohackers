defmodule PrimeTimeTest do
  use ExUnit.Case

  test "echoes back JSON" do
    {:ok, socket} = :gen_tcp.connect(~c"localhost", 5006, mode: :binary, active: false)
    :gen_tcp.send(socket, Jason.encode!(%{"method" => "isPrime", "number" => 7}) <> "\n")

    assert {:ok, data} = :gen_tcp.recv(socket, 0, 5_000)
    assert String.ends_with?(data, "\n")
    assert Jason.decode!(data) == %{"method" => "isPrime", "prime" => true}

    :gen_tcp.send(socket, Jason.encode!(%{"method" => "isPrime", "number" => 6}) <> "\n")

    assert {:ok, data} = :gen_tcp.recv(socket, 0, 5_000)
    assert String.ends_with?(data, "\n")
    assert Jason.decode!(data) == %{"method" => "isPrime", "prime" => false}
  end
end
