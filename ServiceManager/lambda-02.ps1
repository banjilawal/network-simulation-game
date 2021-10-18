class BinaryTree {
    [string] $Name
    [int] $Capacity
    [int] $Size
    [string []] $Vertices

    BinaryTree () {}

    BinaryTree ([string] $name, [string []] $items) {
        $this.Capacity = 128

        if ($items.Length -gt $this.Capacity) {
            throw "The number of items in the list exceeds " + $($this.Capacity) + " organizational units"
        }

        $this.Name = $name
        $this.Size = $items.Length
        $this.Vertices = [string[]]::new($this.Capacity)

        $this.convertArray($items)

    } # <--- close BinaryTree


    [void] convertArray ([string []] $items) {

        if ($this.noDuplicates($items) -eq $false) {
            throw "This array cannot be converted to a tree.  It contains duplicate items"
            exit(123400)
        }

        $this.Vertices[0] = $items[0]
        #write-host "level " $(0) ": " $this.Vertices[0] "`r"
        for ([int] $index = 0; $index -lt $items.Length; $index++) {
            [int] $left = (2 * $index) + 1
            [int] $right = (2 * $index) + 2

            $this.Vertices[$left] = $items[$left]
            $this.Vertices[$right] = $items[$right]

           # write-host "level " $($index + 1) ": " $this.Vertices[$left] "`t" $this.Vertices[$right] 
        }

    } # <--- close convertArray


    [void] add ([string] $node) {

    } # <--- close add


    [void] add ([string] $parent, [string] $child) {

    } # <--- close add


    [int] location ([string] $target) {
        [int] $location = $null

        if ($this.NodeList -contains $target) {
            $location = $this.Vertices.IndexOf($target)
        }
        return $location

    } # <--- close traverse


    [string] display () {
        [string] $text = "Tree Name: " + $this.Name + " Size:  " + $($this.Size) + " " + $this.Vertices.GetType() + "`n"

        <#
        $text += "`t`t`t" + $($this.Verices[0])
        for ([int] $index = 0; $index -lt $this.Size; $index++) {
            [int] $left = (2 * $index) + 1
            [int] $right = (2 * $index) + 2    
            
            $text += "`t`t`t" + $($this.Vertices[$left]) + "`t" + $($this.Vertices[$right])
        }
        #>
        return $text

    } # <--- close display


    hidden [bool] noDuplicates ([string []] $items) {
        [int] $index = 0
        [bool] $noDuplicates = $true
 
        [hashtable] $map = $this.frequencyMapper($items)

        while ($index -lt $map.Count -and $noDuplicates -eq $true) {
            if ($map[$index].Values -gt 1) {
                $noDuplicates = $false
            }
            $index++
        }
        return $noDuplicates

    } # <--- close noDuplicates


    hidden [bool] noDuplicates ([string] $target) {
        [bool] $duplicate = $false
        [hashtable] $map = $this.frequencyMapper()

        if ( ($map.Keys -contains $target) -and ($map.$target -gt 0) ) {
            $duplicate = $true
        }

        return $duplicate

    } # <--- close noDuplicates


    hidden [hashtable] frequencyMapper ([string []] $items) {
        [hashtable] $map = @{}

        foreach ($item in $items) {
            [int] $frequency = $this.countOccurences($item)
            $map.Add($item, $frequency)
        }
        return $map

    } # <--- close frequencyMapper  


    hidden [hashtable] frequencyMapper () {
        [hashtable] $map = @{}

        foreach ($node in $this.NodeList) {
            [int] $frequency = $this.countOccurences($node)
            $map.Add($node, $frequency)
        }
        return $map

    } # <--- close frequencyMapper


    hidden [int] countOccurences ([string] $target) {
        [int] $occurences = 0

        foreach ($node in $this.NodeList) {
            if ($node -eq $target) {
                $occurences++
            }
        }

        return $occurences

    } # <--- close countOccurences


} # <--- end class BinaryTree

[string []] $departments = @("human resources", "marketing", "finance", "research & development", "sales")
$departments += @("admin", "management", "it", "sysadmin", "support", "print", "web", "accounting", "invoices", "payable", "payroll")

[string] $name = [string] $name = Get-Content "C:\Dropbox\scripts\datasets\classical\classical" | Get-Random

#[BinaryTree] $tree = [BinaryTree]::new()
#$tree

$tree = [BinaryTree]::new($name, $departments)
$tree.display()
#$departments
#$tree.display()