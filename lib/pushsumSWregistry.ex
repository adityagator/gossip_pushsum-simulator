defmodule SW do 
  use Agent
  
  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def getSW(pid,x) do
   # Agent.get(pid, fn state -> if x in state, do: state[x], else: [0,0] end, :infinity) 
   Agent.get(pid, fn state -> state[x] end)
  end 
  
  def add(pid, x, sw) do
    Agent.update(pid, fn state -> Map.put(state, x, sw) end, :infinity)
  end  

  def updateSW(pid,x,val) do 
    Agent.update(pid, fn state -> Map.update!(state,x, fn _sw -> val end) end, :infinity)
  end
end
