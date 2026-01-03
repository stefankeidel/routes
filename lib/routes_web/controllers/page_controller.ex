defmodule RoutesWeb.PageController do
  use RoutesWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
