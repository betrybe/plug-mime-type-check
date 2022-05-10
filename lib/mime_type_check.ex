defmodule MimeTypeCheck do
  @moduledoc """
  A plug that checks the mime-type of a uploaded file through a request

  It requires an options:

    * `:allowed_mime_types` - a list of allowed file mime types for the route. It must be a list.

  To use you can just plug in your controller and it will work to all your actions.
  You must pass the `:allowed_mime_types` list, for example:

      plug MimeTypeCheck, allowed_mime_types: ["text/csv"]

  You can apply just to defined actions, for example:

      plug MimeTypeCheck, allowed_mime_types: ["text/csv"] when action in [:create, :update]

  Or you can plug in your `router.ex` file:

      pipeline :uploads do
        plug MimeTypeCheck, allowed_mime_types: ["text/csv"]
      end

      scope "/api", MyModuleWeb do
        pipe_through :uploads

        post "/upload", UploadController, :upload
      end
  """
  import Plug.Conn

  def init(opts) do
    {allowed_mime_types, _} = Keyword.pop(opts, :allowed_mime_types)

    unless allowed_mime_types do
      raise ArgumentError,
            "MimeTypeCheck expects a set of mime-types to be given in :allowed_mime_types"
    end

    %{allowed_mime_types: allowed_mime_types}
  end

  def call(conn, opts) do
    case get_req_header(conn, "content-type") do
      ["multipart/form-data"] -> check_mime_type(conn, opts)
      _ -> conn
    end
  end

  defp check_mime_type(%{params: params} = conn, opts) do
    case check_invalids(params, opts[:allowed_mime_types]) do
      [] -> conn
      invalid_fields -> send_bad_request_response(conn, invalid_fields)
    end
  end

  defp check_invalids(params, allowed_mime_types) do
    params
    |> Enum.map(fn {k, v} -> {k, check_value(v, allowed_mime_types)} end)
    |> Enum.filter(fn v -> v |> elem(1) |> filter_invalids() end)
    |> Enum.map(fn v -> elem(v, 0) end)
  end

  defp check_value(%Plug.Upload{} = v, allowed_mime_types),
    do: Enum.member?(allowed_mime_types, get_file_type(v.path))

  defp check_value(v, allowed_mime_types) when is_map(v),
    do: check_invalids(v, allowed_mime_types)

  defp check_value(_, _), do: true

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
