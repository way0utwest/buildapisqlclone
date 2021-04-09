<#
.Description
This script will create a new image for the clone server, database server, and database passed in. The image name will default to the databasename_new on creation.

If the image creation succeeds, this script will rename a current image, named databasename_current, to databasename_old. The new image will then be renamed to databasename_current.

.parameter ServerUrl
This is the URL of the clone server, including the http or https.

.parameter MachineName
This is the name of the database server instance where the source database is located

.parameter InstanceName
This is the named instance name. This is optional, and can be ignored if the default instance is used.

.parameter ImageLocation
This is the path to the location for storing clone image files. This should be a UNC path.
#>
	
$ServerUrl = 'http://Aristotle:14145' # Set to your Clone server URL
$MachineName = 'Aristotle' # The machine name of the SQL Server instance to create the clones on
$InstanceName = '' # The instance name of the SQL Server instance to create the clones on
$ImageLocation = '\\Aristotle\SQLCloneImages' # Point to the file share we want to use to store the image
$MaskingSetPath = "\\Aristotle\MaskingSets\dmdemo_prodmask.DMSMaskSet" # The path to a masking set
$DatabaseName = 'DMDemo_5_Prod' # The name of the database
$ImageName = $DatabaseName + "_New" # Name of the new image to create
$ImageCurrent = $DatabaseName + "_Current" # Name of the current image that exists (if it does)
$ImageOld = $DatabaseName + "_Old" # Name of the image that gets a new name

Connect-SqlClone -ServerUrl $ServerUrl
$SqlServerInstance = Get-SqlCloneSqlServerInstance -MachineName $MachineName -InstanceName $InstanceName
$ImageDestination = Get-SqlCloneImageLocation -Path $ImageLocation

$MaskingSet = New-SqlCloneMask -Path $MaskingSetPath

$ImageOperation = New-SqlCloneImage -Name $ImageName `
    -SqlServerInstance $SqlServerInstance `
    -DatabaseName $DatabaseName `
    -Destination $ImageDestination `
    -Modifications $MaskingSet

Wait-SqlCloneOperation -Operation $ImageOperation


# Rename the current image
$ImageList = Get-SqlCloneImage
foreach ($Image in $ImageList) {
    if ($Image.Name -eq $ImageOld) {
        # Remove old Clones if they exist against the old image
        #########################################################
        # NOTE:
        # This is destructive and all developers should know this
        #########################################################
        $oldClones = Get-SqlClone | Where-Object {$_.ParentImageId -eq $Image.Id}
        foreach ($clone in $oldClones)
        {
            Remove-SqlClone $clone | Wait-SqlCloneOperation
        }
        # Remove the old Image
        Remove-SqlCloneImage -Image $Image | Wait-SqlCloneOperation
    }
}

# Old Image should be removed at this point
# Rename the current to old
foreach ($Image in $ImageList) {
    if ($Image.Name -eq $ImageCurrent) {
        Rename-SqlCloneImage -Image $Image -NewName $ImageOld
    }
}

# Rename the new image to the Current one
$ImageToRename = Get-SqlCloneImage -Name $ImageName 
Rename-SqlCloneImage -Image $ImageToRename -NewName $ImageCurrent

