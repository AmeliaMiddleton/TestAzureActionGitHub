# Azure Deployment Setup Script
# This script helps you set up the initial configuration for Azure deployment
# It automates the creation of Azure resources needed for your .NET Blazor application
# 
# What this script does:
# 1. Checks if Azure CLI is installed and you are logged in
# 2. Creates a Resource Group to organize your Azure resources
# 3. Creates an App Service Plan to host your web application (Free F1 tier available)
# 4. Creates an Azure Web App configured for .NET 8.0
# 5. Downloads the publish profile needed for GitHub Actions deployment
#
# Prerequisites:
# - Azure CLI installed (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
# - Logged in to Azure (run az login first)
# - Active Azure subscription

# Define script parameters with default values
param(
    [string]$WebAppName,        # Name for your Azure Web App (e.g., "myapp-prod")
    [string]$ResourceGroupName, # Name for your Resource Group (e.g., "myapp-rg")
    [string]$Location = "East US", # Azure region for your resources
    [string]$Sku = "F1"        # App Service Plan SKU (F1=Free, B1=Basic, S1=Standard)
)

# Display script header and welcome message
Write-Host "Azure Deployment Setup Script" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# Step 1: Verify Azure CLI is installed and accessible
# This is required for all Azure operations
Write-Host "Checking prerequisites..." -ForegroundColor Cyan
try {
    $azVersion = az --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Azure CLI is installed" -ForegroundColor Green
    } else {
        Write-Host "Azure CLI is not installed. Please install it first." -ForegroundColor Red
        Write-Host "Download from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "Azure CLI is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Step 2: Verify user is authenticated with Azure
# This ensures the script can create and manage Azure resources
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

# Step 3: Collect and validate configuration parameters
# If parameters were not provided, prompt the user for input
if (-not $WebAppName) {
    $WebAppName = Read-Host "Enter the name for your Azure Web App"
}

if (-not $ResourceGroupName) {
    $ResourceGroupName = Read-Host "Enter the name for your Resource Group"
}

# Let user choose the Azure region
if (-not $Location) {
    Write-Host "Popular Azure Regions:" -ForegroundColor Cyan
    Write-Host "1. East US (Virginia) - Good for US East Coast" -ForegroundColor White
    Write-Host "2. West US 2 (Washington) - Good for US West Coast" -ForegroundColor White
    Write-Host "3. Central US (Iowa) - Good for US Central" -ForegroundColor White
    Write-Host "4. North Europe (Ireland) - Good for Europe" -ForegroundColor White
    Write-Host "5. West Europe (Netherlands) - Good for Europe" -ForegroundColor White
    Write-Host "6. East Asia (Hong Kong) - Good for Asia Pacific" -ForegroundColor White
    Write-Host "7. Southeast Asia (Singapore) - Good for Asia Pacific" -ForegroundColor White
    Write-Host "8. Custom - Enter your own region" -ForegroundColor White
    
    $regionChoice = Read-Host "Select region (1-8) or enter custom region name [default: East US]"
    
    switch ($regionChoice) {
        "1" { $Location = "East US" }
        "2" { $Location = "West US 2" }
        "3" { $Location = "Central US" }
        "4" { $Location = "North Europe" }
        "5" { $Location = "West Europe" }
        "6" { $Location = "East Asia" }
        "7" { $Location = "Southeast Asia" }
        "8" { $Location = Read-Host "Enter custom region name (e.g., Canada Central)" }
        default { $Location = "East US" }
    }
    
    Write-Host "Selected region: $Location" -ForegroundColor Green
    
    # Validate region availability
    Write-Host "Validating region availability..." -ForegroundColor Cyan
    try {
        $locations = az account list-locations --query "[?name=='$Location'].{Name:name, DisplayName:displayName}" --output table 2>$null
        if ($LASTEXITCODE -eq 0 -and $locations -and $locations.Length -gt 1) {
            Write-Host "Region $Location is available" -ForegroundColor Green
        } else {
            Write-Host "Warning: Region $Location may not be available or may have limited services" -ForegroundColor Yellow
            Write-Host "   You can continue, but some resources may fail to create" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Could not validate region availability - continuing anyway" -ForegroundColor Yellow
    }
}

# Let user choose the App Service Plan tier
if (-not $Sku) {
    Write-Host "App Service Plan Tiers:" -ForegroundColor Cyan
    Write-Host "1. F1 - Free (Shared, 1GB RAM, 60 minutes/day CPU) - $0/month - May have quota restrictions" -ForegroundColor White
    Write-Host "2. B1 - Basic (Dedicated, 1.75GB RAM, unlimited CPU) - ~$12-15/month" -ForegroundColor White
    Write-Host "3. S1 - Standard (Dedicated, 1.75GB RAM, unlimited CPU) - ~$70-80/month" -ForegroundColor White
    Write-Host "4. P1V2 - Premium V2 (Dedicated, 2GB RAM, unlimited CPU) - ~$140-160/month" -ForegroundColor White
    
    $tierChoice = Read-Host "Select tier (1-4) or enter custom SKU [default: F1]"
    
    switch ($tierChoice) {
        "1" { $Sku = "F1" }
        "2" { $Sku = "B1" }
        "3" { $Sku = "S1" }
        "4" { $Sku = "P1V2" }
        default { 
            $Sku = Read-Host "Enter custom SKU (e.g., B2, S2, P2V2)"
            if (-not $Sku) { $Sku = "F1" }
        }
    }
    
    Write-Host "Selected tier: $Sku" -ForegroundColor Green
}

# Display configuration summary for user confirmation
Write-Host "Configuration Summary:" -ForegroundColor Cyan
Write-Host "Web App Name: $WebAppName" -ForegroundColor White
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "Location: $Location" -ForegroundColor White
Write-Host "App Service Plan: $Sku" -ForegroundColor White

# Ask for user confirmation before proceeding with resource creation
$confirm = Read-Host "Do you want to proceed? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Setup cancelled." -ForegroundColor Yellow
    exit 0
}

# Step 4: Create Azure Resource Group
# Resource Groups organize and manage related Azure resources
Write-Host "Creating Resource Group..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create Resource Group" -ForegroundColor Red
    exit 1
}

