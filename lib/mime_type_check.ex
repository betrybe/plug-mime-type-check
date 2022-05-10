defmodule MimeTypeCheck do
  @moduledoc """
  A plug that checks the mime-type of a uploaded file through a request
  """
  import Plug.Conn

  @allowed_mime_types ~w(
    application/zip
    application/pdf
    application/json
    text/plain
    text/html
    image/bmp
    image/gif
    image/jpeg
    image/jpg
    image/pipeg
    image/svg+xml
    image/tiff
    image/png
  )

  def init(opts) do
    {allowed_mime_types, opts} = Keyword.pop(opts, :allowed_mime_types)

    unless allowed_mime_types do
      raise ArgumentError, "MimeTypeCheck expects a set of mime-types to be given in :allowed_mime_types"
    end

    opts
  end

  def call(conn, opts) do
    case get_req_header(conn, "content-type") do
      ["multipart/form-data"] -> check_mime_type(conn, opts)
      _ -> conn
    end
  end

  defp check_mime_type(conn, opts) do
    case check_invalids(opts) do
      [] -> conn
      invalid_fields -> send_bad_request_response(conn, invalid_fields)
    end
  end

  defp check_invalids(opts) do
    opts
    |> Enum.map(fn {k, v} -> {k, check_value(v)} end)
    |> Enum.filter(fn v -> v |> elem(1) |> filter_invalids() end)
    |> Enum.map(fn v -> elem(v, 0) end)
  end

  defp check_value(%Plug.Upload{} = v),
    do: Enum.member?(@allowed_mime_types, get_file_type(v.path))

  defp check_value(v) when is_map(v), do: check_invalids(v)
  defp check_value(_), do: true

  defp filter_invalids(v) when is_list(v), do: v != []
  defp filter_invalids(v), do: v == false

  defp send_bad_request_response(conn, fields) do
    sufix = if length(fields) > 1, do: "s", else: ""
    msg = "Invalid file#{sufix} mime type#{sufix} in field#{sufix}: " <> Enum.join(fields, ", ")

    conn
    |> put_status(:bad_request)
    |> Phoenix.Controller.json(%{error_message: msg})
    |> halt()
  end

  defp get_file_type(path) do
    {type, 0} = System.cmd("file", ["--mime-type", "-b", path])

    String.replace(type, "\n", "")
  end
end
