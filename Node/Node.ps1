
Set-PSDebug -Strict
Set-StrictMode -Version Latest

### ------------------> Global Variables and constants <------------------ 
[String []] $global:LETTERS  = @("A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M", "N", "P", "Q", "R", "Z")

[int] $global:addition_count = 0
[int] $global:removal_count = 0
[int] $global:item_count = 0


### ------------------> Enums <------------------
enum TerminatorLocation {
    Head = 1; Tail = 2
}

enum Orientation {
    Left = 1; Right = 2
}

enum Direction {
    Forwards = 1; Backwards = 2
}
[Direction] $global:current_direction = [Direction]::new()


### @@@@@@@@@@@------> Script Functions <------@@@@@@@@@@@@
function Get-RandomWord () {

    [string] $word = [string]::Empty
    [string] $path = "C:\Dropbox\scripts\datasets\"
    
    [string []] $files = @("asteroids", "biology", "unique_aeneid_words", "classical", "king-james-bible-words")
    
    $path += ($files | Get-Random) + ".txt"
    $word = Get-Content $path | Get-Random

    return $word

} # <--- close Get-RandomWord


#############################------- Define the Node CLASS -------#############################

class Node {
    <#
        .SYNOPSIS
            Node class is the atomic element used to build linked list data structures

        .DESCRIPTION
            The payload of a [Node] can be of any type so it can be used with any type.
            Ideally the payload would be a generic but Powershell does not natively support
            them so [psobject] is used instead.  This might complicate the implementation of
            linked lists.  [Node] is a separate class from [LinkedList] because PowerShell does
            not support internal (nested) classes.

        .PARAMETER ID
            [string] An optional identifier
            
        .PARAMETER Data
            [psobject] Payload of the node. Cannot be null

        .PARAMETER Next
            [Node] Pointer to the next node.  Default value is null

        .PARAMETER Previous
            [Node] Pointer to previous node.  Default value is null
                    
        .FUNCTIONALITY
            [Node] class contains static methods: 
            - random() - creates a random Node with a random string as its' payload
            - id() - generates a random ID
	#>

    #------------------ Properties  -------------------#
    [string] $ID

    [ValidateNotNullOrEmpty()]
    [psobject] $Data

    [Node] $Next
    [Node] $Previous


    #------------------ Constructors  -------------------#
    Node () {} # <--- close Node

    Node ([psobject] $obj) {
        $this.Next = [Node]::new()
        $this.Previous = [Node]::new()

        $this.Data = $obj
        $this.ID = [Node]::id()

        $this.Next = $null
        $this.Previous = $null

    } # <--- close Node


    #------------------ Getters  -------------------# 

    #------------------ Setters  -------------------# 
 
    #------------------ Methods -------------------#

    #------------------ Helper Functions -------------------# 

    #------------------ Static Methods -------------------#
    hidden static [Node] random () {
        <#
            .SYNOPSIS
                Creates a single Node with a string as its' payload.

            .DESCRIPTION

            .FUNCTIONALITY
                The node's Next and Previous pointers are set to null
        
            .INPUTS
        
            .OUTPUTS
                Node
        #>

        return  [Node]::new((Get-RandomWord))

    } # <--- close randonm


    hidden static [string] id () {
        <#
            .SYNOPSIS
                Randomly generates an id for a Node.

            .DESCRIPTION
                The id is a string with "N_" as its' prefix, "_N" as its suffix, and the series of letters and numbers 
                separated by dashes. Uniqueness is not guaranteed.

            .FUNCTIONALITY

            .INPUTS

            .OUTPUTS
                String
        #>

        [string] $sequence = "N_"
        [int] $characterCount = 5

        for ([int] $index = 0; $index -lt $characterCount; $index++) {
            $sequence += ($global:LETTERS | Get-Random)
        }
        $sequence += "-"

        for ([int] $index = 0; $index -lt $characterCount; $index++) {
            $sequence += Get-Random -Minimum 0 -Maximum 10
        } 

        $sequence += "_N"
        return $sequence

    } # <--- close randomID


} # <--- end class Node



#############################------- Define the LinkedList CLASS -------#############################

class LinkedList {
    <#
        .SYNOPSIS
            LinkedList class implements a doubly linked list with the items being referenced by their index with the first

        .DESCRIPTION
            [LinkedList] is a doubly linked list with a pointers for both the pointers for both the tail and head. Since 
            PowerShell does not natively support generics [LinkedList] may contain items of differing types.  Whenever the 
            class is used for as a collection boxing and unboxing and type checking must be implemented.

        .PARAMETER ID
            [string] An optional identifier
            
        .PARAMETER HeadPointer
            [Node] Points to the first item in the linked list.  Its' data contains a flag indicating this is the header of 
            the linked list

        .PARAMETER TailPointer
            [Node] Points to the last item in the linked list.  Its' data contains a flag indicating this is the tail of the 
            linked list

        .PARAMETER Length
            [int] The number of items in the linked list.  HeadPointer and TailPointer are not included in determining the 
            length of the linked list

        .PARAMETER LeftCursor
            [Node] Stores the location of the most recent traversal from between the middle and TailPointer of the linked list
            Can be used to speed up traversals of long linked lists.

        .PARAMETER LeftCursor
            [Node] Stores the location of the most recent traversal from between HeadPointer and the middle of the linked list
            Can be used to speed up traversals of long linked lists.
                    
        .FUNCTIONALITY
            Since PowerShell does not support generics [LinkedList] can contain items of differing data types it does not contain 
            methods for searching by content or checking for equality of individual list elements or two lists. Traditionally methods 
            in a coolection return the data but with the lack of generic support the nodes are returned so that Type specific 
            implementations can return the data only 
	#>

    #------------------ Properties  -------------------#
    [string] $ID
    [Node] $HeadPointer
    [Node] $TailPointer
    [int] $Length

    hidden [Node] $LeftCursor
    hidden [Node] $RightCursor


    #------------------ Constructors  -------------------#
    LinkedList () {
        <#
            .SYNOPSIS
                Default constructor which sets the head and tail to point
                to each other.

            .Description
                Sets all fields to null or zero except head and tail pointers which are
                not only configured to point to each other but are set with flags
        #>

        $this.Length = 0
        $this.ID = [string]::Empty
        $this.HeadPointer = [Node]::new("HEAD_POINTER_____")
        $this.TailPointer = [Node]::new("_____TAIL_POINTER")

        $this.HeadPointer.Next = $this.TailPointer
        $this.TailPointer.Previous = $this.HeadPointer

        $this.LeftCursor = [Node]::new()
        $this.RightCursor = [Node]::new()

    } # <--- close LinkedList

    LinkedList ([psobject] $obj) { $this.init($null, $obj) } 

    LinkedList ([string] $name, [psobject] $obj) { $this.init($name, $obj) } 

    hidden init ([string] $name, [psobject] $obj) {
        <#
            .SYNOPSIS
                init is used to chain the differing constructors and provide a unified configuration of 
                all [LinkedList] objects that are not null

            .DESCRIPTION

            .PARAMETER name
                [string] An optional identifier. If the name is null 
                
            .PARAMETER obj
                [psobject] The data to be added to the linked list.  Cannot be null 
                        
            .FUNCTIONALITY
                Creates a node with $obj as its' payload and has both head and tail point to the node. 
                Increments $Length field and sets the values of $HeadPointer/TailPointer Data fields 
                with flags that can be used for error checking.

            .INPUTS
                System.String
                PSObject
        #>

        if ($null -eq $name -or $name -eq [string]::Empty) {
            $this.ID = [LinkedList]::id()
        }
        else {
            $this.ID = $name
        }

        $this.HeadPointer = [Node]::new($this.ID + "_HEAD_POINTER_____")
        $this.TailPointer = [Node]::new("_____TAIL_POINTER_" + $this.ID)

        [Node] $node = [Node]::new($obj)

        $this.HeadPointer.Next = $node  
        $this.TailPointer.Previous = $node

        $node.Previous = $this.HeadPointer
        $node.Next = $this.TailPointer

        $this.Length = 1

    } # <--- close init


    #------------------ Getters  -------------------# 
    [Node] first () {
       <#
            .SYNOPSIS
                Returns the first node in the linked list.  If [LinkedList] is empty returns null

            .DESCRIPTION

            .PARAMETER
                        
            .FUNCTIONALITY
 
            .INPUTS

            .OUTPUTS
                Node
        #>

        [Node] $node = [Node]::new()

        if ($this.Length -eq 0) {
            $node = $null
        } 
        else {
            $node = $this.HeadPointer.Next
        }

        return $node

    } # <--- close first


    [Node] last () {
       <#
            .SYNOPSIS
                Returns the last node in the linked list.  If [LinkedList] is empty returns null

            .DESCRIPTION

            .PARAMETER
                        
            .FUNCTIONALITY
 
            .INPUTS

            .OUTPUTS
                Node
        #>

        [Node] $node = [Node]::new()

        if ($this.Length -eq 0) {
            $node = $null
        }
        else {
            $node = $this.TailPointer.Previous
        }

        return $node

    } # <--- close last


    #------------------ Setters  -------------------# 
    [void] add ([int] $location, [psobject] $obj) {
       <#
            .SYNOPSIS
                Adds  an item to the LinkedList by invoking

            .DESCRIPTION
                Adds a psobject to the linked list at the specified location. Any item at the index which matches
                the location gets moved to $index + 1

            .PARAMETER location
                [int] The location corresponds to the index of the node.  For an empty linkedLit the location must be zero.  
                If location is 0 then the node is created right after HeadPointer. When the location corresponds to the length 
                of the linked list then it will be just before TailPointer. location range is [0, $Length]

            .PARAMETER obj
                [psobject] A not-null object 
                        
            .FUNCTIONALITY
 
            .INPUTS
                Int
                PsObject

            .OUTPUTS
        #>

        $this.add($location, [Node]::new($obj))

    } # <--- close add


