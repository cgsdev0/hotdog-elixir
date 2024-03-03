defmodule HotDogServer do
  @hotdog File.read!("hotdog")
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

  def accumulate("\r\n", socket) do
    write_line("HTTP/1.1 200 OK\r\n", socket)
    write_line("\r\n", socket)
    write_line(@hotdog, socket)
    write_line("hotdog delivered 🌭", socket)
    write_line("\r\n", socket)
    :gen_tcp.close(socket)
    nil
  end

  def accumulate(_not_rn_lol, _socket) do
    :ok
  end

  def write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end
end
