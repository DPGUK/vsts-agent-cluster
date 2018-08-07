$VagrantFolder = "$PSScriptRoot\Vagrant"

function Install-GravtChocolatey {
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "You do not have Administrator rights to run this function!`nPlease re-run this function as an Administrator!"
        Break
    }

    Write-Host "***** Setup chocolatey *****`n" -ForegroundColor Cyan

    # Installing chocolatey
    if (Get-Command choco -errorAction SilentlyContinue) {
        Write-Host "    - Upgrading Chocolatey..." -ForegroundColor Cyan
        & choco upgrade chocolatey -y
    }
    else {
        Write-Host "    - Installing Chocolatey..." -ForegroundColor Cyan
        Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }

    & choco feature enable -n allowGlobalConfirmation | Out-Null

    Write-Host "    - Chocolatey is ready to be used!" -ForegroundColor Green
}

function InstallOrUpdateChocoPackage ($package) {
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "You do not have Administrator rights to run this function!`nPlease re-run this function as an Administrator!"
        Break
    }

    function IsPackageInstalled {
        for ($index = 0; $index -lt $installedPackages.Count; $index++) {
            if ($installedPackages[$index] -Match $package) {
                return $true
            }
        }
        return $false
    }

    if (IsPackageInstalled $package) {
        Write-Host "    - Upgrading $package..." -ForegroundColor Cyan
        & choco upgrade $package -y 
    }
    else {
        Write-Host "    - Installing $package..." -ForegroundColor Cyan
        & choco install $package -y 
    }

    Write-Host "    - $package is ready and up-to-date" -ForegroundColor Green
}

function Install-GravtDependencies {
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Error "You do not have Administrator rights to run this function!`nPlease re-run this function as an Administrator!"
        Break
    }

    Write-Host "***** Installing dependencies *****`n" -ForegroundColor Cyan

    InstallOrUpdateChocoPackage "virtualbox"
    InstallOrUpdateChocoPackage "vagrant"
    InstallOrUpdateChocoPackage "curl"
    InstallOrUpdateChocoPackage "nodejs"
    InstallOrUpdateChocoPackage "seq"
    InstallOrUpdateChocoPackage "dotnetcore-sdk"

    Write-Host "***** Dependencies installed successfully *****`n" -ForegroundColor Green
}

function Start-GravtServices {
    Start-GravtMongoDb
    Start-GravtEventStore
}

function Start-GravtMongoDb {
    Push-Location $VagrantFolder
    & vagrant up mongodb
    Pop-Location
}

function Start-GravtEventStore {
    Push-Location $VagrantFolder
    & vagrant up eventstore
    Pop-Location
}

function Stop-GravtServices {
    Stop-GravtMongoDb
    Stop-GravtEventStore
}

function Stop-GravtMongoDb {
    Push-Location $VagrantFolder
    & vagrant halt mongodb
    Pop-Location
}

function Stop-GravtEventStore {
    Push-Location $VagrantFolder
    & vagrant halt eventstore
    Pop-Location
}

function Reset-GravtServices {
    Reset-GravtEventStore
    Reset-GravtMongoDb
}

function Reset-GravtEventStore {
    Push-Location $VagrantFolder
    & .\eventstore-clear-db.cmd
    & .\eventstore-install-projections.cmd
    Pop-Location
}

function Reset-GravtMongoDb {
    Push-Location $VagrantFolder
    & .\mongodb-clear-db.cmd
    Pop-Location
}

function Get-GravtHelp {
    Write-Host "`nLocal Development Cmdlets" -ForegroundColor Cyan
    Write-Host "    - Start-GravtServices" -ForegroundColor Yellow
    Write-Host "        Start mongo DB and the event store"
    Write-Host "    - Start-GravtMongoDb" -ForegroundColor Yellow
    Write-Host "        Launch Vagrant Setup to start MongoDb localhost:27017"
    Write-Host "    - Start-GravtEventStore" -ForegroundColor Yellow
    Write-Host "        Launch Vagrant Setup to start EventStore (http://localhost:2113 / localhost:1113)"
    Write-Host "    - Reset-GravtServices" -ForegroundColor Yellow
    Write-Host "        Reset data of EventStore and MongoDb"
    Write-Host "    - Reset-GravtEventStore" -ForegroundColor Yellow
    Write-Host "        Reset all data in your Local EventStore Database"
    Write-Host "    - Reset-GravtMongoDb" -ForegroundColor Yellow
    Write-Host "        Reset all data in your Local MongoDb Database"
}

Export-ModuleMember -Function Get-GravtHelp, Install-GravtChocolatey, Install-GravtDependencies, Start-GravtServices, Stop-GravtServices, Reset-GravtServices