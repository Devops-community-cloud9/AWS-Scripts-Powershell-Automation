Import-Module AWSPowerShell.NetCore
$AccessKey  = "access key"
$SecretKey  = "secret key"
$Region     = "us-west-1"
$Sgid       = "sg-address"
$snid       = "subnet-address"
$InstanceID = "i-6ff58765gfgf"
$LoadBalancerName   = $InstanceID+"ELB"
$BillingKey         = "Infrastructure"
        

Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs default
Set-DefaultAWSRegion -Region $Region
           
#Create Load Balancer
$listening_obj = new-object Amazon.ElasticLoadBalancing.Model.Listener
$listening_obj.Protocol = "http"
$listening_obj.LoadBalancerPort = 80
$listening_obj.InstancePort = 8088

New-ELBLoadBalancer -Listener $listening_obj -LoadBalancerName $LoadBalancerName -Subnet $snid -SecurityGroup $sgid

$elbtag = New-Object Amazon.ElasticLoadBalancing.Model.Tag
$elbtag.Key = "Billing"
$elbtag.Value = $BillingKey
Add-ELBResourceTag -LoadBalancerName $LoadBalancerName -Tag $elbtag

Write-Output "Set http Listening Ports Access"
$lb_port_list = ((5000,5000),(5001,5001))
foreach ($port in $lb_port_list) {
    $listening_obj = new-object Amazon.ElasticLoadBalancing.Model.Listener
    $listening_obj.Protocol = "HTTP"
    $listening_obj.LoadBalancerPort = $port[0]
    $listening_obj.InstancePort = $port[1]
    New-ELBLoadBalancerListener -LoadBalancerName $LoadBalancerName -Listener $listening_obj
}
$lb_port_list = ((8088,8088),(8443,8088),(9443,9088),(7443,7088))
foreach ($port in $lb_port_list) {
    $listening_obj = new-object Amazon.ElasticLoadBalancing.Model.Listener
    $listening_obj.Protocol = "HTTPS"
    $listening_obj.LoadBalancerPort = $port[0]
    $listening_obj.InstancePort = $port[1]
    $listening_obj.InstanceProtocol = "HTTP"
    $listening_obj.SSLCertificateId = $aws_settings.CertARN
    New-ELBLoadBalancerListener -LoadBalancerName $LoadBalancerName -Listener $listening_obj
}

Register-ELBInstanceWithLoadBalancer -LoadBalancerName $LoadBalancerName -Instance $instanceID

Set-ELBHealthCheck -LoadBalancerName $LoadBalancerName -HealthCheck_Target "http:80/ping"
