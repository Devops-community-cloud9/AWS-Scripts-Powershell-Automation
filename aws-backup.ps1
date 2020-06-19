# Startup 
Set-Location C:\xampp\htdocs\scripts
#MySQL Connection
$dbpass = ConvertTo-SecureString -String 'password' -AsPlainText -Force
$dbuser = 'ps'
$dbcred = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $dbuser, $dbpass
Connect-MySqlServer -Credential $dbCred -ComputerName 'cloud-mgr-pc' -Database 'CloudMGR'

# Load AWS PowerShell Module and Connect to AWS
Write-Output "Import AWS Module"
Import-Module AWSPowerShell

# Email Setup
$style = "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; border-collapse: collapse;}"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 5px; }"
$style = $style + "</style>"
$SMTPServer = "smtp.gmail.com"
$EmailFrom = "send-from@gmail.com" 
$pass = "YourPassword"
$EmailTo = "send-to@gmail.com"
$EmailSubject = "AWS Backup"

$lastSQL = 'Select * from backups order by id desc limit 1'
$lastData = Invoke-MySqlQuery $lastSQL

$backupSQL = "Select * from system where Backup_YN='Yes'"
$backupList = Invoke-MySqlQuery $backupSQL

foreach ($system in $backupList) {
    Write-Host 'Processing ' $system.Name
    $envSQL = "Select * from environments where id=" + $system.Environment_IX
    $envData = Invoke-MySqlQuery $envSQL
    $aws_sql = 'Select * From aws where id = ' + $envData.AWS_IX
    $aws_settings = Invoke-MySqlQuery -query $aws_sql
    Set-AWSCredential -AccessKey $aws_settings.AccessKey -SecretKey $aws_settings.SecretKey -StoreAs default
    Set-DefaultAWSRegion -Region $aws_settings.Region
    
    $today = Get-Date -UFormat "%Y-%m-%d"
    $name = $system.name + " " + $today
    $img = New-EC2Image -InstanceId $system.InstanceID -Name $name -NoReboot $true
    $ami = Get-EC2Image -ImageId $img
    while ($ami.State -ne 'available') {
        Start-Sleep 5
        Write-Host -NoNewline '.'
        $ami = Get-EC2Image -ImageId $img
    }
    Write-Host ' '
    $snap = Get-EC2Snapshot -SnapshotId $ami.BlockDeviceMapping[0].Ebs.SnapshotId
    $backupSQL = 'Insert into backups set system_IX='+$system.id+', name="'+$name+'", region="'+$aws_settings.Region+'", ami="'+$img+'", snap="'+$snap.SnapshotId+'"'
    Invoke-MySqlQuery -query $backupsql
    Start-Sleep 60
}

# CLEANUP PHASE
Write-Host 'Cleaning Old Backups'
$cleanUpCount = 0
$dt = (Get-Date).AddDays(-3)
$yr = $dt.Year.ToString()
$mo = $dt.Month
if ($mo -lt 10) { $mo = '0' + $mo }
$dd = $dt.Day
if ($dd -lt 10) { $dd = '0' + $dd }
$threeDaysAgo = $yr + '-' + $mo + '-' + $dd
$cleanSQL = "Select * from backups where datestamp <= '" + $threeDaysAgo + "'"
$cleanData = Invoke-MySQLQuery $cleanSQL

foreach ($snap in $cleanData) {
    Set-DefaultAWSRegion -Region $snap.region
    Unregister-EC2Image -ImageId $snap.ami
    Remove-EC2Snapshot -SnapshotId $snap.snap -Force
    $cleanUpCount = $cleanUpCount + 1
    $dbUpdSql = 'delete from backups where id = ' + $snap.id
    $dbUpdRun = Invoke-MySqlQuery $dbUpdSql
}

$backupListSQL = 'Select name,datestamp,ami,snap from backups where id > ' + $lastData.id
$backupListData = Invoke-MySqlQuery $backupListSQL
$Message = New-Object System.Net.Mail.MailMessage $EmailFrom, $EmailTo
$Message.Subject = $EmailSubject
$Message.IsBodyHTML = $True
$Message.Body = $backupListData | Select-object name, datestamp, ami, snap | ConvertTo-Html -head $style | Out-String
$Message.Body = $Message.Body + '<br><br>Cleaned ' + $cleanUpCount +' Backups'
$SMTP = New-Object Net.Mail.SmtpClient($SMTPServer, 587)
$SMTP.EnableSsl = $true
$SMTP.Credentials = New-Object System.Net.NetworkCredential ($EmailFrom,$pass)
$SMTP.Send($Message)

