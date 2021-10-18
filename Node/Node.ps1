
Set-PSDebug -Strict
Set-StrictMode -Version Latest

### ------------------> Global Variables and constants <------------------ 
[String []] $global:letters  = @("A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M", "N", "P", "Q", "R", "Z")


### ------------------> Enums <------------------
enum Direction {
    Before = 1; After = 2
}


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
    Node () {

        $this.ID = $null
        $this.Data = $null
        $this.Next = $null
        $this.Previous = $null
        $this.Length = 0

    } # <--- close Node

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
        $precedent = $this.Previous

        if ($node.Length -eq 1) {
            $node.Previous = $precedent
            $node.Next = $this
            $this.Previous = $node
    
            if ($null -ne $precedent) { $precedent.Next = $node }
            $this.Length++
        }
        else {
            $node.first().Previous = $precedent
            $node.last().Next = $this
            $this.Previous = $node.last()
        
            if ($null -ne $precedent) { $precedent.Next = $node.first() }
            $this.Length += $node.Length
        }


    } # <--- close addBefore


    [void] addAfter ([Node] $node) {

        [Node] $consequent = [Node]::new()
        $consequent = $this.Next

        if ($node.Length -eq 1) {
            $node.Next = $consequent
            $node.Previous = $this
            $this.Next = $node

            if ($null -ne $consequent) { $consequent.Previous = $node }
            $this.Length++
        }
        else {
            $node.last().Next = $consequent
            $node.first().Previous = $this
            $this.Next = $node.first()

            if ($null -ne $consequent) { $consequent.Previous = $node.last() }
            $this.Length += $node.Length
        }

    } # <--- close addAfter


    [Node] remove ([Direction] $direction) {

        [Node] $node= [Node]::new()

        if ($this.Length -le 1) {
            throw "Cannot remove items from a node of length " + $($this.size()) + ".  There are no removable items in this " + $this.GetType()
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
            throw "Removal before " + $this.GetType() + " failed: There are no items in front of " + $this.GetType() + " ID " + $this.ID + " with " + $this.Data.ToString()
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
            throw "Removal After " + $this.GetType() + " failed: There are no items behind of " + $this.GetType() + " ID " + $this.ID + " with " + $this.Data.ToString()
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

        $cursor = $this.first()

        while ($null -ne $cursor) {
            $text += "(" + $cursor.Data.ToString() + ")<==>"
            $cursor = $cursor.Next  
        }
        $text = $text.TrimEnd("<==>")
        return $text

    } # <--- close toString


    #------------------ Helper Functions -------------------# 
    [string] randomID () {
        [string] $sequence = "N-"
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
    hidden static [Node] random () {
        [Node] $node = [Node]::new((Get-RandomWord))
        $node.ID = $node.randomID()
        return $node

    } # <--- close random


    hidden static [Direction] randomDirection () {

        [Direction] $direction = [Direction]::new()
        [int] $outcome = Get-Random -Minimum 1 -Maximum 3
    
        switch ($outcome) {
            1 { $direction = [Direction]::Before }
            2 { $direction = [Direction]::After }
        }
        return $direction

    } # <--- close randomDirection


} # <--- end class Node


<#---- Start Node testing code

    [int] $removalCount = 0
    [int] $additionCount = Get-Random -Minimum 0 -Maximum 20

    [Direction] $direction = [Direction]::new()
    [Node] $nodeA = [Node]::random()
    
    "`nInitial Node State: `n" + $nodeA.ToString() 

    for ([int] $index = 0; $index -lt $additionCount; $index++) {
        [Node] $other = [Node]::random()
        $direction = Random-Direction
        #"adding " + $other.Data.ToString() + " " + $direction.ToString() + " " + $node.ID
        $nodeA.add($direction, $other)
    }
    #$node.first().Data.toString()
    #$node.last().Data.toString()
    "`nCurrent State After " + $($additionCount) + " Additions: `n" + $nodeA.ToString() + "`n"
    
    if ($nodeA.Length -gt 1) {

        $removalCount = Get-Random -Minimum 0 -Maximum $nodeA.Length
        "ATTEMPTING " + $($removalCount) + " REMOVALS: "

        for ([int] $index = 0; $index -lt $removalCount; $index++) {
            $direction = Random-Direction
            [Node] $other = $nodeA.remove($direction)
            #"`tRemoving " + $other.Data.ToString() + " " + $direction.ToString() + " " + $nodeA.ID + "'s " + $nodeA.Data.ToString()
            #"`t" + $node.ToString()
        }
    }
    #$node
    "`nFinal Node State after " + $($removalCount) + " Removals: `n" + $nodeA.ToString() + "`n"


    [Node] $nodeB = [Node]::new()
    $nodeB.ID = $nodeB.randomID()
    "ATTEMPTING TO COPY " + $nodeA.ID + "'s data to " + $nodeb.ID
    $nodeB = $nodeA.copy()
    #$nodeB
    $nodeB.ToString()

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

[Stack] $stackA = [Stack]::new([Node]::random())
$stackA


[Node] $node = [Node]::random()
for ($i = 0; $i -lt 6; $i++) {
    $node.add([Direction]::Before, [Node]::random())
}
$stackA.push($node)
$stackA
#$stackA.Pointer.Next.ToString()


<# ---- Start LinkedList testing code
    [int] $removalCount = 0
    [int] $additionCount = Get-Random -Minimum 0 -Maximum 25

    [Stack] $stackA = [Stack]::new( [Node]::random() )
    $stackA
    "Initail State: `n" + $stackA.Pointer.Next.ToString() + "`n"

    "ATTEMPTING TO PUSH " + $($additionCount) + " ITEMS:"

    for ([int] $index = 0; $index -lt $additionCount; $index++) {
        $stackA.push([Node]::random())
    }
    $stackA.Pointer.Next.ToString() + "`n"
    

    if ($stackA.Length -gt 1) {

        $removalCount = Get-Random -Minimum 1 -Maximum $stackA.Length
        "ATTEMPTING REMOVAL OF " + $($removalCount) + " ITEMS"

        for ([int] $index = 0; $index -lt $stackA.Length; $index++) {
            [Node] $item = $stackA.pop()
            $item.ToString() + " popped stck size = " +  $($stackA.Length)
        }
    }
   "`n" + $stackA.Pointer.Next.ToString() + "`n"
   #"`nCurrent State: `n" + 
   #"`n" + $stackA.toString() + "`n"

#> #----> End LinkedList Testing Code 


#############################------- Define the Queue CLASS -------#############################
class Queue  {

    #------------------ Properties  -------------------#
    [string] $ID

    [ValidateNotNullOrEmpty()] 
    [Node] $Front
    [Node] $Tail

    [int] $Length
    
    #------------------ Constructors  -------------------#
    Queue () {}

    Queue ([psobject] $obj) {

        $this.Front = [Node]::new($obj)
        $this.Tail = [Node]::new()
        $this.ID = $this.randomID()

        $this.Tail.Previous = $this.Front
        $this.Front.Next = $this.Tail
        $this.Length++

    } # <--- close Queue


    #------------------ Getters  -------------------# 
    [Node] peek () {

        [Node] $node = [Node]::new()
        $node = $this.Front

        return $node

    } # <--- close peek


    [Node] last () {
        [Node] $node = [Node]::new()

        if ($this.Length -gt 0) {
            $node = $this.Tail.Previous
        }

        return $node

    } # <--- close last


    #------------------ Setters  -------------------# 
    [Node] remove () {
        [Node] $node = [Node]::new()

        if ($this.Length -gt 0) {
            $node = $this.Front
            $this.Front = $node.Next
            $this.Length--

            $node.Next = $null
            $node.Previous = $null
        }
        return $node

    } # <--- close remove


    [void] add ([psobject] $obj) {
        $this.add([Node]::new($obj))

    } # <--- close enqueue


    [void] add ([Node] $node) {

        [Node] $prior = [Node]::new()

        if ($this.Length -eq 0) {
            $this.Front = [Node]::new()
            $this.Tail = [Node]::new()

            $this.Front = $node
            $this.Front.Next = $this.Tail
        }
        else {
            $prior = $this.last()
            Write-Host "prior: " $prior.toString()
    
            $prior.Next = $node
            $node.Previous = $prior
            $node.Next = $this.Tail
    
            $this.Tail.Previous = $node
        }
        $this.Length++

    } # <--- close add


    #------------------ Methods -------------------#
    [string] toString () {
        [string] $text = "Queue  (ID: " + $this.ID + ", Length: " + ($this.Length) + ") "
        
        [Queue] $queue = [Queue]::new()
        [Node] $node = [Node]::new()


        while ($this.Length -gt 0) {
            $node = $this.remove()
            $queue.add($node)

            $text += "<==(" + $node.toString() + ")"
        }

        while ($queue.Length -gt 0) {
            $this.add($queue.remove())
        }

        return $text

    } # <--- close toString
 
    #------------------ Helper Functions -------------------# 
    [string] randomID () {
        [string] $sequence = "Q-"
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


} # <--- end class Queue


<# ---- Start Queue testing code
[int] $removalCount = 0
[int] $additionCount = Get-Random -Minimum 0 -Maximum 25

[Queue] $queue = [Queue]::new([Node]::random() )
"Initail State: `n" + $queue.ToString() + "`n"
$queue.Front
$queue.Tail
<#
for ([int] $index = 0; $index -lt $additionCount; $index++) {
    #[Node] $node = [Node]::random()
    #Write-Host "index: " $index " Node ID: " $node.ID " Node Data: " $node.Data.ToString() 
    $queue.add([Node]::random())
    #"Current HEad: " + $queue.Head.Next.Data.toString()
}
"State After " + $($additionCount) + " Additions: `n" + $queue.ToString() + "`n"

# "`nfirst Node: " + $queue.Head.Next.toString() + ", Last Node: " + $queue.Tail.Previous.toString() + "`n`n"
# $queue

if ($queue.Length -gt 1) {

    $removalCount = Get-Random -Minimum 1 -Maximum $queue.Length

    for ([int] $index = 0; $index -lt $removalCount; $index++) {
        #"Current Head: " + $queue.Head.Next.Data.toString()
        [Node] $node = $queue.remove()
        "`tprocessing " + $node.toString()
    }
}
"State after " + $($removalCount) + " Removals: `n" + $queue.ToString() + "`n"
$queue
#>

#> #----> End Queue Testing Code 


#############################------- Define the Graph CLASS -------#############################
class Graph {

    #------------------ Properties  -------------------#
    [string] $Name

    [ValidateRange(0, [int]::MaxValue)]
    [int] $Height

    [ValidateRange(0, [int]::MaxValue)]
    [int] $MaxDegree

    [Vertex] $Map

    #------------------ Constructors  -------------------#
    Graph () {}
    Graph ([string] $name) { $this.init($name, $null, 5, 5) }
    Graph ([string] $name, [int] $height) { $this.init($name, $null, $height, $height) }
    Graph ([string] $name, [Vertex] $root, [int] $height) { $this.inig($name, $root, $root.MaxDegree, $height) }

    hidden init ([string] $name, [Vertex] $root, [int] $neighborDensity, [int] $height) {

        $this.Name = $name
        $this.MaxDegree = $neighborDensity
        $this.Height = $height
        $this.Map = $this.rootHandler($root)

        $this.populate($this.Map, $this.Height)
        #Write-Host "root node: " $this.Map.ToString()

    } # <--- close init


    #------------------ Getters  -------------------# 

    #------------------ Setters  -------------------# 

    #------------------ Methods -------------------#
    [void] traverse() {

    } # <--- close traverse

    [void] populate ([Vertex] $vertex, [int] $depth) {
        
        if ($vertex.ActualDegree -eq 0 -and $vertex.MaxDegree -gt 0) { 
            $vertex.randomNeighbors() 
        }


        if ($depth -gt 0) {
            foreach ($neighbor in $vertex.Neighbors) {
                $this.populate($neighbor, ($depth - 1))
            }
        }

        if ($depth -eq 0) {
            if ($vertex.MaxDegree -gt 0) {
                [int] $childCount = Get-Random -Minimum 0 -Maximum $vertex.MaxDegree

                for ([int] $index = 0; $index -lt $childCount; $index++) {
                    $vertex.add( [Vertex]::new( ($this.randWord()), 0) )
                }
            }
        }

    } # <--- close populate
 
    #------------------ Helper Functions -------------------# 
    hidden [Vertex] rootHandler ([Vertex] $vertex) {
        [Vertex] $root = [Vertex]::new()
        $root = $vertex
        
        if ($null -eq $root) {
            $root = [Vertex]::new(($this.randWord()), $this.MaxDegree)
        }
       # Write-Host "root: " $root 

        $root.randomNeighbors()
        return $root

    } # <--- close rootHandler


    hidden [string] randWord () {
        [string] $word = [string]::Empty
        [string] $path = "C:\Dropbox\scripts\datasets\"
        [string []] $files = @("asteroids", "biology", "unique_aeneid_words", "classical")
        
        $path += ($files | Get-Random) + ".txt"
        $word = Get-Content $path | Get-Random

        return $word

    } # <--- close randWord
    

    #------------------ Static Methods -------------------#


} # <--- end class Graph

<#---- Start Graph testing code
    [string] $name = Get-Content "C:\Dropbox\scripts\datasets\cities.txt" | Get-Random
    [Graph] $graph = [Graph]::new($name)
    "Graph " + $graph.Name + ": `n" 
    $graph
    
    "`n " + $graph.Name + " Map Info: `n" 
    $graph.Map.toString()    

    "`n" 
    $graph.Map.Neighbors | ForEach-Object { Write-Host "ID: " $_.ID ", Content: " $_.Content ", Max Degree: " $_.MaxDegree ", Actual Degree: " $_.ActualDegree; $_.Neighbors | ForEach-Object {$_}}
    #[Graph] $graph = [Graph]::new()
    #$graph.randWord()
#> #----> End Graph Testing Code 