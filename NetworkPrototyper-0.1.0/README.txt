Title: About NetworkPrototyper
-------------------------------
NetworkPrototyper creates a the baremetal network consisting of Hyper-V guests connected to a private switch.  Hosts are assigned to either
the Server or Workstations VMGroup depending on their eventual role in the virtual network.  Apart from being in the same physical 
disk location and having the same namespace all machines are given an IP address.

The software is in a stable enough state that its' architecture will not change significantly


TODO:
----
1. Create a module of the classes and methods in NetworkPrototyper so it can be used by other components of simulator
2. Create a XML Datastore of all the objects created by the script.
3. Write documentation about VTRree class.
4. Create documentation about the Network class.
5. Test that changes to VTree.removeLeaves actually removes leaves and accurately records the number of group members for all nodes
6. Document the methods and parameters in Workstation class (it's shorter and simpler than Server and Automata classes)
7. Document the Server class' purpose, methods, and fields
8. Document the Automata class
9. Create a collection for the Network class.
