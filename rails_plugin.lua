--
-- Rails Helper Methods for Mysql Workbench
-------------------------------------------------------------------------------
--
-- These helper methods help reverse engineer a rails database
-- Written by Anupam Jain <ajnsit@gmail.com>

-- pluralise and singularise are ports of rails inflection rules
-- Actually a port of the javascript version of the inflector
--  found at http://code.google.com/p/inflection-js/
--  It was initally ported to Javascript by Ryan Schuft (ryan.schuft@gmail.com).

-- private function - returns list of uncountable words
function get_uncountable_words ()
    return {"equipment","information","rice","money","species","series","fish","sheep","moose","deer","news"};
end

-- private function - returns list of rules for singular to plural conversion
function get_singular_rules ()
    return {
        {"(m)en$","%1an"},
        {"(pe)ople$","%1rson"},
        {"(child)ren$","%1"},
        {"([ti])a$", "%1um"},
        {"((a)naly)ses$","%1sis"},
        {"((b)a)ses$","%1sis"},
        {"((d)iagno)ses$","%1sis"},
        {"((p)arenthe)ses$","%1sis"},
        {"((p)rogno)ses$","%1sis"},
        {"((s)ynop)ses$","%1sis"},
        {"((t)he)ses$","%1sis"},
        {"(hive)s$", "%1"},
        {"(tive)s$", "%1"},
        {"(curve)s$", "%1"},
        {"([lr])ves$", "%1f"},
        {"([^fo])ves$", "%1fe"},
        {"([^aeiouy])ies$", "%1y"},
        {"(qu)ies$", "%1y"},
        {"(s)eries$", "%1eries"},
        {"(m)ovies$", "%1ovie"},
        {"(x)es$", "%1"},
        {"(ch)es$", "%1"},
        {"(ss)es$", "%1"},
        {"(sh)es$", "%1"},
        {"(m)ice$", "%1ouse"},
        {"(l)ice$", "%1ouse"},
        {"(bus)es$", "%1"},
        {"(o)es$", "%1"},
        {"(shoe)s$", "%1"},
        {"(cris)es$", "%1is"},
        {"(ax)es$", "%1is"},
        {"(test)es$", "%1is"},
        {"(octop)i$", "%1us"},
        {"(vir)i$", "%1us"},
        {"(alias)es$", "%1"},
        {"(status)es$", "%1"},
        {"^(ox)en", "%1"},
        {"(vert)ices$", "%1ex"},
        {"(ind)ices$", "%1ex"},
        {"(matr)ices$", "%1ix"},
        {"(quiz)zes$", "%1"},
        {"s$", ""}
    };
end

-- private function - returns list of rules for plural to singular conversion
function get_plural_rules ()
    return {
        {"(m)an$","%1en"},
        {"(pe)rson$","%1ople"},
        {"(child)$","%1ren"},
        {"^(ox)$","%1en"},
        {"(ax)is$","%1es"},
        {"(test)is$","%1es"},
        {"(octop)us$","%1i"},
        {"(vir)us$","%1i"},
        {"(alias)$","%1es"},
        {"(status)$","%1es"},
        {"(bu)s$","%1ses"},
        {"(buffal)o$","%1oes"},
        {"(tomat)o$","%1oes"},
        {"(potat)o$","%1oes"},
        {"([ti])um$","%1a"},
        {"sis$","ses"},
        {"(?:([^f])fe)$","%1%2ves"},
        {"(([lr])f)$","%1%2ves"},
        {"(hive)$","%1s"},
        {"([^aeiouy])y$","%1ies"},
        {"(qu)y$","%1ies"},
        {"(x)$","%1es"},
        {"(ch)$","%1es"},
        {"(ss)$","%1es"},
        {"(sh)$","%1es"},
        {"(matr)ix|ex$","%1ices"},
        {"(vert)ix|ex$","%1ices"},
        {"(ind)ix|ex$","%1ices"},
        {"(m)ouse$","%1ice"},
        {"(l)ouse$","%1ice"},
        {"(quiz)$","%1zes"},
        {"s$","s"},
        {"$","s"}
    };
