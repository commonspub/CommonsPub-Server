# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule CommonsPub.HTML.Formatter do
  alias CommonsPub.HTML.Scrubber
  alias MoodleNet.Config
  alias MoodleNet.Repo
  alias MoodleNet.Users.User
  alias MoodleNet.Users

  @safe_mention_regex ~r/^(\s*(?<mentions>([@|&amp;|\+].+?\s+){1,})+)(?<rest>.*)/s
  @link_regex ~r"((?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~%:/?#[\]@!\$&'\(\)\*\+,;=.]+)|[0-9a-z+\-\.]+:[0-9a-z$-_.+!*'(),]+"ui
  @markdown_characters_regex ~r/(`|\*|_|{|}|[|]|\(|\)|#|\+|-|\.|!)/

  defp linkify_opts do
    Config.get(CommonsPub.HTML.Formatter, []) ++
      [
        hashtag: true,
        hashtag_handler: &CommonsPub.HTML.Formatter.hashtag_handler/4,
        mention: true,
        mention_handler: &CommonsPub.HTML.Formatter.mention_handler/4
      ]
  end

  def escape_mention_handler("@" <> nickname = mention, buffer, _, _) do
    case Users.get(nickname) do
      %User{} ->
        # escape markdown characters with `\\`
        # (we don't want something like @user__name to be parsed by markdown)
        String.replace(mention, @markdown_characters_regex, "\\\\\\1")

      _ ->
        buffer
    end
  end

  def escape_mention_handler("&" <> nickname = mention, buffer, _, _) do
    String.replace(mention, @markdown_characters_regex, "\\\\\\1")
  end

  def escape_mention_handler("+" <> nickname = mention, buffer, _, _) do
    String.replace(mention, @markdown_characters_regex, "\\\\\\1")
  end

  def mention_handler("@" <> nickname, buffer, opts, acc) do
    # IO.inspect(mention: nickname)

    case Users.get(nickname) do
      %{id: id} = user ->
        mention_prepare(user, acc, Map.get(opts, :content_type))

      _ ->
        {buffer, acc}
    end
  end

  def mention_handler("&" <> nickname, buffer, opts, acc) do
    IO.inspect(mention: nickname)

    case MoodleNet.Communities.get(nickname) do
      %{id: id} = character ->
        # IO.inspect(found: character)
        mention_prepare(character, acc, Map.get(opts, :content_type))

      _ ->
        {buffer, acc}
    end
  end

  def mention_handler("+" <> nickname, buffer, opts, acc) do
    IO.inspect(mention: nickname)

    ct = Map.get(opts, :content_type)

    # TODO, link to Collection and Taggable

    if MoodleNetWeb.Helpers.Common.is_numeric(nickname) and
         Code.ensure_loaded?(Taxonomy.TaxonomyTags) do
      with {:ok, category} <- Taxonomy.TaxonomyTags.maybe_make_category(nil, nickname) do
        mention_prepare(category, acc, ct)
      end
    else
      case MoodleNet.Collections.get(nickname) do
        %{id: id} = character ->
          IO.inspect(found: character)
          mention_prepare(character, acc, ct)

        _ ->
          # case CommonsPub.Tag.Categories.get(nickname) do
          #   %{id: id} = character ->
          #     IO.inspect(found: character)
          #     mention_prepare(character, acc, ct)

          #   _ ->
          {buffer, acc}
          # end
      end
    end
  end

  defp mention_prepare(obj, acc, content_type \\ "text/html")

  defp mention_prepare(obj, acc, nil),
    do: mention_prepare(obj, acc, "text/html")

  defp mention_prepare(obj, acc, "text/html") do
    obj = MoodleNet.Actors.obj_load_actor(obj)
    url = MoodleNet.Actors.obj_actor(obj).canonical_url
    display_name = MoodleNet.Actors.display_username(obj)

    link =
      Phoenix.HTML.Tag.content_tag(
        :span,
        Phoenix.HTML.Tag.content_tag(
          :a,
          display_name,
          "data-user": obj.id,
          class: "u-url mention",
          href: url,
          rel: "ugc"
        ),
        class: "h-card"
      )
      |> Phoenix.HTML.safe_to_string()

    {link, %{acc | mentions: MapSet.put(acc.mentions, {display_name, obj})}}
  end

  defp mention_prepare(obj, acc, "text/markdown") do
    obj = MoodleNet.Actors.obj_load_actor(obj)
    url = MoodleNet.Actors.obj_actor(obj).canonical_url
    display_name = MoodleNet.Actors.display_username(obj)

    link = "[#{display_name}](#{url})"

    {link, %{acc | mentions: MapSet.put(acc.mentions, {display_name, obj})}}
  end

  def hashtag_handler("#" <> tag = tag_text, _buffer, opts, acc) do
    url = "#{MoodleNetWeb.base_url()}/instance/tag/#{tag}"

    link =
      if(Map.get(opts, :content_type) == "text/markdown") do
        "[#{tag_text}](#{url})"
      else
        Phoenix.HTML.Tag.content_tag(:a, tag_text,
          class: "hashtag",
          "data-tag": tag,
          href: url,
          rel: "tag ugc"
        )
        |> Phoenix.HTML.safe_to_string()
      end

    {link, %{acc | tags: MapSet.put(acc.tags, {tag_text, tag})}}
  end

  @doc """
  Parses a text and replace plain text links with HTML. Returns a tuple with a result text, mentions, and hashtags.

  If the 'safe_mention' option is given, only consecutive mentions at the start the post are actually mentioned.
  """
  @spec linkify(String.t(), keyword()) ::
          {String.t(), [{String.t(), User.t()}], [{String.t(), String.t()}]}
  def linkify(text, options \\ []) do
    options = linkify_opts() ++ options

    if options[:safe_mention] && Regex.named_captures(@safe_mention_regex, text) do
      %{"mentions" => mentions, "rest" => rest} = Regex.named_captures(@safe_mention_regex, text)
      acc = %{mentions: MapSet.new(), tags: MapSet.new()}

      {text_mentions, %{mentions: mentions}} = Linkify.link_map(mentions, acc, options)
      {text_rest, %{tags: tags}} = Linkify.link_map(rest, acc, options)

      {text_mentions <> text_rest, MapSet.to_list(mentions), MapSet.to_list(tags)}
    else
      acc = %{mentions: MapSet.new(), tags: MapSet.new()}
      {text, %{mentions: mentions, tags: tags}} = Linkify.link_map(text, acc, options)

      {text, MapSet.to_list(mentions), MapSet.to_list(tags)}
    end
  end

  @doc """
  Escapes a special characters in mention names.
  """
  def mentions_escape(text, options \\ []) do
    options =
      Keyword.merge(options,
        mention: true,
        url: false,
        mention_handler: &CommonsPub.HTML.Formatter.escape_mention_handler/4
      )

    if options[:safe_mention] && Regex.named_captures(@safe_mention_regex, text) do
      %{"mentions" => mentions, "rest" => rest} = Regex.named_captures(@safe_mention_regex, text)
      Linkify.link(mentions, options) <> Linkify.link(rest, options)
    else
      Linkify.link(text, options)
    end
  end

  def html_escape({text, mentions, hashtags}, type) do
    {html_escape(text, type), mentions, hashtags}
  end

  def html_escape(text, "text/html") do
    Scrubber.filter_tags(text)
  end

  def html_escape(text, "text/plain") do
    Regex.split(@link_regex, text, include_captures: true)
    |> Enum.map_every(2, fn chunk ->
      {:safe, part} = Phoenix.HTML.html_escape(chunk)
      part
    end)
    |> Enum.join("")
  end
end