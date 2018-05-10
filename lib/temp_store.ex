defmodule TempStore do
  @moduledoc """
  Documentation for TempStore.
  """

  use GenServer

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    state = Map.new(opts)
    GenServer.start_link(__MODULE__, Map.put(state, :name, name), name: name)
  end

  def set(name \\ __MODULE__, key, value) do
    GenServer.cast(name, {:set, key, value})
  end

  def get(name \\ __MODULE__, key) do
    GenServer.call(name, {:get, key})
  end

  def save(name \\ __MODULE__, filename) when is_binary(filename) do
    GenServer.call(name, {:save, filename})
  end

  def load(name \\ __MODULE__, filename) when is_binary(filename) do
    GenServer.call(name, {:load, filename})
  end

  def init(state) do
    tid = :ets.new(state.name, [:set])
    {:ok, Map.put(state, :tid, tid)}
  end

  def handle_cast({:set, key, value}, state) do
    :ets.insert(state.tid, {key, value})
    {:noreply, state}
  end

  def handle_call({:get, key}, _from, state) do
    value =
      case :ets.lookup(state.tid, key) do
        [{^key, value}] -> value
        _ -> nil
      end
    {:reply, value, state}
  end

  def handle_call({:save, filename}, _from, state) do
    result = :ets.tab2file(state.tid, String.to_charlist(filename))
    {:reply, result, state}
  end

  def handle_call({:load, filename}, _from, state) do
    {:ok, tid} = :ets.file2tab(String.to_charlist(filename))
    {:reply, :ok, %{state | tid: tid}}
  end
end
