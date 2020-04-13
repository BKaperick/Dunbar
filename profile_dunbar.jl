using TimerOutputs
#using BenchmarkTools
include("dunbar.jl")

function profileBitItByN(k::Int64, nRange, T)
  to = TimerOutput()
  for t=1:T
    for n = nRange
      @timeit to "($(n))" reduce(+,BitIt(n,k))
    end
  end
  return to
end

function profileBitItByK(n::Int64, kRange, T)
  to = TimerOutput()
  for t=1:T
    for k = kRange
      @timeit to "($(k))" reduce(+,BitIt(n,k))
    end
  end
  return to
end

"""
    profileOldPAG(n::Int64, k::Int64, T::Int64)

Profile old iterations of `ProportionAreGossipable(n,k)` in `old_dunbar.jl`
with the latest in `dunbar.jl`.
"""
function profileOldPAG(n::Int64, k::Int64, T)
  kMin = Int64(ceil(1.5*(n-1)))
  to = TimerOutput()
  #burn-in to make sure everything is compiled
  proportionAreGossipable(5,7)
  proportionAreGossipable2(5,7)
  proportionAreGossipable1(5,7)
  for t=1:T
    @timeit to "pag1($(n),$(k))" proportionAreGossipable1(n,k)
    @timeit to "pag2($(n),$(k))" proportionAreGossipable2(n,k)
    @timeit to "pag3($(n),$(k))" proportionAreGossipable(n,k) # latest
  end
  return to
end

"""
    profileMinPAG(n::Int64, T::Int64)

Profile `ProportionAreGossipable(n,k)` for all combinatorially-unique values 
of `k` with `T` trials. 
"""
function profileMinPAG(nRange::OrdinalRange{Int64}, T)
  proportionAreGossipable(7,9) # make sure compiled
  to = TimerOutput()
  for n in nRange
    profileMinPAG(n,T,to)
  end
end

"""
    profileMinPAG(n::Int64, T::Int64, to::TimerOutput)

Profile `ProportionAreGossipable(n,k)` updating `to` for minimum non-trivial 
value of `k` with `T` trials. 
"""
function profileMinPAG(n::Int64,T,to=TimerOutput())
  kMin = Int64(ceil(1.5*(n-1)))
  profilePAG(n,kMin,to,T)
  println(to)
  return to
end

"""
    profilePAG(n::Int64, T::Int64)

Profile `ProportionAreGossipable(n,k)` for all combinatorially-unique values 
of `k` with `T` trials. 
"""
function profilePAG(n::Int64, T)
  kMax = Int64(0.5*n^2-1.5*n+2)
  kMin = Int64(ceil(n*(n-1)/4))
  return profilePAG(n,kMax:-1:kMin,T)
end

"""
    profilePAG(n::Int64,kRange::OrdinalRange{Int64}, T::Int64)

Profile `ProportionAreGossipable(n,k)` for all values of `k` in `kRange` with 
`T` trials. 
"""
function profilePAG(n::Int64,kRange::OrdinalRange{Int64}, T)
  proportionAreGossipable(5,7)
  to = TimerOutput()
  for k in kRange
    profilePAG(n,k,to,T)
    println(to)
  end
  return to
end

"""
    profilePAG(n::Int64, k::Int64, to::TimerOutput, T::Int64)

Profile `ProportionAreGossipable(n,k)` updating `to` with `T` trials. 
"""
function profilePAG(n::Int64, k::Int64, to::TimerOutput, T)
  for t=1:T
    @timeit to "pag($(n),$(k))" proportionAreGossipable(n,k)
  end
end

function timerOutputToMarkdown(to)#::TimerOutput)
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
benchmark() = profileMinPAG(7,3)

# export table to readme.
#open("Readme.md","a") do io
#  println(io,timerOutputToMarkdown(to));
#end


