using SQLite
using DataFrames

db = SQLite.DB("precomputed")
existingPairs = DBInterface.execute(db, "Select nodes,edges from proportions") |> DataFrame

# Helper functions

function query_db(query)
    return DBInterface.execute(db, query) |> DataFrame
end

function get_table()
    query_db("select * from proportions order by nodes, edges")
end

function add_column(table_name, column_name,sqlite_data_type)
    query_db("alter table $table_name add column $column_name $sqlite_data_type;")
end
function add_column(column_name,sqlite_data_type)
    query_db("alter table proportions add column $column_name $sqlite_data_type;")
end

function insert_pag_result(n,k,res::Float64)

    DBInterface.execute(db, "insert into proportions (nodes,edges,pag) values ($n,$k,$res)")
end 

function get_precomputed(n,k)
    df = query_db("select pag from proportions where nodes=$n and edges=$k")
    if (size(df)[1] == 0)
        return Nothing
    end
    return df.pag[1]
end 

"""
    get_and_insert_symmetric_result(n,k)

Retrieves precomputed case or equivalent symmetric case, inserting one or the other
if one is missing.
"""
function get_and_insert_symmetric_result(n,k)
    already_stored = get_precomputed(n,k)
    k_symm = n*(n-1)/2 - k
    already_stored_symm = get_precomputed(n,k_symm)
    if (already_stored != Nothing && already_stored_symm == Nothing)
        insert_pag_result(n,k_symm,already_stored)
    elseif (already_stored == Nothing && already_stored_symm != Nothing)
        insert_pag_result(n,k,already_stored_symm)
    end
    return already_stored
end
