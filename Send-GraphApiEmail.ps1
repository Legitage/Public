
Function Send-GraphApiEmail {
    <#
    .SYNOPSIS
    Sends email as an application using the graph API

    .DESCRIPTION
    Calls the Graph API using native HTTP/REST to send email using an AAD App registration with the Mail.Send permission

    .PARAMETER MsgSenderId
    The user ID of the mailbox to send from 

    .PARAMETER MsgRecipients
    Specified email recipient addresses

    .PARAMETER MsgCcs
    Optional CC email recipients

    .PARAMETER MsgBccs
    Optional BCC email recipients

    .PARAMETER MsgSubject
    Subject line of email

    .PARAMETER MsgBody
    Email message body. Supports HTML formatting

    .PARAMETER MsgAttachment
    Option to attach a a single file (intentional limitation)

    .PARAMETER SaveCopyToSentItems
    If specified will save a copy of the email in the sending mailbox's 'Sent Items'
    The default does not save a copy

    .PARAMETER TenantId
    GUID of the Azure tenant that contains the AAD App registration

    .PARAMETER ClientId
    AAD App registration/client ID value for Graph Mail.Send
 
    AAD Application/

    .PARAMETER ClientSecret
    AAD App registration/client Secret value for Graph Mail.Send

    .NOTES
    This function does not rely on the Microsoft.Graph PowerShell module
    It is possible to add support for multiple file attachments, but this is primary intended for sending emails messages.
    #>

    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [string]$MsgSenderId,
        
        [parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [string[]]$MsgRecipients,

        [parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [string[]]$MsgCcs,

        [parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [string[]]$MsgBccs,

        [parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [string]$MsgSubject,
  
        [parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [string]$MsgBody,

        [parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [System.IO.FileInfo]$MsgAttachment,

        [parameter(Mandatory = $false, ValueFromPipeline = $false)]
        [switch]$SaveCopyToSentItems,

        [parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [string]$TenantId,

        [parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [string]$ClientId,

        [parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [string]$ClientSecret
    )
    
    if ($SaveCopyToSentItems) {
        $saveToSentItems = 'true'
    }
    else {
        $saveToSentItems = 'false'
    }
    
    $toRecipients  = [System.Collections.ArrayList]::new()
    $ccRecipients  = [System.Collections.ArrayList]::new()
    $bccRecipients = [System.Collections.ArrayList]::new()
    $attachments   = [System.Collections.ArrayList]::new()

    foreach ($msgRecipient in $MsgRecipients) {
        $address = @{
            "emailAddress" = @{
                "address" = $msgRecipient
            }
        }
        [void]$toRecipients.Add($address)
    }

    $body = @{
        "message"         = @{
            "subject"      = $MsgSubject
            "body"         = @{
                "contentType" = 'Html'
                "content"     = $MsgBody
            }
            "toRecipients" = $toRecipients
        }
        "SaveToSentItems" = $saveToSentItems
    }

    if ($null -ne $MsgCcs) {
        foreach ($msgCc in $MsgCcs) {
            $address = @{
                "emailAddress" = @{
                    "address" = $msgCc
                }
            }
            [void]$ccRecipients.Add($address)
        }
        $body.message += @{ccRecipients = $ccRecipients }
    }

    # bccRecipients
    if ($null -ne $MsgBccs) {
        foreach ($msgBcc in $MsgBccs) {
            $address = @{
                "emailAddress" = @{
                    "address" = $msgBcc
                }
            }
            [void]$bccRecipients.Add($address)
        }
        $body.message += @{bccRecipients = $bccRecipients }
    }

    if ($null -ne $MsgAttachment) {
        if ((Test-Path -Path $MsgAttachment) -eq $false) {
            Write-Error "Specified file path $MsgAttachment not exist!"
        }
        else {
            $fileName = (Get-Item -Path $MsgAttachment).name
            $base64string = [Convert]::ToBase64String([IO.File]::ReadAllBytes($MsgAttachment))
            $attachment = @{
                "@odata.type"  = '#microsoft.graph.fileAttachment'
                "name"         = $fileName
                "contentBytes" = $base64string
                "contentType"  = 'mime_type'
            }
            [void]$attachments.Add($attachment)
            $body.message += @{attachments = $attachments }
        }
    }

    # Graph API is very particular about json formatting when using HTTP REST calls
    $jsonBody = $body | ConvertTo-JSON -Depth 10

    $authRequest = @{
        Method = 'POST'
        URI    = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
        body   = @{
            grant_type    = "client_credentials"
            scope         = "https://graph.microsoft.com/.default"
            client_id     = $ClientId
            client_secret = $ClientSecret
        }
    }

    $authToken = (Invoke-RestMethod @authRequest).access_token

    $mailSendRequest = @{
        "URI"         = "https://graph.microsoft.com/v1.0/users/$MsgSenderId/sendMail"
        "Headers"     = @{
            "Authorization" = ("Bearer {0}" -F $authToken)
        }
        "Method"      = 'POST'
        "ContentType" = 'application/json'
        "Body"        = $jsonBody
    }

    Invoke-RestMethod @mailSendRequest

    Write-Host "Email summary sent using Graph API"
}
