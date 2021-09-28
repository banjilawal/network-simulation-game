class BinaryTree {
    [int] $Capacity
    [string []] $NodeList

    BinaryTree () {}

    BinaryTree ([string []] $items) {
        $this.Capacity = 1024

        if ($items.Length -gt $this.Capacity) {
            throw "The number of items in the list exceeds " + $($this.Capacity) + " organizational units"
        }

        $this.NodeList = $this.arrayToBinaryTree($items)

    } # <--- close BinaryTree


    [string []] arrayToBinaryTree ([string []] $items) {
        [string []] $tree = [int[]]::new($this.Capacity)

        if ($this.noDuplicates($items) -eq $true) {

        }





        return $tree

    } # <--- close makeTree


    [void] add ([string] $node) {

    } # <--- close add


    [void] add ([string] $parent, [string] $child) {

    } # <--- close add


    [int] location ([string] $target) {
        [int] $location = $null

        if ($this.NodeList -contains $target) {
            $location = $this.NodeList.IndexOf($target)
        }
        return $location

    } # <--- close traverse


    hidden [bool] noDuplicates ([string []] $items) {
        [int] $index = 0
        [bool] $duplicates = $false
 
        [hashtable] $map = $this.frequencyMapper($items)

        while ($index -lt $map.Count -and $duplicates -eq $false) {
            if ($map[$index].Values -gt 1) {
                $duplicates = $true
            }
            $index++
        }
        return $duplicates

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