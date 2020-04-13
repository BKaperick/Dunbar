using TimerOutputs
#using BenchmarkTools
include("old_dunbar.jl")
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
  proportionAreGossipable(5,7)
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
  kMin = Int64(ceil(n*(n-1)/4))
  kMax = Int64(n*(n-1)/2)
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
    nP = numPaths(n,k)
    @timeit to "pag($(n),$(k))($(nP))" proportionAreGossipable(n,k)
  end
end

function timerOutputToMarkdown(to::TimerOutput)
  #table = replace(string(to), r"  ([\d\w\%])" => s"| \1")
  table = replace(string(to), r"([\)nsetgc\ds\%B]) " => s"\1 |")
  badHyphen = table[end]
  
  # replace weird hyphen with mark-down recognizable hyphen
  table = replace(table, Regex(String([Char(9472)])) => s"-")

  table = split(table,"\n")[6:end]
  return reduce(*,map(x -> x*"\n", table))
end
#println(profileBitItByK(32,2:2:8,1))
#println(profileBitItByN(4,4:4:12,2))
#println(profilePAG(5,5))
#println(profilePAG(6,1))

#using Profile
#@time proportionAreGossipable3(6,8)
#Profile.init(delay=0.01)
#Profile.clear()
#@profile @time proportionAreGossipable3(6,8)
#
#@time proportionAreGossipable3(5,1)
open("Readme.md","a") do io
  println(io,timerOutputToMarkdown(to));
end


