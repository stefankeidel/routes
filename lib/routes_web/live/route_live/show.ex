defmodule RoutesWeb.RouteLive.Show do
  use RoutesWeb, :live_view

  alias Routes.Routing
  alias Routes.Routing.RouteVersion

  @status_options [
    {"Draft", "draft"},
    {"Published", "published"},
    {"Archived", "archived"}
  ]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    route = Routing.get_route!(id)
    route_versions = Routing.list_route_versions(route.id)
    next_version_number = Routing.next_route_version_number(route.id)
    changeset = Routing.change_route_version(%RouteVersion{version_number: next_version_number})

    {:ok,
     socket
     |> assign(:current_scope, nil)
     |> assign(:route, route)
     |> assign(:next_version_number, next_version_number)
     |> assign(:platform_options, RouteVersion.platform_select_options())
     |> assign(:status_options, @status_options)
     |> assign(:editing_version_id, nil)
     |> assign(:edit_version_form, nil)
     |> assign(:version_form, to_form(changeset))
     |> allow_upload(:route_file_new,
       accept: ~w(.gpx),
       max_entries: 1,
       max_file_size: 10_000_000
     )
     |> allow_upload(:route_file_edit,
       accept: ~w(.gpx),
       max_entries: 1,
       max_file_size: 10_000_000
     )
     |> stream(:route_versions, route_versions)}
  end

  @impl true
  def handle_event("validate_version", %{"route_version" => params}, socket) do
    changeset =
      %RouteVersion{version_number: socket.assigns.next_version_number}
      |> Routing.change_route_version(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :version_form, to_form(changeset))}
  end

  @impl true
  def handle_event("create_version", %{"route_version" => params}, socket) do
    upload = consume_route_file(socket, :route_file_new) |> List.first()

    case Routing.create_route_version(socket.assigns.route, params, upload) do
      {:ok, _route_version} ->
        next_version_number = Routing.next_route_version_number(socket.assigns.route.id)

        {:noreply,
         socket
         |> put_flash(:info, "Route version added.")
         |> assign(:next_version_number, next_version_number)
         |> assign(
           :version_form,
           to_form(
             Routing.change_route_version(%RouteVersion{version_number: next_version_number})
           )
         )
         |> refresh_versions()}

      {:error, changeset} ->
        {:noreply, assign(socket, :version_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_version", %{"id" => id}, socket) do
    route_version = Routing.get_route_version!(id)

    if route_version.route_id == socket.assigns.route.id do
      {:ok, _deleted} = Routing.delete_route_version(route_version)

      {:noreply,
       socket
       |> maybe_cancel_edit_for(route_version.id)
       |> refresh_versions()}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("edit_version", %{"id" => id}, socket) do
    route_version = Routing.get_route_version!(id)

    if route_version.route_id == socket.assigns.route.id do
      {:noreply,
       socket
       |> assign(:editing_version_id, route_version.id)
       |> assign(:edit_version_form, to_form(Routing.change_route_version(route_version)))
       |> refresh_versions()}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("cancel_edit_version", _params, socket) do
    {:noreply, cancel_edit(socket) |> refresh_versions()}
  end

  @impl true
  def handle_event("update_version", %{"id" => id, "route_version" => params}, socket) do
    route_version = Routing.get_route_version!(id)

    if route_version.route_id == socket.assigns.route.id do
      upload = consume_route_file(socket, :route_file_edit) |> List.first()

      case Routing.update_route_version(route_version, params, upload) do
        {:ok, _updated} ->
          {:noreply,
           socket
           |> put_flash(:info, "Route version updated.")
           |> assign(
             :next_version_number,
             Routing.next_route_version_number(socket.assigns.route.id)
           )
           |> cancel_edit()
           |> refresh_versions()}

        {:error, changeset} ->
          {:noreply,
           socket
           |> assign(:edit_version_form, to_form(changeset))
           |> refresh_versions()}
      end
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
              <div
                id="route-versions-empty"
                class="hidden rounded-2xl border border-dashed border-slate-200 px-6 py-10 text-sm text-slate-500 only:block"
              >
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
                    <%= if @editing_version_id == route_version.id && @edit_version_form do %>
                      <.form
                        for={@edit_version_form}
                        id={"route-version-edit-form-#{route_version.id}"}
                        phx-submit="update_version"
                        phx-value-id={route_version.id}
                        class="mt-4 space-y-4"
                      >
                        <.input
                          field={@edit_version_form[:status]}
                          type="select"
                          label="Status"
                          id={"edit-version-status-#{route_version.id}"}
                          options={@status_options}
                          class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 shadow-sm transition focus:border-slate-300 focus:outline-none focus:ring-2 focus:ring-slate-200"
                          error_class="border-rose-300 ring-2 ring-rose-100"
                        />
                        <.input
                          field={@edit_version_form[:notes]}
                          type="textarea"
                          label="Description"
                          id={"edit-version-notes-#{route_version.id}"}
                          placeholder="What should riders know about this version?"
                          rows="3"
                          class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 shadow-sm transition focus:border-slate-300 focus:outline-none focus:ring-2 focus:ring-slate-200"
                          error_class="border-rose-300 ring-2 ring-rose-100"
                        />
                        <div class="space-y-2">
                          <label class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                            Replace GPX file
                          </label>
                          <div class="rounded-2xl border border-dashed border-slate-200 bg-white px-4 py-4 text-sm text-slate-500">
                            <div class="flex flex-wrap items-center justify-between gap-3">
                              <span>
                                {route_version.file_name || "Upload a GPX track for this version."}
                              </span>
                              <span class="text-xs uppercase tracking-[0.2em] text-slate-400">
                                .gpx only
                              </span>
                            </div>
                            <.live_file_input
                              upload={@uploads.route_file_edit}
                              id={"route-version-file-#{route_version.id}"}
                              class="mt-3 block w-full text-xs text-slate-500 file:mr-4 file:rounded-full file:border-0 file:bg-slate-900 file:px-4 file:py-2 file:text-xs file:font-semibold file:text-white hover:file:bg-slate-800"
                            />
                          </div>
                          <%= for err <- upload_errors(@uploads.route_file_edit) do %>
                            <p class="text-xs text-rose-600">{err}</p>
                          <% end %>
                        </div>
                        <div class="flex flex-wrap gap-2">
                          <button
                            type="submit"
                            class="inline-flex items-center rounded-full bg-slate-900 px-4 py-2 text-xs font-semibold text-white shadow-sm transition hover:bg-slate-800"
                          >
                            Save changes
                          </button>
                          <button
                            type="button"
                            phx-click="cancel_edit_version"
                            class="inline-flex items-center rounded-full border border-slate-200 bg-white px-4 py-2 text-xs font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900"
                          >
                            Cancel
                          </button>
                        </div>
                      </.form>
                    <% else %>
                      <p class="mt-2 text-sm text-slate-500">
                        {route_version.notes || "No description yet."}
                      </p>
                    <% end %>
                    <p class="mt-3 text-xs uppercase tracking-[0.2em] text-slate-400">Reference</p>
                    <%= if route_version.reference_url do %>
                      <a
                        href={route_version.reference_url}
                        target="_blank"
                        rel="noreferrer noopener"
                        class="mt-1 inline-flex items-center gap-3 rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-600 transition hover:border-slate-300 hover:text-slate-900"
                      >
                        <span class="rounded-full bg-slate-900 px-3 py-1 text-xs font-semibold text-white">
                          {RouteVersion.platform_label(route_version.reference_platform)}
                        </span>
                        <span class="text-sm">{reference_host(route_version.reference_url)}</span>
                      </a>
                    <% else %>
                      <p class="mt-1 text-sm text-slate-600">
                        No reference captured.
                      </p>
                    <% end %>
                    <%= if route_version.file_path do %>
                      <p class="mt-4 text-xs uppercase tracking-[0.2em] text-slate-400">
                        GPX file
                      </p>
                      <a
                        href={file_url(route_version.file_path)}
                        class="mt-2 inline-flex items-center gap-2 rounded-2xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-600 transition hover:border-slate-300 hover:text-slate-900"
                      >
                        <span class="rounded-full bg-emerald-100 px-3 py-1 text-xs font-semibold text-emerald-700">
                          {String.upcase(route_version.file_type)}
                        </span>
                        <span class="text-sm">{route_version.file_name}</span>
                      </a>
                    <% end %>
                  </div>
                  <div class="flex flex-wrap items-center gap-2">
                    <%= if @editing_version_id == route_version.id do %>
                      <span class="inline-flex items-center rounded-full border border-slate-200 bg-slate-100 px-4 py-2 text-xs font-semibold text-slate-500">
                        Editing…
                      </span>
                    <% else %>
                      <button
                        type="button"
                        phx-click="edit_version"
                        phx-value-id={route_version.id}
                        class="inline-flex items-center rounded-full border border-slate-200 bg-white px-4 py-2 text-xs font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900"
                      >
                        Edit
                      </button>
                    <% end %>
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
                Track updates with a version number, status, and verified route reference.
              </p>
            </div>
            <div class="mt-5 rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-600">
              <p class="text-xs uppercase tracking-[0.3em] text-slate-400">Next version</p>
              <p class="text-lg font-semibold text-slate-900">
                v{@next_version_number}
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
                field={@version_form[:status]}
                type="select"
                label="Status"
                options={@status_options}
                class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 shadow-sm transition focus:border-slate-300 focus:outline-none focus:ring-2 focus:ring-slate-200"
                error_class="border-rose-300 ring-2 ring-rose-100"
              />
              <.input
                field={@version_form[:notes]}
                type="textarea"
                label="Description"
                placeholder="What should riders know about this version?"
                rows="3"
                class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 shadow-sm transition focus:border-slate-300 focus:outline-none focus:ring-2 focus:ring-slate-200"
                error_class="border-rose-300 ring-2 ring-rose-100"
              />
              <.input
                field={@version_form[:reference_platform]}
                type="select"
                label="Platform"
                options={@platform_options}
                class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 shadow-sm transition focus:border-slate-300 focus:outline-none focus:ring-2 focus:ring-slate-200"
                error_class="border-rose-300 ring-2 ring-rose-100"
              />
              <.input
                field={@version_form[:reference_url]}
                type="url"
                label="Route URL"
                placeholder="https://bikerouter.de/..."
                class="w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 shadow-sm transition focus:border-slate-300 focus:outline-none focus:ring-2 focus:ring-slate-200"
                error_class="border-rose-300 ring-2 ring-rose-100"
              />
              <div class="space-y-2">
                <label class="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400">
                  Upload GPX
                </label>
                <div class="rounded-2xl border border-dashed border-slate-200 bg-white px-4 py-4 text-sm text-slate-500">
                  <div class="flex flex-wrap items-center justify-between gap-3">
                    <span>Store a GPX track along with this version.</span>
                    <span class="text-xs uppercase tracking-[0.2em] text-slate-400">.gpx only</span>
                  </div>
                  <.live_file_input
                    upload={@uploads.route_file_new}
                    id="route-version-file"
                    class="mt-3 block w-full text-xs text-slate-500 file:mr-4 file:rounded-full file:border-0 file:bg-slate-900 file:px-4 file:py-2 file:text-xs file:font-semibold file:text-white hover:file:bg-slate-800"
                  />
                </div>
                <%= for err <- upload_errors(@uploads.route_file_new) do %>
                  <p class="text-xs text-rose-600">{err}</p>
                <% end %>
              </div>

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

  defp reference_host(nil), do: ""

  defp reference_host(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) ->
        host

      _ ->
        url
    end
  end

  defp cancel_edit(socket) do
    socket
    |> assign(:editing_version_id, nil)
    |> assign(:edit_version_form, nil)
  end

  defp maybe_cancel_edit_for(socket, id) do
    if socket.assigns.editing_version_id == id do
      cancel_edit(socket)
    else
      socket
    end
  end

  defp refresh_versions(socket) do
    route_versions = Routing.list_route_versions(socket.assigns.route.id)
    stream(socket, :route_versions, route_versions, reset: true)
  end

  defp consume_route_file(socket, upload_name) do
    consume_uploaded_entries(socket, upload_name, fn %{path: path}, entry ->
      uploads_dir = Path.join([:code.priv_dir(:routes), "static", "uploads"])
      File.mkdir_p!(uploads_dir)

      ext = Path.extname(entry.client_name)
      storage_name = "#{entry.uuid}#{ext}"
      dest = Path.join(uploads_dir, storage_name)

      File.cp!(path, dest)

      {:ok,
       %{
         file_path: Path.join("uploads", storage_name),
         file_name: entry.client_name,
         file_type: normalize_file_type(ext)
       }}
    end)
  end

  defp normalize_file_type("." <> ext), do: String.downcase(ext)
  defp normalize_file_type(ext), do: String.downcase(ext)

  defp file_url(path) do
    RoutesWeb.Endpoint.static_path("/" <> path)
  end
end
