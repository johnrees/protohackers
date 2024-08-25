defmodule Protohackers.PrimeTime do
  use GenServer

  require Logger

  def start_link([] = _opts) do
    GenServer.start_link(__MODULE__, :no_state)
  end

  defstruct [:listen_socket]

  @impl true
  def init(:no_state) do
    listen_options = [
      ifaddr: {0, 0, 0, 0},
      mode: :binary,
      active: false,
      reuseaddr: true,
      exit_on_close: false,
      backlog: 10,
      packet: :line,
      buffer: 1024 * 100
    ]

    case :gen_tcp.listen(5006, listen_options) do
      {:ok, listen_socket} ->
        # dbg(:inet.getopts(listen_socket, [:buffer]))
        Logger.info("Prime Time running on port 5006")
        state = %__MODULE__{listen_socket: listen_socket}
        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @impl true
  def handle_continue(:accept, %__MODULE__{} = state) do
    case :gen_tcp.accept(state.listen_socket) do
      {:ok, socket} ->
        handle_connection(socket)
        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  # Helpers

  defp handle_connection(socket) do
    case echo_lines_until_closed(socket) do
      :ok -> :ok
      {:error, reason} -> Logger.error("Failed to receive data: #{inspect(reason)}")
    end

    :gen_tcp.close(socket)
  end

  defp echo_lines_until_closed(socket) do
    case :gen_tcp.recv(socket, 0, 10_000) do
      {:ok, data} ->
        case Jason.decode(data) do
          {:ok, %{"method" => "isPrime", "number" => number}} when is_number(number) ->
            Logger.debug("Received isPrime request: #{inspect(number)}")

            :gen_tcp.send(socket, [
              Jason.encode!(%{"method" => "isPrime", "prime" => prime?(number)}),
              ?\n
            ])

            echo_lines_until_closed(socket)

          other ->
            Logger.debug("Failed to decode JSON: #{inspect(other)}")
            :gen_tcp.send(socket, "malformed request\n")
            {:error, :invalid_request}
        end

      {:error, :closed} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp prime?(number) when not is_integer(number), do: false
  defp prime?(number) when number <= 1, do: false
  defp prime?(number) when number in [2, 3], do: true

  defp prime?(number) do
    not Enum.any?(2..trunc(:math.sqrt(number)), &(rem(number, &1) == 0))
  end
end
