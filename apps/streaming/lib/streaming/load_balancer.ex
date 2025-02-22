defmodule Streaming.LoadBalancer do
  use GenServer

  @processor_nodes Application.compile_env!(:streaming, :genstage_nodes)

  def start_link(_) do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  @impl true
  def init(initial_index) do
    {:ok, initial_index}
  end

  @impl true
  def handle_call(:get_next, _from, current_index) do
    next_index = rem(current_index + 1, length(@processor_nodes))
    node = Enum.at(@processor_nodes, current_index)
    {:reply, String.to_atom(node), next_index}
  end

  def get_next_node() do
    GenServer.call(__MODULE__, :get_next)
  end
end
