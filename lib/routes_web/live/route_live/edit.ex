defmodule RoutesWeb.RouteLive.Edit do
  use RoutesWeb, :live_view

  alias Routes.Routing

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    route = Routing.get_route!(id)
    changeset = Routing.change_route(route)

    {:ok,
     socket
     |> assign(:current_scope, nil)
     |> assign(:route, route)
     |> assign(:form, to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"route" => route_params}, socket) do
    changeset =
      socket.assigns.route
      |> Routing.change_route(route_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"route" => route_params}, socket) do
    case Routing.update_route(socket.assigns.route, route_params) do
      {:ok, route} ->
        {:noreply,
         socket
         |> put_flash(:info, "Route updated successfully.")
         |> push_navigate(to: ~p"/routes/#{route}")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="space-y-8">
        <div class="rounded-3xl border border-slate-200/70 bg-white/90 p-8 shadow-lg shadow-slate-200/40">
          <div class="flex flex-col gap-3">
            <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
              Edit Route
            </p>
            <h1 class="text-3xl font-semibold text-slate-900">Update {@route.name}</h1>
            <p class="text-sm text-slate-500">
              Keep the route details current before publishing new versions.
            </p>
          </div>
        </div>

        <div class="rounded-3xl border border-slate-100 bg-white p-8 shadow-sm">
          <.form
            for={@form}
            id="route-form"
            phx-change="validate"
            phx-submit="save"
            class="space-y-6"
          >
            <div class="grid gap-5">
              <.input
                field={@form[:name]}
                label="Route name"
                placeholder="Harbor Express"
                class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 shadow-sm transition focus:border-slate-300 focus:outline-none focus:ring-2 focus:ring-slate-200"
                error_class="border-rose-300 ring-2 ring-rose-100"
              />
              <.input
                field={@form[:description]}
                type="textarea"
                label="Description"
                placeholder="Summarize the route purpose, path, and key checkpoints."
                rows="4"
                class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 shadow-sm transition focus:border-slate-300 focus:outline-none focus:ring-2 focus:ring-slate-200"
                error_class="border-rose-300 ring-2 ring-rose-100"
              />
            </div>
            <div class="flex flex-wrap items-center gap-3">
              <button
                type="submit"
                id="route-submit"
                class="inline-flex items-center justify-center rounded-full bg-slate-900 px-6 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:-translate-y-0.5 hover:bg-slate-800"
              >
                Save changes
              </button>
              <.link
                navigate={~p"/routes/#{@route}"}
                id="route-cancel"
                class="inline-flex items-center justify-center rounded-full border border-slate-200 bg-white px-6 py-2.5 text-sm font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900"
              >
                Cancel
              </.link>
            </div>
          </.form>
        </div>
      </section>
    </Layouts.app>
    """
  end
end
