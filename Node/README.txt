The [Node] family of classes which includes: [Node], [Stack], [Queue], and [LinkedList] is simply a collection of data structures that can be used elsewhere in the application.  Ideally they would all be 
abstract classes or Generics so they be customized for essential features a collection has.

Search:  This must be implemented per data type (encapsulated class)
Iterators:  Might have to create a separate [Iterator] class
Equality:  This can only be accurately tested by checking encapsulated data
Splitting/Joining:  The ideal option is to split or join by either location of a desired value or by nodal index.  Without implementing a search can only split join by index.  
Uniqueness: Need a hashtable of payload's contents to validate to prevent duplicate values

