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
    # TODO: rename ncalls to ntrials
    columns_string = "command,nodes,edges,ncalls,avgtime,avgalloc"
    for (name,timer) in to.inner_timers
        command,inputs = split(name,'(')
        nodes,edges = split(replace(inputs,")" => ""),",")
        timer_data = timer.accumulated_data
        trials = timer_data.ncalls

        # Convert time to milliseconds
        avgtime = Int64(round(timer_data.time / (trials * 1e6)))

        # Convert allocations to MiB (2^20 bytes)
        avgalloc = Int64(round(timer_data.allocs / (trials * (2^20))))
        
        # Update an existing row if this same command has already been run with these params
        # with this code
        (trials, avgtime, avgalloc) = combine_benchmark_results_with_existing_row(command, nodes, edges, trials, avgtime, avgalloc)
        values_string = "'$command',$nodes,$edges,$trials,$avgtime,$avgalloc"

        insert_with_hash_and_date(benchmark_timing_table, columns_string, values_string)
    end
end

"""
    combine_benchmark_results_with_existing_row(command, nodes, edges, ncalls, avgtime, avgalloc)

Checks if this benchmark result has already been computed on this commit, and if so, returns 
the updated average combining these two runs so we can update the row instead of inserting a new one.
"""
function combine_benchmark_results_with_existing_row(command, nodes, edges, trials, avgtime, avgalloc)
    commithash = get_current_git_hash()
    # For now, assume there is just one
    prev_row = query_db("select ncalls, avgtime, avgalloc from $benchmark_timing_table 
             where command = '$command' and nodes = $nodes and edges = $edges and commit_hash = '$commithash'")
    if (size(prev_row)[1] == 0)
        return (ncalls, avgtime, avgalloc)
    end

    new_trials = trials + prev_row["ncalls"][1]
    new_avgtime = ((avgtime * ncalls) + (prev_row["ncalls"][1] * prev_row["avgtime"][1])) / trials
    new_avgalloc = ((avgalloc * ncalls) + (prev_row["ncalls"][1] * prev_row["avgalloc"][1])) / trials
    return (new_trials, new_avgtime, new_avgalloc)
end

# export table to readme.
#open("Readme.md","a") do io
#  println(io,timeroutput_to_markdown(to));
#end


