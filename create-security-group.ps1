Import-Module AWSPowerShell.NetCore
$AccessKey  = "access-key"
$SecretKey  = "secret-key"
$Region     = "us-west-1"
$open_port_list = 443, 80, 8443
$restricted_port_list = 3389, 23
$from_restricted_ip ="172.0.0.1/32"
$groupname = "My Access Group"
$vpc_id = "vpc-vpcidnumber"

Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs default
Set-DefaultAWSRegion -Region $Region

$VPCGroupID = New-EC2SecurityGroup -VpcId $vpc_id -GroupName $groupname -GroupDescription "Scripted Acess Group"

$tag = New-Object Amazon.EC2.Model.Tag
$tag.key = "Name"
$tag.Value = $groupname
New-EC2Tag -Resource $VPCGroupID -Tag $tag
$tagb = New-Object Amazon.EC2.Model.Tag
$tagb.key = "Billing"
$tagb.Value = "Infrastructure"
New-EC2Tag -Resource $VPCGroupID -Tag $tagb

foreach ($port in $open_port_list) {
    $port_obj = new-object Amazon.EC2.Model.IpPermission
    $port_obj.IpProtocol = "tcp"    # Protocol can be tcp, udp, icmp or protocol number
    $port_obj.FromPort = $port
    $port_obj.ToPort = $port
    $port_obj.IpRanges.Add("0.0.0.0/0")
    Grant-EC2SecurityGroupIngress -GroupId $VPCGroupID -IpPermissions $port_obj
}
foreach ($port in $restricted_port_list) {
    $port_obj = new-object Amazon.EC2.Model.IpPermission
    $port_obj.IpProtocol = "tcp"
    $port_obj.FromPort = $port
    $port_obj.ToPort = $port
    $port_obj.IpRanges.Add($from_restricted_ip)
    Grant-EC2SecurityGroupIngress -GroupId $VPCGroupID -IpPermissions $port_obj
}