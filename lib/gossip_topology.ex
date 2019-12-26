defmodule GossipTopology do
  def getneighbs(agent, x, topology) when topology == "full" do
    neighbs = GossipRecord.getNodes_except(agent,x)
    neighbs
  end

  def  getneighbs(agent, x, topology) when topology == "line" do
    neighbs = GossipRecord.getNeighbs(agent, [x-1, x+1])
    neighbs
  end

  def getneighbs(agent, x, topology) when topology == "rand2D" do
    coords = GossipRecord.getCoords(agent)
    ##IO.puts "Coordinates are #{inspect(coords)} at x = #{inspect(x)}"
    curr = Enum.at(coords,x)
    neighb_nodes = for i <- 1..length(coords)-1, i !=x, distancein2D(curr, Enum.at(coords,i)), do: i
    #IO.puts "neighb_nodes = #{inspect(neighb_nodes)}"
    neighbs = GossipRecord.getNeighbs(agent, neighb_nodes)
    neighbs
   end

  def getneighbs(agent, x, topology) when topology == "honeycomb" do
      numNodes = GossipRecord.nodesAlive(agent)
      len = round(ceil(:math.sqrt(numNodes)))
      coords = if (div(x-1,len) + rem(x-1,len) |> rem(2) == 0) , do: [x - len] , else: [x + len]
      coords = case (rem(x,len)) do
                 1 -> coords ++ [x + 1]
                 0 -> coords ++ [x - 1]
                 _ -> coords ++ [x-1, x+1]
               end
      neighbs = GossipRecord.getNeighbs(agent, coords)
      neighbs
  end

  def getneighbs(agent, x, topology) when topology == "randhoneycomb" do
    numNodes = GossipRecord.nodesAlive(agent)
    len = round(ceil(:math.sqrt(numNodes)))
    coords = if (div(x-1,len) + rem(x-1,len) |> rem(2) == 0) , do: [x - len] , else: [x + len]
    coords = case (rem(x,len)) do
               1 -> coords ++ [x + 1]
               0 -> coords ++ [x - 1]
               _ -> coords ++ [x-1, x+1]
             end
    neighbs = GossipRecord.getNeighbs(agent, coords)
    randomNeighb = GossipRecord.getRandomNeighb(agent)
    neighbs = neighbs ++ [randomNeighb]
    neighbs
  end

  def getneighbs(agent, x, topology) when topology == "3Dtorus" do
    numNodes = GossipRecord.nodesAlive(agent)
    side = :math.pow(numNodes, 1/3) |> round()
    hor_coords = cond do
                  rem(x-1, side*side) < side -> [(side*side - side + x),( x + side)]
                  rem(x-1, side*side) >= (side*side - side) -> [(x - side), (x - (side*side - side))]
                  true -> [(x - side), (x + side)]
                 end
    ver_coords = cond do
                    rem(x, side*side)|> rem(side)==0 -> [(x-1) , (x-side+1)]
                    rem(x, side*side)|> rem(side)==1 -> [(x + side-1), (x+1)]
                    true -> [(x+1), (x-1)]
                  end
    z_coords = cond do
               (x <= side*side) -> [(side*side*side - (side*side - x)), (x + side*side)]
               (x > side*side*side - side*side) -> [(x - side*side), (side*side - (side*side*side - x))]
               true -> [(x - side*side), (x+ side*side)]
               end

    coords = hor_coords ++ ver_coords ++ z_coords
   # IO.puts "neighbors of #{inspect(x)} are #{inspect(coords)}"
    neighbs = GossipRecord.getNeighbs(agent, coords)
    neighbs
  end

  def getReady(agent, numNodes, topology) when topology == "rand2D" do
   # nodes = GossipRecord.getNodes(agent)
    coords = for _i<-1..numNodes, do: [ :rand.uniform(), :rand.uniform()]
    GossipRecord.addNode(agent, :coords, [[0,0] | coords])
  end

  def getReady(_agent, _numNodes, _topology) do
     "No need of any preprocessing"
  end

  def distancein2D([x1,y1], [x2,y2]) do
    xlen = abs(x1 - x2)
    ylen = abs(y1 - y2)
    if (xlen*xlen + ylen*ylen)< 0.01, do: true, else: false
  end


end
