[String []] $global:letters  = @("A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M", "N", "P", "Q", "R", "Z")

function Get-RandomWord () {
    [string] $word = [string]::Empty
    [string] $path = "C:\Dropbox\scripts\datasets\"
    [string []] $files = @("asteroids", "biology", "unique_aeneid_words", "classical")
    
    $path += ($files | Get-Random) + ".txt"
    $word = Get-Content $path | Get-Random

    return $word

} # <--- close randWord


#############################------- Define the Vertex CLASS -------#############################
enum SearchCategory {
    ID = 0; Content = 1
}

enum Visited {
    No = 0; Yes = 1
}


class Vertex {

    #------------------ Properties  -------------------#
    [string] $ID
    [psobject] $Content
    [Visited] $Visited

    [ValidateRange(0, [int]::MaxValue)]
    [int] $MaxDegree

    [ValidateRange(0, [int]::MaxValue)]
    [int] $ActualDegree

    [Vertex []] $Neighbors 

    #------------------ Constructors  -------------------#
    Vertex () {}
    Vertex ([psobject] $obj) { $this.init($obj, 5, $null)}   
    Vertex ([psobject] $obj, [int] $maxEdges) { $this.init($obj, $maxEdges, $null)}
    Vertex ([psobject] $obj, [int] $maxEdges, [vertex []] $vertices) { $this.init($obj, $maxEdges, $vertices)}

    hidden init ([psobject] $obj, [int] $maxEdges, [Vertex []] $vertices) {

        if ($null -eq $obj) {
            throw "A null object was passed as the Content parameter to " + $this.GetType() + "'s non-default constructor"
            exit(884828)
        }

        if ($vertices.Length -gt $maxEdges) { $maxEdges = $vertices.Length }

        $this.ID = $this.randID()
        $this.Visited = [Visited]::No
        $this.MaxDegree = $maxEdges
        $this.ActualDegree = 0
        $this.Content = $obj
        $this.arrayHandler($vertices)

    } # <--- close init


    hidden [void] arrayHandler ([Vertex []] $vertices) {

        if ($vertices.Length -gt $this.MaxDegree) {
            $this.MaxDegree = $vertices.Length
        }

        $this.Neighbors = $this.newArray($this.MaxDegree)
        $this.ActualDegree = 0

        $this.add($vertices)

    } # <--- close arrayHandler


    hidden [Vertex []] newArray ([int] $size) {
        [Vertex []] $array = [Vertex []]::new($size)

        for ([int] $index = 0; $index -lt $array.Length; $index++) {
            $array[$index] = $null
        }
        return $array


    } # <--- close newArray


    [bool] isEmptyVertex () {
        [bool] $empty = $false

        if ($null -eq $this) {
            $empty = $true
        }
        elseif ( $this.noNeighbors() -eq $true -and $null -eq $this.Content -and $null -eq $this.ID) {
            $empty = $true
        }
        else {
            $empty = $false
        }

        return $empty

    } # <--- close emptyVertex


    [bool] noNeighbors () {
        [bool] $empty = $true
        [int] $counter = 0

        while ($counter -lt $this.Neighbors.Length -or $empty -eq $true) {
            if  ($null -ne $this.Neighbors[$counter]) { $empty= $false }
            $counter++    
        }
        return $empty

    } # <--- close noNeighbors


    #------------------ Getters  -------------------# 

    #------------------ Setters  -------------------# 
    hidden [void] setID () {

        $this.ID = $this.rand()

    } # <--- close setID


    [void] add ([Vertex []] $vertices) {
        if ($null -eq $vertices) {
            throw "Cannot add null array to a vertex's neighbors"
        }

        if ($vertices.Length -gt ($this.MaxDegree - $this.ActualDegree) ) {
            throw "The " + $this.GetType() + " " + $this.ID + " has " + $($vertices.Length -gt ($this.MaxDegree - $this.ActualDegree)) + " too few spaces to add all the vertices in the array parameter" 
        }

        foreach ($vertex in $vertices) {
            $this.add($vertex)
        }

    } # <--- close addNeighbors


