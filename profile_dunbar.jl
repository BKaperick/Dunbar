using TimerOutputs
include("Dunbar.jl")

function profile_bitit_by_n(k::Int64, nrange, T)
  to = TimerOutput()
  for t=1:T
    for n = nrange
      @timeit to "($(n))" reduce(+,BitIt(n,k))
    end
  end
  return to
end

function profile_bitit_by_k(n::Int64, krange, T)
  to = TimerOutput()
  for t=1:T
    for k = krange
      @timeit to "($(k))" reduce(+,BitIt(n,k))
    end
  end
  return to
end

"""
    profile_min_pag(n::Int64, T::Int64)

Profile `proportion_are_gossipable(n,k)` for all combinatorially-unique values 
of `k` with `T` trials. 
"""
function profile_min_pag(nrange::OrdinalRange{Int64}, T)
  proportion_are_gossipable(7,9) # make sure compiled
  to = TimerOutput()
  for n in nrange
    profile_min_pag(n,T,to)
  end
end

"""
    profile_min_pag(n::Int64, T::Int64, to::TimerOutput)

Profile `proportion_are_gossipable(n,k)` updating `to` for minimum non-trivial 
value of `k` with `T` trials. 
"""
function profile_min_pag(n::Int64,T,to=TimerOutput())
  kmin = Int64(ceil(1.5*(n-1)))
  profile_pag(n,kmin,to,T)
  println(to)
  return to
end

"""
    profile_pag(n::Int64, T::Int64)

Profile `proportion_are_gossipable(n,k)` for all combinatorially-unique values 
of `k` with `T` trials. 
"""
function profile_pag(n::Int64, T)
  kmax = Int64(0.5*n^2-1.5*n+2)
  kmin = Int64(ceil(n*(n-1)/4))
  return profile_pag(n,kmax:-1:kmin,T)
end

"""
    profile_pag(n::Int64,krange::OrdinalRange{Int64}, T::Int64)

Profile `proportion_are_gossipable(n,k)` for all values of `k` in `krange` with 
`T` trials. 
"""
function profile_pag(n::Int64,krange::OrdinalRange{Int64}, T)
  proportion_are_gossipable(5,7)
  to = TimerOutput()
  for k in krange
    profile_pag(n,k,to,T)
    println(to)
  end
  return to
end

"""
    profile_pag(n::Int64, k::Int64, to::TimerOutput, T::Int64)

Profile `proportion_are_gossipable(n,k)` updating `to` with `T` trials. 
"""
function profile_pag(n::Int64, k::Int64, to::TimerOutput, T)
  for t=1:T
    @timeit to "pag($(n),$(k))" proportion_are_gossipable(n,k)
  end
end

function timeroutput_to_markdown(to)#::TimerOutput)
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
benchmark() = profile_min_pag(7,3)

# export table to readme.
#open("Readme.md","a") do io
#  println(io,timeroutput_to_markdown(to));
#end


