# Azure Deployment Setup Script with Region Tier Support
# This script helps you set up Azure resources and find regions that support specific tiers

param(
    [string]$WebAppName,
    [string]$ResourceGroupName,
    [string]$Location,
    [string]$Sku
)

# Function to find regions with specific tier support
function Find-RegionWithTierSupport {
    Write-Host "What tier are you looking for?" -ForegroundColor Cyan
    Write-Host "1. F1 - Free (most restrictive)" -ForegroundColor White
    Write-Host "2. B1 - Basic" -ForegroundColor White
    Write-Host "3. S1 - Standard" -ForegroundColor White
    Write-Host "4. P1V2 - Premium" -ForegroundColor White
    
    $tierToFind = Read-Host "Select tier to check (1-4)"
    
    switch ($tierToFind) {
        "1" { $tierToFind = "F1" }
        "2" { $tierToFind = "B1" }
        "3" { $tierToFind = "S1" }
        "4" { $tierToFind = "P1V2" }
        default { 
            $tierToFind = Read-Host "Enter custom tier to check (e.g., F1, B1, S1)"
        }
    }
    
    Write-Host "Searching for regions that support $tierToFind tier..." -ForegroundColor Yellow
    Write-Host "This may take a few minutes..." -ForegroundColor Yellow
    
    # List of regions to test
    $regionsToTest = @(
        "East US", "West US 2", "Central US", "South Central US",
        "North Europe", "West Europe", "East Asia", "Southeast Asia",
        "Canada Central", "Canada East", "Brazil South", "Australia East"
    )
    
    $supportedRegions = @()
    $testedCount = 0
    
    foreach ($region in $regionsToTest) {
        $testedCount++
        Write-Host "Testing region $testedCount of $($regionsToTest.Count): $region" -ForegroundColor Cyan
        
        try {
            # Test if we can create a temporary app service plan in this region
            $testGroupName = "test-group-$([System.Guid]::NewGuid().ToString('N')[0..7] -join '')"
            $testPlanName = "test-plan-$([System.Guid]::NewGuid().ToString('N')[0..7] -join '')"
            
            # Create temporary resource group
            $null = az group create --name $testGroupName --location $region --output none 2>$null
            
            if ($LASTEXITCODE -eq 0) {
                # Try to create app service plan with the specified tier
                $null = az appservice plan create --name $testPlanName --resource-group $testGroupName --location $region --sku $tierToFind --output none 2>$null
                
                if ($LASTEXITCODE -eq 0) {
                    $supportedRegions += $region
                    Write-Host "$region supports $tierToFind" -ForegroundColor Green
                } else {
                    Write-Host "$region does not support $tierToFind" -ForegroundColor Red
                }
                
                # Clean up temporary resources
                $null = az group delete --name $testGroupName --yes --output none 2>$null
            }
        } catch {
            Write-Host "Could not test $region" -ForegroundColor Yellow
        }
        
        # Small delay to avoid rate limiting
        Start-Sleep -Milliseconds 500
    }
    
    Write-Host "Region testing completed!" -ForegroundColor Green
    
    if ($supportedRegions.Count -gt 0) {
        Write-Host "Found $($supportedRegions.Count) regions that support $tierToFind" -ForegroundColor Green
        for ($i = 0; $i -lt $supportedRegions.Count; $i++) {
            Write-Host "$($i + 1). $($supportedRegions[$i])" -ForegroundColor White
        }
        
        $regionChoice = Read-Host "Select a region (1-$($supportedRegions.Count)) or enter custom region name"
        
        if ($regionChoice -match '^\d+$' -and [int]$regionChoice -le $supportedRegions.Count) {
            return $supportedRegions[[int]$regionChoice - 1]
        } else {
            return $regionChoice
        }
    } else {
        Write-Host "No regions found that support $tierToFind tier" -ForegroundColor Red
        Write-Host "Try using a different tier (B1 instead of F1)" -ForegroundColor Yellow
        
        $fallbackRegion = Read-Host "Enter a region to try anyway (e.g., East US)"
        return $fallbackRegion
    }
}

# Main script logic
Write-Host "Azure Deployment Setup Script" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# Check Azure CLI
Write-Host "Checking prerequisites..." -ForegroundColor Cyan
try {
    $azVersion = az --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Azure CLI is installed" -ForegroundColor Green
    } else {
        Write-Host "Azure CLI is not installed. Please install it first." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Azure CLI is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check Azure login
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Logged in as: $($account.user.name)" -ForegroundColor Green
    } else {
        Write-Host "Not logged in to Azure. Please run az login first." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Not logged in to Azure. Please run az login first." -ForegroundColor Red
    exit 1
}

# Region selection (always prompt for region)
Write-Host "`nLet's choose your Azure region:" -ForegroundColor Cyan
Write-Host "Popular Azure Regions:" -ForegroundColor Cyan
Write-Host "1. East US (Virginia)" -ForegroundColor White
Write-Host "2. West US 2 (Washington)" -ForegroundColor White
Write-Host "3. Central US (Iowa)" -ForegroundColor White
Write-Host "4. North Europe (Ireland)" -ForegroundColor White
Write-Host "5. West Europe (Netherlands)" -ForegroundColor White
Write-Host "6. East Asia (Hong Kong)" -ForegroundColor White
Write-Host "7. Southeast Asia (Singapore)" -ForegroundColor White
Write-Host "8. Find regions with specific tier support (e.g., Free F1)" -ForegroundColor White
Write-Host "9. Custom - Enter your own region" -ForegroundColor White

