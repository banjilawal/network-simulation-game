
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

enum Direction {
    Before = 1; After = 2
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


function Random-Direction () {
    [int] $outcome = Get-Random -Minimum 1 -Maximum 3

    switch ($outcome) {
        1 { return [Direction]::Before }
        2 { return [Direction]::After }
    }
} # <--- close Random-Direction


#############################------- Define the Node CLASS -------#############################

class Node {

    #------------------ Properties  -------------------#
    [string] $ID

    [ValidateNotNullOrEmpty()]
    [psobject] $Data

    [Node] $Next
    [Node] $Previous

    [int] $Length


    #------------------ Constructors  -------------------#
    Node () {} # <--- close Node

    Node ([psobject] $obj) {

        $this.Next = [Node]::new()
        $this.Previous = [Node]::new()

        $this.Data = $obj
        $this.ID = $this.randomID()
        $this.Length = 1

        $this.Next = $null
        $this.Previous = $null

    } # <--- close Node


    #------------------ Getters  -------------------# 
    [Node] first () {
        [Node] $cursor = [Node]::new()
        $cursor = $this

        while ($null -ne $cursor.Previous) {
            $cursor = $cursor.Previous
        }

        return $cursor

    } # <--- close first


    [Node] last () {
        [Node] $cursor = [Node]::new()
        $cursor = $this

        while ($null -ne $cursor.Next) {
            $cursor = $cursor.Next
        }

        return $cursor

    } # <--- close last


    [int] size () {
        [int] $size = 0
        [Node] $cursor = [Node]::new()

        $cursor = $this.first()

        while ($null -ne $cursor) {
            $size++
            $cursor = $cursor.Next            
        }
        return $size

    } # <--- close size


    #------------------ Setters  -------------------# 
    [void] add ([Direction] $direction, [psobject] $obj) {

        $this.add($direction, [Node]::new($obj))

    } # <--- close add


    [void] add ([Direction] $direction, [Node] $node) {

        if ($null -eq $node) { return }

        switch ($direction.ToString()) {
            "Before" { $this.addBefore($node) }
            "After" { $this.addAfter($node) }
        }

    } # <--- close add


    [void] addBefore ([Node] $node) {

        [Node] $precedent = [Node]::new()
        [Node] $marker = [Node]::new()

        $precedent = $this.Previous

        $marker.Next = $node.first()
        $marker.Previous = $node.last()

        if ($null -ne $precedent) {
            $node.first().Previous = $precedent
            $node.last().Next = $this

            $precedent.Next = $marker.Next
            $this.Previous = $marker.Previous
        }
        else {
            $node.first().Previous = $null
            $node.last().Next = $this

            $this.Previous = $marker.Previous
        }

        $this.Length += $node.Length

    } # <--- close addBefore


    [void] addAfter ([Node] $node) {

        [Node] $consequent = [Node]::new()
        [Node] $marker = [Node]::new()

        $consequent = $this.Next

        $marker.Next = $node.first()
        $marker.Previous = $node.last()

        if ($null -ne $consequent) {
            $node.first().Previous = $this
            $node.last().Next = $consequent

            $this.Next = $marker.Next
            $consequent.Previous = $marker.Previous
        }
        else {
            $node.first().Previous = $this
            $node.last().Next = $null

            $this.Next = $marker.Next
        }

        $this.Length += $node.Length

    } # <--- close addAfter

    [void] join ([TerminatorLocation] $location, [Node] $node) {

        [Node] $marker = [Node]::new()
        [Node] $oldTerminus = [Node]::new()

        if ($node.Length -eq 0 -or $null -eq $node) {
            return
        }

        switch ($location.ToString()) {
            "Head" { 
                $oldTerminus = $this.first()
                $marker = $node.last()
        
                $oldTerminus.Previous = $node.last()
                $marker.Next = $oldTerminus
            }
            "Tail" { 
                $oldTerminus = $this.last()
                $marker = $node.first()
        
                $oldTerminus.Next = $node.first()
                $marker.Previous = $oldTerminus
            }
        }
        $this.Length += $node.Length

    } # <--- close join
 

    [Node] remove ([Direction] $direction) {

        [Node] $node= [Node]::new()

        if ($this.Length -lt 2) {
            throw "Cannot remove items from a node of length " + $($this.size()) + ".  There are no removable items in this " + $this.GetType().ToString()
            exit(430)
        }

        switch ($direction.ToString()) {
            "Before" { $node = $this.removeBefore() }
            "After" { $node = $this.removeAfter() }
        }
        
        return $node

    } # <--- close remove


