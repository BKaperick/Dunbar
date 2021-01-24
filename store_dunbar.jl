using SQLite
using DataFrames
using Dates
using TimerOutputs

function drop_table(name)
    query_db("drop table if exists $name;")
end

"""
    initialize_table(schema_file_name,table_name,overwrite)

Create table based on a schema file, which consists of a line for each column and its type,
and then at the end, key constraints.  Choose to `overwrite` a previous table with this name or not.
"""
function initialize_table(schema_file_name,table_name,overwrite)
    f = open(schema_file_name)
    columns_and_types = join(readlines(f), ", ")
    if_not_exists = overwrite ? "" : "if not exists"
    if overwrite
        drop_table(table_name)
    end
    query_db("create table $if_not_exists $table_name ($columns_and_types)")
end

function query_db(query, mode=global_sql_mode)
    if mode == :verbose
        print("$query\n")
    end
    return DBInterface.execute(db, query) |> DataFrame
end

function get_table(name)
    return query_db("select * from $name order by nodes, edges")
end

function get_table_info(table)
    return query_db("pragma table_info($table)")
end

function add_column(table_name, column_name,sqlite_data_type)
    query_db("alter table $table_name add column $column_name $sqlite_data_type;")
end

function rename_table(old_name,new_name)
    query_db("alter table $old_name rename to $new_name")
end 

"""
    delete_column(table, column)

Delete `column` from `table`.  There is no direct SQLite command for this, so we create a
new schema without `column` and copy all the data to it.  Inefficient, but it works for our
scale.
"""
function delete_column(table, column)
    # Get schema string of columns, without the column to remove
    table_info = get_table_info(table)
    filtered_info_iterator = filter(r -> r.name != column, eachrow(table_info))
    
    # Extract and format column, type and key information
    primary_keys = map(r -> r.name, sort(filter(r -> r.pk > 0, filtered_info_iterator)))
    pk_string = "primary key ($(join(primary_keys, ", "))) on conflict replace"
    columns_and_types = map(r -> "$(r.name) $(r.type)", filtered_info_iterator)
    columns = map(r -> "$(r.name)", filtered_info_iterator)
    columns_types_string = join(columns_and_types, ", ")
    columns_string = join(columns, ", ")
    
    # Create new table with the new schema
    tmp_name = "tmp$table"
    drop_table(tmp_name)
    rename_table(table, tmp_name)
    create_query = "create table if not exists $table ($columns_types_string, $pk_string)"
    query_db(create_query)
    
    # Populate new table with old data
    select_query = "select $columns_string from $table"
    populate_query = "insert into $tmp_name ($columns_string) $select_query"
    query_db(populate_query)

    # Rename temporary table back to original name and drop the temporary table
    drop_table(table)
    rename_table(tmp_name, table)
    drop_table(tmp_name)
end

function insert_pag_result(n,k,res::Float64)
    k_symm = n*(n-1)/2 - k
    columns_string = "nodes,edges,pag"
    values_string = "$n,$k,$res"
    values_string_symm = "$n,$k_symm,$res"
    insert_with_hash_and_date(pag_result_table, columns_string, values_string)
    insert_with_hash_and_date(pag_result_table, columns_string, values_string_symm)
end 

"""
    insert_with_hash_and_date(table, columns_string, values_string)

All our db tables have a `commit_hash` column and a `run_date` column to track the code state
when the row was updated.  This helper function computes and concatenates these to a partial
insert command.
"""
function insert_with_hash_and_date(table, columns_string, values_string)
    commit_hash = get_current_git_hash()
    run_date = Dates.now()
    query_db("insert into $table ($columns_string,commit_hash,run_date) values ($values_string,'$commit_hash','$run_date')")
end

"""
    get_precomputed_pag_result(n,k)

Returns the precomputed value from a former run of proportion_are_gossipable(n,k) stored
in the db.
"""
function get_precomputed_pag_result(n,k)
    df = query_db("select pag from $pag_result_table where nodes=$n and edges=$k")
    if (size(df)[1] == 0)
        return Nothing
    end
    return df.pag[1]
end 

"""
    get_current_git_hash()

Get the first 7 characters of the latest commit hash.  This, combined with `run_date`
are stored in all the tables as a record of the code state at the time of the row insertion
"""
function get_current_git_hash()
    return read(pipeline(`git log --pretty=format:'%h' -n 1`), String)
end
