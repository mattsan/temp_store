defmodule TempStoreTest do
  use ExUnit.Case
  doctest TempStore

  setup do
    start_supervised(TempStore)
    :ok
  end

  test "get an unstored value" do
    assert TempStore.get(123) == nil
  end

  test "get a stored value" do
    TempStore.set(123, 456)
    assert TempStore.get(123) == 456
  end
end
