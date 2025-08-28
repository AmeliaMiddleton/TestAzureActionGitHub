# Azure Deployment Setup Script
# This script helps you set up the initial configuration for Azure deployment
# It automates the creation of Azure resources needed for your .NET Blazor application
# 
# What this script does:
# 1. Checks if Azure CLI is installed and you're logged in
# 2. Creates a Resource Group to organize your Azure resources
# 3. Creates an App Service Plan to host your web application
# 4. Creates an Azure Web App configured for .NET 8.0
# 5. Downloads the publish profile needed for GitHub Actions deployment
#
# Prerequisites:
# - Azure CLI installed (https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
# - Logged in to Azure (run 'az login' first)
# - Active Azure subscription

# Define script parameters with default values
param(
    [string]$WebAppName,        # Name for your Azure Web App (e.g., "myapp-prod")
    [string]$ResourceGroupName, # Name for your Resource Group (e.g., "myapp-rg")
    [string]$Location = "East US" # Azure region for your resources
)

# Display script header and welcome message
Write-Host "🚀 Azure Deployment Setup Script" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Step 1: Verify Azure CLI is installed and accessible
# This is required for all Azure operations
Write-Host "`n🔍 Checking prerequisites..." -ForegroundColor Cyan
try {
    $azVersion = az --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Azure CLI is installed" -ForegroundColor Green
    } else {
        Write-Host "❌ Azure CLI is not installed. Please install it first." -ForegroundColor Red
        Write-Host "Download from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "❌ Azure CLI is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Step 2: Verify user is authenticated with Azure
# This ensures the script can create and manage Azure resources
try {
    $account = az account show 2>$null | ConvertFrom-Json
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Logged in as: $($account.user.name)" -ForegroundColor Green
    } else {
        Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Not logged in to Azure. Please run 'az login' first." -ForegroundColor Red
    exit 1
}

# Step 3: Collect and validate configuration parameters
# If parameters weren't provided, prompt the user for input
if (-not $WebAppName) {
    $WebAppName = Read-Host "Enter the name for your Azure Web App"
}

if (-not $ResourceGroupName) {
    $ResourceGroupName = Read-Host "Enter the name for your Resource Group"
}

# Display configuration summary for user confirmation
Write-Host "`n📋 Configuration Summary:" -ForegroundColor Cyan
Write-Host "Web App Name: $WebAppName" -ForegroundColor White
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "Location: $Location" -ForegroundColor White

# Ask for user confirmation before proceeding with resource creation
$confirm = Read-Host "`nDo you want to proceed? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Setup cancelled." -ForegroundColor Yellow
    exit 0
}

# Step 4: Create Azure Resource Group
# Resource Groups organize and manage related Azure resources
Write-Host "`n🔧 Creating Resource Group..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create Resource Group" -ForegroundColor Red
    exit 1
}

# Step 5: Create App Service Plan
# App Service Plans define the compute resources and pricing tier for your web apps (Windows for .NET)
Write-Host "🔧 Creating App Service Plan..." -ForegroundColor Yellow
az appservice plan create --name "$WebAppName-plan" --resource-group $ResourceGroupName --location $Location --sku B1

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create App Service Plan" -ForegroundColor Red
    exit 1
}

# Step 6: Create Azure Web App
# This is the actual web application hosting service for your .NET Blazor app
Write-Host "🔧 Creating Web App..." -ForegroundColor Yellow
az webapp create --resource-group $ResourceGroupName --plan "$WebAppName-plan" --name $WebAppName --runtime "DOTNETCORE:8.0"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create Web App" -ForegroundColor Red
    exit 1
}

# Step 7: Configure Web App startup settings
# This tells Azure how to start your .NET Blazor application
Write-Host "🔧 Configuring Web App..." -ForegroundColor Yellow
az webapp config set --resource-group $ResourceGroupName --name $WebAppName --startup-file "dotnet TestAzureActionGithub.dll"

# Step 8: Download publish profile
# The publish profile contains credentials and settings needed for GitHub Actions deployment
Write-Host "🔧 Getting publish profile..." -ForegroundColor Yellow
$publishProfile = az webapp deployment list-publishing-profiles --resource-group $ResourceGroupName --name $WebAppName --xml 2>$null

if ($LASTEXITCODE -eq 0) {
    # Save the publish profile to a local file for easy access
    $publishProfile | Out-File -FilePath "publish-profile.xml" -Encoding UTF8
    Write-Host "✅ Publish profile saved to publish-profile.xml" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to get publish profile" -ForegroundColor Red
}

# Step 9: Display completion message and next steps
Write-Host "`n🎉 Setup Complete!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host "Your Azure Web App has been created successfully!" -ForegroundColor White

# Provide clear next steps for the user to complete the setup
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Copy the content of publish-profile.xml" -ForegroundColor White
Write-Host "2. Go to your GitHub repository - Settings - Secrets - Actions" -ForegroundColor White
Write-Host "3. Add a new secret named AZURE_WEBAPP_PUBLISH_PROFILE" -ForegroundColor White
Write-Host "4. Paste the publish profile content as the value" -ForegroundColor White
Write-Host "5. Update the workflow files with your Web App name: $WebAppName" -ForegroundColor White
Write-Host "6. Push your changes to trigger the deployment!" -ForegroundColor White

# Provide useful links for ongoing management
Write-Host "`n🔗 Useful Links:" -ForegroundColor Cyan
Write-Host "Azure Portal: https://portal.azure.com" -ForegroundColor White
Write-Host "Your Web App: https://$WebAppName.azurewebsites.net" -ForegroundColor White
