
# Introduction 

We investigate [Dunbar's Number](https://en.wikipedia.org/wiki/Dunbar%27s_number) which claims that humans can "comfortably maintain ~150 stable relationships".  Some sociological research explains this threshold as the maximal size for a stable organization without explicitly-enforced heirarchies in place.  Moreover, stability in human organizations without these heirarchies are strengthened by humans' natural tendency to gossip as a form of bonding.

## Mathematical Structure

Here, we model such an informal human organization, where each node represents a person, and each edge represents some general sense of mutual knowing-eachotherness.  We say person A and distinct person B can gossip about distinct person C if and only if person A and C share an edge and person B and C share an edge.  That is, `A`,`B`, and `C` form a triangle subgraph.

Then, we say a graph `G` is *gossipable* if every node `A` in `G` has the ability to gossip with a distinct node `C` in `G` about at least one other node `C` in `G`. 
So, this is equivalent to the statement that every node in `G` is part of a triangle subgraph.

## Goals of this Project
We hope to investigate gossipability in the context of Dunbar's number.  Ideally, we want to be able to motivate the value 150 with an argument stemming from gossipability.  

Firstly, we must develop code that scales well enough to compute gossipability for classes of graphs on the order of 150 nodes.  Given the scaling of our current implementation, we suspect randomized approximations will serve as a necessary tool to achieve the desired results.


# Timing Comparisions
Comparing the currrent implementation of `ProportionAreGossipable(n,k)`, denoted `pag3` and the previous two iterations.
We can see the current implementation `pag3` gives us a pretty good increase over the naive `pag1` and only slightly less naive `pag2`.

For general discussion, we'll consider a function as  *infeasible* if it takes longer than 300 seconds on my machine.

 Section   |  time |   alloc 
 ----------|-------|---------
 pag1(7,9) |  345s |  325GiB 
 pag2(7,9) |  326s |  325GiB 
 pag3(7,9) | 4.74s | 2.59GiB 
 pag4(7,9) | 2.18s | 2.60GiB 
 pag5(7,9) | 1.24s | 1.91GiB
 pag6(7,9) | 456ms |  399MiB

For computations on my laptop, we see the first two implementations are infeasible for testing gossipability of graphs of even 7 nodes.


## Latest Iteration if `proportion_are_gossipable(n,k)

Observe for graphs of `n=9` nodes, we reach infeasibility with `k=27` edges for the latest iteration.  The largest class of graphs to test with 9 nodes would be `k=18`, so we still cannot fully compute with 9 nodes.

Section   |   time| %tot   |  alloc | %tot 
----------|-------|--------|--------|-------
pag(9,25) |   764s| 60.5%  |  797GiB| 60.8%    
pag(9,26) |   325s| 25.7%  |  337GiB| 25.7%    
pag(9,27) |   120s| 9.53%  |  125GiB| 9.53%    
pag(9,28) |  43.6s| 3.45%  | 40.1GiB| 3.06%    
pag(9,29) |  10.9s| 0.86%  | 11.1GiB| 0.84%    

## Strategies for computing `is_gossipable(G)`

The two main bottlenecks are: 
1. `GraphIt(n,k)` -- Generation of all the graphs for a given number of nodes `n` and number of edges `k`.   
2. `is_gossipable(G)` -- Test for whether a given graph is gossipable.

We have four strategies for computing `is_gossipable(G)`:
1. `graphsearch` -- The initial implementation, performing an explicit search in the neighborhood of length 2 from each node to ensure itself was a neighbor of a distinct node two connections away (i.e., a path of length 3 exists from each node to itself, forming a triangle).
2. `fullmatmult` -- A more sophisticated approach, with the overhaul of the encoding of `G` to an adjacency matrix representation, we note the i^th diagonal of `G^3` counts the number of paths of length 3 from node `i` to itself.  This method explicitly computes `G^3` and checks if any of its diagonals are 0.
3. `cutearlyred` -- An attempted improvement on #2, we note the `i^th` diagonal of G^3 is in fact equal to `g_i^TGg_i`, where `g_i` is the `i^th` row (or column, in our case of undirected graphs, the adjacency matrix is symmetric).  We loop through the diagonals immediately returning false once one of these values is zero, hoping cut out some unnecessary iterations.
4. `condensered` -- Another variation on #2 with the same formulation as #3, but this time with a more condense iteration.  We lose the explicit iteration reduction, but I suspect that that kind of optimization and more is able to be done under the hood by removing the for loop (usually a safe strategy for easy speed ups for this type of operation). 

We test these four variations of `is_gossipable` on our standard benchmark size of `n=7` and `k=9`.
 
Section           |  ncalls |   time |  %tot |    avg |    alloc |  %tot |     avg
------------------|---------|--------|-------|--------|----------|-------|-----
 fullmatmult(7,9) |    294k |  944ms | 45.0% | 3.21μs |  1.68GiB | 65.6% | 6.00KiB
 graphsearch(7,9) |    294k |  477ms | 22.7% | 1.62μs |   559MiB | 21.3% | 1.95KiB
 cutearlyred(7,9) |    294k |  381ms | 18.1% | 1.30μs |   184MiB | 7.01% |    656B
 condensered(7,9) |    294k |  297ms | 14.2% | 1.01μs |   161MiB | 6.13% |    574B

We immediately see the `fullmatmult` approach lags behind in both memory and time compared to even the `graphsearch` approach.  Of course, it is important to keep in mind that the size of the adjacency matrix is a paltry `7x7`, and the size of our problems of interest will never exceed O(100), so computing `G^3` multiple times is not as ridiculous as it may initially sound.

Before drawing any conclusions, it is certainly worth more at least a slightly larger test. 

 Section           |  ncalls |   time |  %tot |    avg |    alloc |  %tot |     avg
-------------------|---------|--------|-------|--------|----------|-------|----
 graphsearch(8,16) |   30.4M |   143s | 35.3% | 4.71μs |   154GiB | 38.8% | 5.32KiB
 cutearlyred(8,16) |   30.4M |   121s | 29.9% | 3.99μs |  51.3GiB | 12.9% | 1.77KiB
 fullmatmult(8,16) |   30.4M |   118s | 29.2% | 3.89μs |   182GiB | 45.6% | 6.27KiB
 condensered(8,16) |   30.4M |  22.6s | 5.57% |  743ns |  10.8GiB | 2.72% |    382B

In this test, each `is_gossipable` call is made ~103x more, `G` is now 8x8, and sparsity ~25% as opposed to ~36% in the previous example.  Sparsity considerations of G is something we expect could be of value as we scale the code further.

We see this time that although `cutearlyred` maintains a dramatically smaller amount of allocated memory than `graphsearch` and `fullmatmult`, but is slightly slower than `fullmatmult` this time.  The explicit for-loop of `cutearlyred` appears to be scaling poorly.  Meanwhile, `condensered` is really a best-of-both-worlds combination of those two strategies, resulting in significantly better performance than all the rest on both these measures.

We will use `condensered` as the basis for `is_gossipable` going forward, updating benchmarks and moving other implementations to `old_dunbar.jl` in the next commit.

# Summary Comparison

We need at least `n=3` nodes to ask non-trivially about gossipability of a graph.  Additionally, we note that for a fully-connected graph of `n` nodes and `k=n(n-1)/2` edges, each node has `n-1` edges connected to it, so we can safely remove `n-3` of those while still guaranteeing gossipability.  Lastly, noting the symmetry in number of graphs with `k` edges vs. `n(n-1)/2 - k` edges, we conclude there are `n(n-1)/2-(n-3) - ceil(n(n-1)/4)` classes of graphs with `n` nodes to time.


n            | 3| 4| 5| 6| 7| 8| 9|...|150
-------------|--|--|--|--|--|--|--|---|-------
cum. classes | 1| 3| 6|10|16|25|37|...|270,322


So we can compare across iterations by computing how many classes the current iteration can achieve with each test being feasible.

Iteration | Number of feasible class checks| Commit
----------|--------------------------------|--------
pag1      | 13 / 270,322                   | [c7721da](https://github.com/bkaperick/Dunbar/commit/c7721da)
pag2      | 13 / 270,322                   | [f4373b](https://github.com/bkaperick/Dunbar/commit/f4373b)
pag3      | 16 / 270,322                   | [dbff44a](https://github.com/bkaperick/Dunbar/commit/dbff44a)
pag4      | 23 / 270,322                   | [ddd3d3c](https://github.com/bkaperick/Dunbar/commit/ddd3d3c)
pag5      | 27 / 270,322                   | [76e5731](https://github.com/bkaperick/Dunbar/commit/76e5731)
pag6      | 28 / 270,322                   | HEAD

Again, for the motivating application, the goal is to do these compations for `n~150`, so we include that as reference.



