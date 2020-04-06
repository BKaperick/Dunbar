
"""
    paths(b, k)

The simple combinatorial problem of counting how many strings of `b` bits exist where
exactly `k` are active.
"""
function paths(b::Int,k::Int)
  return paths(b,k,Dict{Tuple{Int,Int},Int}())::Int
end
function paths(b::Int,k::Int, cache::Dict{Tuple{Int,Int},Int})::Int #, cache=Dictionary((int,int),int)
  if (haskey(cache, (b,k)))
    return cache[b,k]
  elseif k > b
    result = 0
  elseif k == b || k == 0
    result = 1
  elseif k == 1
    result = b
  else
    result = sum([paths(j,k-1) for j in range(k-1,stop=b-1)])
  end
  cache[b,k] = result
  return result
end

"""
    numPaths(n, k)

Counts the number of graphs with `n` nodes exist with `k` edges.
"""
function numPaths(n::Int8,k::Int8)::Int8
  b = n*(n-1)/2
  return paths(b,k)
end

"""
    generateActiveBitArrays(n, k)

Generates the sequential sequences of `n`-bit strings with `k` active bits
formatted as an array of booleans
"""
function generateActiveBitArrays(n, k)::Array{Array{Bool,1},1}
  return generateActiveBitArrays(n, k, Dict{Tuple{Int64,Int64},Array{Array{Bool,1},1}}())
end
function generateActiveBitArrays(n, k, cache::Dict{Tuple{Int64,Int64},Array{Array{Bool,1},1}})::Array{Array{Bool,1},1}
  cache[2,1] = [[true,false],[false,true]]
  if (haskey(cache, (n,k)))
    return cache[n,k]
  end
  if (n == 0)
    cache[n,k] = []
    return []
  end
  if (n == 2 && k == 1)
    cache[n,k] = [[true,false],[false,true]]
    return [[true,false],[false,true]]
  end
  root = vcat([true for _ in range(1,stop=k)], [false for _ in range(1,stop=n-k)])
  if (k == 0 || n == k || n == 1)
    cache[n,k] = [root]
    return [root]
  elseif (k > n/2)
    return notall(generateActiveBitArrays(n, n-k,cache))
  else
    inner00 = [vcat(false, inner, false) for inner in generateActiveBitArrays(n-2,k,cache)] 
    inner01 = [vcat(false,inner,true) for inner in generateActiveBitArrays(n-2,k-1,cache)]
    inner10 = [vcat(true, inner,false) for inner in generateActiveBitArrays(n-2,k-1,cache)]
    val1 = vcat(inner00,inner01,inner10)
    if (k == 1)
      cache[n,k] = val1
      return val1
    else
      inner11 = [vcat(true,inner,true) for inner in generateActiveBitArrays(n-2,k-2,cache)]
      val2 = vcat(val1, inner11)
      cache[n,k] = val2
    end
  end
end

function notall(a::Array{Bool,1})
  return [!x for x in a]
end
function notall(a::Array{Array{Bool, 1},1})
  return [notall(x) for x in a]
end

for n=1:8
  for k=0:n
    @assert paths(n,k) == length(generateActiveBitArrays(n,k))
  end
end
"""
    initializeGraph(nodes, edges)

Constructs the graph data structure from a set of string node names `nodes` and
a set of 2-tuple relations stored in the iterable `edges`.
"""
function initializeGraph(nodes, edges)
  graph = []
  for node in nodes
    outEdges = []
    for edge in edges
      if node == edge[1]
        push!(outEdges,edge[2])
      elseif node == edge[2]
        push!(outEdges,edge[1])
      end
    end
    push!(graph, (node, outEdges))
  end
  return Dict(graph)
end

"""
    isInTriangle(graph, node)

Decides if the node named `node` in `graph` is part of a triangle.  That is,
there exists a neighbor node `m` for which `node` and `m` have a mutual, 
distinct neighbor.
"""
function isInTriangle(graph,node)
  edges = graph[node]
  next = []
  for e in edges
    next = vcat(next, [ee for ee in graph[e] if ee != node])
    for n in next
      if node in graph[n]
        return true
      end
    end
  end
  return false
end

"""
    isGossipable(G)

Decides if all nodes contained in graph `G` are in a triangle.
"""
function isGossipable(G)
  return all([isInTriangle(G,n) for (n,es) in G])
end
nodes = ["a","b","c","d"]
edges = [("a","b"),("b","c"),("c","a"),("a","d")]
G = initializeGraph(nodes, edges)
println(isGossipable(G))

"""
    generateGs(n, k)

Take in the number of nodes `n` and the number of allowed edges `k`.  All 
possible graphs with these parameters are iterated through.
"""
function generateGs(n,k)
  # Get generic node names
  nodes = [string(Char(64+x)) for x in range(1,stop=n)]
  
  # Build array of all possible undirected edges, length (n-1)*n/2 
  allEdges = []
  for (i,n) in enumerate(nodes)
    allEdges = vcat(allEdges, [(n,m) for m in nodes[i+1:end]])
  end
  println("assembled edges: ", length(allEdges))
  numEdges = length(allEdges)
  Gs = []
  bitArrays = generateActiveBitArrays(numEdges, k)
  println("gotten bit arrays: ", length(bitArrays))

  for schema in bitArrays
    currentEdges = allEdges[schema]
    G = initializeGraph(nodes, currentEdges)
    Gs = vcat(Gs, G)
  end
  println("initialized graphs")
  println(length(Gs))
  #println("returning: ", Gs)
  return Gs
end

"""
    proportionAreGossipable(n, k)

Returns the proportion of all possible graphs with `n` nodes and `k` edges
which are gossipable.
"""
function proportionAreGossipable(n, k)
  # easily-proven lower bound
  if (k < n)
    return 0.0
  end

  count = 0
  total = 0
  for G in generateGs(n,k)
    count += isGossipable(G)
    total += 1
  end
  return count / total 
end
