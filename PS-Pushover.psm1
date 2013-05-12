<#
    .SYNOPSIS
    Send messages through the Pushover API

    .DESCRIPTION
    Send a variety of messages through the Pushover API.
    Some options can be globally set for all messages per session.

    .NOTES
    AUTHOR: Kieranties

    .LINK
    https://pushover.net/api
#>

# The API endpoint used when sending messages
$pushoverEndpoint = "https://api.pushover.net/1/messages.json"

# The valid collection of sounds allowed by pushover
$pushoverSounds = @("pushover","bike","bugle","cashregister",
                    "classical", "cosmic", "falling", "gamelan",
                    "incoming", "intermission", "magic", "mechanical",
                    "pianobar", "siren", "spacealarm", "tugboat",
                    "alien", "climb", "persistent", "echo", "updown"
                    "none")

# The valid collection of priorities allowed by pushover
$pushoverPriorities = @{
    Quiet = -1
    Normal = 0
    Emergency = 1
   <# 
      Confirmation = 2

      While the API suggests 2 is a valid option it currently returns 400 when 
      added to the parameter request collection
   #>
}

<#
    .SYNOPSIS
    Throws an error on the API token if given value is not valid
#>
Function Test-Token{
    param($given)

    if([string]::IsNullOrEmpty($given)){

        throw "API token has not been set in function call or in the session.`r`n" `
              + "Provide the -token parameter or call Set-PushoverSession -token <value> to`r`n" `
              + "set the parameter for the session lifetime"
    }
}

<#
    .SYNOPSIS
    Throwse an error on the user param if given value is not valid
#>
Function Test-User{
    param($given)

    if([string]::IsNullOrEmpty($given)){

        throw "User has not been set in function call or in the session.`r`n" `
              + "Provide the -user parameter or call Set-PushoverSession -user <value> to`r`n" `
              + "set the parameter for the session lifetime"
    }
}

<#
    .SYNOPSIS
    Throws an error on the sounds param if given value is not in the sounds collection
#>
Function Test-AgainstSounds {
    param($given)

    if($pushoverSounds -contains $given){
        return $true
    }

    throw "$given is not a valid sound option.`r`nCall Get-PushoverSounds to see all valid options"
}

<#
    .SYNOPSIS
    Throws an error on the priorities param if given value is not in the priority collection
#>
Function Test-AgainstPriorities {
    param($given)

    if(($pushoverPriorities.Keys -contains $given) -or ($pushoverPriorities.Values -contains $given)){
        return $true
    }
    throw "$given is not a valid priority option.`r`nCall Get-PushoverPriorities to see all valid options"
}

<#
    .SYNOPSIS
    Resolves the priority value to send in a message
#>
Function Resolve-MessagePriority{
    param(
        # The priority name or value to resolve
        $priority
    )

    if($priority){
        if($pushoverPriorities.Keys -contains $priority){
            return $pushoverPriorities[$priority]
        } else {
            return $priority
        }
    }

    $null
}

<#
    .SYNOPSIS
    Converts the given datetime to a unix timestamp value
#>
Function ConvertTo-Epoch{
    param(
        # The timestamp to convert
        $datetime
    )

    if($datetime){
        [datetime]$parsed = [datetime]::Now
        if([datetime]::TryParse($datetime, [ref]$parsed)){
            $epoch = Get-Date -Date "01/01/1970"
            return (New-TimeSpan -Start $epoch -End $parsed).TotalSeconds
        }
    }

    $null
}

<#
    .SYNOPSIS
    Returns a list of sounds valid for Pushover

    .DESCRIPTION
    Returns a list of sounds that can be used as options for -sound
    in calls to Set-PushoverSession and Send-PushoverMessage
#>
Function Get-PushoverSounds { $pushoverSounds }

<#
    .SYNOPSIS
    Returns a list of priorities valid for Pushover

    .DESCRIPTION
    Returns a list of priorities that can be used as options for -priority
    in calls to Set-PushoverSession and Send-PushoverMessage
#>
Function Get-PushoverPriorities { $pushoverPriorities }

