defmodule MimeTypeCheckTest do
  @moduledoc false
  use ExUnit.Case, async: true
  use Plug.Test
  import Plug.Conn, only: [put_req_header: 3]
  import Phoenix.ConnTest, only: [build_conn: 0]

  @cwd File.cwd!()

  test "returns bad request when file mime type is invalid" do
    exe_file = %Plug.Upload{
      content_type: "application/x-dosexec",
      filename: "example.exe",
      path: get_file_path("example.exe")
    }

    conn =
      build_conn()
      |> put_req_header("content-type", "multipart/form-data")
      |> MimeTypeCheck.call(%{"document" => exe_file, "some_param" => "Lorem ipsum"})

    assert conn.resp_body == "{\"error_message\":\"Invalid file mime type in field: document\"}"
    assert conn.status == 400
  end

  test "returns bad request when more than one file mime type is invalid" do
    exe_file = %Plug.Upload{
      content_type: "application/x-dosexec",
      filename: "example.exe",
      path: get_file_path("example.exe")
    }

    sh_file = %Plug.Upload{
      content_type: "text/x-shellscript",
      filename: "example.sh",
      path: get_file_path("example.sh")
    }

    conn =
      build_conn()
      |> put_req_header("content-type", "multipart/form-data")
      |> MimeTypeCheck.call(%{"file1" => exe_file, "file2" => sh_file})

    assert conn.resp_body ==
             "{\"error_message\":\"Invalid files mime types in fields: file1, file2\"}"

    assert conn.status == 400
  end

  test "returns conn when file mime type is valid" do
    png_file = %Plug.Upload{
      content_type: "image/png",
      filename: "example.png",
      path: get_file_path("example.png")
    }

    conn =
      build_conn()
      |> put_req_header("content-type", "multipart/form-data")
      |> MimeTypeCheck.call(%{"document" => png_file, "some_param" => "Lorem ipsum"})

    assert %Plug.Conn{} = conn
    assert conn.status == nil
  end

  test "returns conn when content-type header is not multipart/form-data" do
    conn =
      build_conn()
      |> put_req_header("content-type", "application/json")
      |> MimeTypeCheck.call(%{"some_param" => "Lorem ipsum"})

    assert %Plug.Conn{} = conn
    assert conn.status == nil
  end

  test "returns bad request when any file of multiple field has mime type invalid" do
    exe_file = %Plug.Upload{
      content_type: "application/x-dosexec",
      filename: "example.exe",
      path: get_file_path("example.exe")
    }

    sh_file = %Plug.Upload{
      content_type: "text/x-shellscript",
      filename: "example.sh",
      path: get_file_path("example.sh")
    }

    png_file = %Plug.Upload{
      content_type: "image/png",
      filename: "example.png",
      path: get_file_path("example.png")
    }

    documents = %{
      0 => exe_file,
      1 => sh_file,
      2 => png_file
    }

    conn =
      build_conn()
      |> put_req_header("content-type", "multipart/form-data")
      |> MimeTypeCheck.call(%{"documents" => documents, "some_param" => "Lorem ipsum"})

    assert conn.resp_body == "{\"error_message\":\"Invalid file mime type in field: documents\"}"
    assert conn.status == 400
  end

  test "returns bad request when nested field has mime type invalid" do
    exe_file = %Plug.Upload{
      content_type: "application/x-dosexec",
      filename: "example.exe",
      path: get_file_path("example.exe")
    }

    user = %{
      "name" => "Foo Bar",
      "profile" => %{
        "image" => exe_file
      }
    }

    conn =
      build_conn()
      |> put_req_header("content-type", "multipart/form-data")
      |> MimeTypeCheck.call(%{"user" => user, "some_param" => "Lorem ipsum"})

    assert conn.resp_body == "{\"error_message\":\"Invalid file mime type in field: user\"}"
    assert conn.status == 400
  end

  defp get_file_path(filename),
    do: Path.join([@cwd, "test", "support", "fixtures", filename])
end
