using LinearAlgebra

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

"""
    initializeGraph(nodes, edges)

Constructs the graph data structure from a set of string node names `nodes` and
a set of 2-tuple relations stored in the iterable `edges`.
"""
function initializeGraph(n,bitArray)::Symmetric{Bool,Array{Bool,2}}
  #G = Array{Int64}(undef, n, n)
  G = zeros(Bool, n, n)
  indexMap = reduce(vcat, [((p-1)*n + p + 1):(p*n) for p in 1:(n-1)])
  G[indexMap] = bitArray 
  return Symmetric(G,:L)
end

"""
    isInTriangle(graph, node)

Decides if the node named `node` in `graph` is part of a triangle.  That is,
there exists a neighbor node `m` for which `node` and `m` have a mutual, 
distinct neighbor.
"""
function isInTriangle(graph::Symmetric{Bool,Array{Bool,2}},node)
  edges(node) = [i for (i,n) in enumerate(graph[node,1:end]) if n]
  for e in edges(node)
    for ee in edges(e)
      if graph[node,ee]
        return true
      end
    end
  end
  return false
end
function isInTriangle(graph::Array{Array{Int64,1},1},node)
  edges = graph[node]
  for e in graph[node]     # nbd of node
    for ee in graph[e]     # nbd of e
      if node in graph[ee] # is node in nbd of ee
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
isGossipable(G::Symmetric{Bool,Array{Bool,2}}) = !any(diag(G*G*G) .== 0)

mutable struct GraphIt
  n::Int64
  k::Int64
  bitArrays::BitIt
  bitState::Tuple{Array{Bool,1},Int64}
  start::Symmetric{Bool,Array{Bool,2}}
  onemore::Bool
end

function GraphIt(n,k)
  numEdges = Int64(n*(n-1)/2)

  # initialize bit iterator
  bi = BitIt(numEdges,k)
  bitStart,bitState = iterate(bi)

  start = initializeGraph(n, bitStart)
  return GraphIt(n,k,bi,bitState,start,false)
end

function Base.iterate(gi::GraphIt, state=(gi.start, 0))
  elem,count = state
  if gi.onemore
    return nothing
  end
   
  # get pointers to current edges selected
  next = iterate(gi.bitArrays, gi.bitState)
  if (next == nothing)
    gi.onemore = true
    return (elem, (elem,count+1))
  else gi.bitState = next[2] end
  schema = next[1]

  # build graph and return state
  G = initializeGraph(gi.n, schema)
  return (elem, (G, count + 1))
end

"""
    proportionAreGossipable(n, k)

Returns the proportion of all possible graphs with `n` nodes and `k` edges
which are gossipable.
"""
function proportionAreGossipable(n, k)
  # easily-proven lower bound
  if (k < 1.5*(n-1))
    println("safely ignored")
    return 0.0
  end

  count = 0
  total = 0
  for G in GraphIt(n,k)
    #println(G)
    count += isGossipable(G)
    total += 1
  end
  println(count, " / ", total)
  return count / total
end