    [Node] removeBefore() {
        [Node] $discard = [Node]::new()
        [Node] $keep = [Node]::new()

        if ($null -eq $this.Previous) {
            throw "Removal before " + $this.GetType().ToString() + " failed: There are no items in front of " + $this.GetType().ToString() + " ID " + $this.ID.ToString() + " with " + $this.Data.ToString()
            exit(353)
        }

        $keep = $this.Previous.Previous
        $discard = $this.Previous
        $this.Previous = $null

        if ($null -ne $keep) {
            $this.Previous = $keep
            $keep.Next = $this
        }
        $this.Length--

        $discard.Next = $null
        $discard.Previous = $null

        return $discard

    } # <--- close removeBefore


    [Node] removeAfter() {
        [Node] $discard = [Node]::new()
        [Node] $keep = [Node]::new()

        if ($null -eq $this.Next) {
            throw "Removal After " + $this.GetType().ToString() + " failed: There are no items behind of " + $this.GetType().ToString() + " ID " + $this.ID.ToString() + " with " + $this.Data.ToString()
            exit(353)
        }

        $keep = $this.Next.Next
        $discard = $this.Next
        $this.Next = $null

        if ($null -ne $keep) {
            $this.Next = $keep
            $keep.Previous = $this
        }
        $this.Length--

        $discard.Next = $null
        $discard.Previous = $null

        return $discard

    } # <--- close removeAfter


    [Node] split([Direction] $direction) {
        [Node] $node = [Node]::new()

        if ($this.Length -le 1) {
            throw "Split Operation failed. A lsit must have at least two items for a split operation to work"
            exit(222)         
        }

        switch ($direction.ToString()) {
            "Before" { 
                $node = $this.Previous
    
                if ($null -eq $node) {
                    throw "Split Operation failed.  You cannot split before the first item in the list"
                    exit(222) 
                }
                $node.Next = $null
                $this.Previous = $null
            }
            "After" { 
                $node = $this.Next

                if ($null -eq $node) {
                    throw "Split Operation failed.  You cannot split after the last item in the list"
                    exit(222) 
                }
                $node.Previous = $null
                $this.Next = $null
            }
        }
        return $node

    } # <--- close split


    #------------------ Methods -------------------#
    [Node] copy () {

        [Node] $cursor = [Node]::new()
        $cursor = $this.first()

        [Node] $node = [Node]::new($cursor.Data)
        #Write-Host "`tInitialized copy with " $cursor.Data

        while ($null -ne $cursor.Next) {
            $cursor = $cursor.Next
            #Write-Host "`t copying " + $cursor.Data
            $node.add([Direction]::After, $cursor.Data)      
            
            #"`tCurrent copy progress: " + $node.ToString()
        }
        return $node

    } # <--- close copy


    [string] toString () {

        [string] $text = "Node ID: " + $this.ID + ", Length: " + $($this.size()) + ": " 
        [Node] $cursor = [Node]::new()

        if ($this.Length -eq 1) {
            $text += ": <--(" + $this.Data.ToString() + ")"
        }
        elseif ($this.Length -gt 1 -and $this.Length -le 20) { 
            
            $text = "Node ID: " + $this.ID + ", Anchor Data: "  + $this.Data.ToString() + ", Length: " + $($this.size()) + ": <--" 
            $cursor = $this.first()

            while ($null -ne $cursor) {
                $text += "(" + $cursor.Data.ToString() + ")<==>"
                $cursor = $cursor.Next  
            }


        }
        else {
            $text = "Node ID: " + $this.ID + ", Anchor Data: "  + $this.Data.ToString() + ", Length: " + $($this.size()) + ": " 
            $text += "<--(" + $this.first().Data.ToString() + ")<==>" + "...<==>(" + $this.Data.ToString() + ")<==>...<==>(" + $this.last().Data.ToString() + ")"
        }

        $text = $text.TrimEnd("<==>")
        $text += "-->"
        return $text

    } # <--- close toString


    #------------------ Helper Functions -------------------# 
    [string] randomID () {
        [string] $sequence = "N-"
        [int] $characterCount = 4

        for ([int] $index = 0; $index -lt $characterCount; $index++) {
            $sequence += ($global:LETTERS | Get-Random)
        }
        $sequence += "-"

        for ([int] $index = 0; $index -lt $characterCount; $index++) {
            $sequence += Get-Random -Minimum 0 -Maximum 10
        } 
        return $sequence

    } # <--- close randomID


    #------------------ Static Methods -------------------#
    hidden static [Node] random () {

        return [Node]::random(1)

    } # <--- close random


