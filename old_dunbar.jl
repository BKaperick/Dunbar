# Used to store previous function iterations for benchmarking purposes

include("dunbar.jl")
"""
    generateGs(n, k)

Take in the number of nodes `n` and the number of allowed edges `k`.  All 
possible graphs with these parameters are iterated through.
"""
function generateGs1(n,k)
  # Get generic node names
  nodes = [string(Char(64+x)) for x in range(1,stop=n)]
  
  # Build array of all possible undirected edges, length (n-1)*n/2 
  allEdges = []
  for (i,n) in enumerate(nodes)
    allEdges = vcat(allEdges, [(n,m) for m in nodes[i+1:end]])
  end
  #println("assembled edges: ", length(allEdges))
  numEdges = length(allEdges)
  Gs = []
  bitArrays = generateActiveBitArrays(numEdges, k)
  #println("gotten bit arrays: ", length(bitArrays))

  for schema in bitArrays
    currentEdges = allEdges[schema]
    G = initializeGraph(nodes, currentEdges)
    Gs = vcat(Gs, G)
  end
  #println("initialized graphs")
  #println(length(Gs))
  #println("returning: ", Gs)
  return Gs
end
function generateGs2(n,k)
  # Get generic node names
  nodes = [string(Char(64+x)) for x in range(1,stop=n)]
  
  # Build array of all possible undirected edges, length (n-1)*n/2 
  allEdges = []
  for (i,n) in enumerate(nodes)
    allEdges = vcat(allEdges, [(n,m) for m in nodes[i+1:end]])
  end
  #println("assembled edges: ", length(allEdges))
  numEdges = length(allEdges)
  Gs = []
  bitArrays = BitIt(numEdges, k)
  #println("gotten bit arrays: ", length(bitArrays))

  for (i,schema) in enumerate(bitArrays)
    currentEdges = allEdges[schema]
    G = initializeGraph(nodes, currentEdges)
    Gs = vcat(Gs, G)
  end
  return Gs
end

"""
    proportionAreGossipable(n, k)

Returns the proportion of all possible graphs with `n` nodes and `k` edges
which are gossipable.
"""
function proportionAreGossipable1(n, k)
  # easily-proven lower bound
  if (k < 1.5*(n-1))
    return 0.0
  end

  count = 0
  total = 0
  for G in generateGs1(n,k)
    count += isGossipable(G)
    total += 1
  end
  #println(count, " / ", total)
  return count / total
end
function proportionAreGossipable2(n, k)
  # easily-proven lower bound
  if (k < 1.5*(n-1))
    println("safely ignored")
    return 0.0
  end

  count = 0
  total = 0
  for G in generateGs2(n,k)
    count += isGossipable(G)
    total += 1
  end
  println(count, " / ", total)
  return count / total
end


