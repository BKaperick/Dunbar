
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
function numPaths(n::Int64,k::Int64)::Int64
  b = n*(n-1)/2
  return paths(b,k)
end

mutable struct BitIt
  n::Int64 # number of bits
  k::Int64 # number of active bits (hamming weight)
  i::Int64 # current index within iteration
  l::Int64 # current active bit within iteration
end

BitIt(numBits::Int64,numActive::Int64) = numBits >= numActive ? BitIt(numBits,numActive,numActive,numActive) : throw(ArgumentError("numActive cannot be larger than numBits"))

function Base.iterate(bi::BitIt, state=(vcat([true for _ in range(1,stop=bi.k)], [false for _ in range(1,stop=bi.n-bi.k)]), 0))
  elem,count = state
  k,n,i,l = bi.k,bi.n,bi.i,bi.l

  # Base case
  if (n == k || k == 0)
    return count == 0 ? (elem, (elem, count+1)) : nothing
  end

  # End of iteration, but still need to return final value
  if l == 0
    if i > 0
      bi.i = 0
      return (elem, state)
    else
      return nothing
    end
  end
  if elem[i]
    if i == n || elem[i+1]
      bi.i -= 1
      bi.l -= 1
      return Base.iterate(bi, state)
    else
      # Have identified the correct bit to "shift" over
      out = copy(elem)
      groupend = i+1+k-l
      out[i+1:groupend] .= true
      out[groupend+1:n] .= false
      out[i] = false
      bi.i = groupend
      bi.l = k
      return (elem, (out, count+1))
    end
  else
    bi.i -= 1
    return Base.iterate(bi, state)
  end
end

Base.length(bi::BitIt) = paths(bi.n, bi.k)

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
    result = cache[n,k]
  elseif (n == 0)
    result = []
  elseif (n == 2 && k == 1)
    result = [[true,false],[false,true]]
  else
    root = vcat([true for _ in range(1,stop=k)], [false for _ in range(1,stop=n-k)])
    if (k == 0 || n == k || n == 1)
      result = [root]
    elseif (k > n/2)
      result = notall(generateActiveBitArrays(n, n-k,cache))
    else
      inner00 = [vcat(false, inner, false) for inner in generateActiveBitArrays(n-2,k,cache)] 
      inner01 = [vcat(false,inner,true) for inner in generateActiveBitArrays(n-2,k-1,cache)]
      inner10 = [vcat(true, inner,false) for inner in generateActiveBitArrays(n-2,k-1,cache)]
      val1 = vcat(inner00,inner01,inner10)
      if (k == 1)
        result = val1
      else
        inner11 = [vcat(true,inner,true) for inner in generateActiveBitArrays(n-2,k-2,cache)]
        val2 = vcat(val1, inner11)
        result = val2
      end
    end
  end
  cache[n,k] = result
  return result
end

function notall(a::Array{Bool,1})
  return [!x for x in a]
end
function notall(a::Array{Array{Bool, 1},1})
  return [notall(x) for x in a]
end

"""
    initializeGraph(nodes, edges)

Constructs the graph data structure from a set of string node names `nodes` and
a set of 2-tuple relations stored in the iterable `edges`.
"""
function initializeGraph(nodes, edges)::Dict{String, Array{String,1}}
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

mutable struct GraphIt
  n::Int64
  k::Int64
  nodes::Array{String,1}
  allEdges::Array{Tuple{String,String},1}
  bitArrays::BitIt
  bitState::Tuple{Array{Bool,1},Int64}
  start::Dict{String, Array{String,1}}
end

function GraphIt(n,k)
  numEdges = Int64(n*(n-1)/2)
  nodes = [string(Char(64+x)) for x in range(1,stop=n)]
  
  # Build array of all possible undirected edges, length (n-1)*n/2 
  #allEdges = Tuple{String,String}[]
  allEdges = []
  for (i,node) in enumerate(nodes)
    allEdges = vcat(allEdges, [(node,m) for m in nodes[i+1:end]])
  end

  # initialize bit iterator
  bi = BitIt(numEdges,k)
  bitStart,bitState = iterate(bi)
  #bitState = (bitStart,0)

  start = initializeGraph(nodes, allEdges[bitStart])
  return GraphIt(n,k,nodes,allEdges,bi,bitState,start)
end

function Base.iterate(gi::GraphIt, state=(gi.start, 0))
  elem,count = state
  if count >= Base.length(gi.bitArrays)
    return nothing
  end
   
  # get pointers to current edges selected
  next = iterate(gi.bitArrays, gi.bitState)
  if (next == nothing)
    return (elem, (elem,count+1))
  else gi.bitState = next[2] end
  schema = next[1]
  
  # get edges selected
  currentEdges = gi.allEdges[schema]

  # build graph and return state
  G = initializeGraph(gi.nodes, currentEdges)
  return (elem, (G, count + 1))
end



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
function proportionAreGossipable3(n, k)
  # easily-proven lower bound
  if (k < 1.5*(n-1))
    println("safely ignored")
    return 0.0
  end

  count = 0
  total = 0
  for G in GraphIt(n,k)
    count += isGossipable(G)
    total += 1
  end
  println(count, " / ", total)
  return count / total
end