end

--- Singularise a given name
-- Arguments:
--   str String name to singularise
-- Returns: Singularised String
function singularise (str)
    local i, x, j, rule, uncountable_words, singular_rules, matches;
    str = string.lower(str);
    uncountable_words = get_uncountable_words();
    for i,x in ipairs(uncountable_words) do
        if x == str then
            return str;
        end
    end
    singular_rules = get_singular_rules();
    for j, rule in ipairs(singular_rules) do
        str, matches = string.gsub(str, rule[1], rule[2]);
        if matches > 0 then
            return str;
        end
    end
    return str;
end

--- Pluralise a given name
-- Arguments:
--   str String name to pluralise
-- Returns: Pluralised String
function pluralise (str)
    local i, x, j, rule, uncountable_words, plural_rules, matches;
    str = string.lower(str);
    uncountable_words = get_uncountable_words();
    for i,x in ipairs(uncountable_words) do
        if x == str then
            return str;
        end
    end
    plural_rules = get_plural_rules();
    for j, rule in ipairs(plural_rules) do
        str, matches = string.gsub(str, rule[1], rule[2]);
        if matches > 0 then
            return str;
        end
    end
    return str;
end

-- create_foreign_keys_for_table will use rails style rules to search for
-- foreign key relationships and create them if possible.
-- connect_all_rails_fk_relationships will perform the same for all tables
-- in a given schema

--- Private function: Finds columns that match the given regex in a table
-- Arguments:
--   table_object db.Table object to search in
--   column_name_regex string pattern for column names to match
-- Returns: lua table/list of objects of type db.Column
function find_table_columns_matching(table_object, column_name_regex)
	local columns = table_object.columns;
	local c = grtV.getn(columns);
	local i;
	local found_columns = {};
	for i=1, c do
		if string.match(columns[i].name, column_name_regex) ~= nil then
			table.insert(found_columns, columns[i]);
		end
	end
	return found_columns;
end


--- Adds RAILS style foreign keys to a table
-- It searches for the reference table in the schema given
-- Arguments:
--   table_object db.Table object to add foreign keys to
--   schema GRT object of type db.Schema
-- Returns: nothing
--
function create_foreign_keys_for_table (tbl, schema)
    local found_columns, found_table, tablename, new_fk, refpk;
    -- Get table columns which look like foreign keys
    found_columns = find_table_columns_matching(tbl, ".*_id$");
    -- Iterate over them
    for i,col in ipairs(found_columns) do
        -- extract table name
        tablename = pluralise(string.gsub(col.name, "_id", ""));
		print("-- column col.name.. Searching for reference table `" .. tablename .. "` --");
        -- Find the referenced tables if any
        found_table = find_table_named(schema, tablename);
        if found_table ~= nil then
    		print("-- Table `" .. tablename .. "` found! --");
            -- Get the id field of the referenced table
            refpk = find_table_column_named(found_table, "id");
            if refpk ~= nil then
        		print("-- Table `" .. tablename .. "` has primary key `id`. Creating foreign key --");
                -- Create a foreign key relation (1:n non identifying relation)
                new_fk = grtV.newObj("db.mysql.ForeignKey", {
                    name = "fk_" .. tbl.name .. "_" .. found_table.name,
                    owner = tbl,
                    columns = {col},
                    referencedTable = found_table,
                    referencedMandatory = 1,
                    referencedColumns = {refpk},
                    mandatory = 1,
                    many = 1,
                    modelOnly = 0,
                    -- deleteRule = NO ACTION,
                    -- updateRule = NO ACTION,
                    -- comment = "",
                    -- oldName = "",
                    deferability = 0
                });

                -- add to the list of foreign keys
                grtV.insert(tbl.foreignKeys, new_fk);
            end
        end
    end
end

--- Adds RAILS style foreign keys to all tables in the supplied schema
-- Arguments:
--   schema GRT object of type db.Schema
-- Returns: nothing
--
function connect_all_rails_fk_relationships (schema)
    foreach_table(schema, create_foreign_keys_for_table, schema);
end

