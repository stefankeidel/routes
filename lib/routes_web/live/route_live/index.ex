defmodule RoutesWeb.RouteLive.Index do
  use RoutesWeb, :live_view

  alias Routes.Routing
  alias Routes.Routing.RouteVersion

  @impl true
  def mount(_params, _session, socket) do
    routes = Routing.list_routes_with_latest_versions()

    {:ok,
     socket
     |> assign(:current_scope, nil)
     |> stream(:routes, routes)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    route = Routing.get_route!(id)
    {:ok, _deleted} = Routing.delete_route(route)

    {:noreply, stream_delete(socket, :routes, route)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="space-y-8">
        <div class="flex flex-col gap-4 rounded-3xl border border-slate-200/70 bg-white/90 p-6 shadow-lg shadow-slate-200/40">
          <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                Route Library
              </p>
              <h1 class="mt-2 text-3xl font-semibold text-slate-900">Routes</h1>
              <p class="mt-2 text-sm text-slate-500">
                Capture the intent of each route and track how it evolves over time.
              </p>
            </div>
            <div class="flex items-center gap-3">
              <.link
                navigate={~p"/routes/new"}
                id="route-new"
                class="inline-flex items-center justify-center rounded-full bg-slate-900 px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:-translate-y-0.5 hover:bg-slate-800"
              >
                New route
              </.link>
            </div>
          </div>
        </div>

        <div
          id="routes"
          phx-update="stream"
          class="grid gap-4 rounded-3xl border border-slate-100 bg-white p-4 shadow-sm"
        >
          <div
            id="routes-empty"
            class="hidden rounded-2xl border border-dashed border-slate-200 px-6 py-12 text-center text-sm text-slate-500 only:block"
          >
            No routes yet. Create your first route to start versioning.
          </div>
          <div
            :for={{id, route} <- @streams.routes}
            id={id}
            class="group rounded-2xl border border-slate-200/70 bg-slate-50/60 px-5 py-4 transition hover:border-slate-300 hover:bg-white"
          >
            <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p class="text-lg font-semibold text-slate-900">{route.name}</p>
                <p class="mt-1 text-sm text-slate-500">
                  {route.description || "No description yet. Add a note about how this route works."}
                </p>
                <%= if latest = route.latest_version do %>
                  <div class="mt-3 flex flex-wrap items-center gap-3 text-sm text-slate-600">
                    <span class="inline-flex items-center rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
                      Latest v{latest.version_number}
                    </span>
                    <a
                      href={latest.reference_url}
                      target="_blank"
                      rel="noreferrer noopener"
                      class="inline-flex items-center gap-1 text-xs font-semibold text-slate-700 underline decoration-dotted decoration-slate-400 underline-offset-4 hover:text-slate-900"
                    >
                      View on {RouteVersion.platform_label(latest.reference_platform)}
                      <.icon name="hero-arrow-up-right-mini" class="size-3" />
                    </a>
                  </div>
                <% else %>
                  <p class="mt-3 text-xs uppercase tracking-[0.3em] text-slate-300">
                    No published version
                  </p>
                <% end %>
              </div>
              <div class="flex flex-wrap items-center gap-2">
                <.link
                  navigate={~p"/routes/#{route}"}
                  id={"route-view-#{route.id}"}
                  class="inline-flex items-center rounded-full border border-slate-200 bg-white px-4 py-2 text-xs font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900"
                >
                  View
                </.link>
                <.link
                  navigate={~p"/routes/#{route}/edit"}
                  id={"route-edit-#{route.id}"}
                  class="inline-flex items-center rounded-full border border-slate-200 bg-white px-4 py-2 text-xs font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900"
                >
                  Edit
                </.link>
                <button
                  type="button"
                  id={"route-delete-#{route.id}"}
                  phx-click="delete"
                  phx-value-id={route.id}
                  phx-confirm="Delete this route and its versions?"
                  class="inline-flex items-center rounded-full border border-rose-200 bg-white px-4 py-2 text-xs font-semibold text-rose-600 transition hover:border-rose-300 hover:text-rose-700"
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end
end
