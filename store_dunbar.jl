using SQLite
using DataFrames
using Dates

#existingPairs = DBInterface.execute(db, "Select nodes,edges from proportions") |> DataFrame

# Helper functions

function drop_table(name)
    query_db("drop table if exists $name;")
end

function initialize_table(schema_file_name,table_name,overwrite)
    f = open(schema_file_name)
    columns_and_types = join(readlines(f), ", ")
    if_not_exists = overwrite ? "" : "if not exists"
    if overwrite
        drop_table(table_name)
    end
    query_db("create table $if_not_exists $table_name ($columns_and_types)")
end

function query_db(query)
    return DBInterface.execute(db, query) |> DataFrame
end

function get_table()
    return query_db("select * from proportions order by nodes, edges")
end

function get_table_info(table)
    return query_db("pragma table_info($table)")
end

function add_column(table_name, column_name,sqlite_data_type)
    query_db("alter table $table_name add column $column_name $sqlite_data_type;")
end
function add_column(column_name,sqlite_data_type)
    query_db("alter table proportions add column $column_name $sqlite_data_type;")
end

function rename_table(old_name,new_name)
    query_db("alter table $old_name rename to $new_name")
end 

function delete_column(table, column)
    # Get schema string of columns, without the column to remove
    table_info = get_table_info(table)
    filtered_info_iterator = filter(r -> r.name != column, eachrow(table_info))
    
    primary_keys = map(r -> r.name, sort(filter(r -> r.pk > 0, filtered_info_iterator)))
    pk_string = "primary key ($(join(primary_keys, ", "))) on conflict replace"
    columns_and_types = map(r -> "$(r.name) $(r.type)", filtered_info_iterator)
    columns = map(r -> "$(r.name)", filtered_info_iterator)
    columns_types_string = join(columns_and_types, ", ")
    columns_string = join(columns, ", ")
    
    # create new table with the new schema
    tmp_name = "tmp$table"
    drop_table(tmp_name)
    rename_table(table, tmp_name)
    create_query = "create table if not exists $table ($columns_types_string, $pk_string)"
    query_db(create_query)
    
    # populate new table with old data
    select_query = "select $columns_string from $table"
    populate_query = "insert into $tmp_name ($columns_string) $select_query"
    query_db(populate_query)

    # Rename temporary table back to original name
    drop_table(table)
    rename_table(tmp_name, table)

    # drop temporary table
    drop_table(tmp_name)
end

function insert_pag_result(n,k,res::Float64)
    git_hash = get_current_git_hash()
    run_date = Dates.now()
    DBInterface.execute(db, "insert into proportions (nodes,edges,pag,commit_hash,run_date) values ($n,$k,$res,'$git_hash','$run_date')")
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

function get_current_git_hash()
    return read(pipeline(`git log --pretty=format:'%h' -n 1`), String)
end