    [void] add ([psobject] $obj) {

        if ($null -eq $obj) {
            throw "A null object cannot be converted into a neighboring vertex"
            exit(385385)
        }

        if ($this.ActualDegree -eq $this.MaxDegree) {
            throw $this.GetType() + " " + $this.ID + " already has the maximum of " + $($this.MaxDegree) + " neighbors."
            exit(94995)
        }  
        
        [Vertex] $vertex = [Vertex]::new($obj, 0)
        $this.add($vertex)

    } # <--- close add


    [void] add ([Vertex] $vertex) {

        if ($null -eq $vertex) {
            throw "An empty vertex cannot be added to the neigbors"
            exit(385385)
        }

        if ($this.ActualDegree -eq $this.MaxDegree) {
            throw $this.GetType() + " " + $this.ID + " already has the maximum of " + $($this.MaxDegree) + " neighbors."
            exit(94995)
        }
        $this.Neighbors[$this.actualDegree] = $vertex
        $this.ActualDegree++

    } # <--- close add


    [void] remove () {

        if ($this.noNeighbors() -eq $true) { return }

        for ([int] $index = 0; $index -lt $this.ActualDegree; $index++) {
            $this.Neighbors[$index] = $null
            $this.ActualDegree--
        }

    } # <--- close remove


    [void] remove ([int] $neighborLocation) {

        if ($neighborLocation -lt 0) { return }

        for ([int] $index = $neighborLocation; $index -lt $this.ActualDegree; $index++) {
            $this.Neighbors[$index] = $this.Neighbors[$index + 1]
        }

    } # <--- close remove


    [int] locate ([SearchCategory] $category, [string] $targetID, [psobject] $targetObj) {
        [int] $location = -1
        [int] $counter = 0

        if ($category -eq [SearchCategory]::ID) {
            if ($null -ne $targetObj -and $null -eq $targetID) {
                throw "Node.locate() failed.  Atempted to search by ID with null targetID paramter"
                exit(248024)
            }

            while ($counter -lt $this.ActualDegree -and $location -lt 0) {
                if ($this.Neighbors[$counter].ID -eq $targetID) { $location = $counter }
                $counter++  
            }

            if ($location -eq -1 -and $this.ID -eq $targetID) { $location = -200 }
        }

        if ($category -eq [SearchCategory]::Content) {
            if ($null -ne $targetID -and $null -eq $targetObj) {
                throw "Node.locate() failed.  Atempted to search by Content with null targetObj paramter"
                exit(248024)
            }

            while ($counter -lt $this.ActualDegree -and $location -lt 0) {
                if ($this.Neighbors[$counter].Content.Equals($targetObj) ) { $location = $counter}
                $counter++
            }

            if ($location -eq -1 -and $this.Content.Equals($targetObj) ) { $location = -200 }

        }

        return $location

    } # <--- close location


    [vertex] search ([SearchCategory] $category, [string] $targetID, [psobject] $targetObj) {
        [int] $location = $this.locate($category, $targetID, $targetObj)

        [Vertex] $vertex = [Vertex]::new()

        switch ($location) {
            {$_ -eq -1} { $vertex = $null  }
            {$_ -ge 0 -or $_ -lt $this.ActualDegree} { $vertex = $this.Neighbors[$location] }
            {$_ -eq -200} { $vertex = $this }
            {Default} { $vertex = $null}
        }

        return $vertex

    } # <--- close 


