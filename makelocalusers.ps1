 #setting Variables 
$computer = $Env:ComputerName
$text = "C:\FileName.csv"
$user = import-csv -path $text -delimiter ';'
foreach($strUser in $user)
{
 $user = $strUser.username
 $password = $strUser.Password
 $first = $strUser.First
 $last = $strUser.Last
 #$description =  $struser.description
 $groups = $strUser.Groups.split(',')
 Clear-Host  
##First check if user exists
$objComputer = [ADSI]"WinNT://$computer,computer"
$colUsers = ($objComputer.psbase.children | Where-Object {$_.psBase.schemaClassName -eq "User"} | Select-Object -expand Name)
$userFound = $colUsers -contains $user
if (! $userFound) {
  write-host "The $user account did not exist."
  write-host "Creating $user"
 $ObjOU = [ADSI]"WinNT://$computer"
 $objUser = $objOU.Create("User", $user)
 $objUser.setpassword($password)
 $objUser.UserFlags = 64 + 65536
 $objUser.put("fullname",$first + " " + $last)
 #$objUser.put("description",$description)
 $objUser.SetInfo()
 foreach($mygroup in $groups){
    $objGroup = [ADSI]"WinNT://$computer/$mygroup"
    $objGroup.add("WinNT://$computer/$user")
    $objGroup.SetInfo()
}
  
  Write-Host "complete"
}
else {
  write-host "$user account exists."
  write-host "skipping"
 }} 
