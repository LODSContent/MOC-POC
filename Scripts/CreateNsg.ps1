# This script creates a Network Security Group that restricts RDP access to Azure VMs from the public IP addresses
# used for outbound Internet access from the Skillable datacenters. You should not change the $publicIPs variable,
# unless you want to specify a different range of IP addresses for allowable RDP access, for example, your 
# host computer. 

# This script requires that you will need to supply values for the resource group and virtual network name. 

# Please note that this script associates the NSG with all the subnets defined in the virtual network. If
# you will be creating more than one subnet, you may wish to run this script after you have created all 
# the subnets in the virtual network.

# The easiest way to deploy this script is to upload it to an Azure CloudShell window and then run it
# by using the command .\CreateNsg.ps1 -RGname <ResourceGroupName> -VnetName <Virtual Network Name>

#Define script inputs and variables
Param(
    [Parameter(Mandatory=$true,HelpMessage="The resource group name")][string]$RGName,
    [Parameter(Mandatory=$true,HelpMessage="The virtual network name")][string]$VnetName
)
$NSGName = 'RDP-NSG'
$Loc = (Get-AzResourceGroup -name $RGName).Location
$publicIPs = '103.18.85.0/24','104.214.106.0/25','163.47.101.0/25','185.254.59.0/24','206.196.30.0/26'
$Vnet = Get-AzVirtualNetwork -ResourceGroupName $RGName -Name $VnetName

#Define and splat parameters for Network Security Group (NSG) cmdlet
$NSGparams = @{
    'Name' = $NSGName
    'ResourceGroupName' = $RGName
    'Location' = $Loc
}

#Create NSG using defined parameters
$NSG = New-AzNetworkSecurityGroup @NSGparams


#Define and splat paramters for NSG rule cmdlet to allow RDP access only from specific hosts on the Internet
$NSGRuleParams = @{
    'Name'                      = 'restrictRDP'
    'NetworkSecurityGroup'      = $NSG
    'Protocol'                  = 'TCP'
    'Direction'                 = 'Inbound'
    'Priority'                  = 1000
    'SourceAddressPrefix'       = $publicIPs
    'SourcePortRange'           = '*'
    'DestinationAddressPrefix'  = '*'
    'DestinationPortRange'      = 3389
    'Access'                    = 'Allow'
}

#Configure the rule

Add-AzNetworkSecurityRuleConfig @NSGRuleParams | Set-AzNetworkSecurityGroup

# Get the array of available subnets in the virtual network

$subnets = $Vnet.subnets

# Associate each subnet found in the array to the Network Security Group

foreach ($subnet in $subnets)
    {
        Set-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $Vnet -Name $subnet.Name -AddressPrefix $subnet.AddressPrefix -NetworkSecurityGroup $NSG
    }

# Commit the changes to the virtual network

Set-AzVirtualNetwork -VirtualNetwork $Vnet
