defmodule HttpServer.Request do
  require Logger
  defstruct [:method, :path, :version, headers: %{}]

  @spec parse_request(port() | {:"$inet", atom(), any()}) :: %HttpServer.Request{}
  def parse_request(socket) do
    {:ok, line} = :gen_tcp.recv(socket, 0)
    [method, path, version] = String.trim(line) |> String.split(" ")

    normalized_path = if String.ends_with?(path, "/"), do: path <> "index.html", else: path

    request = %HttpServer.Request{method: method, path: normalized_path, version: version}
    parse_headers(socket, request)
  end

  defp parse_headers(socket, request) do
    {:ok, line} = :gen_tcp.recv(socket, 0)

    case line do
      "\r\n" -> request
      header_field -> parse_headers(socket, add_header_field(request, header_field))
    end
  end

  defp add_header_field(request, line) do
    field = String.trim(line) |> String.split(": ")

    case field do
      [key, value] ->
        Map.update!(
          request,
          :headers,
          &Map.update(&1, key, "", fn current_value -> "#{current_value}, #{value}" end)
        )

      _ ->
        Logger.warning(
          "malformed header field: \"#{line}\" from Request #{request.method} #{request.path}"
        )

        request
    end
  end
end
