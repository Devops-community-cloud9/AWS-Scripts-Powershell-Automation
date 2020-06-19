            $dbtag = New-Object Amazon.RDS.Model.Tag
            $dbtag.key = "Name"
            $dbtag.Value = $vpc.Name
            $dbtagb = New-Object Amazon.RDS.Model.Tag
            $dbtagb.key = "Billing"
            $dbtagb.Value = "Infrastructure"

            $dbname = "DB-" + $vpc.name + "-" + $vpc.id
            $instid = "DB-INST-" + $vpc.name + "-" + $vpc.id
            $dbpass = Create-Password 16 ulns
            New-RDSDBSubnetGroup -DBSubnetGroupName $instid -DBSubnetGroupDescription 'OM Subnets for DB' `
                    -SubnetId $vpc.SubnetId, $vpc.SubnetId -Tag $dbtag, $dbtagb
            $RBD =  New-RDSDBInstance -AllocatedStorage 30 -BackupRetentionPeriod 3 `
                    -MultiAZ $true -DBInstanceClass db.t2.medium -DBInstanceIdentifier $instid `
                    -Engine MariaDB -MasterUsername dbadmin -MasterUserPassword $dbpass `
                    -VpcSecurityGroupId $vpc.SecurityGroupID -StorageEncrypted $true `
                    -PubliclyAccessible $false -DBSubnetGroupName $istid
            while ($true) {
                $DBReady = Get-RDSDBInstance -DBInstanceIdentifier $RBD.DBInstanceIdentifier
                if ($DBReady.DBInstanceStatus -eq 'available') {
                    break
                }
            }
            $endpoint = $DBReady.Endpoint.Address
            Add-RDSTagsToResource -ResourceName $DBReady.DBInstanceArn -Tag $dbtag
            Add-RDSTagsToResource -ResourceName $DBReady.DBInstanceArn -Tag $dbtagb
