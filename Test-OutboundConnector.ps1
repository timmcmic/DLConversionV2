<#
    .SYNOPSIS

    This function tests each accepted domain on the group to ensure it appears in Office 365.

    .DESCRIPTION

    This function tests each accepted domain on the group to ensure it appears in Office 365.

    .EXAMPLE

    Test-AcceptedDomain -originalDLConfiguration $originalDLConfiguration

    #>
    Function Test-OutboundConnector
     {
        [cmdletbinding()]

        Param
        (
            [Parameter(Mandatory = $true)]
            $overrideCentralizedMailTransportEnabled
        )

        #Define variables that will be utilzed in the function.

        [array]$exchangeOnlineOutboundConnectors=@()

        #Initiate the test.
        
        Out-LogFile -string "********************************************************************************"
        Out-LogFile -string "BEGIN Test-OutboundConnectors"
        Out-LogFile -string "********************************************************************************"

        $exchangeOnlineOutboundConnectors = get-o365OutboundConnector

        if ($overrideCentralizedMailTransportEnabled -eq $FALSE)
        {
            foreach ($outboundConnector in $exchangeOnlineOutboundConnectors)
            {
                if ($outboundConnector.RouteAllMessagesViaOnPremises -eq $TRUE)
                {
                    out-logfile -string "***WARNING***"
                    out-logfile -string "Centralized transport is enabled."
                    out-logfile -string "When centralized mail transport is enabled - if the migrated group contains any on premises mailboxes the public MX is utilized for routing."
                    out-logfile -string "If not properly tested this could lead to NDRs or messages appearing as external to on premises resources."
                    out-logfile -string "Migrating this DL can only be accomplished by acknolwedging centralized mail transport is enabled using the -overrideCentalizedMailTransportEnabled:$TRUE"
                    out-logfile -string $outboundConnector.name
                    out-logfile -string $outboundConnector.RouteAllMessagesViaOnPremises
                    out-logfile -string "***WARNING***" -isError:$true
                }
                else 
                {
                    out-logfile -string "Connector not enabled for centralized mail transport."
                    out-logfile -string $outboundConnector.Name
                    out-logfile -string $outboundConnector.RouteAllMessagesViaOnPremises
                }
            }
        }
        else 
        {
            foreach ($outboundConnector in $exchangeOnlineOutboundConnectors)
            {
                if ($outboundConnector.RouteAllMessagesViaOnPremises -eq $TRUE)
                {
                    out-logfile -string "***WARNING***"
                    out-logfile -string "Centralized transport is enabled."
                    out-logfile -string "When centralized mail transport is enabled - if the migrated group contains any on premises mailboxes the public MX is utilized for routing if the message originated from on premises."
                    out-logfile -string "If not properly tested this could lead to NDRs or messages appearing as external to on premises resources."
                    out-logfile -string "The administrator has acknowledged the warning by overriding centralized mail transport enabled."
                    out-logfile -string $outboundConnector.name
                    out-logfile -string $outboundConnector.RouteAllMessagesViaOnPremises
                    out-logfile -string "***WARNING***"
                }
                else 
                {
                    out-logfile -string "Connector not enabled for centralized mail transport."
                    out-logfile -string $outboundConnector.Name
                    out-logfile -string $outboundConnector.RouteAllMessagesViaOnPremises
                }
            }
        }

        Out-LogFile -string "END Test-OutboundConnector"
        Out-LogFile -string "********************************************************************************"
    }