defmodule TempStore do
  @moduledoc """
  ETS を利用した一時記憶です。

  起動すると自動的に `TempStore` という名前でプロセスが一つ作成されます。
  名前の指定をせずに関数を呼び出した場合、この最初に作成されたプロセスに対して操作を行います。
  """

  use GenServer

  @doc """
  新しい一時記憶のプロセスを作成します。

  プロセスを識別するための名前を引数で指定します。
  新たに作成したプロセスに対して操作を行う場合は、関数を呼び出す時にここで与えた名前を指定します。

  ```elixir
  TempStore.start_link(name: :new_store)
  ```
  """
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    state = Map.new(opts)
    GenServer.start_link(__MODULE__, Map.put(state, :name, name), name: name)
  end

  @doc """
  キーを指定して値を保存します。

  キーと値には任意の型の値を指定することができます。
  保存した値は `get/2` で取得できます。

  ```elixir
  TempStore.set(:foo, "Foo")
  TempStore.set("bar", [1, 2, 3])
  TempStore.set({'baz'}, %{a: 1, b: 2})
  ```

  プロセスを作成した時に指定した名前を第一引数に指定すると、そのプロセスに対して操作を行います。

  ```elixir
  TempStore.start_link(name: :new_store)
  TempStore.set(:new_store, :foo, "ふー")
  ```
  """
  def set(name \\ __MODULE__, key, value) do
    GenServer.cast(name, {:set, key, value})
  end

  @doc """
  キーを指定して値を取得します。

  `set/3` で保存した時に指定したキーを指定すると、保存された値を返します。キーに対応する値が存在しない場合は `nil` を返します。

  ```elixir
  TempStore.get(:foo)    # => "Foo"
  TempStore.get("bar")   # => [1, 2, 3]
  TempStore.get({'baz'}) # => %{a: 1, b: 2}
  ```

  プロセスを作成した時に指定した名前を第一引数に指定すると、そのプロセスに対して操作を行います。

  ```elixir
  TempStore.start_link(name: :new_store)
  TempStore.set(:new_store, :foo, "ふー")
  TempStore.get(:new_store, :foo) # => "ふー"
  """
  def get(name \\ __MODULE__, key) do
    GenServer.call(name, {:get, key})
  end

  @doc """
  データをファイルに保存します。

  指定したファイルに全データを書き出します。
  プロセスを作成した時に指定した名前を第一引数に指定すると、そのプロセスに対して操作を行います。
  """
  def save(name \\ __MODULE__, filename) when is_binary(filename) do
    GenServer.call(name, {:save, filename})
  end

  @doc """
  データをファイルから読み出します。

  指定したファイルから全データを読み出します。それまで保存していたデータはすべて失われます。
  プロセスを作成した時に指定した名前を第一引数に指定すると、そのプロセスに対して操作を行います。
  """
  def load(name \\ __MODULE__, filename) when is_binary(filename) do
    GenServer.call(name, {:load, filename})
  end

  @doc false
  def init(state) do
    tid = :ets.new(state.name, [:set])
    {:ok, Map.put(state, :tid, tid)}
  end

  @doc false
  def handle_cast({:set, key, value}, state) do
    :ets.insert(state.tid, {key, value})
    {:noreply, state}
  end

  @doc false
  def handle_call({:get, key}, _from, state) do
    value =
      case :ets.lookup(state.tid, key) do
        [{^key, value}] -> value
        _ -> nil
      end
    {:reply, value, state}
  end

  @doc false
  def handle_call({:save, filename}, _from, state) do
    result = :ets.tab2file(state.tid, String.to_charlist(filename))
    {:reply, result, state}
  end

  @doc false
  def handle_call({:load, filename}, _from, state) do
    {:ok, tid} = :ets.file2tab(String.to_charlist(filename))
    {:reply, :ok, %{state | tid: tid}}
  end
end
