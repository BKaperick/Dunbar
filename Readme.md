
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

 Section   |  time | %tot |   alloc | %tot 
 ----------|-------|------|---------|------
 pag1(7,9) |  345s |50.9% |  325GiB |49.6% 
 pag2(7,9) |  326s |48.1% |  325GiB |49.6% 
 pag3(7,9) | 4.74s |0.70% | 2.59GiB |0.40% 
 pag4(7,9) | 2.18s |0.32% | 2.60GiB |0.40%

For computations on my laptop, we see the first two implementations are infeasible for testing gossipability of graphs of even 7 nodes.


## Latest Iteration

Note by symmetry that `pag(7,11)` should be approximately comparable to `pag(7,9)` from the above timing comparison.   

 Section           | ncalls |   time | %tot |   avg |   alloc | %tot |    avg
 ------------------|--------|--------|------|-------|---------|------|--------
 pag(7,11)(352716) |      3 |  15.8s |33.3% | 5.25s | 9.00GiB |34.2% |3.00GiB
 pag(7,12)(293930) |      3 |  14.3s |30.2% | 4.76s | 7.37GiB |28.0% |2.46GiB
 pag(7,13)(203490) |      3 |  8.71s |18.4% | 2.90s | 5.05GiB |19.2% |1.68GiB
 pag(7,14)(116280) |      3 |  5.07s |10.7% | 1.69s | 2.87GiB |10.9% |0.96GiB
 pag(7,15)(54264)  |      3 |   2.31s| 4.87%|  769ms|  1.35GiB| 5.12%|  461MiB
 pag(7,16)(20349)  |      3 |  879ms |1.85% | 293ms |  525MiB |1.94% | 175MiB
 pag(7,17)(5985)   |      3 |  283ms |0.60% |94.2ms |  157MiB |0.58% |52.4MiB
 pag(7,18)(1330)   |      3 | 59.9ms |0.13% |20.0ms | 35.6MiB |0.13% |11.9MiB
 pag(7,19)(210)    |      3 | 8.98ms |0.02% |2.99ms | 5.75MiB |0.02% |1.92MiB
 pag(7,20)(21)     |      3 | 1.67ms |0.00% | 558μs |  615KiB |0.00% | 205KiB
 pag(7,21)(1)      |      3 |  698μs |0.00% | 233μs | 45.8KiB |0.00% |15.3KiB


Observe for graphs of `n=8` nodes, we reach infeasibility with `k=17` edges for the latest iteration.  The largest class of graphs to test with 8 nodes would be `k=14`, so we still cannot fully compute with 8 nodes.

 Section             |  ncalls |    time |  %tot |    avg |    alloc |  %tot |     avg
 -|-|--|--|--------------|---------|---------|---------
 pag(8,15)(37442160) |       1 |    393s | 26.6% |   393s |   373GiB | 24.3% |  373GiB
 pag(8,14)(40116600) |       1 |    370s | 25.1% |   370s |   400GiB | 26.0% |  400GiB
 pag(8,16)(30421755) |       1 |    287s | 19.4% |   287s |   303GiB | 19.7% |  303GiB
 pag(8,17)(21474180) |       1 |    195s | 13.2% |   195s |   214GiB | 13.9% |  214GiB
 pag(8,18)(13123110) |       1 |    122s | 8.29% |   122s |   131GiB | 8.51% |  131GiB
 pag(8,19)(6906900)  |       1 |   62.8s | 4.25% |  62.8s |  68.9GiB | 4.48% | 68.9GiB
 pag(8,20)(3108105)  |       1 |   30.3s | 2.05% |  30.3s |  31.0GiB | 2.01% | 31.0GiB
 pag(8,21)(1184040)  |       1 |   11.6s | 0.79% |  11.6s |  11.8GiB | 0.77% | 11.8GiB
 pag(8,22)(376740)   |       1 |   3.41s | 0.23% |  3.41s |  3.76GiB | 0.24% | 3.76GiB
 pag(8,23)(98280)    |       1 |   904ms | 0.06% |  904ms |  0.98GiB | 0.06% | 0.98GiB
 pag(8,24)(20475)    |       1 |   206ms | 0.01% |  206ms |   209MiB | 0.01% |  209MiB
 pag(8,25)(3276)     |       1 |  31.5ms | 0.00% | 31.5ms |  33.4MiB | 0.00% | 33.4MiB
 pag(8,26)(378)  |       1 |  3.92ms | 0.00% | 3.92ms |  3.86MiB | 0.00% | 3.86MiB
 pag(8,27)(28)     |       1 |   272μs | 0.00% |  272μs |   294KiB | 0.00% |  294KiB
 pag(8,28)(1)    |       1 |  76.6μs | 0.00% | 76.6μs |  11.3KiB | 0.00% | 11.3KiB

# Summary Comparison

We need at least `n=3` nodes to ask non-trivially about gossipability of a graph.  And mod some symmetry, there are `n(n-1)/2 - ceil(n(n-1)/4) + 1` classes of graphs with `n` nodes to test.


n            | 3| 4| 5| 6| 7| 8|...|150
-------------|--|--|--|--|--|--|---|-------
cum. classes | 2| 6|12|20|31|46|...|281,348


So we can compare across iterations by computing how many classes the current iteration can achieve with each test being feasible.

Iteration | Number of feasible class checks| Commit
----------|--------------------------------|--------
pag1      | 28 / 281,348                   | [c7721da](https://github.com/bkaperick/Dunbar/commit/c7721da)
pag2      | 28 / 281,348                   | [f4373b](https://github.com/bkaperick/Dunbar/commit/f4373b)
pag3      | 37 / 281,348                   | [dbff44a](https://github.com/bkaperick/Dunbar/commit/dbff44a)
pag4      | 44 / 281,348                   | HEAD

Again, for the motivating application, the goal is to do these compations for `n~150`, so we include that as reference.

