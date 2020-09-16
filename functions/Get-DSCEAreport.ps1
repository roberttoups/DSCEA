function Get-DSCEAreport {
  <#
.SYNOPSIS
Generates a HTML based report after Start-DSCEAscan has been run

.DESCRIPTION
Used to create viewable reports after Start-DSCEAscan has created a results.xml file which will be parsed.

.PARAMETER ItemName
Switch parameter - This is the item name from the configuration file, used to generate a report of every machine's compliance against that item

.PARAMETER ComputerName
Switch parameter - Supplying a computer name will cause the report to display all items (true/false) pertaining to ComputerName

.PARAMETER Overall
Switch parameter - Indicating that the report generated will display all up true/false per computer in regards to compliance against the entire configuration file

.PARAMETER Detailed
Switch parameter - Indicating that the report generated will display all non-compliant configuration file items detected, grouped by computer

.PARAMETER InFile
The file name (full file path) of the XML file you would like to convert.  If one is not provided, Get-DSCEAreport looks to the current directory for the most recently created XML file.

.PARAMETER OutPath
The full file path to use as a location to store HTML reports.  The file path must be a pre-existing folder.  If one is not provided, Get-DSCEAreport will create the HTML file in the current directory.

.LINK
https://microsoft.github.io/DSCEA

.EXAMPLE
Get-DSCEAreport -ItemName MicrosoftAntimalwareService

Description
-----------
This command returns all systems that were scanned and their compliance in regards to the Microsoft AntiMalware Service

.EXAMPLE
Get-DSCEAreport -ComputerName 'dc1'

Description
-----------
This command returns all configuration items for computer 'dc1'

.EXAMPLE
Get-DSCEAreport -Overall

Description
-----------
This command returns true/false per machine regarding whether they comply with the entire configuration file

.EXAMPLE
Get-DSCEAreport -Detailed

Description
-----------
This command returns non-compliant configuration file items detected, grouped by computer
#>
  [CmdLetBinding()]
  param(
    [parameter(
      Mandatory = $true,
      ParameterSetName = 'ItemName'
    )]
    [String]
    $ItemName,

    [parameter(
      Mandatory = $true,
      ParameterSetName = 'ComputerName'
    )]
    [String]
    $ComputerName,

    [parameter(
      Mandatory = $true,
      ParameterSetName = 'Overall'
    )]
    [Switch]
    $Overall,

    [parameter(
      Mandatory = $true,
      ParameterSetName = 'Detailed'
    )]
    [Switch]
    $Detailed,

    [String]
    $InFilePath = (
      Get-ChildItem -Path $PSScriptRoot -Filter 'results*.xml' |
        Sort-Object -Property 'LastWriteTime' -Descending |
        Select-Object -First 1 |
        Select-Object -ExpandProperty 'FullName'
    ),

    [parameter(
      Mandatory = $false
    )]
    [String]
    $OutPath = (Join-Path -Path $PSScriptRoot -ChildPath '')
  )
  #----------------------------------------------------------------------------------------------------------------------#
  # Default Variables
  #----------------------------------------------------------------------------------------------------------------------#
  $ProgramPath = Join-Path -Path 'C:\ProgramData' -ChildPath 'DSCEA'
  #----------------------------------------------------------------------------------------------------------------------#
  # Collect Module Directory Paths
  #----------------------------------------------------------------------------------------------------------------------#
  $FileSystemSeparator = ';'
  $PSModulePathList = $env:PSModulePath.Split($FileSystemSeparator)
  #----------------------------------------------------------------------------------------------------------------------#
  # Test for the existance of the Web logo and copy it if needed
  #----------------------------------------------------------------------------------------------------------------------#
  $WebLogoPath = Join-Path -Path $ProgramPath -ChildPath 'logo.png'
  if((Test-Path -Path $WebLogoPath) -eq $false) {
    foreach($PSModulePath in $PSModulePathList) {
      $TestPath = Join-Path -Path $PSModulePath -ChildPath 'DSCEA'
      if(Test-Path -Path $TestPath) {
        if((Test-Path -Path $ProgramPath) -eq $false) {
          $ArgumentCollection = @{
            Path        = $ProgramPath
            Type        = 'Directory'
            ErrorAction = 'Stop'
          }
          try {
            New-Item @ArgumentCollection
          } catch {
            $SpecificReason = "Failed to create $ProgramPath."
            $ErrorMessage = $PSItem.Exception.Message
            throw "($ErrorMessage): $SpecificReason Exiting."
          }
        }
        $LogoPath = Get-ChildItem -Path $PSModulePath-Filter 'logo.png' -Recurse -File |
          Select-Object -First 1 |
          Select-Object -ExpandProperty 'FullName'

        $ArgumentCollection = @{
          Path        = $LogoPath
          Destination = $DestinationPath
          Force       = $true
          ErrorAction = 'Stop'
        }
        try {
          Copy-Item @ArgumentCollection
        } catch {
          $SpecificReason = "Failed to copy $LogoPath to $DestinationPath."
          $ErrorMessage = $PSItem.Exception.Message
          throw "($ErrorMessage): $SpecificReason Exiting."
        }
        if(Test-Path -Path $DestinationPath) {
          $LogoFound = $true
          break
        }
      }
    }
  }
  #----------------------------------------------------------------------------------------------------------------------#
  # Load the Results File (better safe than confused)
  #----------------------------------------------------------------------------------------------------------------------#
  if((Test-Path -Path $InFilePath) -eq $false) {
    throw "Failed to locate $InFilePath"
  }
  $Results = Import-Clixml -Path $InFilePath
  $ReportDate = (
    Get-ChildItem -Path $InFilePath |
      Select-Object -ExpandProperty 'LastWriteTime'
  )
  #----------------------------------------------------------------------------------------------------------------------#
  # Overall
  #----------------------------------------------------------------------------------------------------------------------#
  if($Overall) {
    $Results |
      Select-Object -ExpandProperty Compliance |
      Where-Object { $null -ne $_.PSComputerName } |
      Select-Object -Property (
        @{Name = 'Computer'; Expression = { $_.PSComputerName } },
        @{Name = 'Compliant'; Expression = { $_.InDesiredState } }
      ) |
      ConvertTo-HTML -Head $webstyle -Body (
        "<img src='$WebLogoPath'/><br>",
        '<titlesection>DSC Configuration Report</titlesection><br>',
        '<datesection>Report last run on", $date, "</datesection><p>'
      ) |
      Out-File (Join-Path -Path $OutPath -ChildPath 'OverallComplianceReport.html')
    Get-ItemProperty (Join-Path -Path $OutPath -ChildPath 'OverallComplianceReport.html')
  }
  #----------------------------------------------------------------------------------------------------------------------#
  # Detailed
  #----------------------------------------------------------------------------------------------------------------------#
  if($Detailed) {
    $Results | ForEach-Object {
      $_.Compliance | ForEach-Object {
        $_.ResourcesNotInDesiredState |
          Select-Object @{Name = "Computer"; Expression = { $_.PSComputerName } }, ResourceName, InstanceName, InDesiredState
        }
      } | ConvertTo-HTML -Head $webstyle -body "<img src='C:\ProgramData\DSCEA\logo.png'/><br>", "<titlesection>DSC Configuration Report</titlesection><br>", "<datesection>Report last run on", $date, "</datesection><p>" |
      Out-File (Join-Path -Path $OutPath -ChildPath 'DetailedComplianceReport.html')
    Get-ItemProperty (Join-Path -Path $OutPath -ChildPath 'DetailedComplianceReport.html')
  }
  #----------------------------------------------------------------------------------------------------------------------#
  # ItemName
  #----------------------------------------------------------------------------------------------------------------------#
  if($ItemName) {
    $Results | ForEach-Object {
      $_.Compliance | ForEach-Object {
        $_.ResourcesInDesiredState | ForEach-Object { $_ | Select-Object @{Name = "Computer"; Expression = { $_.PSComputerName } }, ResourceName, InstanceName, InDesiredState }
        $_.ResourcesNotInDesiredState | ForEach-Object { $_ | Select-Object @{Name = "Computer"; Expression = { $_.PSComputerName } }, ResourceName, InstanceName, InDesiredState }
      }
    } | Where-object { $_.InstanceName -ieq $ItemName } |
    ConvertTo-HTML -Head $webstyle -body "<img src='C:\ProgramData\DSCEA\logo.png'/><br>", "<titlesection>DSC Configuration Report</titlesection><br>", "<datesection>Report last run on", $date, "</datesection><p>" |
    Out-File (Join-Path -Path $OutPath -ChildPath "ItemComplianceReport-$ItemName.html")
    Get-ItemProperty (Join-Path -Path $OutPath -ChildPath "ItemComplianceReport-$ItemName.html")
  }
  #----------------------------------------------------------------------------------------------------------------------#
  # ComputerName
  #----------------------------------------------------------------------------------------------------------------------#
  if($ComputerName) {
    $Results | where-object { $_.Computer -ieq $ComputerName } | ForEach-Object {
      $_.Compliance | ForEach-Object {
        $_.ResourcesNotInDesiredState | Select-Object @{Name = "Computer"; Expression = { $_.PSComputerName } }, ResourceName, InstanceName, InDesiredState
        $_.ResourcesInDesiredState | Select-Object @{Name = "Computer"; Expression = { $_.PSComputerName } }, ResourceName, InstanceName, InDesiredState
      }
    } | ConvertTo-HTML -Head $webstyle -body "<img src='C:\ProgramData\DSCEA\logo.png'/><br>", "<titlesection>DSC Configuration Report</titlesection><br>", "<datesection>Report last run on", $date, "</datesection><p>" |
    Out-File (Join-Path -Path $OutPath -ChildPath "ComputerComplianceReport-$ComputerName.html")
    Get-ItemProperty (Join-Path -Path $OutPath -ChildPath "ComputerComplianceReport-$ComputerName.html")
  }
}
#----------------------------------------------------------------------------------------------------------------------#
# Stop the Clock
#----------------------------------------------------------------------------------------------------------------------#
Write-Host "[i] Run Time: $([System.Math]::Floor($RunTime.Elapsed.TotalHours).ToString('#,#00')):$($RunTime.Elapsed.Minutes):$($RunTime.Elapsed.Seconds.ToString('00'))" -ForegroundColor 'Yellow'