# Step 5: Create App Service Plan
# App Service Plans define the compute resources and pricing tier for your web apps (Windows for .NET)
Write-Host "Creating App Service Plan ($Sku)..." -ForegroundColor Yellow
az appservice plan create --name "$WebAppName-plan" --resource-group $ResourceGroupName --location $Location --sku $Sku

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create App Service Plan" -ForegroundColor Red
    Write-Host "This may be due to quota restrictions or region limitations" -ForegroundColor Yellow
    Write-Host "Try using a different region or tier (B1 instead of F1)" -ForegroundColor Yellow
    exit 1
}

# Step 6: Create Azure Web App
# This is the actual web application hosting service for your .NET Blazor app
Write-Host "Creating Web App..." -ForegroundColor Yellow
az webapp create --resource-group $ResourceGroupName --plan "$WebAppName-plan" --name $WebAppName --runtime "DOTNETCORE:8.0"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create Web App" -ForegroundColor Red
    exit 1
}

# Step 7: Configure Web App startup settings
# This tells Azure how to start your .NET Blazor application
Write-Host "Configuring Web App..." -ForegroundColor Yellow
az webapp config set --resource-group $ResourceGroupName --name $WebAppName --startup-file "dotnet TestAzureActionGithub.dll"

# Step 8: Download publish profile
# The publish profile contains credentials and settings needed for GitHub Actions deployment
Write-Host "Getting publish profile..." -ForegroundColor Yellow
$publishProfile = az webapp deployment list-publishing-profiles --resource-group $ResourceGroupName --name $WebAppName --xml 2>$null

if ($LASTEXITCODE -eq 0) {
    # Save the publish profile to a local file for easy access
    $publishProfile | Out-File -FilePath "publish-profile.xml" -Encoding UTF8
    Write-Host "Publish profile saved to publish-profile.xml" -ForegroundColor Green
} else {
    Write-Host "Failed to get publish profile" -ForegroundColor Red
}

# Step 9: Display completion message and next steps
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "Your Azure Web App has been created successfully!" -ForegroundColor White

# Provide clear next steps for the user to complete the setup
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Copy the content of publish-profile.xml" -ForegroundColor White
Write-Host "2. Go to your GitHub repository - Settings - Secrets - Actions" -ForegroundColor White
Write-Host "3. Add a new secret named AZURE_WEBAPP_PUBLISH_PROFILE" -ForegroundColor White
Write-Host "4. Paste the publish profile content as the value" -ForegroundColor White
Write-Host "5. Update the workflow files with your Web App name: $WebAppName" -ForegroundColor White
Write-Host "6. Push your changes to trigger the deployment!" -ForegroundColor White

# Provide useful links for ongoing management
Write-Host "Useful Links:" -ForegroundColor Cyan
Write-Host "Azure Portal: https://portal.azure.com" -ForegroundColor White
Write-Host "Your Web App: https://$WebAppName.azurewebsites.net" -ForegroundColor White