    [void] add ([int] $location, [Node] $node) {
       <#
            .SYNOPSIS
                Adds a node to LinkedList at $location

            .DESCRIPTION
                Adds a new node to the linked list at the specified location. Any item at the index which matches
                the location gets moved to $index + 1

            .PARAMETER location
                [int] The location corresponds to the index of the node.  For an empty linkedLit the location must be zero.  
                If location is 0 then the node is created right after HeadPointer. When the location corresponds to the length 
                of the linked list then it will be just before TailPointer. location range is [0, $Length]

            .PARAMETER obj
                [psobject] A not-null object 
                        
            .FUNCTIONALITY
 
            .INPUTS
                Int
                PsObject

            .OUTPUTS
        #>

        #Write-Host ">>> Entering [LinkedList].add() >>> at location" $($location) "of" $($this.Length) "linked list"

        [int] $maxPosition = $this.Length

        #if ($this.Length -eq 0) { $maxPosition = 0 }

        if ($location -lt 0 -or $location -gt $maxPosition) {
            throw "LinkedList add operation failed: destination " + $($location) + "  threw out of bounds exception on LinkedList of size " + $($this.Length)
            exit(13313)
        }

        [Node] $cursor = [Node]::new()
        [Node] $precedent = [Node]::new()

        $cursor = $this.traverse([Direction]::Forwards, $location)
        $precedent = $cursor.Previous

        #Write-Host "`t`t`t Prior to Adding" $node.Data " at location:" $location "[ " $precedent.Data "<--(cursor:`b" $cursor.Data ")-->"# $consequent.data "]"

        $node.Previous = $precedent
        $precedent.Next = $node

        $node.Next = $cursor
        $cursor.Previous = $node
        #Write-Host "`t`t`t Affer Adding" $node.Data " at location:" $location "[ " $precedent.Data "<--(node Data:" $node.Data ")-->" $cursor.data "]"

        $this.Length++
        #Write-Host "<<< EXITING [LinkedList].add() <<<"

    } # <--- close add


    [void] insert ([int] $location, [LinkedList] $list) {
           <#
            .SYNOPSIS
                Adds all data nodes from list into the invoking linked list starting at location 

            .DESCRIPTION
                Grows the linked list by inserting all data nodes from list into invoking linked list.  NOdes are added
                contigously from first to last node. 

            .PARAMETER location
                [int] The location corresponds to the index of the node.  For an empty linkedLit the location must be zero.  
                If location is 0 then the node is created right after HeadPointer. When the location corresponds to the length 
                of the linked list then it will be just before TailPointer. location range is [0, $Length].

            .PARAMETER list
                [LinkedList] The list whose nodes will be added to the invoking linked list
                        
            .FUNCTIONALITY
                Does not make any changes to $list parameter passed to the method.
                Does not assure the types in $list parameter match the ones in invoking linked list
                Length field increases by $list.Length
 
            .INPUTS
                Int
                LinkedList

            .OUTPUTS
        #>

        #Write-Host "`t`t >>> ENTERED [LinkedList]::insert >>>"

        [int] $maxPosition = $this.Length

        if ($location -lt 0 -or $location -gt $maxPosition) {
            throw "LinkedList insert operation failed: location " + $($location) + "  threw out of bounds exception on LinkedList of size " + $($this.Length)
            exit(3242)
        }

        [Node] $cursor = [Node]::new()

        [Node] $precedent = [Node]::new()
        [NOde] $consequent = [Node]::new()

        [Node] $listPrecedent = [Node]::new()
        [Node] $listConsequent = [Node]::new()

        $cursor = $this.traverse([Direction]::Forwards, $location)

        $precedent = $cursor
        $consequent = $cursor.Next

        #Write-Host "`t`t`t location:" $location "[ " $precedent.Data "<--(cursor Data:" $cursor.Data ")-->" $consequent.data "]"

        $listPrecedent = $list.HeadPointer.Next
        $listConsequent = $list.TailPointer.Previous

        $precedent.Next = $listPrecedent
        $listPrecedent.Previous = $cursor
        #Write-Host "`t`t`t`t precedent.Next:" $precedent.Next.Data "listPrecedent.Previous:" $listPrecedent.Previous.Data
        #Write-Host "`t`t`t`t listPrecedent.Previous:" $listPrecedent.Previous.Data "precedent.Next:" $precedent.Next.Data "`n"

        $consequent.Previous = $listConsequent
        $listConsequent.Next = $consequent
        #Write-Host "`t`t`t`t consequent.Previous:" $consequent.Previous.Data "listConsequent.Next:" $listConsequent.Next.Data
        #Write-Host "`t`t`t`t listConsequent.Next:" $listConsequent.Next.Data "consequent.Previous:" $consequent.Previous.Data  "`n"

        $this.Length += $list.Length
        #Write-Host "`t`t <<< EXITING [LinkedList]::insert <<<"

    } # <-- close insert


    [void] join ([TerminatorLocation] $terminator, [LinkedList] $list) {
        <#
            .SYNOPSIS
                Adds all data nodes from list parameter to either the begininning or end of invoking linked list 

            .DESCRIPTION

            .PARAMETER terminator
                [TerminatorLocation] enum which indicates if list's data nodes will be either added to the tail 
                or head of current linked list.

            .PARAMETER list
                [LinkedList] The list whose nodes will be added to the invoking linked list
                        
            .FUNCTIONALITY
                Does not make any changes to $list parameter passed to the method.
                Does not assure the types in $list parameter match the ones in invoking linked list
                Length field increases by $list.Length
 
            .INPUTS
                TerminatorLocation 
                LinkedList

            .OUTPUTS
        #>

        #Write-Host "`t`t >>> ENTERED [LinkedList]::join AT" $terminator.ToString().ToUpper()  ">>>"

        if ($list.Length -eq 0 -or $null -eq $list) {
            return
        }

        [Node] $marker = [Node]::new()
        [Node] $firstNode = [Node]::new()
        [Node] $lastNode = [Node]::new()

        #Write-Host "`t`t`t temp List State" $temp.ToString()

        $firstNode = $list.HeadPointer.Next
        $lastNode = $list.TailPointer.Previous

        #Write-Host "`t`t`t temp_first_node_data:" $firstNode.Data "temp_last_node_data:" $lastNode.Data       

        switch ($terminator.ToString()) {
            "Head" { 
                $marker = $this.HeadPointer.Next
                #Write-Host "`t`t`t`t`told first nodes"  $marker.Previous.Data "<--(" $marker.Data ")-->" $marker.Next.Data

                $marker.Previous = $lastNode
                $lastNode.Next = $marker
                #Write-Host "`t`t`t`t`tcurrent marker node state"  $marker.Previous.Data "<--(" $marker.Data ")-->" $marker.Next.Data

                $this.HeadPointer.Next = $firstNode
                $firstNode.Previous = $this.HeadPointer
                #Write-Host "`t`t`t`t`tcurrent first nodes"  $this.HeadPointer.Data "<--(" $this.HeadPointer.Next.Data ")-->" $this.HeadPointer.Next.Next.Data              
            }
            "Tail" { 
                $marker = $this.TailPointer.Previous
                #Write-Host "`t`t`t`t`told last nodes"  $marker.Previous.Data "<--(" $marker.Data ")-->" $marker.Next.Data

                $marker.Next = $firstNode
                $firstNode.Previous = $marker
                #Write-Host "`t`t`t`t`tcurrent marker node state"  $marker.Previous.Data "<--(" $marker.Data ")-->" $marker.Next.Data

                $this.TailPointer.Previous = $lastNode
                $lastNode.Next = $this.TailPointer
                #Write-Host "`t`t`t`t`tcurrent first nodes" $this.TailPointer.Previous.Previous.Data "<--(" $this.TailPointer.Previous.Data ")-->" $this.TailPointer.Data     
            }
        }

        $this.Length += $list.Length

        #Write-Host "`t`t`t final temp state:" $list.toString()
        #Write-Host "`t`t`t this current state:" $this.toString()

        #Write-Host "`t`t <<< EXITING [LinkedList]::join <<<"

    } # <--- close join


    [Node] removeNode ([int] $location) {
        <#
            .SYNOPSIS
                Removes node at specified location in the linked list. 

            .DESCRIPTION
                Removes the node at the specific index and decreases the Length field parameter by one.  

            .PARAMETER location
                [int] The location corresponds to the index of the node.  For an empty linked list the location must be zero.  
                If location is 0 then the node is created right after HeadPointer. When the location corresponds to the length 
                of the linked list then it will be just before TailPointer. location range is [0, $Length].
                        
            .FUNCTIONALITY
                Returns the node at the location instead of the data.  at that location.  
                Length field decreases by one.
 
            .INPUTS
                int

            .OUTPUTS
                Node
        #>

        if ($this.Length -eq 0) {
            throw "LinkedList removeNode operation failed: empthy LinkedList expception thrown"
        }

        [int] $maxPosition = $this.Length

        #Write-Host "`t >>> ENTERED [LinkedList].removeNode() >>> at location" $($location) "of" $($this.Length) "sized linked list"

        if ($location -lt 0 -or $location -gt $maxPosition) {
            throw "LinkedList removeNode operation failed: location " + $($location) + " threw out of bounds exception on LinkedList of size " + $($this.Length)
            exit(13313)
        }

        [Node] $cursor = [Node]::new()
        [Node] $precedent = [Node]::new()
        [Node] $consequent = [Node]::new()

        [Direction] $direction = [Direction]::Forwards

        if ($this.Length -gt 0 -and $location -eq $this.Length) {
            $direction = [Direction]::Backwards
        }

        #Write-Host "`t`t traverse direction:" $direction.ToString()

        $cursor =  $this.traverse($direction, $location)
        #Write-Host "`t`t cursor location data:" $cursor.Previous.Data "<--(`b" $cursor.Data "`b)-->" $cursor.Next 

        $consequent = $cursor.Next
        $precedent = $cursor.Previous

        $precedent.Next = $consequent
        $consequent.Previous = $precedent

        #Write-Host "`t`t State after cursor removal:"  $precedent.Data "<==>" $consequent.Data 

        $cursor.Next = $null
        $cursor.Previous = $null

        $this.Length--
        #Write-Host "`t <<< EXITING [LinkedList]::removeNode <<<"

        return $cursor

    } # <--- close removeNode


