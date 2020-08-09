using Plots
include("Dunbar.jl")

"""
    gather_error(n,k,samples)

Calls `gather_error` after exactly computing the `true_value`.
"""
function gather_error(n,k,samples)
  true_value = proportion_are_gossipable(n,k,:verbose)
  println("true value: ", true_value)
  return gather_error(n,k,samples,true_value)
end

"""
    gather_error(n,k,samples,true_value)

Computes the estimated `proportion_are_gossipable(n,k)` value for each sample 
size in `samples`, and then returns a `(length(samples),2)` array of the 
estimated value and its relative error.
"""
function gather_error(n,k,samples,true_value)::Array{AbstractFloat,2}
  error(x) = abs(true_value - x) / true_value
  est_cum = 0
  s_cum = 0
  last_s = 0
  ests = []
  for (i,s)=enumerate(samples)
    s_left = s - last_s
    s_cum += s_left
    est_cum += randomized_proportion_are_gossipable(n,k,s_left,:debug)
    println(s, ": ", est_cum/s_cum, " | ", error(est_cum/s_cum))
    append!(ests, est_cum / s_cum)
  end
  errors = [error(est) for est in ests]
  return hcat(ests,errors)
end

function estimate_order(estimates)
  q_ests = []
  prev_diff = estimates[3] - estimates[2]
  denominator = log(abs(prev_diff / (estimates[2] - estimates[1])))
  for k=3:length(estimates)-1
    diff = estimates[k+1] - estimates[k]
    numerator = log(abs(diff/prev_diff))
    append!(q_ests, numerator/denominator)
    
    denominator = numerator
    prev_diff = diff
  end
  return q_ests
end


samples = 1000:1000:10000;
errs = gather_error(Int8(10),Int8(19),samples,1)
#plot(samples,errs[:,2],lab="relative error",w=3,ylims=(0,1))
plot(samples,errs[:,1],lab="estimated proportion",w=3,ylims=(0,1))
qs = estimate_order(errs[5:end,1])
mean(qs)


