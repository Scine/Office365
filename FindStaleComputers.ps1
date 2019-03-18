##This script will search out all computers in your AD, and list them in order of last logon date, newest at the top.  This will help find old computers that aren't active anymore.

##Be sure to change the OU and DC information to match your environment.

##Note, this won't do anything but list them.  You can add an additional bit at the end to disable computers older than X date, but be careful with that.

##If you've enjoyed my script, come on back regularly, to https://github.com/Scine/office365 as I post regularly!

Get-ADComputer -SearchBase "OU=Computers,DC=DOMAIN,DC=SUFFIX" -Filter * -Properties LastLogonDate | sort LastLogonDate -desc | ft Name,LastLogonDate,DistinguishedName
