
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

For computations on my laptop, we see the first two implementations are infeasible for testing gossipability of graphs of even 7 nodes.


## Latest Iteration

Observe for graphs of `n=9` nodes, we reach infeasibility with `k=27` edges for the latest iteration.  The largest class of graphs to test with 9 nodes would be `k=18`, so we still cannot fully compute with 9 nodes.

Section |    ncalls |    time |  %tot |    avg |    alloc |  %tot |     avg
-|-|-|-|-|-|-|--------------------------------------------------------------------
pag(9,27) |       1 |    502s | 71.3% |   502s |   676GiB | 70.9% |  676GiB
pag(9,28) |       1 |    160s | 22.7% |   160s |   217GiB | 22.8% |  217GiB
pag(9,29) |       1 |   42.6s | 6.05% |  42.6s |  60.0GiB | 6.29% | 60.0GiB

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
pag5      | 27 / 270,322                   | HEAD

Again, for the motivating application, the goal is to do these compations for `n~150`, so we include that as reference.

