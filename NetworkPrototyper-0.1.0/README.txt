Title: About NetworkPrototyper
-------------------------------
NetworkPrototyper creates a the baremetal network consisting of Hyper-V guests connected to a private switch.  Hosts are assigned to either
the Server or Workstations VMGroup depending on their eventual role in the virtual network.  Apart from being in the same physical 
disk location and having the same namespace all machines are given an IP address.

The software is in a stable enough state that its' architecture will not change significantly


TODO:
----
1. Implement logic for combinations of server roles and which minimal user interface they need
2. Create a module of the classes and methods in NetworkPrototyper so it can be used by other components of simulator
3. Create a XML Datastore of all the objects created by the script.
4. Write documentation about VTRree class.
5. Create documentation about the Network class.
6. Test that changes to VTree.removeLeaves actually removes leaves and accurately records the number of group members for all nodes
7. Document the methods and parameters in Workstation class (it's shorter and simpler than Server and Automata classes)
8. Document the Server class' purpose, methods, and fields
9. Document the Automata class
10. Create a collection for the Network class. 