    hidden static [Node] random ([int] $maxNodeSize) {

        [Node] $node = [Node]::new((Get-RandomWord))

        if ($maxNodeSize -gt 1) {
            [int] $number = Get-Random -Minimum 0 -Maximum ($maxNodeSize + 1)
            for ([int] $index = 0; $index -lt $number; $index++) { $node.add([Node]::anyDirection(), [Node]::new((Get-RandomWord))) }
        }
        return $node

    } # <--- close randonLengthNode


    hidden static [Direction] anyDirection () {

        [Direction] $direction = [Direction]::new()
        [int] $outcome = Get-Random -Minimum 1 -Maximum 3
    
        switch ($outcome) {
            1 { $direction = [Direction]::Before }
            2 { $direction = [Direction]::After }
        }
        return $direction

    } # <--- close randomDirection


} # <--- end class Node


#<#---- Start Node testing code
    [Node] $nodeA = [Node]::random(12)
    [Node] $other = [Node]::new()

    "`nNodeA State:`n" + $nodeA.toString() + "`n"

    $global:addition_count = Get-Random -Minimum 0 -Maximum 10  
    "ATTEMPTING TO ADD " + $($global:addition_count) + " SINGLE NODES:"
    "--------------------------------------------------"

    for ([int] $index = 0; $index -lt $global:addition_count; $index++) {
        $other = [Node]::random()
        $global:current_direction = Random-Direction
        
        $nodeA.add($global:current_direction, $other)
        "`tSuccesfully added " + $other.Data.toString() + " " + $global:current_direction.toString() + " " + $nodeA.ID + "'s " + $nodeA.Data.toString()
    }
    "`nNodeA State:`n" + $nodeA.toString() + "`n"

    $global:item_count = Get-Random -Minimum 0 -Maximum 1 
    "`nTESTING FIRST/LAST METHODS ON " + $($global:addition_count) + " VARIABLE LENGTH NODES:"
    "-----------------------------------------------------------------"

    for ([int] $index = 0; $index -lt $global:item_count; $index++) {
        $other = [Node]::random(1)
        "`t" + $other.toString()
        "`t`tFirst Record: " + $other.first().Data.ToString() + ", Last Record: " + $other.last().Data.ToString()
    }


    $global:item_count = Get-Random -Minimum 0 -Maximum 6
    "ATTEMPTING TO ADD " + $($global:item_count) + " VARIABLE LENGTH NODES TO NODE ID " + $nodeA.ID.toString() + "'s VALUE OF " + $nodeA.Data.ToString() 
    "--------------------------------------------------------------------------------------"
    for ([int] $index = 0; $index -lt $global:item_count; $index++) {
        $other = [Node]::random(15)
        $direction = [Node]::anyDirection()

        #"`t" + $($index) + " " + $other.toString() + " will be added " + $direction.ToString() + " " + $nodeA.ID + "'s value of " + $nodeA.Data.ToString()
        $nodeA.add([Node]::anyDirection(), $other)
        #"`t" + $nodeA.toString()
    }
    "`nNode State:`n" + $nodeA.toString() + "`n"

    if ($nodeA.Length -gt 1) {
        [Node] $item = [Node]::new()
        $global:item_count = Get-Random -Minimum 0 -Maximum $nodeA.Length

        "ATTEMPTING TO Remove " + $($global:item_count) + " NODES AROUND ANCHOR NODE " + $nodeA.ID.toString() + "'s VALUE OF " + $nodeA.Data.ToString()
        "--------------------------------------------------------------------------------------"

        for ([int] $index = 0; $index -lt $global:item_count; $index++) {
            $direction = [Node]::anyDirection()
            $item = $nodeA.remove($direction)
    
            #"`t" + $($index) + ": " + $item.Data.ToString() + " deleted " + $direction.ToString() + " " + $nodeA.ID + "'s value of " + $nodeA.Data.ToString()
            #"`t`t" + $nodeA.toString()
        }
    }
    "`nNode State:`n" + $nodeA.toString() 

    "ATTEMPTING TO SPLIT NODES BEFORE ANCHOR NODE " + $nodeA.ID.toString() + "'s VALUE OF " + $nodeA.Data.ToString()
    "--------------------------------------------------------------------------------------"
    $other = $nodeA.split([Direction]::Before)
    "`t Split off nodes:`n " + "`t`t" +$other.ToString()
    "`Node State:`n" + $nodeA.toString() + "`n"


    [Node] $nodeB = [Node]::random(14)
    "NodeB State:`n" + $nodeB.ToString() + "`n"
    "`nATTEMPTING TO JOIN NODEA to NODE B's HEAD"
    "--------------------------------------------------------------------------------------"
    $nodeB.join([TerminatorLocation]::Head, $nodeA)
    "`tNode B State:`n`t" + $nodeB.ToString()

