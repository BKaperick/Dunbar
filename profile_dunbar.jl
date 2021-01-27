using TimerOutputs
using BenchmarkTools
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
    profile_min_pag(nrange::OrdinalRange{Integer}, to::TimerOutput, trials)

Profile `proportion_are_gossipable(n,k)` for all `n` in `nrange` and minimal non-trivial `k`.
"""
function profile_min_pag(nrange::OrdinalRange{Integer}, to::TimerOutput, trials)
    results 
    for n in nrange
        result = profile_min_pag(n,trials,to)
        push!(results, result)
    end
    return results
end

"""
    profile_min_pag(n::Integer, T::Integer, to::TimerOutput)

Profile `proportion_are_gossipable(n,k)` updating `to` for minimum non-trivial 
value of `k` with `T` trials. 
"""
function profile_min_pag(n::T,trials,to::TimerOutput) where T<:Integer
    kmin = T(ceil(1.5*(n-1)))
    return profile_pag(n,kmin,to,trials)
end

"""
    profile_pag(n::T, trials, to::TimerOutput)

Profile `proportion_are_gossipable(n,k)` for all combinatorially-unique values 
of `k` with `trials` trials. 
"""
function profile_pag(n::T, trials, to::TimerOutput) where T<:Integer
    kmax = T(0.5*n^2-1.5*n+2)
    kmin = T(ceil(n*(n-1)/4))
    return profile_pag(n, kmax:-one(T):kmin, trials, to)
end

"""
    profile_pag(n::T, krange::OrdinalRange{T}, trials, to::TimerOutput)

Profile `proportion_are_gossipable(n,k)` for all values of `k` in `krange` with 
`trials` trials. 
"""
function profile_pag(n::T, krange::OrdinalRange{T}, trials, to::TimerOutput) where T<:Integer
    result = 0.0
    results = []
    for k in krange
        result = profile_pag(n,k,trials,to)
        push!(results, result)
    end
    return results
end

"""
    profile_pag(n::Integer, k::Integer, to::TimerOutput, T::Integer)

Profile `proportion_are_gossipable(n,k)` updating `to` with `T` trials. 
"""
function  profile_pag(n::Integer, k::Integer, trials, to::TimerOutput)
    result = 0.0
    for t=1:trials
        # result is deterministic, so ok its overwritten on each loop
        result = @timeit to "pag($(n),$(k))" proportion_are_gossipable(n,k)
    end
    return result
end

"""
    profile_pag(n::Integer, k::Integer, to::TimerOutput, T::Integer)

Profile `proportion_are_gossipable(n,k)` updating `to` with `T` trials. 
"""
function  profile_pag(n::Integer, k::Integer, trials)
    result = 0.0
    for t=1:trials
        # result is deterministic, so ok its overwritten on each loop
        result = @benchmark proportion_are_gossipable(n,k)
    end
    return result
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
to = TimerOutput()
benchmark() = profile_min_pag(Int8(7),3,to)
benchmark(n) = profile_min_pag(Int8(n),3,to)


"""
    store_benchmark_result(to::TimerOutput)

Converts a `TimerOutput` object into a (possibly multiple) row(s) in `benchmark_timing_table`.
"""
function store_benchmark_result(to::TimerOutput)
    columns_string = "command,nodes,edges,ncalls,avgtime,avgalloc"
    for (name,timer) in to.inner_timers
        command,inputs = split(name,'(')
        nodes,edges = split(replace(inputs,")" => ""),",")
        timer_data = timer.accumulated_data
        ncalls = timer_data.ncalls

        # Convert time to milliseconds
        avgtime = Int64(round(timer_data.time / (timer_data.ncalls * 1e6)))

        # Convert allocations to MiB (2^20 bytes)
        avgalloc = Int64(round(timer_data.allocs / (timer_data.ncalls * (2^20))))
        
        values_string = "'$command',$nodes,$edges,$ncalls,$avgtime,$avgalloc"
        insert_with_hash_and_date(benchmark_timing_table, columns_string, values_string)
    end
end


# export table to readme.
#open("Readme.md","a") do io
#  println(io,timeroutput_to_markdown(to));
#end


