defmodule OpentelemetryLoggerTest do
  use ExUnit.Case, async: false
  require Logger
  doctest OpentelemetryLogger

  @backend OpentelemetryLogger

  setup do
    # We add and remove the backend here to avoid cross-test effects
    Logger.add_backend(@backend, flush: true)

    on_exit(fn ->
      :ok = Logger.remove_backend(@backend)
    end)
  end

  test "works" do
    Logger.debug("foo")
  end
end
