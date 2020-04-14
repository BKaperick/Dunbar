using LinearAlgebra

mutable struct BitIt{T<:Integer}
  n::T # number of bits
  k::T # number of active bits (hamming weight)
  i::T # current index within iteration
  l::T # current active bit within iteration
end

BitIt(num_bits::Integer,num_active::Integer) = num_bits >= num_active ? BitIt(num_bits,num_active,num_active,num_active) : throw(ArgumentError("num_active cannot be larger than num_bits"))

function Base.iterate(bi::BitIt, state=(vcat([true for _ in range(1,stop=bi.k)], [false for _ in range(1,stop=bi.n-bi.k)]), 0))
  elem,count = state
  k,n,i,l = bi.k,bi.n,bi.i,bi.l

  # Base case
  if n == k || k == 0
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
    initialize_graph(nodes, edges)

Constructs the graph data structure from a set of string node names `nodes` and
a set of 2-tuple relations stored in the iterable `edges`.
"""
function initialize_graph(n,bitArray)::Symmetric{Bool,Array{Bool,2}}
  G = zeros(Bool, n, n)
  indexMap = reduce(vcat, [((p-1)*n + p + 1):(p*n) for p in 1:(n-1)])
  G[indexMap] = bitArray 
  return Symmetric(G,:L)
end

"""
    is_in_triangle(graph, node)

Decides if the node named `node` in `graph` is part of a triangle.  That is,
there exists a neighbor node `m` for which `node` and `m` have a mutual, 
distinct neighbor.
"""
function is_in_triangle(graph::Symmetric{Bool,Array{Bool,2}},node)
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
function is_in_triangle(graph::Array{Array{Integer,1},1},node)
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
    is_gossipable(G)

Decides if all nodes contained in graph `G` are in a triangle.
"""
is_gossipable(G::Symmetric{Bool,Array{Bool,2}}) = !any(diag(G*G*G) .== 0)

# Slightly better for small cases, but scales poorly.  Consider n=9,k=29, PAG is ~2x slower with ~16% more memory used
#is_gossipable(G::Symmetric{Bool,Array{Bool,2}},n::Integer) = all(is_in_triangle(G,node) for node=1:n)

mutable struct GraphIt{T<:Integer}
  n::T
  k::T
  bitarrays::BitIt
  bitstate::Tuple{Array{Bool,1},T}
  start::Symmetric{Bool,Array{Bool,2}}
  onemore::Bool
end

function GraphIt(n::Integer,k::Integer)
  numEdges = Integer(n*(n-1)/2)

  # initialize bit iterator
  bi = BitIt(numEdges,k)
  bitstart,bitstate = iterate(bi)

  start = initialize_graph(n, bitstart)
  return GraphIt(n,k,bi,bitstate,start,false)
end

function Base.iterate(gi::GraphIt, state=(gi.start, 0))
  elem,count = state
  if gi.onemore
    return nothing
  end
   
  # get pointers to current edges selected
  next = iterate(gi.bitarrays, gi.bitstate)
  if next == nothing
    gi.onemore = true
    return (elem, (elem,count+1))
  else gi.bitstate = next[2] end
  schema = next[1]

  # build graph and return state
  G = initialize_graph(gi.n, schema)
  return (elem, (G, count + 1))
end

"""
    proportion_are_gossipable(n, k)

Returns the proportion of all possible graphs with `n` nodes and `k` edges
which are gossipable.
"""
function proportion_are_gossipable(n, k)
  # easily-proven lower bound
  if k < 1.5*(n-1)
    println("safely ignored")
    return 0.0
  end

  count = 0
  total = 0
  for G in GraphIt(n,k)
    count += is_gossipable(G)
    total += 1
  end
  #println(count, " / ", total)
  return count / total
end
