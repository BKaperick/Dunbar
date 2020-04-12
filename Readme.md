
# Timing Comparisions
Comparing the currrent implementation of `ProportionAreGossipable(n,k)`, denoted `pag3` and the previous two iterations.
We can see the current implementation `pag3` gives us a pretty good increase over the naive `pag1` and only slightly less naive `pag2`.

For general discussion, we'll consider a function as  *infeasible* if it takes longer than 300 seconds on my machine.

 ────────────────────────────────────────────────────────────────────
                             Time                   Allocations      
                     ──────────────────────   ───────────────────────
  Tot / % measured:        855s / 78.9%            652GiB / 100%     

 Section     ncalls     time   %tot     avg     alloc   %tot      avg
 ────────────────────────────────────────────────────────────────────
 pag1(7,9)        1     345s  51.0%    345s    325GiB  49.8%   325GiB
 pag2(7,9)        1     326s  48.3%    326s    325GiB  49.8%   325GiB
 pag3(7,9)        1    4.74s  0.70%   4.74s   2.59GiB  0.40%  2.59GiB
 ────────────────────────────────────────────────────────────────────

For computations on my laptop, we see the previous two implementations are infeasible for testing gossipability of graphs of 7 nodes.


## Latest Iteration


 ──────────────────────────────────────────────────────────────────────────
                                   Time                   Allocations      
                           ──────────────────────   ───────────────────────
     Tot / % measured:          710ms / 92.9%            409MiB / 91.4%    

 Section           ncalls     time   %tot     avg     alloc   %tot      avg
 ──────────────────────────────────────────────────────────────────────────
 pag(6,8)(6435)         3    236ms  35.7%  78.6ms    150MiB  40.2%  50.1MiB
 pag(6,9)(5005)         3    179ms  27.1%  59.5ms    114MiB  30.5%  38.0MiB
 pag(6,10)(3003)        3    136ms  20.6%  45.3ms   66.8MiB  17.9%  22.3MiB
 pag(6,11)(1365)        3   84.6ms  12.8%  28.2ms   30.2MiB  8.07%  10.1MiB
 pag(6,12)(455)         3   15.3ms  2.31%  5.09ms   10.1MiB  2.70%  3.37MiB
 pag(6,13)(105)         3   7.74ms  1.17%  2.58ms   2.38MiB  0.64%   812KiB
 pag(6,14)(15)          3   1.49ms  0.23%   496μs    366KiB  0.10%   122KiB
 pag(6,15)(1)           3    522μs  0.08%   174μs   38.2KiB  0.01%  12.7KiB
 ──────────────────────────────────────────────────────────────────────────

Note by symmetry that `pag(7,11)` should be approximately comparable to `pag(7,9)` from the above timing comparison.   

 ────────────────────────────────────────────────────────────────────────────
                                     Time                   Allocations      
                             ──────────────────────   ───────────────────────
      Tot / % measured:           48.7s / 97.2%           28.4GiB / 92.6%    

 Section             ncalls     time   %tot     avg     alloc   %tot      avg
 ────────────────────────────────────────────────────────────────────────────
 pag(7,11)(352716)        3    15.8s  33.3%   5.25s   9.00GiB  34.2%  3.00GiB
 pag(7,12)(293930)        3    14.3s  30.2%   4.76s   7.37GiB  28.0%  2.46GiB
 pag(7,13)(203490)        3    8.71s  18.4%   2.90s   5.05GiB  19.2%  1.68GiB
 pag(7,14)(116280)        3    5.07s  10.7%   1.69s   2.87GiB  10.9%  0.96GiB
 pag(7,15)(54264)         3    2.31s  4.87%   769ms   1.35GiB  5.12%   461MiB
 pag(7,16)(20349)         3    879ms  1.85%   293ms    525MiB  1.94%   175MiB
 pag(7,17)(5985)          3    283ms  0.60%  94.2ms    157MiB  0.58%  52.4MiB
 pag(7,18)(1330)          3   59.9ms  0.13%  20.0ms   35.6MiB  0.13%  11.9MiB
 pag(7,19)(210)           3   8.98ms  0.02%  2.99ms   5.75MiB  0.02%  1.92MiB
 pag(7,20)(21)            3   1.67ms  0.00%   558μs    615KiB  0.00%   205KiB
 pag(7,21)(1)             3    698μs  0.00%   233μs   45.8KiB  0.00%  15.3KiB
 ────────────────────────────────────────────────────────────────────────────


Observe for graphs of `n=8` nodes, we reach infeasibility with `k=17` edges for the latest iteration.  The largest class of graphs to test with 8 nodes would be `k=14`, so we still cannot fully compute with 8 nodes.

 ──────────────────────────────────────────────────────────────────────────────
                                       Time                   Allocations
                               ──────────────────────   ───────────────────────
       Tot / % measured:            1556s / 51.5%            470GiB / 92.6%

 Section               ncalls     time   %tot     avg     alloc   %tot      avg
 ──────────────────────────────────────────────────────────────────────────────
 pag(8,17)(21474180)        1     368s  46.0%    368s    201GiB  46.1%   201GiB
 pag(8,18)(13123110)        1     230s  28.7%    230s    123GiB  28.3%   123GiB
 pag(8,19)(6906900)         1     117s  14.7%    117s   65.3GiB  15.0%  65.3GiB
 pag(8,20)(3108105)         1    54.4s  6.79%   54.4s   29.7GiB  6.83%  29.7GiB
 pag(8,21)(1184040)         1    21.8s  2.73%   21.8s   11.5GiB  2.64%  11.5GiB
 pag(8,22)(376740)          1    6.40s  0.80%   6.40s   3.69GiB  0.85%  3.69GiB
 pag(8,23)(98280)           1    1.88s  0.23%   1.88s   0.98GiB  0.22%  0.98GiB
 pag(8,24)(20475)           1    418ms  0.05%   418ms    211MiB  0.05%   211MiB
 pag(8,25)(3276)            1   61.6ms  0.01%  61.6ms   34.1MiB  0.01%  34.1MiB
 pag(8,26)(378)             1   8.40ms  0.00%  8.40ms   3.97MiB  0.00%  3.97MiB
 pag(8,27)(28)              1   1.25ms  0.00%  1.25ms    309KiB  0.00%   309KiB
 pag(8,28)(1)               1    203μs  0.00%   203μs   17.6KiB  0.00%  17.6KiB
 ──────────────────────────────────────────────────────────────────────────────

# Summary Comparison

We need at least `n=3` nodes to ask non-trivially about gossipability of a graph.  And mod some symmetry, there are `n(n-1)/2 - ceil(n(n-1)/4) + 1` classes of graphs with `n` nodes to test.


n            | 3| 4| 5| 6| 7| 8|
--------------------------------------
cum. classes | 2| 6|11|19|30|44|


So we can compare across iterations by computing how many classes the current iteration can achieve with each test being feasible.

Iteration | Number of feasible class checks
-------------------------------------------
pag1      | 28
pag2      | 28
pag3      | 37
