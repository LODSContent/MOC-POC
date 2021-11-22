# This script creates a Network Security Group that restricts RDP access to Azure VMs from the public IP addresses
# used for outbound Internet access from the Skillable datacenters. You should not change the $publicIPs variable,
# unless you want to specify a different range of IP addresses for allowable RDP access, for example, your 
# host computer. 

# Please change the $RGName and $VnetName variables as appropriate for your lab environment. 

# Please note that the this script associates the NSG with only the first subnet defined in the virtual network. If you
# have more than one subnet, please modify the script as appropriate. 

#Define general variables
$NSGName = 'RDP-NSG'
$RGName = 'az140-11-RG' #Change this value, if appropriate
$Loc = (Get-AzResourceGroup -name $RGName).Location
$publicIPs = '103.18.85.0/24','104.214.106.0/25','163.47.101.0/25','185.254.59.0/24','206.196.30.0/26'
$VnetName = 'az140-adds-vnet11' #Change this value, if appropriate
$Vnet = Get-AzVirtualNetwork -ResourceGroupName $RGName -Name $VnetName

#Define parameters for Network Security Group (NSG) cmdlet
$NSGparams = @{
    'Name' = $NSGName
    'ResourceGroupName' = $RGName
    'Location' = $Loc
}

#Create NSG using defined parameters
$NSG = New-AzNetworkSecurityGroup @NSGparams


#Define paramters for NSG rule cmdlet to allow RDP access only from specific hosts on the Internet
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



#Use the 1st subnet defined in the VNet
$SubnetParams = @{
    'VirtualNetwork'        = $Vnet
    'Name'                  = ($Vnet.Subnets[0]).Name
    'AddressPrefix'         = ($Vnet.Subnets[0]).AddressPrefix
    'NetworkSecurityGroup' = $NSG
}

# Associate the NSG with the subnet 

Set-AzVirtualNetworkSubnetConfig @SubnetParams
Set-AzVirtualNetwork -VirtualNetwork $Vnet