<#
    .SYNOPSIS
    Sets session wide properties for the PS-Pushover module

    .DESCRIPTION
    Allows some PS-Pushover properties to be set for the lifetime of a
    powershell session, reducing the number of parameters required in each
    call to Send-PushoverMessage
#>
Function Set-PushoverSession{
    param(
        # The API token for the application
        [string]$token,
        # The user key of the user who will receive the message
        [string]$user,
        # The priority of the message.  Call Get-PushoverPriorities for valid options
        [ValidateScript({Test-AgainstPriorities $_})]
        [string]$priority,
        # The device name 
        [string]$device,
        # The title for messages
        [string]$title,
        # The sound to use on the device.  Call Get-PushoverSounds for valid options
        [ValidateScript({Test-AgainstSounds $_})]
        [string]$sound
    )

    if($token){ $Script:token = $token }
    if($user){ $Script:user = $user }
    if($priority){ $Script:priority = $priority }
    if($device) { $Script:device = $device }
    if($title) { $Script:title = $title }
    if($sound) { $Script:sound = $sound }
}

<#
    .SYNOPSIS
    Gets details of the Pushover session parameters

    .DESCRIPTION
    Returns the values set for each session level parameter used in calls
    to Send-PushoverMessage and set through calls to Set-PushoverSession
#>
Function Get-PushoverSession{
    @{
        token = $Script:token
        user = $Script:user
        priority = $Script:priority
        device = $Script:device
        title = $Script:title
        sound = $Script:sound
    }
}

<#
    .SYNOPSIS
    Send a message through the Pushover API

    .DESCRIPTION
    Send messages to devices using the Pushover API.  Messages can be sent to
    any user device and as any application.  Parameters can be provide on a per message
    basis or set session wide.

    .EXAMPLE
    PS C:\> Send-PushoverMessage "Message from Powershell" -token 21480143nlkjn313 -user 238423048234hhjkkjh

    This comand will send a message through Pushover using the given token and user

    .EXAMPLE
    PS C:\> Set-PushoverSession -token 21480143nlkjn313 -user 238423048234hhjkkjh
    PS C:\> Send-PushoverMessage "Message from Powershell"

    The first command sets the token and user params for the powershell session.
    The second command then sends a message using the session parameters

    .EXAMPLE
    PS C:\> spm "Message from Powershell" -title "IMPORTANT!" -priority 1 -sound persistent

    This command will send a message as an emergency priority and play the persistent noise
    on the users device
    

#>
Function Send-PushoverMessage{
    param(
        # Required.  The message to send
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Message to send")]
        [string]$message,
        # Required if not set using Set-PushoverSession.  The api token for the application
        [string]$token = $Script:token,
        # Required if not set using Set-PushoverSession. The user token of the message recipient
        [string]$user = $Script:user,
        # The priority of the message.  Call Get-PushoverPriorities for valid options
        [ValidateScript({Test-AgainstPriorities $_})]
        [string]$priority = $Script:priority,
        # The device name
        [string]$device = $Script:device,
        # The title of the message
        [string]$title = $Script:title,
        # The sound to use on the device.  Call Get-PushoverSounds for valid options
        [ValidateScript({Test-AgainstSounds $_})]
        [string]$sound = $Script:sound,
        # An associated url for the message
        [string]$url,
        # The title to use for the provided -url parameter
        [string]$urlTitle,
        # The timestamp used for the message
        [ValidateScript({[datetime]::parse($_)})]
        $timestamp
    )

    # Validate
    Test-Token $token
    Test-User $user

    # Compose param collections
    $parameters = @{
        token = $token
        user = $user
        message = $message
        device = $device
        title = $title
        sound = $sound
        url = $url
        url_title = $urlTitle
        priority = Resolve-MessagePriority $priority
        timestamp = ConvertTo-Epoch $timestamp
    }  

    # Send the message
    $parameters | Invoke-RestMethod -Uri $pushoverEndpoint -Method Post
}

# Expose module content
New-Alias spm Send-PushoverMessage
Export-ModuleMember -Function *Pushover* -Alias *