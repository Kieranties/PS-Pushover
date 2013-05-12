PS-Pushover
====================

A PowerShell module to send messages over the [Pushover API]

**Requires**: PowerShell 3.0

Install
-------

To get up and running using the module run the following


    <#
        .SYNOPSIS
        Simple install script for PS-Pushover
    #>

    $moduleName = "PS-Pushover"
    $branch = "master"
    $urlStub = "https://raw.github.com/Kieranties/$moduleName/$branch/"
    $psm = "$urlStub$moduleName.psm1"

    $client = New-Object System.Net.WebClient
    $modPath = $env:PSModulePath.Split(";") | ? { $_ } | select -First 1 # or wherever you put your modules
    $modFolder = New-Item (Join-Path $modPath $moduleName) -ItemType directory -Force # force used so you can use same script to update

    $psm | % {
        $fileName = Split-Path $_ -leaf
        $client.DownloadFile($_, (Join-Path $modFolder $filename))
    }

    "$moduleName install complete"

Setup
-----
You'll need to do the following before making use of the module

### Create a Pushover Application

+ Visit the [new application] page and create an application for yourself
+ Take note of the _API Token/Key_
+ Visit the [Pushover] homepage
+ Take note of your _User Key_

### (Optional) Setting session parameters in profile

The function ``Send-PushoverMessage`` (aliased to ``spm``) allows all parameters to be passed in each call.
If you're going to be using the function often, it's easier to set things once.

In your profile you can do the following:
    
    	Import-Module PS-Pushover
		Set-PushoverSession -token <your API Token> -user <your User Key>

Other options are also available, call ``Set-PushoverSession -detailed`` for more information

Functions
---------

The full list of functions available are:

+ ``Get-PushoverPriorities`` - Returns a list of valid priorities for use in sending messages
+ ``Get-PushoverSession`` - Returns details of the properties set for the current powershell session
+ ``Get-PushoverSounds`` - Returns a list of valid sounds for use in sending messages
+ ``Send-PushoverMessage`` - Sends a message using the Pushover API
+ ``Set-PushoverSession`` - Sets properties for use throughout the current powershell session

-----

Links
-------
+ [@Kieranties]
+ [License]
+ [Pushover]

[@Kieranties]: http://twitter.com/kieranties
[License]: http://kieranties.mit-license.org/
[Pushover]: https://pushover.net/
[Pushover API]: https://pushover.net/api
[new application]: ttps://pushover.net/apps/build