    [LinkedList] cut ([int] $start, [int] $end) {
        <#
            .SYNOPSIS
                Removes all nodes from start to end locations inclusive and puts them in a new linked list.  

            .DESCRIPTION
                There is no guarantee the data in the nodes are of the same type. There is no guarntee the nodes
                have been sorted by their content.  They are placed in the new linked list in ascending order of 
                their locations  

            .PARAMETER start
                [int] The location to start the cut.  Cannot be larger than end location

            .PARAMETER end
                [int] The location to end the cut.  Must not be at smaller than end location
                        
            .FUNCTIONALITY
                Creates a new linked list of length [end - start + 1]
                Sets decreases invoking list length by [end - start]
 
            .INPUTS
                int
                int

            .OUTPUTS
                LinkedList
        #>

        if ($this.Length -eq 0) {
            throw "LinkedList cut operation failed: empthy LinkedList expception thrown"
        }

        [int] $maxPosition = $this.Length

        if ($start -gt $end) {
            throw "LinkedList cut operation failed: start location " + ($start) + " greater than end location " + $($end)
            exit(1101)
        }

        if ($start -lt 0 -or $start -gt $maxPosition) {
            throw "LinkedList cut operation failed: start location " + $($start)+ "  threw out of bounds exception on LinkedList of size " + $($this.Length)
            exit(13313)
        }

        if ($end -lt 0 -or $end -gt $maxPosition) {
            throw "LinkedList cut operation failed: end location " + $($end) + "  threw out of bounds exception on LinkedList of size " + $($this.Length)
            exit(13313)
        }

        [LinkedList] $child = [LinkedList]::new()

        [Node] $precedent = [Node]::new()
        [Node] $consequent = [Node]::new()

        [Node] $firstChildNode = [Node]::new()
        [Node] $lastChildNode = [Node]::new()

        $firstChildNode = $this.traverse([Direction]::Forwards, $start)
        $lastChildNode = $this.traverse([Direction]::Forwards, $end) 

        $precedent = $firstChildNode.Previous
        $consequent = $lastChildNode.Next

        $child.HeadPointer.Next = $firstChildNode
        $firstChildNode.Previous = $child.HeadPointer

        $child.TailPointer.Previous = $lastChildNode
        $lastChildNode.Next = $child.TailPointer

        $precedent.Next = $consequent
        $consequent.Previous = $precedent

        $this.Length -= ($end - $start) + 1
        $child.Length = ($end - $start) + 1

        $child.ID = [LinkedList]::id()

        return $child

    } # <--- close cut


    [LinkedList] split([TerminatorLocation] $terminator, [int] $location) {
        <#
            .SYNOPSIS
                Removes all nodes between the location and the designated head or tail pointer.  Node at location 
                is included for removal.  

            .DESCRIPTION
                If the terminator indicates HeadPointer all nodes between first to location will be put in a new 
                linked list in ascending order of their location index.  If the terminator indicates TailPointer
                then nodes from location to last are put in the new linked list 

            .PARAMETER terminator
                [TermintorLocation] enum

            .PARAMETER location
                [int] The location corresponds to the index of the node.  For an empty linked list the location must 
                be zero.  If location is 0 then the node is created right after HeadPointer. When the location corresponds 
                to the length of the linked list then it will be just before TailPointer. location range is [0, $Length].
                        
            .FUNCTIONALITY
                Creates a new linked list of length location
                Decreases the number of nodes from invoking list length by location
 
            .INPUTS
                [TermintorLocation] enum
                int

            .OUTPUTS
                LinkedList
        #>

        if ($this.Length -eq 0) {
            throw "LinkedList split operation failed: empthy LinkedList expception thrown"
        }

        [int] $maxPosition = $this.Length

        if ($location -lt 0 -or $location -gt $maxPosition) {
            throw "LinkedList split operation failed: location " + $($location) + "  threw out of bounds exception on LinkedList of size " + $($this.Length)
            exit(13313)
        }

        [LinkedList] $child = [LinkedList]::new()

        [Node] $cursor = [Node]::new()

        [Node] $firstChildNode = [Node]::new()
        [Node] $lastChildNode = [Node]::new()

        $cursor = $this.traverse([Direction]::Forwards, $location)

        switch ($terminator.ToString()) {
            "Head" {
                [Node] $leftMost = $cursor.Next

                $firstChildNode= $this.HeadPointer.Next
                $lastChildNode = $cursor

                $child.HeadPointer.Next = $firstChildNode
                $firstChildNode.Previous = $child.HeadPointer

                $child.TailPointer.Previous = $lastChildNode
                $lastChildNode.Next = $child.TailPointer

                $child.Length = $location + 1

                $this.HeadPointer.Next = $leftMost
                $leftMost.Previous = $this.HeadPointer
                $this.Length -= ($location + 1)
            }
            "Tail" {
                [Node] $rightMost = $cursor.Previous

                $firstChildNode= $cursor
                $lastChildNode = $this.TailPointer.Previous

                $child.HeadPointer.Next = $firstChildNode
                $firstChildNode.Previous = $child.HeadPointer

                $child.TailPointer.Previous = $lastChildNode
                $lastChildNode.Next = $child.TailPointer

                $child.Length = $this.Length - $location


                $this.TailPointer.Previous = $rightMost
                $rightMost.Next = $this.TailPointer
                $this.Length = $location
            }
        }

        $child.ID = [LinkedList]::id()
        return $child

    } # <--- close split


    #------------------ Methods -------------------#
    [bool] isEmpty () {

        [bool] $empty = $false
        [bool] $zeroItems = $false
        [bool] $noDataPointers = $false

        $noDataPointers = $this.nullPointing()

        if ($this.Length -eq 0) {
            $zeroItems = $true
        }

        if ($zeroItems -ne $noDataPointers) {
            throw "Inconsistent results between nullPointng and LinkedList length tests.  Cannot determine emptiness of LinkedList"
            exit(12)
        }

        $empty = $zeroItems
        return $empty

    } # <--- close isEmpty


    [LinkedList] copy () {
        <#
            .SYNOPSIS
                Makes a deep copy of all the data into a new linked list   

            .DESCRIPTION
                All data is copied from data nodes in order of the location into a new linked list
                        
            .FUNCTIONALITY
                original linked list is left unchanged copy has duplicate information and length as the invoking linked list
 
            .INPUTS
                None

            .OUTPUTS
                LinkedList
        #>

        if ($this.Length -eq 0) {
            throw "LinkedList copy operation failed: empthy LinkedList expception thrown"
        }

        [LinkedList] $list = [LinkedList]::new()
        [Node] $cursor = [Node]::new()

        $cursor = $this.TailPointer.Previous

        while ($cursor.Data.ToString() -ne $this.HeadPointer.Data) {
            $list.add(0, $cursor.Data)            
            $cursor = $cursor.Previous
        }

        $list.ID = [LinkedList]::id()
        return $list

    } # <--- close copy


    hidden [string] toString () {
         <#
            .SYNOPSIS
                Converts the linked fields and it's data to a string  

            .DESCRIPTION
                For readability; if the LinkedList.Length > 20 only the first and last nodes are printed with ellipses for
                the remainder. Assumes the Data field of each node can be converted to a string. This method is for internal 
                testing and should be overriden by any child classes.
                        
            .FUNCTIONALITY
                Output might not be displayed correctly if the Node.Data does not have its' own toString method.
 
            .INPUTS
                None

            .OUTPUTS
                System.String
        #>

        [Node] $cursor = [Node]::new() 
        [string] $text = "LinkedList ID: " + $this.ID + ", Length: " + $($this.Length) + ": <-" 
        
        $cursor = $this.HeadPointer.Next

        if ($this.Length -ge 0 -and $this.Length -lt 20) {

            while ($null -ne $cursor.Next) {
                $text += "(" + $cursor.Data.ToString() + ")<==>"  
                $cursor = $cursor.Next  
            }
        }
        else {
            $text += "(" + $this.HeadPointer.Next.Data.ToString() + ")<==>" + "...<==>(" + $this.TailPointer.Previous.Data.ToString() + ")"       
        }

        $text = $text.TrimEnd("<==>")
        $text += "->"

        return $text

    } # <--- close toString


    #------------------ Helper Functions -------------------# 
    hidden [int] getMiddle () {

        [int] $middle = 0

        if ($this.Length % 2 -eq 1) {
            $middle = ($this.Length / 2) + 1
        }
        else {
            $middle = $this.Length / 2
        }

        return $middle

    } # <--- close getMiddle

    hidden [Direction] directionHandler ([int] $location) {

        if ($this.Length -eq 0) { return [Direction]::Head }

        [Direction] $direction = [Direction]::Head

        [int] $threshold = 0
        [int] $middle = $this.getMiddle()
 
        if ($location -eq 0) {
            $direction = [Direction]::Head
        }

        if ($location -eq $this.Length) {
            $direction = [Direction]::Tail
        }

        return $direction

    } # <--- close directionHandler


    hidden [bool] nullPointing () {

        [bool] $result = $false
        [bool] $previousNull = $false
        [bool] $nextNull = $false

        if ($null -eq $this.HeadPointer.Next.Next) {
            $nextNull = $true
        }

        if ($null -eq $this.TailPointer.Previous.Previous) {
            $previousNull = $true
        }

        if ($nextNull -ne $previousNull) {
            throw "Inconsistent Header/Tail null pointer results.  One indicates empy LinkedList while the other does not"
            exit(454)
        }
        else {
            $result = $nextNull
        }

        return $result

    } # <--- close nullPointing


    hidden [Node] traverse ([Direction] $direction, [int] $destination) {
         <#
            .SYNOPSIS
                Travels to the destination index and returns the node

            .DESCRIPTION
                This is a wrapper method which invokes either the forward or backwards helper methods depending on the
                value of the direction paramater

            .PARAMETER direction
                [Direction] enum which indicates wether to start the traverse forwards from HeadPointer or backwards from 
                TailPointer
                
            .PARAMETER destination
                [int] The location corresponds to the index of the node.  For an empty linked list the location must be zero.  
                If location is 0 then the node is created right after HeadPointer. When the location corresponds to the length 
                of the linked list then it will be just before TailPointer. location range is [0, $Length].
                        
            .FUNCTIONALITY
                Does not make any changes to the linked list.  Does not directly travel to the location by calling eithers
                its' forwards or backawards helper methods.

 
            .INPUTS
                [Direction] enum
                int

            .OUTPUTS
                Node
        #>

        [int] $maxPosition = $this.Length

        if ($this.Length -eq 0) { $maxPosition = 0 }

        if ($destination -lt 0 -or $destination -gt $maxPosition) {
            #$this.size()
            throw "LinkedList traverse operation failed: destination " + $($destination) + "  threw out of bounds exception on LinkedList of size " + $($this.Length)
            exit(3242)
        }

        [Node] $node = [Node]::new()

        switch ($direction.ToString()) {
            "Forwards" { $node = $this.forwards($destination) }
            "Backwards" { $node = $this.backwards($destination) }
        }

        return $node

    } # <--- close traverse


