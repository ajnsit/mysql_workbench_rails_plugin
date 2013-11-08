mysql_workbench_rails_plugin
============================

A rails plugin for mysql workbench (old code)

Some usage notes from my old post here (http://blog.syntaxvssemantics.com/2009/05/ruby-on-rails-helper-scripts-for-mysql.html) follow - 

Usage
=====

MySQL Workbench has an awesome feature called "Reverse Engineer" which does not behave well with Rails style databases because of the following -

  1. Table names are plural
  2. Foreign keys are singular! E.g. a foreign key to table "Products" will be called "product_id"!
  3. Primary keys are always "id", regardless of the table name.

These pecularities with the Rails db schemas make it impossible for MySQL Workbench to infer table relationships, and you have to do it by hand.

I spent a few hours creating a Lua script to automate this tedious process. Here are the steps to import a rails schema with all the relationships -

  1. Open MySQL Workbench
  2. Then run the Main script by pressing Ctrl+Shift+R and selecting rails_plugin.lua from the location where you saved it.
  3. Make sure there are no errors in the output window.
  4. Reverse engineer your DB schema to get all the tables into an ER diagram. None of the tables will be related to each other die to the problems mentioned above. We'll fix that in a minute!
  5. Select "view > advanced > GRT shell" to open the shell which will allow you to invoke functions from the script.
  6. Now the semi-hard part. You need to get an object of your schema so that you can pass it to the script. Type the following in the shell - `print(get_schema(1).name);`. If this matches your database name then great! otherwise try `print(get_schema(2).name);` then `print(get_schema(3).name);` and so on till you find the index of your schema. (Remember that Lua is NOT zero indexed like usual programming languages. This means that there is no index 0). I'll assume that the correct index is 2.
  7. Type the following in the shell - sc = get_schema(2). Where 2 is the number you got in the previous step. Now the variable sc points to the correct schema.
  8. Now the final magic step! Type` connect_all_rails_fk_relationships (sc)`; in the shell! Watch the magic happen!

Maybe someday I will convert this to a plugin with a user friendly GUI!

PS: The script also includes a Lua port of the RoR inflectors (pluralise and singularise). Maybe those are useful independent of MySQL workbench. Check them out.
