defmodule GossipNode do
  use GenServer, restart: :temporary, timeout: 100000
  import GossipTopology

  def start_link([x, agent,neighbs, topology, count, converged]) do
    GenServer.start_link(__MODULE__, [x, agent,neighbs, topology, count, converged])
  end

  def handle_cast(:initializeNode, [x, agent, _neighbs, topology, count, converged] ) do
    myneighbs = getneighbs(agent,x, topology)
    #wait_task = Task.start(fn -> waitforMessages(300) end)
    _monitor_task = Task.start(fn -> monitorTask(x,agent,self())end)
    {:noreply, [x, agent,myneighbs, topology, count, converged], 100000}
  end

  def monitorTask(x, agent, pid) do
     Process.sleep(180000)
     GossipRecord.deleteNode(agent,x)
     Process.exit(pid, :kill)
  end

  def waitforMessages(time) do
     Process.sleep(time)
  end

  def handle_info(:gossip, [x, agent, neighbs, topology, count, converged]) do
   # IO.puts "Received when count = #{count} at #{inspect(self())}"
    count = count+1
    if count>=10 do
      #IO.puts "Node #{inspect(self())} converged"
      Status.put(converged, x)
      GossipRecord.deleteNode(agent,x)
      Process.exit(self(), :normal)
    end
    if count == 1 do
      _spread_task = Task.start(fn -> spreadgossip(agent, neighbs) end)
    end
   # if count < 10 , do: task2 = Task.start(fn -> waitforMessages(300) end)
    {:noreply, [x, agent, neighbs, topology, count, converged],10000}
  end

  def handle_info(:timeout, [x, agent, neighbs, topology, count, converged]) do
    #IO.puts "Node #{inspect(self())} didn't receive messages, terminating now."
    GossipRecord.deleteNode(agent, x)
    Process.exit(self(), :normal)
    {:noreply, [x, agent, neighbs, topology, count, converged] }
  end

  def spreadgossip(agent, neighbs) do
   # Process.sleep(150)
    alive = neighbs |> Enum.filter(fn pid -> Process.alive?(pid) end)
    if alive != [], do: alive |> Enum.random() |> send(:gossip)
    spreadgossip(agent, neighbs)
  end


  # def terminate(_reason, [x, agent, _neighbs, _topology, _count]) do
  #    IO.puts "Node #{inspect(self())} didn't receive messages, terminating now."
  #    GossipRecord.deleteNode(agent, x)
  #    :normal
  # end

  def init([x, agent,neighbs, topology, count, converged]) do
    GossipRecord.addNode(agent,x,self())
    {:ok, [x, agent,neighbs, topology, count, converged]}
  end
end
