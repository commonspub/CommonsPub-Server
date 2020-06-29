defmodule MoodleNetWeb.My.TimelineLive do
  use MoodleNetWeb, :live_component

  alias MoodleNetWeb.Component.{
    ActivitiesListLive
  }
  alias MoodleNetWeb.GraphQL.{
    InstanceResolver
  }

  alias MoodleNetWeb.GraphQL.{
    UsersResolver
  }

  def mount(socket) do
    {
      :ok,
      socket
      |> assign(
        page: 1,
        has_next_page: false,
        after: [],
        before: []
      )
      #  |> fetch(), temporary_assigns: [activities: []]
    }
  end

  def update(assigns, socket) do
    IO.inspect(assigns)

    {
      :ok,
      socket
      |> fetch(assigns)
    }
  end

  defp fetch(socket, assigns) do
    # IO.inspect(ma: assigns)
    # TODO: replace with logged in user's inbox
    {:ok, inbox} =
      UsersResolver.user_inbox_edge(
        assigns.current_user,
        %{after: socket.assigns.after, limit: 10},
        # %{after: socket.assigns.after, before: socket.assigns.before, limit: 10},
        %{}
      )

    IO.inspect(inbox)

    assign(socket,
      activities: inbox.edges,
      has_next_page: inbox.page_info.has_next_page,
      after: inbox.page_info.end_cursor,
      before: inbox.page_info.start_cursor
    )
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, socket |> assign(page: assigns.page + 1) |> fetch(assigns)}
  end

  def render(assigns) do
    ~L"""
    <%= live_component(
      @socket,
      ActivitiesListLive,
      assigns
      )
    %>
  """
  end
end