    [Node] $nodeC = [Node]::random(16)
    "NodeC State:`n`t" + $nodeC.ToString()

    [Node] $nodeD = [Node]::random(7)
    "NodeD State:`n`t" + $nodeD.ToString()

    "`nATTEMPTING TO JOIN NODEC to NODE D's TAIL"
    "--------------------------------------------------------------------------------------"
    $nodeD.join([TerminatorLocation]::Tail, $nodeC)
    "`tNode D State:`n`t" + $nodeD.ToString() + "`n"


    "ATTEMPTING TO COPY " + $nodeC.ID + "'s data to nodeE"
    "--------------------------------------------------------------------------------------"
    "`n`tNodeC State:`n`t" + $nodeC.ToString() + "`n"
    [Node] $nodeE = $nodeC.copy()
    "NodeE State:`n" + $nodeE.ToString()

#> #----> End Node Testing Code 


#############################------- Define the LinkedList CLASS -------#############################

class Stack {

    #------------------ Properties  -------------------#
    [string] $ID 
    [Node] $Pointer

    [ValidateRange(0,[int]::MaxValue)]
    [int] $Length

    #------------------ Constructors  -------------------#
    Stack () {}

    Stack ([Node] $node) { $this.init($node) }
    Stack ([psobject] $obj) { $this.init( [Node]::new($obj) ) }

    hidden init ([Node] $node) {

        $this.Pointer = [Node]::new()
        #$this.Items = [Node]::new()

        #$this.Items = $node.first()
        $this.Pointer.add([Direction]::After,  $node.first())
   
        $this.ID = $this.randomID()
        $this.Length = ($node.Length - 1)

    } # <--- close init


    #------------------ Getters  -------------------# 
    [Node] peek () {

        [Node] $node = [Node]::new()
       
        $node = $this.Pointer.Next
        return $node

    } # <--- close peek


    #------------------ Setters  -------------------# 
    [void] push ([psobject] $obj) {

        $this.push([Node]::new($obj))

    } # <--- close add


    [void] push ([Node] $node) {

        if ($null -eq $this.Pointer -or $null -eq $this.Pointer.Next -or $this.Length -eq 0) {
            $this.init($node)
        }

        $this.Pointer.add([Direction]::After, $node.first())
        $this.Length += $node.Length

    } # <--- close add


    [Node] pop () {

        [Node] $placeHolder = [Node]::new()
        [Node] $node = [Node]::new()

        if ($this.Length -lt 1) {
            throw "The " + $this.GetType() + " is already empty.  No items can be removed from an empty stack"
            exit(4347)
        }

        $node = $this.Pointer.remove([Direction]::After)
        $placeHolder = $node.remove([Direction]::After)
        
        $this.Pointer.add([Direction]::After, $placeHolder)
        $this.Length--

        return $node

    } # <--- close pop


    #------------------ Methods -------------------#
    [string] toString () {

        [Node] $node = [Node]::new()
        [Stack] $stack = [Stack]::new()

        [string] $text = "Stack  (ID: " + $this.ID + ", Length: " + ($this.Length) + ") <--"

        Write-Host "" $text 

        $node = $this.Pointer.peek()
        while ($null -ne $node) {
             $stack.push($node)

            Write-Host "node: " $node.ToString()
            $text += "(" + $node.Data.ToString() + ")<=="
            Write-Host "Length: " $this.Length " " $text

            $node = $this.po()
        }

        $node = $stack.peek()
        while ($null -ne $node) {
            $this.push($node)  
            Write-Host "node: " $node.ToString() ", temp stack length: " $($stack.Length) ", this stack length: " $($this.Length)
            $this.push($node)   
        }

        return $text

    } # <--- close toString


    #------------------ Helper Functions -------------------# 
    [string] randomID () {
        [string] $sequence = "S-"
        [int] $characterCount = 4

        for ([int] $index = 0; $index -lt $characterCount; $index++) {
            $sequence += ($global:letters | Get-Random)
        }

        $sequence += "-"

        for ([int] $index = 0; $index -lt $characterCount; $index++) {
            $sequence += Get-Random -Minimum 0 -Maximum 9
        } 

        return $sequence

    } # <--- close randomID


    #------------------ Static Methods -------------------#
    [Stack] random() {

        [int] $size = Get-Random -Minimum 0 -Maximum 50
        [Stack] $stack = [Stack]::new()

        $stack.ID = $stack.randomID()
   
        for ([int] $index = 0; $index -lt $size; $index++) {
            $stack.push([Node]::random())
        }

        return $stack

    } # <--- close random

} # <--- end class Stack