    #------------------ Methods -------------------#
    [string] listNeighbors () {
        [string] $text = "["

        if ($this.noNeighbors() -eq $true) {
            $text += ""
        }

        if ($this.ActualDegree -gt 0) {
            $text += $this.Neighbors[0].ID

            if ($this.ActualDegree -eq 1) {
                $text += ""
            }
            elseif ($this.ActualDegree -gt 1 -and $this.ActualDegree -le 4) {
                for ([int] $index = 1; $index -lt $this.ActualDegree; $index++) {
                    $text += $this.Neighbors[$index].ID + ","
                }
                $text = $text.TrimEnd(",")
            }
            else {
                $text += "..," + $this.Neighbors[$this.ActualDegree - 1].ID
            }

        }
        $text = $text.Trim(" ")
        $text += "]"

        return $text

    } # <--- close listNeighbors


    [string] toString () {
        [string] $text = "Vertex: { ID: " + $this.ID + ", "

        $text += "Content: " + $this.Content.ToString() + ", "
        $text += "Max Degree: " + $($this.MaxDegree) + ", "
        $text += "Actual Degrees: " + $($this.getActualDegree()) + ", "
        $text += "Neighbors = " + $this.listNeighbors() + " }"

        return $text

    } # <--- close toString


    [bool] equals ([psobject] $obj) {
        [bool] $isEqual = $false

        if ($obj.GetType() -eq $this.GetType()) {
            [Vertex] $vertex = [Vertex] $obj

            if ($this.Neighbors.Length -eq $vertex.Neighbors) {
                [int] $i = 0
                [int] $j = 0
                [bool] $result = $false

                while ($i -lt $this.Neighbors.Length -and $result -eq $false) {
                    while ($j -lt $vertex.Length -and $result -eq $false) {
                        if ($this.sameID($vertex.ID) -eq $true -and $this.sameContent($vertex.Content) -eq $true) {
                            $result = $true
                        }
                        $j++  
                    }
                    $i++
                }
            }
        }
        return $isEqual

    } # <--- close equal


    [void] clear () {

        $this.Visited = [Visited]::No

        for ([int] $index = 0; $index -lt $this.ActualDegree; $index++) {
            $this.Neighbors[$index].Visted = [Visited]::No
        }


    } # <--- close clear


    [void] randomNeighbors () {

        if ($this.MaxDegree -eq 0) { return }

        [int] $number = Get-Random -Minimum 0 -Maximum $this.MaxDegree

        for ([int] $index = 0; $index -lt $number; $index++) {
            [int] $degree = Get-Random -Minimum 0 -Maximum ($this.MaxDegree + 3)
            [string] $word = Get-Content "C:\Dropbox\scripts\datasets\single_words.txt" | Get-Random

            $this.add( [Vertex]::new($word, $degree) )
        }

    } # <--- close randomNeigbhors
 

    #------------------ Helper Functions -------------------# 
    [string] randID () {

        [int] $letterCount = 3
        [int] $numberCount = 4
        [string] $alphaNumeric = [string]::Empty


        for ([int] $index = 0; $index -lt $letterCount; $index++) {
            $alphaNumeric += ($global:letters | Get-Random)
        }
        $alphaNumeric += "-"

        for ([int] $index = 0; $index -lt $numberCount; $index++) {
            $alphaNumeric += (Get-Random -Minimum 0 -Maximum 9)
        }
        return $alphaNumeric.Trim()

    } # <--- close randID


    [bool] sameID ([vertex] $vertex) {

        return ($this.ID -eq $vertex.ID)

    } # <--- close sameId

    
    hidden [bool] sameContent ([psobject] $obj) {
         [bool] $same = $false

         if ( $this.Content.GetType() -eq $obj.GetType() ) {
             if ($this.Content.Equals($obj)) {
                 $same = $true
             }
         }
         return $same

    } # <--- close sameContent


    [bool] uniqueID ([string] $alphaNumeric) {
        [bool] $result = $true

        if ($this.ID -eq $alphaNumeric) {
            $result = $false
        }
        elseif ($this.Neighbors.ID -contains $alphaNumeric) {
            $result = $false
        }
        else {
            $result = $false
        }
        return $result

    } # <--- uniqueID


