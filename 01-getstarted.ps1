Connect-SqlClone -ServerUrl "http://localhost:14145"

$SqlServerInstance = Get-SqlCloneSqlServerInstance -MachineName 'Aristotle' -InstanceName ''

New-SqlCloneImage -Name "TestImage" -SqlServerInstance "Aristotle" -DatabaseName 'DMDemo_5_Prod' -Destination "\\Aristotle\SQLCloneImages\"



