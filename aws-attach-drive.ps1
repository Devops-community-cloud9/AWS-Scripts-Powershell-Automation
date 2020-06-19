Import-Module AWSPowerShell.NetCore
$AccessKey  = "access key"
$SecretKey  = "secret key"
$Region     = "us-west-1"
$snid = "subnet-address"
$Instid = "i-instid"
$BillingKey = "Infrastructure"

Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs default
Set-DefaultAWSRegion -Region $Region      
       
# Create and Attach Log Drive
$sn = Get-EC2Subnet -SubnetId $snid
$tag = @{ Key="Billing"; Value=$billingkey}
$tagspec = New-Object Amazon.EC2.Model.TagSpecification
$tagspec.ResourceType = 'volume'
$tagspec.Tags.Add($tag)

$vol = New-EC2Volume -Size 40 -AvailabilityZone $sn.AvailabilityZone -TagSpecification $tagspec
$status = Get-EC2Volume -VolumeId $vol.VolumeId 
$status.Status
while ($status.status -ne "available") {
    Start-Sleep 5
    $status.Status
    $status = Get-EC2Volume -VolumeId $vol.VolumeId 
}
$voladd = Add-EC2Volume -InstanceId $instid -VolumeId $vol.VolumeId -Device /dev/sdh

$setdrivecmd = "Get-Disk | Where partitionstyle -eq 'RAW' | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel 'Logs' -Confirm:`$false "
$setdrive = @('import-module AWSPowerShell', $setdrivecmd)
$scriptstat = Send-SSMCommand -InstanceId @($instid) -DocumentName AWS-RunPowerShellScript -Parameter @{'commands'=$setdrive}

$drive = (Get-EC2Instance -InstanceId $instid).Instances.BlockDeviceMappings | Where-Object -FilterScript { $PSItem.DeviceName -match '/dev/sda1' }
$drive.Ebs.VolumeId
New-EC2Tag -Resource $drive.Ebs.VolumeId -Tag @{ Key= 'Billing'; Value=$billing}
# End Attach Log drive