include("dunbar.jl")

# Paths enumerating tests
for n=1:8
  for k=0:n
    correctAns = paths(n,k)
    @assert correctAns == length(generateActiveBitArrays(n,k))
    @assert correctAns == length(collect(BitIt(n,k)))
  end
end

# Graph tests
nodes = ["a","b","c","d"]
edges = [("a","b"),("b","c"),("c","a"),("a","d")]
G = initializeGraph(nodes, edges)
@assert !isGossipable(G)
@assert isInTriangle(G,"a")
@assert isInTriangle(G,"b")
@assert isInTriangle(G,"c")
@assert !isInTriangle(G,"d")
