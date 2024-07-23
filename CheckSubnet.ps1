
# Recommended by Azure architect blog: https://blogs.technet.microsoft.com/rspitz/2018/03/02/powershell-script-to-determine-if-an-ip-range-is-part-of-the-azure-datacenter-ip-range/
# The checkSubnet function will check ip to ip, ip to subnet, subnet to ip or subnet to subnet belong to each other and return true or false and the direction of the check

function CheckNetworkToSubnet ([uint32]$un2, [uint32]$ma2, [uint32]$un1) {
    $ReturnArray = "" | Select-Object -Property Condition, Direction
 
    if ($un2 -eq ($ma2 -band $un1)) {
        $ReturnArray.Condition = $True
        $ReturnArray.Direction = "Addr1ToAddr2"
        return $ReturnArray
    }
    else {
        $ReturnArray.Condition = $False
        $ReturnArray.Direction = "Addr1ToAddr2"
        return $ReturnArray
    }
}

function CheckSubnetToNetwork ([uint32]$un1, [uint32]$ma1, [uint32]$un2) {
    $ReturnArray = "" | Select-Object -Property Condition, Direction
 
    if ($un1 -eq ($ma1 -band $un2)) {
        $ReturnArray.Condition = $True
        $ReturnArray.Direction = "Addr2ToAddr1"
        return $ReturnArray
    }
    else {
        $ReturnArray.Condition = $False
        $ReturnArray.Direction = "Addr2ToAddr1"
        return $ReturnArray
    }
}

function CheckNetworkToNetwork ([uint32]$un1, [uint32]$un2) {
    $ReturnArray = "" | Select-Object -Property Condition, Direction
 
    if ($un1 -eq $un2) {
        $ReturnArray.Condition = $True
        $ReturnArray.Direction = "Addr1ToAddr2"
        return $ReturnArray
    }
    else {
        $ReturnArray.Condition = $False
        $ReturnArray.Direction = "Addr1ToAddr2"
        return $ReturnArray
    }
}

function SubToBinary ([int]$sub) {
    return ((-bnot [uint32]0) -shl (32 - $sub))
}

function NetworkToBinary ($network) {
    $a = [uint32[]]$network.split('.')
    return ($a[0] -shl 24) + ($a[1] -shl 16) + ($a[2] -shl 8) + $a[3]
}


function checkSubnet ([string]$addr1, [string]$addr2) {
    # Separate the network address and lenght
    $network1, [int]$subnetlen1 = $addr1.Split('/')
    $network2, [int]$subnetlen2 = $addr2.Split('/')

    #Convert network address to binary
    [uint32] $unetwork1 = NetworkToBinary $network1 
    [uint32] $unetwork2 = NetworkToBinary $network2

    #Check if subnet length exists and is less then 32(/32 is host, single ip so no calculation needed) if so convert to binary
    if ($subnetlen1 -lt 32) {
        [uint32] $mask1 = SubToBinary $subnetlen1
    }
 
    if ($subnetlen2 -lt 32) {
        [uint32] $mask2 = SubToBinary $subnetlen2
    }

    #Compare the results
    if ($mask1 -and $mask2) {
        # If both inputs are subnets check which is smaller and check if it belongs in the larger one
        if ($mask1 -lt $mask2) {
            return CheckSubnetToNetwork $unetwork1 $mask1 $unetwork2
        }
        else {
            return CheckNetworkToSubnet $unetwork2 $mask2 $unetwork1
        }
    }
    elseIf ($mask1) {
        # If second input is address and first input is subnet check if it belongs
        return CheckSubnetToNetwork $unetwork1 $mask1 $unetwork2
    }
    elseIf ($mask2) {
        # If first input is address and second input is subnet check if it belongs
        return CheckNetworkToSubnet $unetwork2 $mask2 $unetwork1
    }
    else {
        # If both inputs are ip check if they match
        # Added 'return' statement as this appears to have been a typo in the original
        return CheckNetworkToNetwork $unetwork1 $unetwork2
    }
}
