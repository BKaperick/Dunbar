include("dunbar.jl")
include("store_dunbar.jl")
include("profile_dunbar.jl")
include("constants.jl")
db = SQLite.DB("precomputed")


initialize_table("schema.txt",pag_result_table,false) 
initialize_table("benchmark_schema.txt",benchmark_timing_table,false) 

proportion_are_gossipable(7,9) # make sure compiled successfully

function profile_and_precompute_pag(n,k)
    
end
