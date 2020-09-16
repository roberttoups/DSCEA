function Start-DSCEAscan {
  <#
.SYNOPSIS
Will run Test-DscConfiguration -ReferenceConfiguration using the provided MOF file against the remote systems supplied and saves the scan results to a XML file

.DESCRIPTION
Run this function after you have defined the remote systems to scan and have created a MOF file that defines the settings you want to check against

.PARAMETER MofFile
The file name (full file path) to the MOF file you are looking to use with DSCEA to perform a scan.  If no value is provided, Start-DSCEAscan will look into the current directory for a file named localhost.mof

.PARAMETER ComputerName
Comma separated list of computer names that you want to scan

.PARAMETER InputFile
The file name (full file path) to a text file that contains a list of computers you want to scan

.PARAMETER CimSession
Provide DSCEA with a CimSession object to perform compliance scans against remote systems that are either not members of the same domain as the management system, are workgroup systems or require other credentials

.PARAMETER Path
Provide DSCEA with a folder path containing machine specific MOF files to allow for a scan of those systems against unique per system settings

.PARAMETER ResultsFile
The file name for the DSCEA scan results XML file.  If no value is provided, a time based file name will be auto-generated.

.PARAMETER OutputPath
The full file path for the DSCEA scan results XML file.  The defined path must already exist. If no value is provided, the result XML file will be saved to the current directory.

.PARAMETER LogsPath
The full file path for the any DSCEA scan log files.  The defined path must already exist. If no value is provided, log files will be saved to the current directory.

.PARAMETER JobTimeout
Individual system timeout (seconds) If no value is provided, the default value of 600 seconds will be used.

.PARAMETER ScanTimeout
Total DSCEA scan timeout (seconds)  If no value is provided, the default value of 3600 seconds will be used.

.PARAMETER Force
The force parameter attempts to close any running DSC related processes on systems being scanned before a scan begins to avoid LCM conflicts.  Force is not enabled by default.

.LINK
https://microsoft.github.io/DSCEA

.EXAMPLE
Start-DSCEAscan -MofFile .\localhost.mof -ComputerName dsctest-1, dsctest-2, dsctest-3

Description
-----------
This command executes a DSCEA scan against 3 remote systems, dsctest-1, dsctest-2 and dsctest-3 using a locally defined MOF file that exists in the current directory. This MOF file specifies the settings to check for during the scan. Start-DSCEAscan returns a XML results file containing raw data that can be used with other functions, such as Get-DSCEAreport to create reports with consumable information.

.EXAMPLE
Start-DSCEAscan -MofFile C:\Users\username\Documents\DSCEA\localhost.mof -ComputerName dsctest-1, dsctest-2, dsctest-3

Description
-----------
This command executes a DSCEA scan against 3 remote systems, dsctest-1, dsctest-2 and dsctest-3 using a locally defined MOF file that exists at "C:\Users\username\Documents\DSCEA". This MOF file specifies the settings to check for during the scan. Start-DSCEAscan returns a XML results file containing raw data that can be used with other functions, such as Get-DSCEAreport to create reports with consumable information.

.EXAMPLE
Start-DSCEAscan -MofFile .\localhost.mof -InputFile C:\Users\username\Documents\DSCEA\computers.txt

Description
-----------
This command executes a DSCEA scan against the systems listed within "C:\Users\username\Documents\DSCEA\computers.txt" using a locally defined MOF file that exists in the current directory. This MOF file specifies the settings to check for during the scan. Start-DSCEAscan returns a XML results file containing raw data that can be used with other functions, such as Get-DSCEAreport to create reports with consumable information.

.EXAMPLE
Start-DSCEAscan -MofFile C:\Users\username\Documents\DSCEA\localhost.mof -InputFile C:\Users\username\Documents\DSCEA\computers.txt

Description
-----------
This command executes a DSCEA scan against the systems listed within "C:\Users\username\Documents\DSCEA\computers.txt" using a locally defined MOF file that exists at "C:\Users\username\Documents\DSCEA". This MOF file specifies the settings to check for during the scan. Start-DSCEAscan returns a XML results file containing raw data that can be used with other functions, such as Get-DSCEAreport to create reports with consumable information.

.EXAMPLE
Start-DSCEAscan -MofFile C:\Users\username\Documents\DSCEA\localhost.mof -ComputerName dsctest-1, dsctest-2, dsctest-3 -OutputPath C:\Temp\DSCEA\Output -ResultsFile "results.xml" -LogsPath C:\Temp\DSCEA\Logs -JobTimeout 10 -ScanTimeout 60 -Force -Verbose

Description
-----------
This command executes a DSCEA scan against 3 remote systems, dsctest-1, dsctest-2 and dsctest-3 using a locally defined MOF file that exists at "C:\Users\username\Documents\DSCEA". This MOF file specifies the settings to check for during the scan. Start-DSCEAscan returns a XML results file containing raw data that can be used with other functions, such as Get-DSCEAreport to create reports with consumable information.
This example specifies custom values for -OutputPath and -LogsPath, which must be directories that are pre-existing to store results and logs from the scan. This scan also specifies custom values for -ResultsFile to provide the file name of the scan results file, -JobTimeout and -ScanTimeout which provide new timeout values for individual system timeouts and the overall scan timeout, a -Force option which attempts to close any running DSC related processes on systems being scanned before a scan begins to avoid LCM conflicts and -Verbose, which will provide full verbose output of the scan process.

.EXAMPLE
$UserName = 'LocalUser'
$Password = ConvertTo-SecureString -String "P@ssw0rd" -AsPlainText -Force
$Servers = "dsctest-4,dsctest-5,dsctest-6"
$Cred =  New-Object System.Management.Automation.PsCredential -ArgumentList $UserName, $Password
$Sessions = New-CimSession -Authentication Negotiate -ComputerName $Servers -Credential $Cred
Start-DscEaScan -CimSession $Sessions -MofFile C:\Users\username\Documents\DSCEA\localhost.mof -Verbose

Description
-----------
This command utilizes New-CimSession and executes a DSCEA scan against 3 remote non-domain systems, dsctest-4, dsctest-5 and dsctest-6 using a locally defined MOF file that exists at "C:\Users\username\Documents\DSCEA". This MOF file specifies the settings to check for during the scan. Start-DSCEAscan returns a XML results file containing raw data that can be used with other functions, such as Get-DSCEAreport to create reports with consumable information.

.EXAMPLE
Start-DSCEAscan -Path 'C:\Users\username\Documents\DSCEA\MOFFiles'

Description
-----------
This command executes a DSCEA scan against the systems supplied as machine specific MOF files stored inside 'C:\Users\username\Documents\DSCEA\MOFFiles'. Start-DSCEAscan returns a XML results file containing raw data that can be used with other functions, such as Get-DSCEAreport to create reports with consumable information.
#>
  [CmdletBinding()]
  param(
    [parameter(
      Mandatory = $false
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $OutputPath = (Join-Path -Path '.' -ChildPath ''),

    [parameter(
      Mandatory = $false
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $LogsPath = (Join-Path -Path '.' -ChildPath ''),

    [parameter(
      Mandatory = $true,
      ParameterSetName = 'ComputerName'
    )]
    [parameter(
      Mandatory = $true,
      ParameterSetName = 'InputFile'
    )]
    [parameter(
      Mandatory = $true,
      ParameterSetName = 'CimSession'
    )]
    [ValidateScript(
      { Test-Path -Path $_ -PathType 'Leaf' -Filter '*.mof' }
    )]
    [String]
    $MofFile,

    [parameter(
      Mandatory = $true,
      ParameterSetName = 'InputFile'
    )]
    [ValidateScript(
      { Test-Path -Path $_ -PathType 'Leaf' -Filter '*.txt' }
    )]
    [String]
    $InputFile,

    [parameter(
      Mandatory = $false
    )]
    [ValidateNotNullOrEmpty()]
    [String] #Int32?
    $JobTimeout = 600,

    [parameter(
      Mandatory = $false
    )]
    [ValidateNotNullOrEmpty()]
    [String] #Int32?
    $ScanTimeout = 3600,

    [parameter(
      Mandatory = $false
    )]
    [Switch]
    $Force,

    [parameter(
      Mandatory = $false
    )]
    [ValidateScript(
      { Test-Path -Path $_ -PathType 'Leaf' -Filter '*.xml' }
    )]
    [ValidateNotNullOrEmpty()]
    [String]
    $ResultsFile = (Join-Path -Path '.' -ChildPath "DSCEA Scan Results-$(Get-Date -Format 'yyyyMMddHHmmss').xml"),

    [parameter(
      Mandatory = $true,
      ParameterSetName = 'ComputerName'
    )]
    [String[]]
    $ComputerName,

    [parameter(
      Mandatory = $true,
      ParameterSetName = 'CimSession'
    )]
    [Microsoft.Management.Infrastructure.CimSession[]]
    $CimSession,

    [parameter(
      Mandatory = $true,
      ParameterSetName = 'Path'
    )]
    [String]
    $Path
  )
  #----------------------------------------------------------------------------------------------------------------------#
  # Begin DSCEA Engine
  #----------------------------------------------------------------------------------------------------------------------#
  Write-Verbose -Message 'DSCEA Scan has started'

  $RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, 10).Open() #Min Runspaces, Max Runspaces
  $ScriptBlock = {
    param (
      [parameter(
        Mandatory = $true
      )]
      [ValidateNotNullOrEmpty()]
      [Alias('Computer')]
      [String]
      $ComputerName,

      [parameter(
        Mandatory = $true
      )]
      [ValidateScript(
        { Test-Path -Path $_ -PathType 'Leaf' -Filter '*.mof' }
      )]
      [String]
      $MofFile,

      [parameter(
        Mandatory = $true
      )]
      [ValidateNotNullOrEmpty()]
      [String]
      $JobTimeout,

      [parameter(
        Mandatory = $true
      )]
      $ModulesRequired,

      [parameter(
        Mandatory = $false
      )]
      [Microsoft.Management.Infrastructure.CimSession]
      $CimSession,

      [parameter(
        Mandatory = $true
      )]
      [String]
      $FunctionRoot,

      [parameter(
        Mandatory = $false
      )]
      [switch]
      $Force
    )
    #----------------------------------------------------------------------------------------------------------------------#
    # Load the Module Functions inside the Script Block
    #----------------------------------------------------------------------------------------------------------------------#
    Get-ChildItem -Path $FunctionRoot -Filter '*.ps1' -File |
      ForEach-Object {
        . $_.FullName |
          Out-Null
      }

    $RunTime = Measure-Command {
      try {
        if($PSBoundParameters.ContainsKey('Force')) {
          for ($i = 1; $i -lt 10; $i++) {
            Repair-DSCEngine -ComputerName $ComputerName -ErrorAction 'SilentlyContinue'
          }
        }
        #----------------------------------------------------------------------------------------------------------------------#
        # Copy resources if required
        #----------------------------------------------------------------------------------------------------------------------#
        if($null -eq $ModulesRequired) {
          if($CimSession) {
            $PSSession = New-PSSession -ComputerName $CimSession.ComputerName
          } else {
            $PSSession = New-PSSession -ComputerName $ComputerName
          }
          Copy-DSCResource -PSSession $PSSession -ModulesToCopy $ModulesRequired
          Remove-PSSession $PSSession
        }
        #----------------------------------------------------------------------------------------------------------------------#
        # Perform DSC MOF Test on Remote System
        #----------------------------------------------------------------------------------------------------------------------#
        if($PSBoundParameters.ContainsKey('CimSession')) {
          $DSCJob = Test-DSCConfiguration -ReferenceConfiguration $mofFile -CimSession $CimSession -AsJob |
            Wait-Job -Timeout $JobTimeout
        } else {
          $DSCJob = Test-DSCConfiguration -ReferenceConfiguration $mofFile -CimSession $ComputerName -AsJob |
            Wait-Job -Timeout $JobTimeout
        }
        if(!$DSCJob) {
          $JobFailedError = "$ComputerName was unable to complete in the alloted job timeout period of $JobTimeout seconds"
          for ($i = 1; $i -lt 10; $i++) {
            Repair-DSCEngine -ComputerName $ComputerName -ErrorAction 'SilentlyContinue'
          }
          return
        }
        $Compliance = Receive-Job $DSCJob -ErrorVariable 'JobFailedError'
        Remove-Job $DSCJob
      } catch {
        $JobFailedError = $_
      }
    }

    if($PSBoundParameters.ContainsKey('CimSession')) {
      return [PSCustomObject]@{
        RunTime    = $RunTime
        Compliance = $Compliance
        Exception  = $JobFailedError
        Computer   = $CimSession.ComputerName
      }
    } else {
      return [PSCustomObject]@{
        RunTime    = $RunTime
        Compliance = $Compliance
        Exception  = $JobFailedError
        Computer   = $computer
      }
    }
  }

  $Jobs = @()
  $Results = @()

  if($PSBoundParameters.ContainsKey('Path')) {
    $targets = Get-ChildItem -Path $Path | Where-Object { ($_.Name -like '*.mof') -and ($_.Name -notlike '*.meta.mof') }
    $targets | Sort-Object | ForEach-Object {
      $JobParameters = @{
        Computer        = $_.BaseName
        MofFile         = $_.FullName
        JobTimeout      = $JobTimeout
        ModulesRequired = Get-MOFRequiredModules -mofFile $_.FullName
        FunctionRoot    = $functionRoot
      }
      if($PSBoundParameters.ContainsKey('Force')) {
        $JobParameters += @{Force = $true }
      }
      $job = [Powershell]::Create().AddScript($ScriptBlock).AddParameters($JobParameters)
      Write-Verbose "Initiating DSCEA scan on $_"
		    $job.RunSpacePool = $RunspacePool
      $Jobs += [PSCustomObject]@{
        Pipe   = $job
        Result = $job.BeginInvoke()
      }
    }
  }

  if($PSBoundParameters.ContainsKey('CimSession')) {
    $MofFile = (Get-Item $MofFile).FullName
    $ModulesRequired = Get-MOFRequiredModules -mofFile $MofFile
    $CimSession | ForEach-Object {
      $JobParameters = @{
        CimSession      = $_
        MofFile         = $MofFile
        JobTimeout      = $JobTimeout
        ModulesRequired = $ModulesRequired
        FunctionRoot    = $functionRoot
      }
      if($PSBoundParameters.ContainsKey('Force')) {
        $JobParameters += @{Force = $true }
      }
      $job = [Powershell]::Create().AddScript($ScriptBlock).AddParameters($JobParameters)
      Write-Verbose ('Initiating DSCEA scan on {0}' -f $_.ComputerName)
		    $job.RunSpacePool = $RunspacePool
      $Jobs += [PSCustomObject]@{
        Pipe   = $job
        Result = $job.BeginInvoke()
      }
    }
  }

  if($PSBoundParameters.ContainsKey('ComputerName')) {
    $MofFile = (Get-Item $MofFile).FullName
    $ModulesRequired = Get-MOFRequiredModules -mofFile $MofFile
    $FirstRunList = $ComputerName
    $PSResults = Invoke-Command -ComputerName $FirstRunList -ErrorAction SilentlyContinue -AsJob -ScriptBlock {
      $PSVersionTable.PSVersion
    } | Wait-Job -Timeout $JobTimeout
    $PSJobResults = Receive-Job $PSResults

    $RunList = ($PSJobResults | where-object -Property Major -ge 5).PSComputername
    $VersionErrorList = ($PSJobResults | where-object -Property Major -lt 5).PSComputername

    $PSVersionErrorsFile = Join-Path -Path $LogsPath -ChildPath ('PSVersionErrors.{0}.xml' -f (Get-Date -Format 'yyyyMMdd-HHmm-ss'))

    Write-Verbose "Connectivity testing complete"
    if($VersionErrorList) {
      Write-Warning "The following systems cannot be scanned as they are not running PowerShell 5.  Please check '$VersionErrorList' for details"
    }
    $RunList | Sort-Object | ForEach-Object {
      $JobParameters = @{
        Computer        = $_
        MofFile         = $MofFile
        JobTimeout      = $JobTimeout
        ModulesRequired = $ModulesRequired
        FunctionRoot    = $functionRoot
      }
      if($PSBoundParameters.ContainsKey('Force')) {
        $JobParameters += @{Force = $true }
      }
      $job = [Powershell]::Create().AddScript($ScriptBlock).AddParameters($JobParameters)
      Write-Verbose "Initiating DSCEA scan on $_"
		    $job.RunSpacePool = $RunspacePool
      $Jobs += [PSCustomObject]@{
        Pipe   = $job
        Result = $job.BeginInvoke()
      }
    }
  }

  if($PSBoundParameters.ContainsKey('InputFile')) {
    $MofFile = (Get-Item $MofFile).FullName
    $ModulesRequired = Get-MOFRequiredModules -mofFile $MofFile
    $FirstRunList = Get-Content $InputFile
    $PSResults = Invoke-Command -ComputerName $FirstRunList -ErrorAction SilentlyContinue -AsJob -ScriptBlock {
      $PSVersionTable.PSVersion
    } | Wait-Job -Timeout $JobTimeout
    $PSJobResults = Receive-Job $PSResults

    $RunList = ($PSJobResults | where-object -Property Major -ge 5).PSComputername
    $VersionErrorList = ($PSJobResults | where-object -Property Major -lt 5).PSComputername

    $PSVersionErrorsFile = Join-Path -Path $LogsPath -ChildPath ('PSVersionErrors.{0}.xml' -f (Get-Date -Format 'yyyyMMdd-HHmm-ss'))

    Write-Verbose "Connectivity testing complete"
    if($VersionErrorList) {
      Write-Warning "The following systems cannot be scanned as they are not running PowerShell 5.  Please check '$VersionErrorList' for details"
    }
    $RunList | Sort-Object | ForEach-Object {
      $JobParameters = @{
        Computer        = $_
        MofFile         = $MofFile
        JobTimeout      = $JobTimeout
        ModulesRequired = $ModulesRequired
        FunctionRoot    = $functionRoot
      }
      if($PSBoundParameters.ContainsKey('Force')) {
        $JobParameters += @{Force = $true }
      }
      $job = [Powershell]::Create().AddScript($ScriptBlock).AddParameters($JobParameters)
      Write-Verbose "Initiating DSCEA scan on $_"
		    $job.RunSpacePool = $RunspacePool
      $Jobs += [PSCustomObject]@{
        Pipe   = $job
        Result = $job.BeginInvoke()
      }
    }
  }


  #Wait for Jobs to Complete
  Write-Verbose "Processing Compliance Testing..."
  $OverallTimeout = New-TimeSpan -Seconds $ScanTimeout
  $ElapsedTime = [system.diagnostics.stopwatch]::StartNew()
  do {
    Start-Sleep -Milliseconds 500
    $JobsComplete = ($Jobs.result.IsCompleted | Where-Object { $_ -eq $true }).count

    #percentage complete can be added as the number of jobs completed out of the number of total jobs
    Write-Progress -activity "Working..." -PercentComplete (($JobsComplete / $Jobs.count) * 100) -status "$([String]::Format("Time Elapsed: {0:d2}:{1:d2}:{2:d2}     Jobs Complete: {3} of {4} ", $ElapsedTime.Elapsed.hours, $ElapsedTime.Elapsed.minutes, $ElapsedTime.Elapsed.seconds, $JobsComplete, $Jobs.count))";

    if($ElapsedTime.elapsed -gt $OverallTimeout) {
      Write-Warning "The DSCEA scan was unable to complete because the timeout value of $($OverallTimeout.TotalSeconds) seconds was exceeded."
      return
    }
  } while (($Jobs.Result.IsCompleted -contains $false) -and ($ElapsedTime.elapsed -lt $OverallTimeout)) #while elapsed time < 1 hour by default

  #Retrieve Jobs
  $Jobs | ForEach-Object {
    $Results += $_.Pipe.EndInvoke($_.Result)
  }

  ForEach ($ExceptionWarning in $Results.Exception) {
    Write-Warning $ExceptionWarning
  }

  #Save Results
  Write-Verbose "$([String]::Format("Total Scan Time: {0:d2}:{1:d2}:{2:d2}", $ElapsedTime.Elapsed.hours, $ElapsedTime.Elapsed.minutes, $ElapsedTime.Elapsed.seconds))"
  $Results | Export-Clixml -Path (Join-Path  -Path $OutputPath -Child $ResultsFile) -Force
  Get-ItemProperty (Join-Path  -Path $OutputPath -Child $ResultsFile)

  #This function will display a divide by zero message if no computers are provided that are running PowerShell 5 or above
  if($VersionErrorList) {
    #add in comma separated option for multiple systems
    Write-Warning "The DSCEA scan completed but did not scan all systems.  Please check '$PSVersionErrorsFile' for details"
    $VersionErrorList | Export-Clixml -Path $PSVersionErrorsFile -Force
  }

  if($Results.Exception) {
    Write-Warning "The DSCEA scan completed but job errors were detected.  Please check '$ResultsFile' for details"
  }

}
