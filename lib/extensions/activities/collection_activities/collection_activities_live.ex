defmodule MoodleNetWeb.CollectionLive.CollectionActivitiesLive do
  use MoodleNetWeb, :live_component

  alias MoodleNetWeb.Component.{
    ActivitiesListLive
  }

  alias MoodleNetWeb.GraphQL.{
    CollectionsResolver
  }

  # def mount(socket) do
  #   {
  #     :ok,
  #     socket,
  #     temporary_assigns: [
  #       activities: [],
  #       page: 1,
  #       has_next_page: false,
  #       after: [],
  #       before: [],
  #       pagination_target: "#instance-activities"
  #     ]
  #   }
  # end

  def update(assigns, socket) do
    # IO.inspect(assigns, label: "ASSIGNS:")
    {
      :ok,
      socket
      |> assign(assigns)
      |> fetch(assigns)
    }
  end

  defp fetch(socket, assigns) do
    # IO.inspect(after: assigns.after)

    {:ok, outboxes} =
      CollectionsResolver.outbox_edge(
        assigns.collection,
        %{after: assigns.after, limit: 10},
        %{context: %{current_user: assigns.current_user}}
      )

    assign(socket,
      activities: outboxes.edges,
      has_next_page: outboxes.page_info.has_next_page,
      after: outboxes.page_info.end_cursor,
      before: outboxes.page_info.start_cursor
    )
  end

  def handle_event("load-more", _, %{assigns: assigns} = socket) do
    {:noreply, socket |> assign(page: assigns.page + 1) |> fetch(assigns)}
  end

  def render(assigns) do
    ~L"""
      <div id="collection-activities">
      <%= live_component(
        @socket,
        ActivitiesListLive,
        assigns
        )
      %>
      </div>
    """
  end
end
