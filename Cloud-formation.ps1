
$ssraw = Get-EBAvailableSolutionStackList
$ss = $ssraw.SolutionStacks |  Where-Object -FilterScript { $PSItem -match 'node.js' }
$p1 = New-Object -Type Amazon.CloudFormation.Model.Parameter
$p1.ParameterKey = "SolutionStack"
$p1.ParameterValue = $ss
$p2 = New-Object -Type Amazon.CloudFormation.Model.Parameter
$p2.ParameterKey = "S3Source"
$p2.ParameterValue = $aws_settings.Bucket
$p3 = New-Object -Type Amazon.CloudFormation.Model.Parameter
$p3.ParameterKey = "AppZip"
$p3.ParameterValue = 'TTS-v4.4.3.zip'
$p4 = New-Object -Type Amazon.CloudFormation.Model.Parameter
$p4.ParameterKey = "AppName"
$p4.ParameterValue = 'TTS-v4.4.3'
$p5 = New-Object -Type Amazon.CloudFormation.Model.Parameter
$p5.ParameterKey = "DBArn"
$p5.ParameterValue = 'om-test-1.database.us-west-1.rds.amazonaws.com'
$p6 = New-Object -Type Amazon.CloudFormation.Model.Parameter
$p6.ParameterKey = "SSLArn"
$p6.ParameterValue = 'arn:aws:acm:us-west-1:accountno:certificate/certificate-id-arn'

$template = "https://s3.amazonaws.com/" + $aws_settings.Bucket + "/Cloud-formation.json"
$TTS_Stack = New-CFNStack -StackName "TTSApplication" -TemplateURL $template  -Parameter @( $p1, $p2, $p3, $p4, $p5, $p6 ) -OnFailure DO_NOTHING -Capability "CAPABILITY_IAM"