$regionChoice = Read-Host "Select region (1-9) or enter custom region name"

switch ($regionChoice) {
    "1" { $Location = "East US" }
    "2" { $Location = "West US 2" }
    "3" { $Location = "Central US" }
    "4" { $Location = "North Europe" }
    "5" { $Location = "West Europe" }
    "6" { $Location = "East Asia" }
    "7" { $Location = "Southeast Asia" }
    "8" { 
        Write-Host "Checking regions with tier support..." -ForegroundColor Cyan
        $Location = Find-RegionWithTierSupport
    }
    "9" { $Location = Read-Host "Enter custom region name (e.g., Canada Central)" }
    default { $Location = Read-Host "Enter region name (e.g., East US)" }
}

Write-Host "Selected region: $Location" -ForegroundColor Green

# Get all required parameters
Write-Host "`nLet's get your configuration details:" -ForegroundColor Cyan
$WebAppName = Read-Host "Enter the name for your Azure Web App"
$ResourceGroupName = Read-Host "Enter the name for your Resource Group"

# Tier selection
Write-Host "`nLet's choose your App Service Plan tier:" -ForegroundColor Cyan
Write-Host "App Service Plan Tiers:" -ForegroundColor Cyan
Write-Host "1. F1 - Free (Shared, 1GB RAM, 60 minutes/day CPU) - $0/month - May have quota restrictions" -ForegroundColor White
Write-Host "2. B1 - Basic (Dedicated, 1.75GB RAM, unlimited CPU) - ~$12-15/month" -ForegroundColor White
Write-Host "3. S1 - Standard (Dedicated, 1.75GB RAM, unlimited CPU) - ~$70-80/month" -ForegroundColor White
Write-Host "4. P1V2 - Premium V2 (Dedicated, 2GB RAM, unlimited CPU) - ~$140-160/month" -ForegroundColor White

$tierChoice = Read-Host "Select tier (1-4) or enter custom SKU"

switch ($tierChoice) {
    "1" { $Sku = "F1" }
    "2" { $Sku = "B1" }
    "3" { $Sku = "S1" }
    "4" { $Sku = "P1V2" }
    default { 
        $Sku = Read-Host "Enter custom SKU (e.g., B2, S2, P2V2)"
    }
}

Write-Host "Selected tier: $Sku" -ForegroundColor Green

# Configuration summary
Write-Host "Configuration Summary:" -ForegroundColor Cyan
Write-Host "Web App Name: $WebAppName" -ForegroundColor White
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "Location: $Location" -ForegroundColor White
Write-Host "App Service Plan: $Sku" -ForegroundColor White

# Confirmation
$confirm = Read-Host "Do you want to proceed? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Setup cancelled." -ForegroundColor Yellow
    exit 0
}

# Create resources
Write-Host "Creating Resource Group..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create Resource Group" -ForegroundColor Red
    exit 1
}

Write-Host "Creating App Service Plan ($Sku)..." -ForegroundColor Yellow
az appservice plan create --name "$WebAppName-plan" --resource-group $ResourceGroupName --location $Location --sku $Sku

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create App Service Plan" -ForegroundColor Red
    Write-Host "This may be due to quota restrictions or region limitations" -ForegroundColor Yellow
    Write-Host "Try using a different region or tier (B1 instead of F1)" -ForegroundColor Yellow
    exit 1
}

Write-Host "Creating Web App..." -ForegroundColor Yellow
az webapp create --resource-group $ResourceGroupName --plan "$WebAppName-plan" --name $WebAppName --runtime "dotnet:8"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create Web App" -ForegroundColor Red
    exit 1
}

Write-Host "Configuring Web App..." -ForegroundColor Yellow
az webapp config set --resource-group $ResourceGroupName --name $WebAppName --startup-file "dotnet TestAzureActionGithub.dll"

# Get publish profile
Write-Host "Getting publish profile..." -ForegroundColor Yellow
$publishProfile = az webapp deployment list-publishing-profiles --resource-group $ResourceGroupName --name $WebAppName --xml 2>$null

if ($LASTEXITCODE -eq 0) {
    $publishProfile | Out-File -FilePath "publish-profile.xml" -Encoding UTF8
    Write-Host "Publish profile saved to publish-profile.xml" -ForegroundColor Green
} else {
    Write-Host "Failed to get publish profile" -ForegroundColor Red
}

# Completion
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "Your Azure Web App has been created successfully!" -ForegroundColor White

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Copy the content of publish-profile.xml" -ForegroundColor White
Write-Host "2. Go to your GitHub repository - Settings - Secrets - Actions" -ForegroundColor White
Write-Host "3. Add a new secret named AZURE_WEBAPP_PUBLISH_PROFILE" -ForegroundColor White
Write-Host "4. Paste the publish profile content as the value" -ForegroundColor White
Write-Host "5. Update the workflow files with your Web App name: $WebAppName" -ForegroundColor White
Write-Host "6. Push your changes to trigger the deployment!" -ForegroundColor White

Write-Host "Useful Links:" -ForegroundColor Cyan
Write-Host "Azure Portal: https://portal.azure.com" -ForegroundColor White
Write-Host "Your Web App: https://$WebAppName.azurewebsites.net" -ForegroundColor White