    hidden [Node] forwards ([int] $destination) {
         <#
            .SYNOPSIS
                Travels from the HeadPointer to destination

            .DESCRIPTION
                
            .PARAMETER destination
                [int] The location corresponds to the index of the node.  For an empty linked list the location must be zero.  
                If location is 0 then the node is created right after HeadPointer. When the location corresponds to the length 
                of the linked list then it will be just before TailPointer. location range is [0, $Length].
                        
            .FUNCTIONALITY
                Does not make any changes to the linked list.
 
            .INPUTS
                int

            .OUTPUTS
                Node
        #>

        [int] $counter = 0

        [Node] $cursor = [Node]::new()

        $cursor = $this.HeadPointer.Next

        while ($counter -lt $destination) {
            $cursor = $cursor.Next
            $counter++
        }

        return $cursor

    } # <--- close forwards


    hidden [Node] backwards ([int] $destination) {
         <#
            .SYNOPSIS
                Travels from the TailPointer to destination

            .DESCRIPTION
                
            .PARAMETER destination
                [int] The location corresponds to the index of the node.  For an empty linked list the location must be zero.  
                If location is 0 then the node is created right after HeadPointer. When the location corresponds to the length 
                of the linked list then it will be just before TailPointer. location range is [0, $Length].
                        
            .FUNCTIONALITY
                Does not make any changes to the linked list.
 
            .INPUTS
                int

            .OUTPUTS
                Node
        #>

        #Write-Host "`t >>> ENTERED [LinkedList].backwards() >>> to get to" $($destination) "of" $($this.Length) "sized linked list"
        [int] $counter = $this.Length
        
        [Node] $cursor = [Node]::new()
        $cursor = $this.TailPointer.Previous

        while ($counter -gt $destination) {
            Write-Host "`t`t counter:" $($counter) "current cursor state:" $cursor.Previous.Data "<--(`b" $cursor.Data "`b)-->" $cursor.Next.Data  
            $cursor = $cursor.Previous
            $counter--
        }

        #Write-Host "`t`tdestination:" $destination "`b's data:" $cursor.Previous.Data "<--(`b" $cursor.Data "`b)-->" $cursor.Next.Data  
        #Write-Host "`t <<< EXITING [LinkedList].backwards <<<"
        return $cursor

    } # <--- close backwards


    #------------------ Static Methods -------------------#
    hidden static [LinkedList] random () {
         <#
            .SYNOPSIS
                Creates an random linked list of at least 1 string, at most 5 strings

            .DESCRIPTION
                        
            .FUNCTIONALITY
 
            .INPUTS
                None

            .OUTPUTS
                LinkedList
        #>

        return [LinkedList]::random($null, 6)

    } # <--- close random


    hidden static [LinkedList] random ([int] $maxSize) {
         <#
            .SYNOPSIS
                Creates an random linked list of at least 1 string. at most (maxSize - 1) strings

            .DESCRIPTION
                        
            .FUNCTIONALITY
 
            .INPUTS
                int

            .OUTPUTS
                LinkedList
        #>

        if ($maxSize -le 0) {
            throw "random LinkedList generation failed: maxSize less than 1 exception thrown"
            exit(905)
        }

        return [LinkedList]::random($null, $maxSize)

    } # <--- close random


    hidden static [LinkedList] random ([string] $name, [int] $maxSize) {
         <#
            .SYNOPSIS
                Creates an random linked list of at least 1 string, at most (maxSize -1) strings

            .DESCRIPTION
                Unlike the [LinkedList]::rand() and [LinkedList]::rand(int) this method can assign a specific id to the randomly
                generated linked list.

            .PARAMETER name
                [string] The optional id that will be assigned to the random linked list.  If its' null or blank a randomly generated
                id will be assigned to the linked list

            .PARAMETER maxSize
                [int] The maxSize must be greater than zero.
                        
            .FUNCTIONALITY
 
            .INPUTS
                string
                int

            .OUTPUTS
                LinkedList
        #>

        if ($maxSize -le 0) {
            throw "random LinkedList generation failed: maxSize less than 1 exception thrown"
            exit(905)
        }

        if ($null -eq $name -or $name -eq [string]::Empty) {
            [LinkedList] $list = [LinkedList]::new((Get-RandomWord))
        }
        else {
            [LinkedList] $list = [LinkedList]::new($name, (Get-RandomWord))
        }
        
        #Write-Host "`tInitial Linked List State: " $list.ToString()

        if ($maxSize -gt 1) {
            [int] $extraNodeCount = Get-Random -Minimum 0 -Maximum ($maxSize)
            #Write-Host "`textra node count: " $extraNodeCount

            for ([int] $index = 0; $index -lt $extraNodeCount; $index++) { 
                $list.add(0, (Get-RandomWord)) 
                #Write-Host "`t`tindex: " $index ", Current LinkedList " $list.ToString()
            }
        }

        return $list

    } # <--- close randonm


    hidden static [string] id () {
         <#
            .SYNOPSIS
                Generates a  

            .DESCRIPTION
                The id will have prefix "LL_", suffix "_L" and will consist of a series of numbers and letters and dashes.
                        
            .FUNCTIONALITY
                There is no guarantee the ids will be unique
 
            .INPUTS
                None

            .OUTPUTS
                System.String
        #>

        [string] $sequence = "LL_"
        [int] $characterCount = 4

        for ([int] $index = 0; $index -lt $characterCount; $index++) {
            $sequence += ($global:LETTERS | Get-Random)
        }
        $sequence += "-"

        for ([int] $index = 0; $index -lt $characterCount; $index++) {
            $sequence += Get-Random -Minimum 0 -Maximum 10
        } 
        $sequence += "_L"
        return $sequence

    } # <--- close randomID


    hidden static [TerminatorLocation] anyTerminator () {
         <#
            .SYNOPSIS
                Converts the linked fields and it's data to a string  

            .DESCRIPTION
                For readability; if the LinkedList.Length > 20 only the first and last nodes are printed with ellipses for
                the remainder. Assumes the Data field of each node can be converted to a string. This method is for internal 
                testing and should be overriden by any child classes.
                        
            .FUNCTIONALITY
                Output might not be displayed correctly if the Node.Data does not have its' own toString method.
 
            .INPUTS
                None

            .OUTPUTS
                TerminatorLocation enum
        #>

        [TerminatorLocation] $terminator = [TerminatorLocation]::new()

        [int] $outcome = Get-Random -Minimum 1 -Maximum 3

        switch ($outcome) {
            1 { $terminator = [TerminatorLocation]::Head }
            2 { $terminator = [TerminatorLocation]::Tail }
        }  
        return $terminator

    } # <--- close anyTerminator


} # <--- end class LinkedList


