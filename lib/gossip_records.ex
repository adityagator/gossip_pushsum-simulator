defmodule GossipRecord do
  use Agent
  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def getNeighbs(pid,list) do
    neighbs = (Agent.get(pid, fn state ->  for i <- list, Map.has_key?(state,i), do: state[i] end, :infinity))
    neighbs
  end
  def getNodes(pid) do
    Agent.get(pid, fn state -> Map.values(state) end, :infinity)
  end
  def addNode(pid, x, node_pid) do
    Agent.update(pid, fn state -> Map.put(state, x, node_pid) end, :infinity)
  end

  def deleteNode(pid,x) do
    Agent.update(pid, fn state -> Map.delete(state, x) end, :infinity)
  end

  def getNodes_except(pid,x) do
    Agent.get(pid, fn state -> Map.delete(state,x)|> Map.values() end, :infinity)
  end

  def nodesAlive(pid) do
    Agent.get(pid, fn state -> map_size(state) end, :infinity)
  end

  def getCoords(pid) do
    Agent.get(pid, fn state -> state[:coords] end, :infinity)
  end

  def getRandomNeighb(pid) do
   Agent.get(pid, fn state -> Map.values(state) |> Enum.random() end, 500000)
 end
end
