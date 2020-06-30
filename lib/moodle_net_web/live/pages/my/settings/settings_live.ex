defmodule MoodleNetWeb.SettingsLive do
  use MoodleNetWeb, :live_view
  import MoodleNetWeb.Helpers.Common
  alias MoodleNetWeb.Helpers.{Profiles}
  alias MoodleNetWeb.GraphQL.UsersResolver
  alias MoodleNet.Users.User

  def mount(_params, session, socket) do
    {:ok, session_token} = MoodleNet.Access.fetch_token_and_user(session["auth_token"])
    user = e(session_token, :user, %{})

    {:ok,
     socket
     |> assign(
       page_title: "Settings",
       selected_tab: "general",
       current_user: user,
       session: session_token
     )}
  end

  def handle_event("post", data, socket) do
    profile = data |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)

    {:ok, edit_profile} =
      UsersResolver.update_profile(%{profile: profile}, %{
        context: %{current_user: socket.assigns.current_user}
      })

    # IO.inspect(edit_profile)

    {:noreply,
     socket
     |> put_flash(:info, "Published!")
     |> redirect(to: "/my/profile")}
  end

  def handle_params(%{} = params, url, socket) do
    user = Profiles.user_load(socket, params, %{image: true, icon: true, actor: true})

    {:noreply,
     assign(socket,
       user: user
     )}
  end
end