<#---- Start LinkedList testing code
    Clear-Host

    [int] $end = 0
    [int] $start = 0 
    [int] $index = 0
    [int] $location = 0

    [Node] $node = [Node]::new()
    [string] $word = [string]::Empty

    [TerminatorLocation] $terminator =[TerminatorLocation]::new()

    [LinkedList] $listA = [LinkedList]::random("listA", 3)
    [LinkedList] $other = [LinkedList]::new()

    "`listA State:`n`t" + $listA.toString() + "`n"


    #=======EMPTY LinkedList TESTS
    [LinkedList] $empty = [LinkedList]::new()
    $empty.ID = "emptyLinkedList"

    [LinkedList] $mirror = [LinkedList]::new()
    $mirror.ID = "mirror"

    #"Checking for first and last elements of " + $empty.ID
    #"--------------------------------------------------"
    #$null -eq $empty.first()
    #$null -eq $empty.last()
    #"`tpeeked at " + $node.Data + " ON " + $empty.ID + "`n" 

    #"REMOVING AN ITEM FROM " + $empty.ID
    #"--------------------------------------------------"
    #$node = $empty.removeNode(0)
    #"`tpeeked at " + $node.Data + " ON " + $empty.ID + "`n" 


    #"SPLITTING AN EMPTY STACK " + $empty.ID + " STACK TO " + $mirror.ID + " QUEUE"
    #"--------------------------------------------------"
    #$mirror = $empty.split([TerminatorLocation]::Tail, 0)

    #"ATTEMPTING TO COPY " + $empty.ID + " TO " + $mirror.ID + " QUEUE"
    #"--------------------------------------------------"
    #$mirror = $empty.copy()

    #"ATTEMPTING TO ADD " + $mirror.ID + " QUEUE TO " + $empty.ID
    #"--------------------------------------------------"
    #"`n`t initial " + $empty.toString()
    #"`t initial " + $mirror.toString()    
    #$empty.add($mirror)
    #"`n`tempty list state: " + $empty.toString() + "`n"

    #"ATTEMPTING TO ADD DATA TO " + $empty.ID
    #"--------------------------------------------------"
    #$empty.add((Get-RandomWord))
    #"`n`tempty list state: " + $empty.toString() + "`n"


    #=======TESTING ADD
    $global:item_count = Get-Random -Minimum 0 -Maximum 6  
    "ATTEMPTING TO ADD " + $($global:item_count) + " WORDS TO LINKED_LIST " + $listA.ID + " :"
    "--------------------------------------------------"

    for ($index = 0; $index -lt $global:item_count; $index++) {  
        $word = Get-RandomWord     
        $listA.add($index, $word)
        "`tOperation " + $($index) + " Result: added " + $word + " >>> " + $listA.ToString()
    }
    "`nlistA State:`n`t" + $listA.toString() + "`n"

    #=======TESTING ISEMPTY
    "`nTESTING ISEMPTY METHOD ON LINKED LISTS OTHER AND A"
    "--------------------------------------------------------------------------------------"

    "`n`tIt is " + $other.isEmpty().ToString() + " that other of length " + $($other.Length) + " is empty"
    "`tIt is " +  $listA.isEmpty().ToString() + " that listA of length " + $($listA.Length) + " is empty"


    #=======TESTING REMOVAL OF ALL LINKED LIST ELEMENTS
    [LinkedList] $listJ = [LinkedList]::random(20)
    "`nATTEMPTING TO EMPTY LIKED_LIST_J  WITH ID" + $listJ.ID + " AND LENGTH " + $listj.Length
    "--------------------------------------------------------------------------------------"

    "`n`tlistJ State:`n`t`t" + $listJ.toString()
    [int] $size = $listJ.Length

    for ($index = 0; $index -lt $size; $index++) {
        $node = $listJ.removeNode(0)
        "`t`tRemoval Operation: " + $($index) + " " + $listJ.ToString() 
    }    

     #=======TESTING INSERT   
    $global:item_count = Get-Random -Minimum 0 -Maximum 4
    "`nATTEMPTING TO ADD " + $($global:item_count) + " LISTS TO CURRENT LIST " + $listA.ID.toString() #+ "'s VALUE OF " + $listA.toString() 
    "--------------------------------------------------------------------------------------"

    for ($index = 0; $index -lt $global:item_count; $index++) {
        $location = Get-Random -Minimum 0 -Maximum $listA.Length
        $other = [LinkedList]::random(4)

        #"`tOperation " + $($index) + " Result: Inserting " + $other.ToString() + " at " + $($location) + "`n`n`t`tTO TARGET>>>>>>>" + $listA.ToString() + "`n"

        try {
            $size = $listA.size()
            $listA.insert($location, $other)      
        }
        catch {
            $listA.size()
        }

    }
    "`nlistA State:`n`t" + $listA.toString() + "`n"

    #=======TESTING COPY
    [LinkedList] $listB = [LinkedList]::random(6)
    "ATTEMPTING TO COPY DATA FROM LINKED LIST " +  $listB.ID 
    "--------------------------------------------------------------------------------------"

    [LinkedList] $copy = $listB.copy()
    "`ncopied list State:`n`t" + $copy.ToString()
    "original listB State:`n`t" + $listB.ToString() + "`n"

    #=======TESTING REMOVE
    [LinkedList] $listC = [LinkedList]::random(12)
    $global:item_count = Get-Random -Minimum 0 -Maximum $listC.Length
    "ATTEMPTING TO Remove " + $($global:item_count) + " ITEMS FROM " + $($listC.Length) + " NODE LONG LINKED_LIST " + $listC.ID
    "--------------------------------------------------------------------------------------"

    for ([int] $index = 0; $index -lt $global:item_count; $index++) {
        ##"`t`t" + $listA.ToString() 

        $location = Get-Random -Minimum 0 -Maximum $listC.Length
        ##"`t`t  current length=" + $($listC.Length) + ", location= " + $location

        try {
            $node = $listC.removeNode($location)
        }
        catch {
            $listC.size()
        }
        
        #"`t`t`tOperation " + $($index) + " Result: " + $node.Data.ToString() + " removed  at location " + $($location)
    }
    "`nlistC State:`n`t" + $listC.toString() + "`n"
 
    #=======TESTING JOIN
    [LinkedList] $listD = [LinkedList]::random(6)
    [LinkedList] $listE = [LinkedList]::random(8)

    if ($listE.Length -gt 1) {
        $terminator = [LinkedList]::anyTerminator()

        "`nATTEMPTING TO JOIN LINKED_LIST_D TO LINKED_LIST_E AT " + $terminator.ToString()
        "--------------------------------------------------------------------------------------"
    
        "`tlistD State:`n`t`t" + $listD.toString()
        "`tlistE State:`n`t`t" + $listE.toString() + "`n"
    
        $listE.join($terminator, $listD)
        "listE State:`n`t" + $listE.ToString() + "`n"
    }

    #=======TESTING COPY
    [LinkedList] $listF = [LinkedList]::random(13)
    [LinkedList] $listG = [LinkedList]::new()

    if ($listF.Length -gt 1) {

        $terminator = [LinkedList]::anyTerminator()
        $location = Get-Random -Minimum 0 -Maximum $listF.Length
 
        "ATTEMPTING TO SPLIT COPIED LIST " + $listF.ID + " FROM LOCATION " + $($location) + " TO " + $terminator.ToString()
        "--------------------------------------------------------------------------------------"
        "`n`tpre-split listF State:`n`t`t" + $listF.toString()

        $listG = $listF.split($terminator, $location)
        "`tSplit off nodes:`n " + "`t`t" +$listG.ToString()
        "listF State:`n`t" + $listF.toString() + "`n"
    }

    #=======TESTING CUT
    [LinkedList] $original = [LinkedList]::random(12)
    $start = Get-Random -Minimum 0 -Maximum $original.Length
    $end = 0

    if ($start -gt 0) {

        while ($end -le $start) {
            #"current start: " + $($start) + " current end: " + $($end)
            $start = Get-Random -Minimum 0 -Maximum $original.Length
            $end = Get-Random -Minimum $start -Maximum $original.Length  
        } 

        [LinkedList] $sublist = [LinkedList]::new()

        "`nATTEMPTING TO CUT SUBLIST FROM  POSTIONS  " + $($start) + " TO " + $($end) + " IN " + $original.ID + " LINKED_LIST"
        "--------------------------------------------------------------------------------------"
    
        "`n`toriginal State:`n`t`t" + $original.toString()
        $sublist = $original.cut($start, $end)
        "`tsublist State:`n`t`t" + $sublist.toString() + "`n"
        "original State:`n`t" + $original.ToString()  
    }

#> #----> End LinkedList Testing Code  


#############################------- Define the STACK CLASS -------#############################

class Stack : LinkedList {
    <#
        .SYNOPSIS
            Implements a stack data structure using the LinkedList class.

        .DESCRIPTION
            Like its parent class Stack is not a fully defined collection since it does not support searching, sorting, comparisions,
            and equality methods. Neither does it have an iterator since PowerShell classes do not natively suppport iterators.  Without
            builtin support for generics the Stack class stores PSObject items.  This class is mainly to privude a unified way of traversing
            Stacks for any data type which inherits from the Stack class. 

        .PARAMETER ID
            [string] An optional identifier for each Stack instance.  Uniqueness is not guaranteed.
                              
        .FUNCTIONALITY
	#>

    #------------------ Properties  -------------------#
    [string] $ID 

    #------------------ Constructors  -------------------#
    Stack () : base() {
        <#
            .SYNOPSIS
                Creates an empty stack with a all fields set to null or zero.
        #>
    }

    Stack ([psobject] $obj) : base($obj) { 
        <#
            .SYNOPSIS
                Initializes the stack obj

            .DESCRIPTION
                The initialized stack is given a randomly generated id. Uniqueness of the id is not guaranteed.

            .FUNCTIONALITY

            .PARAMETER obj
                [psobject] First item pushed onto the stack.  When this constructor is invoked the base type must not be PSObject.  

            .INPUTS
                PSObject

            .OUTPUTS
                None
        #>

        $this.ID = [Stack]::id() 
    
    } # <--- close Stack
    
    
    Stack ([string] $name, [psobject] $obj) : base($obj) { 
            <#
            .SYNOPSIS
                Initializes a stack with obj and sets its ID to the designated name if it is not null

            .DESCRIPTION
                If name is null or blank a a randomly generated stack id will be created.  There is no check done for unique stack IDs.

            .FUNCTIONALITY

            .PARAMETER name
                [string] Can be null or blank.

            .PARAMETER obj
                The data which is pushed onto the the stack.  When the stack is implemented the base type must not be PSObject.

            .INPUTS
                String
                PSObject

            .OUTPUTS
                None
        #>

        $this.ID = $name 
    
    } # <--- close Stack


    #------------------ Getters  -------------------# 
    [Node] peek () {
        <#
            .SYNOPSIS
                Returns the first node in the stack. 

            .DESCRIPTION
                Unlike the getters for a true collection this returns the node instead of the data in the node.  If the stack is empty
                an empty stack exception is thrown.

            .FUNCTIONALITY
                Does not modify the stack. But care must be taken since the node returned is still pointing to other stack items.

            .INPUTS
                None

            .OUTPUTS
                Node
        #>
        
        #Write-Host "`t>>> Entering [Stack].peek() >>>"

        if ($this.Length -eq 0) {
            throw "Stack peek operation failed: Empty stack exception thrown"
            exit(111)
        }

        [Node] $node = $this.HeadPointer.Next
        #$node.Next = $null
        #$node.Previous = $null
        #Write-Host "`t`t first stack item: " $node.Data

        #Write-Host "`t<<< Exiting [Stack].peek() <<<"

        return $node

    } # <--- close peek


    #------------------ Setters  -------------------# 
    [void] push ([psobject] $obj) {
        <#
            .SYNOPSIS
                Pushes an item onto the stack.  The item cannot be null

            .DESCRIPTION
                Method does not check to see if the new item is of the same type as previous stack contents

            .FUNCTIONALITY

            .PARAMETER obj
                [psobject] The item being pushed onto the stack.  Make sure its' base type is not PSObject

            .INPUTS
                PSObject

            .OUTPUTS
                None
        #>

        if ($null -eq $obj) { 
            throw "Stack push operation failed: null parameter exception thrown"
            exit(202) 
        }
        $this.add(0, $obj)

    } # <--- close push


    [Node] pop () {
        <#
            .SYNOPSIS
                Removes the topmost node from the stack and returns it.

            .DESCRIPTION
                The node returned must be processed to extract the data. If the stack is empty throws an empty stack exception.

            .FUNCTIONALITY

            .INPUTS
                None

            .OUTPUTS
                Node
        #>

        if ($this.Length -eq 0) {
            throw "Stack pop operation failed: empty stack exception thrown"
            exit(111)
        }

        [Node] $node = [Node]::new()
        $node = $this.removeNode(0)
        return $node

    } # <--- close pop


    #------------------ Methods -------------------#
    [Stack] copy () {
        <#
            .SYNOPSIS
                Makes a deep copy of the stack's contents.

            .DESCRIPTION
                If the stack is empty an empty stack exception is thrown.

            .FUNCTIONALITY
                No modifications are made to the original stack

            .INPUTS
                None

            .OUTPUTS
                Stack
        #>

        if ($this.Length -eq 0) {
            throw "Stack copy operation failed: empty stack exception thrown"
            exit(45)
        }

        [Stack] $copy = [Stack]::new()
        [Stack] $staging = [Stack]::new()
        [Stack] $temp = [Stack]::new()

        [Node] $node = [Node]::new()

        [int] $stackSize = $this.Length

        for ([int] $index = 0; $index -lt $stackSize; $index++) {
            $node = $this.pop()

            $staging.push($node.Data)
            $temp.push($node.Data)
        }

        for ([int] $index = 0; $index -lt $stackSize; $index++) {
            $copy.push($staging.pop().Data)
            $this.push($temp.pop().Data)
        }

        $copy.ID = [Stack]::id()
        return $copy

    } # <--- close copy


