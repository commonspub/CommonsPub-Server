# SPDX-License-Identifier: AGPL-3.0-only

defmodule CommonsPub.Search.Meili do
  require Logger

  alias ActivityPub.HTTP

  def search_meili(%{} = params, index) when is_binary(index) do
    IO.inspect(search_params: params)
    {:ok, req} = api(:post, params, index <> "/search")
    res = Jason.decode!(req.body)
    # IO.inspect(res)
    res
  end

  def get(object) do
    get(object, "")
  end

  def set_attributes(attrs, index) do
    settings(%{attributesForFaceting: attrs}, index)
  end

  def post(object) do
    post(object, "")
  end

  def post(object, index_path, fail_silently \\ false) do
    api(:post, object, index_path, fail_silently)
  end

  def put(object) do
    put(object, "")
  end

  def put(object, index_path, fail_silently \\ false) do
    api(:put, object, index_path, fail_silently)
  end

  def settings(object, index) do
    post(object, index <> "/settings")
  end

  def api(http_method, object, index_path, fail_silently \\ false) do
    search_instance = System.get_env("SEARCH_MEILI_INSTANCE", "localhost:7700")
    api_key = System.get_env("MEILI_MASTER_KEY")

    url = "http://#{search_instance}/indexes" <> index_path

    # if api_key do
    headers = [
      {"X-Meili-API-Key", api_key},
      {"Content-type", "application/json"}
    ]

    # else
    #   headers = [] #FIXME
    # end

    with {:ok, %{status: code} = ret} when code == 200 or code == 201 or code == 202 <-
           http_request(http_method, url, headers, object) do
      # IO.inspect(ret)
      {:ok, ret}
    else
      {_, message} ->
        http_error(fail_silently, http_method, message, object)
    end
  end

  if Mix.env() == :test do
    def http_error(fail_silently, http_method, _message, _object) do
      Logger.info("Meili - Could not #{http_method} objects")
    end
  else
    def http_error(fail_silently, http_method, message, object) do
      if(fail_silently) do
        Logger.info("Meili - Could not #{http_method} object")
        # Logger.info(inspect(object))
        :ok
      else
        Logger.error("Meili - Couldn't #{http_method} objects:")
        Logger.warn(inspect(message))
        Logger.info(inspect(object))
        {:error, message}
      end
    end
  end

  def http_request(http_method, url, headers, object) do
    if(http_method == :get) do
      query_str = URI.encode_query(object)
      get_url = url <> "?" <> query_str
      apply(HTTP, http_method, [get_url, headers])
    else
      # IO.inspect(object)
      json = Jason.encode!(object)
      # IO.inspect(json: json)
      apply(HTTP, http_method, [url, json, headers])
    end
  end
end
