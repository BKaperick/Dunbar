using Plots
include("Dunbar.jl")

"""
    gather_error(n,k,samples)

Calls `gather_error` after exactly computing the `true_value`.
"""
function gather_error(n,k,samples)
  true_value = proportion_are_gossipable(n,k,:verbose)
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
  ests = []
  for (i,s)=enumerate(samples)
    s_cum += s
    est_cum += proportion_are_gossipable(n,k,s,:debug)
    append!(ests, est_cum / s_cum)
  end
  errors = [error(est) for est in ests]
  return hcat(ests,errors)
end

"""
    plot_error(n,k,samples)

Calls `plot_error` after exactly computing the `true_value`.
"""
function plot_error(n,k,samples)
  true_value = proportion_are_gossipable(n,k,:verbose)
  scatter(legend=false)
  return plot_error(n,k,samples,true_value)
end

"""
    plot_error(n,k,samples,true_value)

Computes the estimated `proportion_are_gossipable(n,k)` value for each sample 
size in `samples`, and then plots the sample size against the value's relative 
error .
"""
function plot_error(n,k,samples,true_value)::Array{AbstractFloat,2}
  error(x) = abs(true_value - x) / true_value
  est_cum = 0
  s_cum = 0
  ests = []
  for (i,s)=enumerate(samples)
    s_cum += s
    est_cum += proportion_are_gossipable(n,k,s,:debug)
    scatter!((s,error(est_cum)))
    #append!(ests, est_cum / s_cum)
  end
  #errors = [error(est) for est in ests]
  #return hcat(ests,errors)
end

samples = 1000:1000:5000000;
#plot_error(Int8(6),Int8(8),samples)
errs = gather_error(Int8(7),Int8(8),samples)
plot()
plot(samples,errs[:,2],lab="relative error",w=3)



