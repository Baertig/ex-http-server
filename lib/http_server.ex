defmodule HttpServer do
  require Logger

  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    {:ok, pid} =
      Task.Supervisor.start_child(HttpServer.ConnectionSupervisor, fn -> serve(client) end)

    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    request = HttpServer.Request.parse_request(socket)
    Logger.info("Request: \"#{request.method} #{request.path}\"")

    base_path = Application.get_env(:http_server, :directory, "./web")

    case File.read(Path.join(base_path, request.path)) do
      {:ok, content} -> HttpServer.Response.send(socket, 200, content)
      {:error, :enoent} -> HttpServer.Response.send(socket, 404)
      {:error, _} -> HttpServer.Response.send(socket, 500)
    end

    serve(socket)
  end
end
