defmodule Status do
  use Agent

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def put(pid,value) do
    Agent.update(pid, fn state -> state ++ [value] end, :infinity)
  end

  def numNodesConverged(pid) do
    Agent.get(pid, fn state -> length(state) end, :infinity)
  end
  def get(pid) do
    Agent.get(pid, fn state -> state end, :infinity)
  end
end
