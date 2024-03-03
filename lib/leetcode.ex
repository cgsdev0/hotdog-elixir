defmodule HotDogServer do
  @hotdog File.read!("hotdog") |> String.trim()
  @mustard File.read!("mustard") |> String.trim()
  require Logger

  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  def loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Task.start_link(fn -> serve(client) end)
    loop_acceptor(socket)
  end

  def serve(socket) do
    with {:ok, data} <- :gen_tcp.recv(socket, 0) do
      IO.inspect(data)
      if accumulate(data, socket) do
        serve(socket)
      end
    end
  end

  def write_thing_part_2(socket, :mustard) do
    write_line(@mustard, socket)
  end

  def write_thing_part_2(socket, :hotdog) do
    write_line(@hotdog, socket)
  end

  def hotdog(socket, style) do
    case write_thing_part_2(socket, style) do
      {:error, _} -> :closed
      :ok ->
        :timer.sleep(1000)
        hotdog(socket, if(style == :hotdog, do: :mustard, else: :hotdog))
    end
  end

  def accumulate("\r\n", socket) do
    write_line("HTTP/1.1 200 OK\r\n", socket)
    write_line("\r\n", socket)
    hotdog(socket, :hotdog)
  end

  def accumulate(_not_rn_lol, _socket) do
    :ok
  end

  def write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end
end