    [Stack] reverse () {
        <#
            .SYNOPSIS
                Creates a deep copy of the stack's data but with the order of items inverted.

            .DESCRIPTION
                If the stack is empty an empty stack exception is thrown.

            .FUNCTIONALITY
                No modifications are made to the original stack

            .INPUTS
                None

            .OUTPUTS
                Stack 1374966
        #>

        if ($this.Length -eq 0) {
            throw "Stack reverse operation failed: empty stack exception thrown"
            exit(1233)
        }

        [Stack] $reverseStack = [Stack]::new()
        [Stack] $staging = [Stack]::new()

        [Node] $node = [Node]::new()

        [int] $stackSize = $this.Length

        for ([int] $index = 0; $index -lt $stackSize; $index++) {
            $node = $this.pop()

            $staging.push($node.Data)
            $reverseStack.push($node.Data)
        }

        for ([int] $index = 0; $index -lt $stackSize; $index++) {
            $node = $staging.pop()
            $this.push($node.Data)
        }

        $reverseStack.ID = [Stack]::id()
        return $reverseStack

    } # <--- close reverse


    [Stack] split ([int] $location) {
        <#
            .SYNOPSIS
                Creates a new stack by splitting the current stack.

            .DESCRIPTION
                The second stack consists of items from the top to the designated location. Location range is [0, Stack.Length].
                After the split the top of the stack is at (location + 1)
                If stack has single item single item stack exception is thrown.
                If the stack is empty an empty stack exception is thrown.

            .FUNCTIONALITY
                Decreases the size of the original stack by location number. If location < 0 or location > Stack.Length throws
                Linked

            .PARAMETER location
                [int] If the location where the split occurs.  

            .INPUTS
                int

            .OUTPUTS
                Stack 1374966
        #>

        if ($this.Length -eq 0) {
            throw "Stack split operation failed: empty stack exception thrown"
            exit(429)
        }

        if ($this.Length -eq 1) {
            throw "Stack split operation failed: single item stack exception thrown"
            exit(200)
        }

        [Stack] $child = [Stack]::new()

        for ($index = 0; $index -lt $location; $index++) {
            $child.push($this.pop().Data)
        }

        $child.ID = [Stack]::id()
        return $child  

    } # <--- close split


    [void] join ([Stack] $stack) {
        <#
            .SYNOPSIS
                Puts another stack ontop of the stack.

            .DESCRIPTION 
                Since stacks are LIFOs we put stacks on top of each other.

            .FUNCTIONALITY

            .PARAMETER stack
                The stack placed ontop of the current one

            .INPUTS
                Stack

            .OUTPUTS
                None
        #>

        if ($stack.Length -eq 0) { return }

        $this.join([TerminatorLocation]::Head, $stack)

    } # <--- close join


    [string] toString () {
         <#
            .SYNOPSIS
                Converts the Stack fields and it's data to a string  

            .DESCRIPTION
                Assumes the Data field of each node can be converted to a string. This method is for internal testing and
                should be overriden by any child classes.
                        
            .FUNCTIONALITY
                Output might not be displayed correctly if the Node.Data does not have its' own toString method.
 
            .INPUTS
                None

            .OUTPUTS
                System.String
        #>

        [Node] $node = [Node]::new()
        [Stack] $staging = [Stack]::new()
        [int] $stackSize = $this.Length

        [string] $text = "Stack ID: " + $this.ID + ", Length: " + $($this.Length) + " <-"

        for ([int] $index = 0; $index -lt $stackSize; $index++) {
            $node = $this.pop()
            $staging.push($node.Data)

            $text += "(" + $node.Data.ToString() + ")<=="
        }

        for ([int] $index = 0; $index -lt $stackSize; $index++) {
            $node = $staging.pop()
            $this.push($node.Data)
        }

        $text = $text.TrimEnd("<==")
        $text += "-|"
  
        return $text

    } # <--- close toString


    #------------------ Helper Functions -------------------# 

    #------------------ Static Methods -------------------#
    static [Stack] random() { 
        <#
            .SYNOPSIS
                Creates an random stack of at least 1 string, at most 5 strings

            .DESCRIPTION
                        
            .FUNCTIONALITY
 
            .INPUTS
                None

            .OUTPUTS
                LinkedList
        #>

        return [Stack]::random($null, 5)

    } # <--- close random


    static [Stack] random([int] $maxSize) {
         <#
            .SYNOPSIS
                Creates an random stack of at least 1 string. at most (maxSize - 1) strings

            .DESCRIPTION
                        
            .FUNCTIONALITY
 
            .INPUTS
                int

            .OUTPUTS
                Stack
        #>

        return [Stack]::random($null, $maxSize)

    } # <--- close random


    static [Stack] random([string] $name, [int] $maxSize) {
         <#
            .SYNOPSIS
                Creates an random string stack of at least 1 string, at most (maxSize -1) strings

            .DESCRIPTION
                Unlike the [Stack]::rand() and [Stack]::rand(int) this method can assign a specific id to the randomly
                generated linked list.

            .PARAMETER name
                [string] The optional id that will be assigned to the random linked list.  If its' null or blank a randomly generated
                id will be assigned to the linked list

            .PARAMETER maxSize
                [int] The maxSize must be greater than zero.
                        
            .FUNCTIONALITY
 
            .INPUTS
                string
                int

            .OUTPUTS
                Stack
        #>

        if ($null -eq $name -or $name -eq [string]::Empty) {
            [Stack] $stack = [Stack]::new((Get-RandomWord)) 
        }
        else {
            [Stack] $stack = [Stack]::new($name, (Get-RandomWord))
        }

        if ($maxSize -gt 1) {
            [int] $extraNodeCount = Get-Random -Minimum 0 -Maximum $maxSize

            for ([int] $index = 0; $index -lt $extraNodeCount; $index++) {
                $stack.push((Get-RandomWord))
            }
        }

        return $stack

    } # <--- close random


    static [string] id () {
         <#
            .SYNOPSIS
                Generates a  

            .DESCRIPTION
                The id will have prefix "S_", suffix "_S" and will consist of a series of numbers and letters and dashes.
                        
            .FUNCTIONALITY
                There is no guarantee the ids will be unique
 
            .INPUTS
                None

            .OUTPUTS
                System.String
        #>
        [string] $sequence = "S_"
        [int] $characterCount = 5

        for ([int] $index = 0; $index -lt $characterCount; $index++) {
            $sequence += ($global:letters | Get-Random)
        }

        $sequence += "-"

        for ([int] $index = 0; $index -lt $characterCount; $index++) {
            $sequence += Get-Random -Minimum 0 -Maximum 9
        } 
        $sequence += "_S"

        return $sequence

    } # <--- close id


} # <--- end class Stack

 
<#---- Start Stack testing code
    Clear-Host

    [int] $index = 0
    [int] $location = 0

    [Node] $node = [Node]::new()
    [string] $word = [string]::Empty

    [Stack] $stackA = [Stack]::new()
    $stackA.ID = "stackA"

    "stackA state:`n`t" + $stackA.toString() + "`n"


    #=======TESTING PUSH
    $global:item_count = Get-Random -Minimum 0 -Maximum 8  
    "ATTEMPTING TO PUSH " + $($global:item_count) + " WORDS ONTO EMPTY " + $stackA.ID + " :"
    "--------------------------------------------------"

    for ($index = 0; $index -lt $global:item_count; $index++) {  
        $word = Get-RandomWord     
        $stackA.push($word)
        "`tOperation " + $($index) + " Result: pushed " + $word + " >>> "# + $stackA.ToString()
    }
    "`nstackA State:`n`t" + $stackA.toString() + "`n"    


    #=======TESTING PEEK
    $global:item_count = Get-Random -Minimum 1 -Maximum 3  
    "ATTEMPTING TO PEEK " + $($global:item_count) + " TIMES AT THE TOP OF " + $stackA.ID + " :"
    "--------------------------------------------------"

    for ($index = 0; $index -lt $global:item_count; $index++) {  
        $node = $stackA.peek()
       "`tOperation " + $($index) + " Result: peeked at " + $node.Data + " ON " + $stackA.ID + "`n" 
    }
    "`nstackA State:`n`t" + $stackA.toString() + "`n"    


    #=======TESTING POP
    $global:item_count = $stackA.Length 
    "ATTEMPTING TO POP " + $stackA.ID + " UNTIL ITS'' EMPTY OF ALL  " + $($stackA.Length) + " ITEMS:"
    "--------------------------------------------------"

    for ($index = 0; $index -lt $global:item_count; $index++) {  
        $node = $stackA.pop()
       "`tOperation " + $($index) + " Result: popped " + $node.Data + " OFF " + $stackA.ToString()
    }
    "`nstackA State:`n`t" + $stackA.toString() + "`n"   
    
    #"TESTING ERROR HANDLING FOR POPPING EMPTY STACK " + $stackA.ID
    #"--------------------------------------------------"
    #$node = $stackA.pop()


    #=======TESTING COPY
    [Stack] $original = [Stack]::random("original", 8)
    [Stack] $copy = [Stack]::new()


    "ATTEMPTING TO COPY " + $original.ID + " STACK TO ANOTHER STACK:"
    "--------------------------------------------------"

    $copy = $original.copy()
    $copy.ID = "copy"

    "`t" + $original.toString()
    "`t" + $copy.toString()     

    "`n$original.ID Stack State:`n`t" + $original.toString() + "`n"


    #=======TESTING REVERSE
    [Stack] $reverse = [Stack]::new()

    "ATTEMPTING TO REVERSE " + $original.ID + " STACK TO ANOTHER STACK:"
    "--------------------------------------------------"

    $reverse = $original.reverse()
    $reverse.ID = "reversed"

    "`t" + $original.toString()
    "`t" + $reverse.toString()     

    "`n$original.ID Stack State:`n`t" + $original.toString() + "`n"


    #=======TESTING SPLIT
    [Stack] $stackB = [Stack]::random("stackB", 12)
    [Stack] $child = [Stack]::new()

    #"SPLITTING A SINGLE ITEM STACK " + $unity.ID + " STACK TO ANOTHER STACK:"
    #"--------------------------------------------------"
    #[Stack] $unity = [Stack]::random("singleItemStack", 1)
    #$child = $unity.split(1)

    #"SPLITTING AN EMPTY STACK " + $empty.ID + " STACK TO ANOTHER STACK:"
    #"--------------------------------------------------"
    #[Stack] $empty = [Stack]::new() 
    #$empty.ID = "emptyStack"
    #$child = $empty.split(1)

    $location = Get-Random -Minimum 0 -Maximum $stackB.Length 
    "ATTEMPTING TO SPLIT STACK " + $stackB.ID + " AT LOCATION " + $($stackB.Length)
    "--------------------------------------------------"
    "`t" + $stackB.toString()
    $child = $stackB.split($location)
    "`t" + $child.toString()     

    "`nstackB Stack State:`n`t" + $stackB.toString() + "`n" 


    #=======TESTING ADD
    [Stack] $stackC = [Stack]::random("stackC", 10)
    [Stack] $empty = [Stack]::new() 
    $empty.ID = "emptyStack"

    "SJOINING AN EMPTY STACK " + $empty.ID + " STACK TO " + $stackB.ID
    "--------------------------------------------------"
 
    "`tStackB before addition " + $stackB.toString()  
    "`tempty before addition " + $empty.toString()  

    $stackB.add($empty)
    #$child = $empty.split(1)

    "`n`tstackB after adding empty:`n`t" + $stackB.toString() + "`n" 


    $location = Get-Random -Minimum 0 -Maximum $stackB.Length 
    "ATTEMPTING TO ADD " + $stackC.ID + " TO " + $stackB.ID
    "--------------------------------------------------"
    "`t" + $stackB.toString()
    "`t" + $stackC.toString()
    $stackB.add($stackC)    

    "`n`tstackB State:`n`t`t" + $stackB.toString() + "`n" 
 
