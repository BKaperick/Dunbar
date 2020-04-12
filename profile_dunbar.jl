using TimerOutputs
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
function profileProportionAreGossipable(n::Int64, T)
  kMin = Int64(ceil(1.5*(n-1)))
  println("k=$(kMin)")
  return profileProportionAreGossipable(n,kMin,T)
end
function profileProportionAreGossipable(n::Int64, k::Int64, T)
  kMin = Int64(ceil(1.5*(n-1)))
  to = TimerOutput()
  println("burn in:")
  proportionAreGossipable3(n,k)
  proportionAreGossipable2(n,k)
  proportionAreGossipable1(n,k)
  println("finished burn")
  for t=1:T
    @timeit to "pag1($(n),$(k))" proportionAreGossipable1(n,k)
    @timeit to "pag3($(n),$(k))" proportionAreGossipable3(n,k)
    @timeit to "pag2($(n),$(k))" proportionAreGossipable2(n,k)
  end
  return to
end


#println(profileBitItByK(32,2:2:8,1))
#println(profileBitItByN(4,4:4:12,2))
println(profileProportionAreGossipable(5,5))
#println(profileProportionAreGossipable(6,1))

#using Profile
#@time proportionAreGossipable3(6,8)
#Profile.init(delay=0.01)
#Profile.clear()
#@profile @time proportionAreGossipable3(6,8)
#
#@time proportionAreGossipable3(5,1)
