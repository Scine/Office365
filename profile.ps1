#Put this file under your C:\users\username\my documents\windowspowershell\ folder

function prompt
{
    # New nice WindowTitle
    $Host.UI.RawUI.WindowTitle = "PowerShell v" + (get-host).Version.Major + "." + (get-host).Version.Minor + " (" + $pwd.Provider.Name + ") " + $pwd.Path
 
    # Admin ?
    if( (
        New-Object Security.Principal.WindowsPrincipal (
            [Security.Principal.WindowsIdentity]::GetCurrent())
        ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    {
        # Admin-mark in WindowTitle
        $Host.UI.RawUI.WindowTitle = "[Admin] " + $Host.UI.RawUI.WindowTitle
 
        # Admin-mark on prompt
        Write-Host "[" -nonewline -foregroundcolor DarkGray
        Write-Host "Admin" -nonewline -foregroundcolor Red
        Write-Host "] " -nonewline -foregroundcolor DarkGray
    }
 
    # Show providername if you are outside FileSystem
    if ($pwd.Provider.Name -ne "FileSystem") {
        Write-Host "[" -nonewline -foregroundcolor DarkGray
        Write-Host $pwd.Provider.Name -nonewline -foregroundcolor Gray
        Write-Host "] " -nonewline -foregroundcolor DarkGray
    }
 
    # Split path and write \ in a gray
    $pwd.Path.Split("\") | foreach {
        Write-Host $_ -nonewline -foregroundcolor Yellow
        Write-Host "\" -nonewline -foregroundcolor Gray
    }
 
    # Backspace last \ and write >
    Write-Host "`b>" -nonewline -foregroundcolor Gray
 
    return " "
}

function Out-vCard {
$input | ForEach-Object {

$filename = "c:\users\username\desktop\" + $_.Name + ".vcf"
Remove-Item $filename -ErrorAction SilentlyContinue
add-content -path $filename "BEGIN:VCARD"
add-content -path $filename "VERSION:2.1"
add-content -path $filename ("N:" + "" + $_.Surname + ";" + $_.GivenName)
add-content -path $filename ("FN:" + $_.Name)
add-content -path $filename ("EMAIL:" + $_.Mail)
add-content -path $filename ("ORG:" + $_.Company)
add-content -path $filename ("TITLE:" + $_.Title)
add-content -path $filename ("TEL;WORK;VOICE:" + $_.PhoneNumber)
add-content -path $filename ("TEL;HOME;VOICE:" + $_.HomePhone)
add-content -path $filename ("TEL;CELL;VOICE:" + $_.MobilePhone)
add-content -path $filename ("TEL;WORK;FAX:" + $_.Fax)
add-content -path $filename ("ADR;WORK;PREF:" + ";;" + $_.StreetAddress + ";" + $_.PostalCode + " " + $_.City + ";" + $_.co + ";;" + $_.Country)
add-content -path $filename ("URL;WORK:" + $_.WebPage)
add-content -path $filename ("EMAIL;PREF;INTERNET:" + $_.Email)
add-content -path $filename "END:VCARD"
} 
}
