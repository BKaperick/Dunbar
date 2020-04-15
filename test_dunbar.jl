include("Dunbar.jl")

# Graph tests
n = 5
edges = Bool[1,1,0,0,1,0,0,1,0,1]
G = initialize_graph(n, edges)
@assert !is_gossipable(G)
#@assert is_in_triangle(G,1)
#@assert is_in_triangle(G,2)
#@assert is_in_triangle(G,3)
#@assert !is_in_triangle(G,4)
#@assert !is_in_triangle(G,5)

@assert abs(proportion_are_gossipable(3,2) - 0.0) < 1e-6
@assert abs(proportion_are_gossipable(3,3) - 1.0) < 1e-6
@assert abs(proportion_are_gossipable(6,8) - 0.08391608391608392) < 1e-6
@assert abs(proportion_are_gossipable(7,9) - 0.011193141224100976) < 1e-6

# inclusive bounds for range of k-values that need be checked
bounds(n) = (ceil(n*(n-1)/4),0.5*n^2 - 1.5*n+2)
bsize(n) = bounds(n)[2] - bounds(n)[1]+1
cumbounds(N) = sum(bsize(n) for n in 3:N)

