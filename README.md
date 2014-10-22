d'ORModel
=========

d'ORModel is an ORM for Delphi, based on models and object fields. 
for now, it uses the "database first" approach: all objects and metadata (delphi attributes) are
generated from the database (MS SQL Server + CE, MySQL is pending).
Everything is fully typed with no hard coded strings (no FieldByName('field1')!) so you can use the
compiler to check your models and code! When you change the database, just regenerate the models and
metadata and recompile: the compiler will gives errors when you use an old renamed field, so no nasty
runtime errors :).

The models and attributes can be used for all layers and tiers:
- data layer, using CRUDs
- bo layer, with direct using data CRUDs for loading and saving
- presentation layer, using the model for a MVC implementation.

Instead of datamodules with queries and hidden design time textual sql statements and fields, everything
is done in code with objects.

## LINQ 
By using a query builder with fluent interfaces, you can create sql statements in your code which are
typesafe and checked by the compiler.

For example:  
```
  TESTCrud.NewQuery
    .Select          ([TESTCrud.Data.ID])
    .Where.FieldValue(TESTCrud.Data.Name).Equal('test');
  if TESTCrud.QuerySelectSingle then
    MessageDlg('Record is found in database!');
```

There are many more cool features, take a look at the unit tests for examples.
