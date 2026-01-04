defmodule Routes.Routing.RouteVersion do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @platforms [
    %{label: "Bikerouter", value: "bikerouter", hosts: ~w[bikerouter.de www.bikerouter.de]},
    %{label: "Komoot", value: "komoot", hosts: ~w[komoot.com www.komoot.com]},
    %{
      label: "Ride with GPS",
      value: "ridewithgps",
      hosts: ~w[ridewithgps.com www.ridewithgps.com]
    }
  ]

  schema "route_versions" do
    field :version_number, :integer
    field :status, :string, default: "draft"
    field :notes, :string
    field :reference_platform, :string
    field :reference_url, :string

    belongs_to :route, Routes.Routing.Route

    timestamps()
  end

  def changeset(route_version, attrs) do
    route_version
    |> cast(attrs, [:version_number, :status, :notes, :reference_platform, :reference_url])
    |> validate_required([:version_number, :status, :reference_platform, :reference_url])
    |> validate_number(:version_number, greater_than: 0)
    |> validate_inclusion(:status, ["draft", "published", "archived"])
    |> validate_length(:notes, max: 600)
    |> validate_inclusion(:reference_platform, platform_values())
    |> validate_length(:reference_url, max: 2000)
    |> validate_reference_url()
    |> unique_constraint(:version_number,
      name: :route_versions_route_id_version_number_index
    )
  end

  def platform_select_options do
    Enum.map(@platforms, &{&1.label, &1.value})
  end

  def platform_label(value) do
    @platforms
    |> Enum.find(&(&1.value == value))
    |> case do
      nil -> value
      platform -> platform.label
    end
  end

  defp platform_values, do: Enum.map(@platforms, & &1.value)

  defp validate_reference_url(changeset) do
    platform = get_field(changeset, :reference_platform)

    validate_change(changeset, :reference_url, fn :reference_url, url ->
      do_validate_reference_url(platform, url)
    end)
  end

  defp do_validate_reference_url(_platform, url) when url in [nil, ""], do: []

  defp do_validate_reference_url(platform, _url) when platform in [nil, ""], do: []

  defp do_validate_reference_url(platform, url) do
    with {:ok, uri} <- normalize_uri(url),
         true <- host_matches_platform?(uri, platform) do
      []
    else
      {:error, reason} -> [reference_url: reason]
      false -> [reference_url: "does not match the selected platform"]
    end
  end

  defp normalize_uri(url) do
    case URI.new(url) do
      {:ok, %URI{scheme: scheme, host: host} = uri}
      when scheme in ["https", "http"] and not is_nil(host) ->
        {:ok, uri}

      _ ->
        {:error, "must be a valid HTTP(S) URL"}
    end
  end

  defp host_matches_platform?(%URI{host: host}, platform)
       when is_binary(host) and is_binary(platform) do
    case Enum.find(@platforms, &(&1.value == platform)) do
      nil -> false
      platform_def -> host in platform_def.hosts
    end
  end

  defp host_matches_platform?(_, _), do: false
end
