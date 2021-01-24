include("dunbar.jl")
include("store_dunbar.jl")
include("profile_dunbar.jl")
include("constants.jl")
db = SQLite.DB("precomputed")


initialize_table("schema.txt",pag_result_table,false) 
initialize_table("benchmark_schema.txt",benchmark_timing_table,false) 

proportion_are_gossipable(7,9) # make sure compiled successfully

function profile_and_precompute_pag(n, k, trials)
    to = TimerOutput()
    result = profile_pag(n, k, trials, to)
    store_benchmark_result(to)

    # Check if (n,k) result is already stored
    precomputed_res = get_precomputed(n, k)
    
    if (precomputed_res == Nothing)
        insert_pag_result(n, k, result)
    end
    
    # Flag if result has changed from a previously stored value
    @assert result == precomputed_res

    return result
end
