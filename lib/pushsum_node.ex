defmodule PushsumNode do
  use GenServer, restart: :temporary, timeout: 200000

  import GossipTopology

  def start_link([x, agent,neighbs, topology, sw, count, converged, sw_registry]) do
    GenServer.start_link(__MODULE__, [x, agent,neighbs, topology, sw, count, converged, sw_registry])
  end

  def handle_cast(:initializeNode, [x, agent, _neighbs, topology, sw, count, converged, sw_registry]) do
    myneighbs = getneighbs(agent,x, topology)
    _monitor_task = Task.start(fn -> monitorTask(x,agent, self()) end)
   {:noreply, [x, agent,myneighbs, topology, sw, count, converged, sw_registry], :infinity}
  end

  def monitorTask(x, agent, pid) do
    Process.sleep(300000)
    #IO.puts "Time limit exceeded for the node #{inspect(pid)}. Terminating"
    GossipRecord.deleteNode(agent, x)
    Process.exit(pid, :kill)
  end

  def waitforMessages(time) do
     Process.sleep(time)
  end

  def keepsyncSW(pid) do
    Process.sleep(50)
    #IO.puts "sending sync message to #{inspect(pid)}"
    send(pid, :syncsw)
    keepsyncSW(pid)
  end

  def handle_info([s1,w1, x1], [x, agent, neighbs, topology, [s,w], count, converged, sw_registry]) do
    myPID = self()
    if s==x do
      _spreadTask = Task.start(fn -> spreadgossip(x, neighbs, sw_registry, myPID) end)
      _update_SW = Task.start(fn -> keepsyncSW(myPID) end)
    end
    #IO.puts "Received message from #{inspect(x1)}, has #{inspect([s1,w1])} when my state is #{inspect([s,w])} at #{inspect(x)}"
    {:noreply, [x, agent, neighbs, topology, [(s+s1), (w+w1)], count, converged, sw_registry], 10000}
  end

  def handle_info(:syncsw, [x, agent, neighbs, topology, [s1,w1], count, converged, sw_registry]) do
    #IO.puts "called to sync sw"
    [s,w] = SW.getSW(sw_registry,x)
    curr_s_to_w = s/w
    new_s_to_w = (s1)/(w1)
    #IO.puts "Current SW ratio: #{curr_s_to_w} New SW ratio #{new_s_to_w}"
    diff = abs(new_s_to_w - curr_s_to_w)
    count = if diff < :math.pow(10, -10) , do:  count + 1, else: 0
    #IO.puts "diff at #{inspect(self())} is #{inspect(diff)} and count is #{inspect(count)}"
    if count==3 do
      # IO.puts "Reached end at #{inspect(self())}"
      Status.put(converged, x)
      GossipRecord.deleteNode(agent,x)
      #  Process.sleep(100)
      # spreadgossip(agent, new_sw, neighbs)
      Process.exit(self(), :normal)
    end
    SW.updateSW(sw_registry,x, [s,w])
    {:noreply, [x, agent, neighbs, topology, [s,w], count, converged, sw_registry], 10000}
  end

  def handle_info(:timeout, [x, agent, neighbs, topology, [s,w], count, converged, sw_registry]) do
    #IO.puts "Node #{inspect(self())} didn't receive any message in 1s. Terminating now"
    #IO.puts "Node #{x} ran out of neighbors"
    GossipRecord.deleteNode(agent,x)
    Process.exit(self(), :normal)

    {:noreply, [x, agent, neighbs, topology, [s,w], count, converged, sw_registry], 30000}
  end

  def spreadgossip(x, neighbs, sw_registry, pid) do
    Process.sleep(10)
    [s,w] = SW.getSW(sw_registry,x)
    alive = neighbs |> Enum.filter(fn pid -> Process.alive?(pid) end)
    if alive != [], do: alive |> Enum.random() |> send([s/2 , w/2, x]), else: send(pid, :timeout)
    send(pid, [s/2, w/2, x])
    spreadgossip(x,neighbs, sw_registry, pid)
  end

  def init([x, agent,neighbs, topology, sw, count, converged, sw_registry]) do
    GossipRecord.addNode(agent,x,self())
    SW.add(sw_registry, x, sw)
    {:ok, [x, agent,neighbs, topology, sw, count, converged, sw_registry], 80000}
  end
end
