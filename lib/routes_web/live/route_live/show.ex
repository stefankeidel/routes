defmodule RoutesWeb.RouteLive.Show do
  use RoutesWeb, :live_view

  alias Routes.Routing
  alias Routes.Routing.RouteVersion

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    route = Routing.get_route!(id)
    route_versions = Routing.list_route_versions(route.id)
    changeset = Routing.change_route_version(%RouteVersion{})

    {:ok,
     socket
     |> assign(:current_scope, nil)
     |> assign(:route, route)
     |> assign(:version_form, to_form(changeset))
     |> stream(:route_versions, route_versions)}
  end

  @impl true
  def handle_event("validate_version", %{"route_version" => params}, socket) do
    changeset =
      %RouteVersion{}
      |> Routing.change_route_version(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :version_form, to_form(changeset))}
  end

  @impl true
  def handle_event("create_version", %{"route_version" => params}, socket) do
    case Routing.create_route_version(socket.assigns.route, params) do
      {:ok, route_version} ->
        {:noreply,
         socket
         |> put_flash(:info, "Route version added.")
         |> assign(:version_form, to_form(Routing.change_route_version(%RouteVersion{})))
         |> stream_insert(:route_versions, route_version, at: 0)}

      {:error, changeset} ->
        {:noreply, assign(socket, :version_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_version", %{"id" => id}, socket) do
    route_version = Routing.get_route_version!(id)

    if route_version.route_id == socket.assigns.route.id do
      {:ok, _deleted} = Routing.delete_route_version(route_version)
      {:noreply, stream_delete(socket, :route_versions, route_version)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="space-y-8">
        <div class="rounded-3xl border border-slate-200/70 bg-white/90 p-8 shadow-lg shadow-slate-200/40">
          <div class="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
            <div class="space-y-3">
              <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                Route detail
              </p>
              <h1 class="text-3xl font-semibold text-slate-900">{@route.name}</h1>
              <p class="max-w-2xl text-sm text-slate-500">
                {@route.description || "Add a description to capture the intent of this route."}
              </p>
            </div>
            <div class="flex flex-wrap items-center gap-2">
              <.link
                navigate={~p"/routes/#{@route}/edit"}
                id="route-edit"
                class="inline-flex items-center rounded-full border border-slate-200 bg-white px-4 py-2 text-xs font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900"
              >
                Edit route
              </.link>
              <.link
                navigate={~p"/routes"}
                id="route-back"
                class="inline-flex items-center rounded-full border border-slate-200 bg-white px-4 py-2 text-xs font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900"
              >
                Back to routes
              </.link>
            </div>
          </div>
        </div>

        <div class="grid gap-8 lg:grid-cols-[1.1fr_0.9fr]">
          <div class="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                  Versions
                </p>
                <h2 class="mt-2 text-xl font-semibold text-slate-900">
                  Route versions
                </h2>
              </div>
            </div>

            <div id="route-versions" phx-update="stream" class="mt-6 grid gap-4">
              <div class="hidden rounded-2xl border border-dashed border-slate-200 px-6 py-10 text-sm text-slate-500 only:block">
                No versions yet. Publish your first version for this route.
              </div>
              <div
                :for={{id, route_version} <- @streams.route_versions}
                id={id}
                class="rounded-2xl border border-slate-200/70 bg-slate-50/60 px-5 py-4"
              >
                <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                  <div>
                    <div class="flex flex-wrap items-center gap-2">
                      <p class="text-lg font-semibold text-slate-900">
                        v{route_version.version_number}
                      </p>
                      <span class={[
                        "rounded-full px-3 py-1 text-xs font-semibold",
                        status_badge_class(route_version.status)
                      ]}>
                        {String.capitalize(route_version.status)}
                      </span>
                    </div>
                    <p class="mt-2 text-sm text-slate-500">
                      {route_version.notes || "No notes yet."}
                    </p>
                    <p class="mt-3 text-xs uppercase tracking-[0.2em] text-slate-400">Definition</p>
                    <p class="mt-1 text-sm text-slate-600">
                      {route_version.definition || "No definition captured."}
                    </p>
                  </div>
                  <div class="flex items-center gap-2">
                    <button
                      type="button"
                      id={"route-version-delete-#{route_version.id}"}
                      phx-click="delete_version"
                      phx-value-id={route_version.id}
                      phx-confirm="Delete this version?"
                      class="inline-flex items-center rounded-full border border-rose-200 bg-white px-4 py-2 text-xs font-semibold text-rose-600 transition hover:border-rose-300 hover:text-rose-700"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="rounded-3xl border border-slate-100 bg-white p-6 shadow-sm">
            <div>
              <p class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                New version
              </p>
              <h2 class="mt-2 text-xl font-semibold text-slate-900">
                Add a version
              </h2>
              <p class="mt-2 text-sm text-slate-500">
                Track updates with a version number, status, and definition.
              </p>
            </div>

            <.form
              for={@version_form}
              id="route-version-form"
              phx-change="validate_version"
              phx-submit="create_version"
              class="mt-6 space-y-5"
            >
              <.input
                field={@version_form[:version_number]}
                type="number"
                label="Version number"
                placeholder="1"
                class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 shadow-sm transition focus:border-slate-300 focus:outline-none focus:ring-2 focus:ring-slate-200"
                error_class="border-rose-300 ring-2 ring-rose-100"
                min="1"
              />
              <.input
                field={@version_form[:status]}
                type="select"
                label="Status"
                options={[Draft: "draft", Published: "published", Archived: "archived"]}
                class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 shadow-sm transition focus:border-slate-300 focus:outline-none focus:ring-2 focus:ring-slate-200"
                error_class="border-rose-300 ring-2 ring-rose-100"
              />
              <.input
                field={@version_form[:notes]}
                type="textarea"
                label="Release notes"
                placeholder="What changed in this version?"
                rows="3"
                class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 shadow-sm transition focus:border-slate-300 focus:outline-none focus:ring-2 focus:ring-slate-200"
                error_class="border-rose-300 ring-2 ring-rose-100"
              />
              <.input
                field={@version_form[:definition]}
                type="textarea"
                label="Definition"
                placeholder="Summarize the route definition or core rules."
                rows="4"
                class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 shadow-sm transition focus:border-slate-300 focus:outline-none focus:ring-2 focus:ring-slate-200"
                error_class="border-rose-300 ring-2 ring-rose-100"
              />

              <button
                type="submit"
                id="route-version-submit"
                class="inline-flex w-full items-center justify-center rounded-full bg-slate-900 px-6 py-3 text-sm font-semibold text-white shadow-sm transition hover:-translate-y-0.5 hover:bg-slate-800"
              >
                Add version
              </button>
            </.form>
          </div>
        </div>
      </section>
    </Layouts.app>
    """
  end

  defp status_badge_class("draft"), do: "bg-slate-200 text-slate-700"
  defp status_badge_class("published"), do: "bg-emerald-100 text-emerald-700"
  defp status_badge_class("archived"), do: "bg-amber-100 text-amber-700"
  defp status_badge_class(_status), do: "bg-slate-200 text-slate-700"
end
