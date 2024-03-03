defmodule HotDogServer do
  require Logger
  
  @hotdog File.read!("hotdog") |> String.trim()
  @mustard File.read!("mustard") |> String.trim()

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
    with {:ok, data} <- :gen_tcp.recv(socket, 0),
         :continue <- read_line(data, socket) do
      IO.inspect(data)
      serve(socket)
    end
  end

  def read_line("\r\n", socket) do
    :gen_tcp.send(socket, "HTTP/1.1 200 OK\r\n")
    :gen_tcp.send(socket, "\r\n")
    hotdog(socket, :hotdog)
  end

  def read_line(_not_rn_lol, _socket), do: :continue
  
  def hotdog(socket, style) do
    with :ok <- :gen_tcp.send(socket, content(style)) do
      :timer.sleep(1000)
      hotdog(socket, flip(style))
    end
  end
  
  def flip(:hotdog), do: :mustard
  def flip(:mustard), do: :hotdog
  
  def content(:hotdog), do: @hotdog
  def content(:mustard), do: @mustard
end
