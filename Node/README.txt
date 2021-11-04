
TITLE: README
--------------

1 INTRODUCTION
---------------
The [Node] family of classes which includes: [Node], [Stack], [Queue], and [LinkedList] is simply a collection of data structures that can be used elsewhere in the application.  
Since [Node] has two pointers it is used to create the doubly linked list class [LinkedList]. [Queue] and [Stack] are derived classes of [LinkedList]. Without native support for 
generics all classes use the [psobject] instead which leads to missing collection features and 
Ideally they would all be 
abstract classes or Generics so they be customized for essential features a collection has.

1.1 Missing Collection Features
---------------------------------
A true collection has the about 8 characteristics wich are missing in the [Node] family of classes.  These are:

    1.  Search:  This must be implemented per data type (encapsulated class)
    2.  Sort: This must be implemented by its data type
    3.  Iterators:  Might have to create a separate [Iterator] class
    4.  Equality:  This can only be accurately tested by checking encapsulated data
    5.  Splitting/Joining:  The ideal option is to split or join by either location of a desired value or by nodal index.  Without implementing a search can only split join by index.  
    6.  Uniqueness: Need a hashtable of payload's contents to validate to prevent duplicate values
    7.  Blackbox Encapsulation: We should not know what data struture is used to store the data. Since all [LinkedList] classes return Node instead of [Node].Data they are not true collection

2 TODO
-------
Initially considered implementing my own Generic class to do automatic boxing/unboxing but that seems to invovle creating a collection of types with their fields or a method of lookign them up
validating a type by its name, fields, so they can be converted.  To do it efficiently seems to be very invovled and convoluted way to enable polymorphism instead will try adding a 

    1.  Add type field to the [LinkedList] class
    2.  Add field lookup method to see what fields each type has for unboxing from [psobject] to type
    3.  Use lookup method to unbox and allow [LinkedList] to use the type in its methods
    4.  Methods that return [Node] get modified to return the unboxed class.
