defmodule GossipSupervisor do
  use Supervisor
  def start_link(state) do 
     Supervisor.start_link(__MODULE__, state, name: __MODULE__)
  end
  def fillnodes(numNodes, topology) when topology == "3Dtorus" do
    numNodes = :math.pow(numNodes, 1/3) |> :math.ceil() |> :math.pow(3)|> floor()
    numNodes
  end

  def  fillnodes(numNodes, topology) do
    numNodes
  end
  @impl true
  def init([numNodes, topology, agent, converged]) do
    numNodes = fillnodes(numNodes, topology)
    children = for x <- 1..numNodes, do: worker(GossipNode, [[x, agent,[], topology,0, converged]], [restart: :temporary, timeout: 200000, id: 10000*x + x])
    Process.sleep(100)
    GossipTopology.getReady(agent, numNodes, topology)
    Supervisor.init(children, strategy: :one_for_one, restart: :temporary)
  end
 end

