##Want to know who's your biggest Office 365 user mailboxes?  This will show you by connecting to Office 365, grabbing all mailbox sizes, then sorting it by size, largest on top.##

$LiveCred = Get-Credential
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $LiveCred -Authentication Basic -AllowRedirection
Import-PSSession $Session

Get-Mailbox -ResultSize Unlimited |

Get-MailboxStatistics |

Select DisplayName, `

@{name="TotalItemSize (MB)"; expression={[math]::Round( `

($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1MB),2)}}, `

ItemCount |

Sort "TotalItemSize (MB)" -Descending