    hidden [bool] neighbhorHas ([psobject] $obj) {
        [int] $counter = 0
        [bool] $result = $false

        while ($counter -lt $this.ActualDegree -or $result -eq $true) {
            if ($this.Neighbors[$counter].sameContent($obj) -eq $true) {
                $result = $true
            }
            $counter++
        }
        return $result

    } # <--- close neighborHas


    [bool] containsObject ([psobject] $obj) {
        [bool] $result = $false

        if ($this.sameContent($obj) -eq $true) {
            $result = $true
        }
        elseif ($this.neighbhorHas($obj) -eq $true) {
            $result = $true
        }
        else {
            $result = $false
        }
        return $result

    } # <--- close containsObject

    [bool] isUnique ([Vertex] $vertex) {
        [bool] $result = $true

        return $result

    } # <--- close isUnique

    [void] copy ([Vertex] $vertex) {

        $this.ID = $vertex.ID
        $this.MaxDegree = $vertex.MaxDegree
        $this.Content = $vertex.Content
        $this.arrayHandler($vertex.Neighbors)

    } # <--- close copy
    

    #------------------ Static Methods -------------------#


} # <--- end class Vertex

<#---- Start Vertex testing code

    #[Vertex] $nullSet = [Vertex]::new()
    #$nullSet

    [string] $word = Get-Content "C:\Dropbox\scripts\datasets\asteroids.txt" | Get-Random
    [int] $maxEdges = Get-Random -Minimum 4 -Maximum 15
    [int] $actualDegree = Get-Random -Minimum 0 -Maximum $maxEdges
    [Vertex []] $vertices = @()

    for ([int] $index = 0; $index -lt $actualDegree; $index++) {

        [string] $content = Get-Content "C:\Dropbox\scripts\datasets\biology.txt" | Get-Random
        [int] $degree = Get-Random -Minimum $index -Maximum $actualDegree 
        $vertices += [Vertex]::new($content, $degree, $null)
    }

    [Vertex] $setA = [Vertex]::new($word, $maxEdges, $vertices)
    $setA.Neighbors
    "`n" + $setA.toString() + "`n"


    "`nBuilding and configuring the next vertex: `n"
    $maxEdges = Get-Random -Minimum 4 -Maximum 20
    $actualDegree = Get-Random -Minimum 0 -Maximum $maxEdges
    $word = Get-Content "C:\Dropbox\scripts\datasets\asteroids.txt" | Get-Random

    [Vertex] $setB = [Vertex]::new($word, $maxEdges, $null)


    for ([int] $index = 0; $index -lt $actualDegree; $index++) {
        [string] $content = Get-Content "C:\Dropbox\scripts\datasets\biology.txt" | Get-Random
        [int] $degree = Get-Random -Minimum 0 -Maximum $maxEdges
        [Vertex] $child = [Vertex]::new($content, $degree, $null)
        [Vertex []] $grandChildren = @()

        for ([int] $jndex = 0; $jndex -lt $degree; $jndex++) {
            $grandChildContent = Get-Content "C:\Dropbox\scripts\datasets\greek-names-ancient.txt" | Get-Random
            [int] $grandChildDegree = Get-Random -Minimum 0 -Maximum $degree
            $granchildren += [Vertex]::($grandChildContent, $grandChildDegree, $null)
        }
        $child.addNeighbors($grandChildren)

        $setB.add($child)
    }

    "VertexB: " + $setB.ToString()
    "VertexB children :"
    $setB.Neighbors |  ForEach-Object { "`t" + $_.ToString() }

    [vertex] $vertexC = [Vertex]::new((Get-Content "C:\Dropbox\scripts\datasets\biology.txt" | Get-Random))
    $vertexC.randomNeighbors()
    $vertexC.toString()
    "`n"
    $vertexC.Neighbors | ForEach-Object { $_ }