#> #----> End Stack Testing Code 


#############################------- Define the QUEUE CLASS -------#############################

class Queue : LinkedList {
   <#
        .SYNOPSIS
            Implements a queue data structure using the LinkedList class.

        .DESCRIPTION
            Like its parent class Queue is not a fully defined collection since it does not support searching, sorting, comparisions,
            and equality methods. Neither does it have an iterator since PowerShell classes do not natively suppport iterators.  Without
            builtin support for generics the Queue class stores PSObject items.  This class is mainly to privude a unified way of traversing
            Queue for any data type which inherits from the Queue class. 

        .PARAMETER ID
            [string] An optional identifier for each Stack instance.  Uniqueness is not guaranteed.
                              
        .FUNCTIONALITY
	#>

    #------------------ Properties  -------------------#
    [string] $ID 

    #------------------ Constructors  -------------------#
    Queue () : base() {
        <#
            .SYNOPSIS
                Creates an empty stack with a all fields set to null or zero.
        #>
    } # <--- close Queue


    Queue ([psobject] $obj) : base($obj) { 
        <#
            .SYNOPSIS
                Initializes the Queue obj

            .DESCRIPTION
                The initialized queue is given a randomly generated id. Uniqueness of the id is not guaranteed.

            .FUNCTIONALITY

            .PARAMETER obj
                [psobject] First item enqueued in the queue.  When this constructor is invoked the base type must not be PSObject.  

            .INPUTS
                PSObject

            .OUTPUTS
                None
        #>
        
        $this.ID = [Queue]::id() 

    } # <--- close Queue


    Queue ([string] $name, [psobject] $obj) : base($obj) { 
         <#
            .SYNOPSIS
                Initializes a queue with obj and sets its ID to the designated name if it is not null

            .DESCRIPTION
                If name is null or blank a a randomly generated queue id will be created.  There is no check done for unique stack IDs.

            .FUNCTIONALITY

            .PARAMETER name
                [string] Can be null or blank.

            .PARAMETER obj
                The data which is pushed onto the the queue.  When the queue is implemented the base type must not be PSObject.

            .INPUTS
                String
                PSObject

            .OUTPUTS
                None
        #>

        $this.ID = $name 

    } # <--- close Queue


    #------------------ Setters  -------------------# 

    #------------------ Getters  -------------------# 
    [Node] peek () {
       <#
            .SYNOPSIS
                Returns the first node in the queue. 

            .DESCRIPTION
                Unlike the getters for a true collection this returns the node instead of the data in the node.  If the queue is empty
                an empty queue exception is thrown.

            .FUNCTIONALITY
                Does not modify the queue. But care must be taken since the node returned is still pointing to other queue items.

            .INPUTS
                None

            .OUTPUTS
                Node
        #>
        #Write-Host "`t>>> Entering [Stack].peek() >>>"

        if ($this.Length -eq 0) {
            throw "Queue peek operation failed: Empty queue exception thrown"
            exit(111)
        }

        [Node] $node = $this.HeadPointer.Next
        #$node.Next = $null
        #$node.Previous = $null
        #Write-Host "`t`t first stack item: " $node.Data

        #Write-Host "`t<<< Exiting [Stack].peek() <<<"

        return $node

    } # <--- close peek

    #------------------ Setters  -------------------# 
    [void] add ([psobject] $obj) {
        <#
            .SYNOPSIS
                Adds an item to the rear of the queue.  The item cannot be null

            .DESCRIPTION
                Method does not check to see if the new item is of the same type as previous queuek contents

            .FUNCTIONALITY

            .PARAMETER obj
                [psobject] The item being pushed onto the queue.  Make sure its' base type is not PSObject

            .INPUTS
                PSObject

            .OUTPUTS
                None
        #>

        if ( $null -eq $obj) { 
            throw "Queue add operation failed: null parameter exception thrown"
            exit(202) 
        }
        $this.add(($this.Length), $obj)

    } # <--- close add


    [void] add ([Queue] $queue) {
        <#
            .SYNOPSIS
                Puts another queue beneath the queue.

            .DESCRIPTION 
                Since queues are FIFOs we put queues below each other.

            .FUNCTIONALITY

            .PARAMETER stack
                The queue placed below the current one

            .INPUTS
                Queue

            .OUTPUTS
                None
        #>

        if ($queue.Length -eq 0) { return }

        [Node] $first = [Node]::new()
        [Node] $last = [Node]::new()
        [Node] $oldEnd = [Node]::new()

        $first = $queue.HeadPointer.Next
        $last = $queue.TailPointer.Previous

        $oldEnd = $this.TailPointer.Previous

        $oldEnd.Next = $first
        $first.Previous = $oldEnd

        $this.TailPointer.Previous = $last
        $last.Next = $this.TailPointer

        $this.Length += $queue.Length        

    } # <--- close add


    [Node] remove () {
        <#
            .SYNOPSIS
                Removes the oldest node from the queuee and returns it.

            .DESCRIPTION
                The node returned must be processed to extract the data. If the stack is empty throws an empty stack exception.

            .FUNCTIONALITY

            .INPUTS
                None

            .OUTPUTS
                Node
        #>

        if ($this.Length -eq 0) {
            throw "Queue remove operation failed: empty queue exception thrown"
            exit(4347)
        }

        [Node] $node = [Node]::new()
        $node = $this.removeNode(0)

        $node.Next = $null
        $node.Previous = $null

        return $node

    } # <--- close add


    #------------------ Methods -------------------#

    #------------------ Methods -------------------#
    [Queue] copy () {
        <#
            .SYNOPSIS
                Makes a deep copy of the queue's contents.

            .DESCRIPTION
                If the queue is empty an empty stack exception is thrown.

            .FUNCTIONALITY
                No modifications are made to the original stack

            .INPUTS
                None

            .OUTPUTS
                Queue
        #>

        if ($this.Length -eq 0) {
            throw "Queue copy operation failed: empty queue exception thrown"
            exit(45)
        }

        [Queue] $copy = [Queue]::new()
        [Queue] $staging = [Queue]::new()

        [Node] $node = [Node]::new()

        [int] $size = $this.Length

        for ([int] $index = 0; $index -lt $size; $index++) {
            $node = $this.remove()

            $copy.add($node.Data)
            $staging.add($node.Data)
        }

        for ([int] $index = 0; $index -lt $size; $index++) {
            $this.add($staging.remove().Data)
        }

        $copy.ID = [Queue]::id()
        return $copy

    } # <--- close copy


    [Queue] reverse () {
        <#
            .SYNOPSIS
                Creates a deep copy of the queue's data but with the order of items inverted.

            .DESCRIPTION
                If the stack is empty an empty queue exception is thrown.

            .FUNCTIONALITY
                No modifications are made to the original queue

            .INPUTS
                None

            .OUTPUTS
                Queue 1374966
        #>

        if ($this.Length -eq 0) {
            throw "Queue copy operation failed: empty queue exception thrown"
            exit(1233)
        }

        [Queue] $reversed = [Queue]::new()
        [Queue] $staging = [Queue]::new()
        [Queue] $temp = [Queue]::new()

        [Node] $node = [Node]::new()

        if ($this.Length -eq 0) {
            $reversed = $this.copy()
            return $reversed
        }

        [int] $size = $this.Length

        for ([int] $index = 0; [int] $index -lt $size; [int] $index++) {
            $node = $this.remove()

            $staging.add($node.Data)
            $temp.add($node.Data)
        }

        for ([int] $index = 0; [int] $index -lt $size; [int] $index++) {
            $this.add($temp.remove().Data)

            $node = $staging.removeNode($staging.Length)
            $reversed.add($node.Data)
        }

        $reversed.ID = [Queue]::id()
        return $reversed

    } # <--- close reverse


    [Queue] split ([int] $location) {
        <#
            .SYNOPSIS
                Creates a new queue by splitting the current queue.

            .DESCRIPTION
                The second queue consists of items from the bottom to the designated location. Location range is [0, Stack.Length].
                After the split the botom of the queue is at (location + 1)
                
                If quuee has single item single item stack exception is thrown. If the queue is empty an empty stack exception is thrown.

            .FUNCTIONALITY
                Decreases the size of the original stack by location number. If location < 0 or location > Stack.Length throws
                Linked

            .PARAMETER location
                [int] If the location where the split occurs.  

            .INPUTS
                int

            .OUTPUTS
                Queue 1374966
        #>


        if ($this.Length -eq 0) {
            throw "Queue split operation failed: empty queue exception thrown"
            exit(429)
        }

        if ($this.Length -eq 1) {
            throw "Queue split operation failed: single item queue exception thrown"
            exit(200)
        }

        [Queue] $child = [Queue]::new()

        for ($index = 0; $index -lt $location; $index++) {
            $child.add($this.remove().Data)
        }

        $child.ID = [Queue]::id()
        return $child  

    } # <--- close split


