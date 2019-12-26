defmodule Proj2 do
  def start(numNodes, topology, algorithm) do
    {:ok, agent} = GossipRecord.start_link(%{})
    {:ok, converged} = Status.start_link([])
    {:ok, pid} =  case algorithm do
              "gossip" -> GossipSupervisor.start_link([numNodes, topology, agent, converged])
               "push-sum" -> PushSumSupervisor.start_link([numNodes, topology, agent, converged])
    end
    ch = Enum.map(Supervisor.which_children(pid), fn {_,c,_,_}-> c end)
   # IO.inspect ch
    firstNode = Enum.random(ch)
    ch |> Enum.map(fn pid ->spawn(fn -> GenServer.cast(pid, :initializeNode) end)|>Process.monitor() end)
    Process.sleep(300)
    start_time = System.monotonic_time(:millisecond)
    if algorithm == "gossip", do: send(firstNode, :gossip), else: send(firstNode, [0,0, self()])
    wait_until_finish(agent, topology)
    end_time = System.monotonic_time(:millisecond)
    numNodesconverged = Status.numNodesConverged(converged)
    IO.puts " #{inspect(numNodesconverged)} nodes converged"
    IO.puts "Total time to converge = #{inspect(end_time - start_time)}"
  end

  def wait_until_finish(agent, topology) when topology == "rand2D" do
    nodes_alive = GossipRecord.nodesAlive(agent)
    Process.sleep(100)
    if nodes_alive >2 , do: wait_until_finish(agent, topology)

  end

  def wait_until_finish(agent, topology) do
    nodes_alive = GossipRecord.nodesAlive(agent)
    Process.sleep(100)
    if nodes_alive != 0, do: wait_until_finish(agent , topology)

  end
end

defmodule Topologies do
  def main(argv) do
    numNodes = String.to_integer(Enum.at(argv,0))
    topology = Enum.at(argv,1)
    algorithm = Enum.at(argv,2)
    Proj2.start(numNodes, topology, algorithm)
  end
end