#> #----> End Vertex Testing Code 


#############################------- Define the Node CLASS -------#############################
enum Direction {
    Before = 1; After = 2
}


function Random-Direction () {
    [int] $outcome = Get-Random -Minimum 1 -Maximum 3

    switch ($outcome) {
        1 { return [Direction]::Before }
        2 { return [Direction]::After }
    }
}


class Node {

    #------------------ Properties  -------------------#
    [string] $ID

    [ValidateNotNullOrEmpty()]
    [psobject] $Data
    [Node] $Next
    [Node] $Previous
    [int] $Length


    #------------------ Constructors  -------------------#
    Node () {}

    Node ([psobject] $obj) {

        if ($obj.getType -eq $this.GetType() ) {
            throw "Node creation failed: attempted to insert a " + $obj.GetType() + " inside Data field of a node"
            exit(2003)
        }

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
            "Before" {  
                [Node] $prior = $this.Previous

                $this.Previous = $node
                $node.Next = $this

                $node.Previous = $prior

                if ($null -ne $prior.Next) { $prior.Next = $node }
            }
            "After" {
                [Node] $consequent = $this.Next

                $this.Next = $node.first()
                $node.first().Previous = $this

                $node.last().Next = $consequent

                if ($null -ne $consequent.Previous) { $consequent.Previous = $node.last() }
            }
        }
        $this.Length++


    } # <--- close add


    [Node] remove ([Direction] $direction) {
        [Node] $item = [Node]::new()

        if ($this.Length -le 1) {
            throw "Cannot remove items from a node of length " + $($this.size()) + ".  There are no removable items in this " + $this.GetType()
            exit(430)
        }

        switch ($direction.ToString()) {
            "Before" { $item = $this.removeBefore() }
            "After" { $item = $this.removeAfter() }
        }
        
        return $item

    } # <--- close remove

    [Node] removeBefore() {
        [Node] $item = [Node]::new()
        [Node] $priorItem = [Node]::new()

        if ($null -eq $this.Previous) {
            throw "Removal before " + $this.GetType() + " failed: There are no items in front of " + $this.GetType() + " ID " + $this.ID + " with " + $this.Data.ToString()
            exit(353)
        }

        $item = $this.Previous
        $priorItem = $item.Previous


        $this.Previous = $null

        if ($null -ne $priorItem) {
            $this.Previous = $priorItem
            $priorItem.Next = $this
        }
        $this.Length--

        $item.Next = $null
        $item.Previous = $null

        return $item

    } # <--- close removeBefore


    [Node] removeAfter() {
        [Node] $item = [Node]::new()
        [Node] $laterItem = [Node]::new()

        if ($null -eq $this.Next) {
            throw "Removal After " + $this.GetType() + " failed: There are no items behind of " + $this.GetType() + " ID " + $this.ID + " with " + $this.Data.ToString()
            exit(353)
        }

        $item = $this.Next
        $laterItem = $item.Next

        $this.Next = $null

        if ($null -ne $laterItem) {
            $this.Next = $laterItem
            $laterItem.Previous = $this
        }
        $this.Length--

        $item.Next = $null
        $item.Previous = $null

        return $item

    } # <--- close removeAfter

    #------------------ Methods -------------------#
    [Node] copy () {
        [Node] $cursor = [Node]::new()
        $cursor = $this.first()

        [Node] $node = [Node]::new($cursor.Data)
        Write-Host "`tInitialized copy with " $cursor.Data

        while ($null -ne $cursor.Next) {
            $cursor = $cursor.Next
            Write-Host "`t copying " + $cursor.Data
            $node.add([Direction]::After, $cursor.Data)      
            
            "`tCurrent copy progress: " + $node.ToString()
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
    static [Node] random () {
        [Node] $node = [Node]::new((Get-RandomWord))
        $node.ID = $node.randomID()
        return $node

    } # <--- close random


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