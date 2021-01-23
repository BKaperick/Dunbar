using TimerOutputs
include("Dunbar.jl")

function profile_bitit_by_n(k::Integer, nrange, trials)
  to = TimerOutput()
  for t=1:trials
    for n = nrange
      @timeit to "($(n))" reduce(+,BitIt(n,k))
    end
  end
  return to
end

function profile_bitit_by_k(n::Integer, krange, trials)
  to = TimerOutput()
  for t=1:trials
    for k = krange
      @timeit to "($(k))" reduce(+,BitIt(n,k))
    end
  end
  return to
end

"""
    profile_min_pag(n::Integer, T::Integer)

Profile `proportion_are_gossipable(n,k)` for all combinatorially-unique values 
of `k` with `T` trials. 
"""
function profile_min_pag(nrange::OrdinalRange{Integer}, trials)
  proportion_are_gossipable(7,9) # make sure compiled
  to = TimerOutput()
  for n in nrange
    profile_min_pag(n,trials,to)
  end
end

"""
    profile_min_pag(n::Integer, T::Integer, to::TimerOutput)

Profile `proportion_are_gossipable(n,k)` updating `to` for minimum non-trivial 
value of `k` with `T` trials. 
"""
function profile_min_pag(n::T,trials,to=TimerOutput()) where T<:Integer
  kmin = T(ceil(1.5*(n-1)))
  profile_pag(n,kmin,to,trials)
  println(to)
  return to
end

"""
    profile_pag(n::Integer, T::Integer)

Profile `proportion_are_gossipable(n,k)` for all combinatorially-unique values 
of `k` with `T` trials. 
"""
function profile_pag(n::T, trials) where T<:Integer
  kmax = T(0.5*n^2-1.5*n+2)
  kmin = T(ceil(n*(n-1)/4))
  return profile_pag(n,kmax:-one(T):kmin,trials)
end

"""
    profile_pag(n::Integer,krange::OrdinalRange{Integer}, T::Integer)

Profile `proportion_are_gossipable(n,k)` for all values of `k` in `krange` with 
`T` trials. 
"""
function profile_pag(n::T,krange::OrdinalRange{T}, trials) where T<:Integer
  @time proportion_are_gossipable(T(5),T(7))
  to = TimerOutput()
  for k in krange
    profile_pag(n,k,to,trials)
    println(to)
  end
  return to
end

"""
    profile_pag(n::Integer, k::Integer, to::TimerOutput, T::Integer)

Profile `proportion_are_gossipable(n,k)` updating `to` with `T` trials. 
"""
function profile_pag(n::Integer, k::Integer, to::TimerOutput, trials)
  for t=1:trials
    @timeit to "pag($(n),$(k))" proportion_are_gossipable(n,k)
  end
end
function profile_ig(n,k)
  to = TimerOutput()
  return profile_ig(n,k,to)
end
function profile_ig(n,k,to)
  for G in GraphIt(n,k)
    @timeit to "graphsearch($(n),$(k))" is_gossipable1(G,n)
    @timeit to "cutearlyred($(n),$(k))" is_gossipable2(G)
    @timeit to "condensered($(n),$(k))" is_gossipable3(G)
    @timeit to "fullmatmult($(n),$(k))" is_gossipable4(G)
  end
  return to
end

function timeroutput_to_markdown(to)
  table = replace(string(to), r"([\)nsetgc\ds\%B]) " => s"\1 |")
  badHyphen = table[end]
  
  # replace weird hyphen with mark-down recognizable hyphen
  table = replace(table, Regex(String([Char(9472)])) => s"-")

  table = split(table,"\n")[6:end]
  table[2] = "--------|-------|-----|-----|----|------|-----|----"*table[2]
  table = table[1:end-1]
  return reduce(*,map(x -> x*"\n", table))
end

# Standard benchmark used at top of Readme.
benchmark() = profile_min_pag(Int8(7),3)
benchmark(n::Int8) = profile_min_pag(n,3)

function store_benchmark_result(to::TimerOutput)
    columns_string = "command,nodes,edges,ncalls,avgtime,alloc"
    for (name,timer) in t.inner_timers
        command,inputs = split(name,'(')
        print(inputs)
        nodes,edges = split(replace(inputs,")" => ""),",")
        ncalls = TimerOutputs.ncalls(timer)
        avgtime = Int64(TimerOutputs.tottime(timer) / (1000 * ncalls))
        alloc = TimerOutputs.totallocated(timer)
        
        values_string = "'$command',$nodes,$edges,$ncalls,$avgtime,$alloc"
        insert_with_hash_and_date(benchmark_timing_table, columns_string, values_string)
    end
end

# export table to readme.
#open("Readme.md","a") do io
#  println(io,timeroutput_to_markdown(to));
#end


