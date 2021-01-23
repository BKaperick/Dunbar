include("dunbar.jl")
include("store_dunbar.jl")
include("profile_dunbar.jl")
include("constants.jl")
db = SQLite.DB("precomputed")


initialize_table("schema.txt",pag_result_table,true) 
initialize_table("benchmark_schema.txt",benchmark_timing_table,true) 
