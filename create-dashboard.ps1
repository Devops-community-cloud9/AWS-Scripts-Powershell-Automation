Import-Module AWSPowerShell.NetCore
$AccessKey  = "access key"
$SecretKey  = "secret key"
$accountno  = "aws-account-number"
$Region     = "us-west-1"
$systems    = @("system-name1","system-name2")
$dashname   = 'DashBoardName'   #No Spaces or special characters

Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs default
Set-DefaultAWSRegion -Region $Region 

# This presumes that you have named your alarms in AWS by SYSTEMNAME-MONITOR 

$dash_start = '{"widgets":['
$dash_end   = ']}'
$dash_body  = ''

foreach ($ec2 in $systems) {

    $dash_body = $dash_body + '{"type":"metric","width":12,"height":4,"properties":{"title":"'+$ec2.name+'-CPU","annotations":{"alarms":["arn:aws:cloudwatch:'+$aws_settings.Region+':'+$accountno+':alarm:'+$ec2.name+'-CPU"]},"view":"timeSeries","stacked":false}},'
    $dash_body = $dash_body + '{"type":"metric","width":12,"height":4,"properties":{"title":"'+$ec2.name+'-Disk","annotations":{"alarms":["arn:aws:cloudwatch:'+$aws_settings.Region+':'+$accountno+':alarm:'+$ec2.name+'-Disk"]},"view":"timeSeries","stacked":false}},'
    $dash_body = $dash_body + '{"type":"metric","width":12,"height":4,"properties":{"title":"'+$ec2.name+'-Memory","annotations":{"alarms":["arn:aws:cloudwatch:'+$aws_settings.Region+':'+$accountno+':alarm:'+$ec2.name+'-Memory"]},"view":"timeSeries","stacked":false}},'
    $dash_body = $dash_body + '{"type":"metric","width":12,"height":4,"properties":{"title":"'+$ec2.name+'-NETWORK-IN","annotations":{"alarms":["arn:aws:cloudwatch:'+$aws_settings.Region+':'+$accountno+':alarm:'+$ec2.name+'-NETWORK-IN"]},"view":"timeSeries","stacked":false}},'
    $dash_body = $dash_body + '{"type":"metric","width":12,"height":4,"properties":{"title":"'+$ec2.name+'-NETWORK-OUT","annotations":{"alarms":["arn:aws:cloudwatch:'+$aws_settings.Region+':'+$accountno+':alarm:'+$ec2.name+'-NETWORK-OUT"]},"view":"timeSeries","stacked":false}},'

}

$dash_body = $dash_body.Substring(0,$dash_body.Length-1)

$dashjson = $dash_start+$dash_body+$dash_end


Write-CWDashboard -DashboardName $dashname -DashboardBody $dashjson



