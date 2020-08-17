defmodule MoodleNetWeb.SearchLive do
  use MoodleNetWeb, :live_view

  import MoodleNetWeb.Helpers.Common

  alias MoodleNetWeb.Component.{
    TabNotFoundLive
  }

  alias MoodleNetWeb.SearchLive.ResultsLive

  def mount(params, session, socket) do
    socket = init_assigns(params, session, socket)
    IO.inspect(params, label: "PARAMS")

    {:ok,
     socket
     |> assign(
       page_title: "Search",
       me: false,
       current_user: socket.assigns.current_user,
       selected_tab: "all",
       search: "",
       hits: [],
       facets: %{},
       num_hits: nil
     )}
  end

  def handle_params(%{"search" => q, "tab" => tab} = params, _url, socket)
      when q != "" do
    IO.inspect(q, label: "SEARCH")
    IO.inspect(tab, label: "TAB")

    facet_filters =
      if tab != "all" do
        %{"index_type" => tab}
      end

    search = CommonsPub.Search.Meili.search(q, nil, ["index_type"], facet_filters)

    IO.inspect(search)

    hits =
      if(Map.has_key?(search, "hits") and length(search["hits"])) do
        # search["hits"]
        hits = Enum.map(search["hits"], &search_hit_prepare/1)
        # Enum.filter(hits, & &1)
      end

    # note we only get proper facets when not already faceting
    facets =
      if tab == "all" and Map.has_key?(search, "facetsDistribution") do
        search["facetsDistribution"]
      else
        socket.assigns.facets
      end

    # IO.inspect(hits)

    {:noreply,
     assign(socket,
       selected_tab: tab,
       hits: hits,
       facets: facets,
       num_hits: search["nbHits"],
       search: q

       #  current_user: socket.assigns.current_user
     )}
  end

  def handle_params(%{"tab" => tab} = params, _url, socket) do
    IO.inspect(tab, label: "TAB")

    {:noreply,
     assign(socket,
       selected_tab: tab
       #  current_user: socket.assigns.current_user
     )}
  end

  def handle_params(params, _url, socket) do
    # community =
    # Communities.community_load(socket, params, %{icon: true, image: true, actor: true})

    # IO.inspect(community, label: "community")

    {:noreply,
     assign(socket,
       #  community: community,
       current_user: socket.assigns.current_user
     )}
  end

  defp link_body(name, icon) do
    assigns = %{name: name, icon: icon}

    ~L"""
      <i class="<%= @icon %>"></i>
      <%= @name %>
    """
  end

  def search_hit_prepare(hit) do
    # is this safe?
    hit |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
  end
end
