defmodule TempStoreTest do
  use ExUnit.Case
  doctest TempStore

  test "greets the world" do
    assert TempStore.hello() == :world
  end
end
