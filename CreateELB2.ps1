
$instance = 'i-idnumber'
$sn1 = 'subnet-id1'
$sn2 = 'subnet-id2'
$sgid = 'sg-groupid'
$vpcid = 'vpc-vpcid'

$lb2 = New-ELB2LoadBalancer -Name 'TTS-LB-01' -Scheme 'internet-facing' -Subnet @($sn1, $sn2) -SecurityGroup @($sgid)
$tg1 = New-ELB2TargetGroup -Name 'TTS-LB-TG-01' -Protocol HTTP -Port 80 -VpcId $VpcId

$lbAction = New-Object -TypeName 'Amazon.ElasticLoadBalancingV2.Model.Action'
$lbAction.TargetGroupArn = $tg1.TargetGroupArn
$lbAction.Type = 'forward'

$lbcert = New-Object -TypeName 'Amazon.ElasticLoadBalancingV2.Model.Certificate'
$lbcert.CertificateArn = 'arn:aws:acm:us-west-1:acctno:certificate/certificateid'

New-ELB2Listener -LoadBalancerArn $lb2.LoadBalancerArn -Port 443 -Protocol HTTPS -DefaultAction @($lbAction) -Certificate @($lbcert)

$lbinstance1 = New-Object -TypeName 'Amazon.ElasticLoadBalancingV2.Model.TargetDescription'
$lbinstance1.Id = $instance
$lbinstance1.Port = 80

Register-ELB2Target -TargetGroupArn $tg1.TargetGroupArn -Target @($lbinstance1)
