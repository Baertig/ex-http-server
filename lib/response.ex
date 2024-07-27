defmodule HttpServer.Response do
  defstruct [:status_code, :body, version: "HTTP/1.1", headers: %{}]

  def send(socket, code) do
    response =
      %HttpServer.Response{
        status_code: code
      }
      |> put_header("Content-Length", 0)
      |> to_string()

    :gen_tcp.send(socket, response)
  end

  def send(socket, 200, body) do
    response =
      %HttpServer.Response{
        status_code: 200,
        body: body
      }
      |> put_header("Content-Length", byte_size(body))
      |> to_string()

    :gen_tcp.send(socket, response)
  end

  defp put_header(response, field, value) do
    Map.update!(response, :headers, fn headers -> Map.put(headers, field, value) end)
  end
end

defimpl String.Chars, for: HttpServer.Response do
  def to_string(response) do
    code = response.status_code
    first_line = "#{response.version} #{code} #{status_phrase(code)}"

    header_fields =
      Enum.map(response.headers, fn {k, v} -> "#{k}: #{v}" end)
      |> Enum.join("\r\n")

    body = response.body || ""

    first_line <> "\r\n" <> header_fields <> "\r\n\r\n" <> body
  end

  defp status_phrase(code) do
    %{
      200 => "Ok",
      400 => "Bad Request",
      404 => "Not Found",
      500 => "Internal Server Error"
    }[code]
  end
end
