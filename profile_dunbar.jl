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

println(profileBitItByK(32,2:2:8,1))
println(profileBitItByN(4,4:4:12,2))
