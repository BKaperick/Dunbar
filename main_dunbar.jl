include("dunbar.jl")
include("store_dunbar.jl")
db = SQLite.DB("precomputed")
initialize_table("schema.txt","proportions",false) 