    [string] toString () {
         <#
            .SYNOPSIS
                Converts the Queue's fields and it's data to a string  

            .DESCRIPTION
                Assumes the Data field of each node can be converted to a string. This method is for internal testing and
                should be overriden by any child classes.
                        
            .FUNCTIONALITY
                Output might not be displayed correctly if the Node.Data does not have its' own toString method.
 
            .INPUTS
                None

            .OUTPUTS
                System.String
        #>

        [Node] $node = [Node]::new()
        [Queue] $staging = [Queue]::new()


        [int] $size = $this.Length

        [string] $text = "Queue (ID: " + $this.ID + ", Length: " + ($this.Length) + ") <-"

        for ([int] $index = 0; $index -lt $size; $index++) {
            $node = $this.remove()
            $text += "(" + $node.Data.ToString() + ")<=="

            $staging.add($node.Data)
        }

        for ([int] $index = 0; $index -lt $size; $index++) {
            $this.add($staging.remove().Data)
        }

        $text = $text.TrimEnd("<==")
        $text += "<-"

        return $text

    } # <--- close toString


    #------------------ Helper Functions -------------------# 
  
    #------------------ Static Methods -------------------#
    static [Queue] random() {
        <#
            .SYNOPSIS
                Creates an random queue of at least 1 string, at most 5 strings

            .DESCRIPTION
                        
            .FUNCTIONALITY
 
            .INPUTS
                None

            .OUTPUTS
                Queue
        #>

        return [Queue]::random($null, 1)

    } # <--- close random


    static [Queue] random([int] $maxSize) {
         <#
            .SYNOPSIS
                Creates an random queue of at least 1 string. at most (maxSize - 1) strings

            .DESCRIPTION
                        
            .FUNCTIONALITY
 
            .INPUTS
                int

            .OUTPUTS
                Stack
        #>

        return [Queue]::random($null, $maxSize)

    } # <--- close random


    static [Queue] random([string] $name, [int] $maxSize) {
         <#
            .SYNOPSIS
                Creates an random string queue of at least 1 string, at most (maxSize -1) strings

            .DESCRIPTION
                Unlike the [Queue]::rand() and [Queue]::rand(int) this method can assign a specific id to the randomly
                generated linked list.

            .PARAMETER name
                [string] The optional id that will be assigned to the random linked list.  If its' null or blank a randomly generated
                id will be assigned to the linked list

            .PARAMETER maxSize
                [int] The maxSize must be greater than zero.
                        
            .FUNCTIONALITY
 
            .INPUTS
                string
                int

            .OUTPUTS
                Queue
        #>

        if ($null -ne $name -or $name -eq [string]::Empty) {
            [Queue] $queue = [Queue]::new($name, (Get-RandomWord))
        }
        else {
            [Queue] $queue = [Queue]::new((Get-RandomWord)) 
        }

        if ($maxSize -gt 1) {
            [int] $extraNodeCount = Get-Random -Minimum 0 -Maximum $maxSize

            for ([int] $index = 0; $index -lt $extraNodeCount; $index++) {
                $queue.add((Get-RandomWord))
            }
        }

        return $queue

    } # <--- close random


    static [string] id () {
        <#
           .SYNOPSIS
               Generates a  

           .DESCRIPTION
               The id will have prefix "Q_", suffix "_Q" and will consist of a series of numbers and letters and dashes.
                       
           .FUNCTIONALITY
               There is no guarantee the ids will be unique

           .INPUTS
               None

           .OUTPUTS
               System.String
       #>
       [string] $sequence = "Q_"
       [int] $characterCount = 4

       for ([int] $index = 0; $index -lt $characterCount; $index++) {
           $sequence += ($global:letters | Get-Random)
       }

       $sequence += "-"

       for ([int] $index = 0; $index -lt $characterCount; $index++) {
           $sequence += Get-Random -Minimum 0 -Maximum 9
       } 
       $sequence += "_Q"

       return $sequence

   } # <--- close id


} # <--- end class Queue


<#---- Start Queue testing code
    Clear-Host

    [int] $index = 0
    [int] $location = 0

    [Node] $node = [Node]::new()
    [string] $word = [string]::Empty

    [Queue] $queueA = [Queue]::random("queueA", 4)

    "queueA state:`n`t" + $queueA.toString() + "`n"

   #=======EMPTY QUEUE TESTS
   [Queue] $empty = [Queue]::new()
   $empty.ID = "emptyQueue"

   [Queue] $mirror = [Queue]::new()
   $mirror.ID = "mirror"

   #"ATTEMPTING TO PEEK AT " + $empty.ID
   #"--------------------------------------------------"
   #$node = $empty.peek()
   #"`tpeeked at " + $node.Data + " ON " + $empty.ID + "`n" 

   #"REMOVING AN ITEM FROM " + $empty.ID
   #"--------------------------------------------------"
   #$node = $empty.remove()
   #"`tpeeked at " + $node.Data + " ON " + $empty.ID + "`n" 


   #"SPLITTING AN EMPTY STACK " + $empty.ID + " STACK TO " + $mirror.ID + " QUEUE"
   #"--------------------------------------------------"
   #$mirror = $empty.split(1)

   #"ATTEMPTING TO COPY " + $empty.ID + " TO " + $mirror.ID + " QUEUE"
   #"--------------------------------------------------"
   #$mirror = $empty.copy()

   #"ATTEMPTING TO ADD " + $mirror.ID + " QUEUE TO " + $empty.ID
   #"--------------------------------------------------"
   #"`n`t initial " + $empty.toString()
   #"`t initial " + $mirror.toString()    
   #$empty.add($mirror)
   #"`n`tempty queue state: " + $empty.toString() + "`n"

   #"ATTEMPTING TO ADD DATA TO " + $empty.ID
   #"--------------------------------------------------"
   #$empty.add((Get-RandomWord))
   #"`n`tempty queue state: " + $empty.toString() + "`n"

    #=======TESTING ADD
    $global:item_count = Get-Random -Minimum 0 -Maximum 8  
    "ATTEMPTING TO ENQUEUE " + $($global:item_count) + " WORDS ONTO " + $queueA.ID + " :"
    "--------------------------------------------------"

    for ($index = 0; $index -lt $global:item_count; $index++) {  
        $word = Get-RandomWord     
        $queueA.add($word)
        #"`tOperation " + $($index) + " Result: enqueued " + $word + " >>> " + $queueA.ToString() + "`n"
    }
    "`tqueueA State:`n`t" + $queueA.toString() + "`n"    


    #=======TESTING PEEK
    $global:item_count = Get-Random -Minimum 1 -Maximum 3  
    "ATTEMPTING TO PEEK " + $($global:item_count) + " TIMES AT THE TOP OF " + $queueA.ID + " :"
    "--------------------------------------------------"

    for ($index = 0; $index -lt $global:item_count; $index++) {  
        $node = $queueA.peek()
       "`tOperation " + $($index) + " Result: peeked at " + $node.Data + " ON " + $queueA.ID + "`n" 
    }
    #"`tqueueA State:`n`t" + $queueA.toString() + "`n"  


    #=======TESTING REMOVE
    $global:item_count = $queueA.Length 
    "ATTEMPTING TO DEQUEUE " + $queueA.ID + " OF ALL  " + $($queueA.Length) + " OF ITS's ITEMS:"
    "--------------------------------------------------"

    for ($index = 0; $index -lt $global:item_count; $index++) {  
        $node = $queueA.remove()
       "`tOperation " + $($index) + " Result: " + $node.Data + " dequeued from " + $queueA.ToString()
    }
    "`n`tqueueA State:`n`t" + $queueA.toString() + "`n"   


    #=======TESTING COPY
    [Queue] $original = [Queue]::random("original", 12)
    [Queue] $copy = [Queue]::new()

    "ATTEMPTING TO COPY " + $original.ID + " QUEUE's CONTENTS TO ANOTHER QUEUE:"
    "--------------------------------------------------"
    $copy = $original.copy()
    $copy.ID = "copy"

    "`t" + $original.toString()
    "`t" + $copy.toString()     

    "`n$original.ID Queue State:`n`t" + $original.toString() + "`n"


    #=======TESTING REVERSE
    [Queue] $reverse = [Queue]::new()

    "ATTEMPTING TO REVERSE " + $original.ID + " QUEUE TO ANOTHER QUEUE:"
    "--------------------------------------------------"

    $reverse = $original.reverse()
    $reverse.ID = "reversed"

    "`t" + $original.toString()
    "`t" + $reverse.toString()     

    "`n$original.ID Queue State:`n`t" + $original.toString() + "`n"


    #=======TESTING SPLIT
    [Queue] $queueB = [Queue]::random("queueB", 12)
    [Queue] $child = [Queue]::new()

    [Queue] $unity = [Queue]::random("singleItemQueue", 1)

    #"SPLITTING A SINGLE ITEM QUEUE " + $unity.ID + " TO ANOTHER QUEUE:"
    #"--------------------------------------------------"
    #$child = $unity.split(1)

    $location = Get-Random -Minimum 0 -Maximum $queueB.Length 
    "ATTEMPTING TO SPLIT QUEUE " + $queueB.ID + " AT LOCATION " + $($queueB.Length)
    "--------------------------------------------------"
    "`t" + $queueB.toString()
    $child = $queueB.split($location)
    "`t" + $child.toString()     

    "`nqueueB Queue State:`n`t" + $queueB.toString() + "`n" 


    #=======TESTING ADD
    [Queue] $queueC = [Queue]::random("queueC", 10)
    [Queue] $empty = [Queue]::new() 
    $empty.ID = "emptyQueue"

    "ATTEMPTING TO JOIN AN EMPTY QUEUE " + $empty.ID + " TO " + $queueB.ID
    "--------------------------------------------------"
 
    "`tQueueB before addition " + $queueB.toString()  
    "`tempty before addition " + $empty.toString()  

    $queueB.add($empty)
    #$child = $empty.split(1)

    "`n`tqueueB state:`n`t" + $queueB.toString() + "`n" 

    $location = Get-Random -Minimum 0 -Maximum $queueB.Length 
    "ATTEMPTING TO ADD " + $queueC.ID + " TO " + $queueB.ID
    "--------------------------------------------------"
    "`t" + $queueB.toString()
    "`t" + $queueC.toString()
    $queueB.add($queueC)    

    "`n`tqueueB State:`n`t`t" + $queueB.toString() + "`n" 
 
#> #----> End Queue Testing Code 