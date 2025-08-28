# Azure Deployment Setup Script
# This script helps you set up the initial configuration for Azure deployment

param(
    [string]$WebAppName,
    [string]$ResourceGroupName,
    [string]$Location = "East US"
)

Write-Host "🚀 Azure Deployment Setup Script" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Check if Azure CLI is installed
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

# Check if user is logged in
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

# Validate parameters
if (-not $WebAppName) {
    $WebAppName = Read-Host "Enter the name for your Azure Web App"
}

if (-not $ResourceGroupName) {
    $ResourceGroupName = Read-Host "Enter the name for your Resource Group"
}

Write-Host "`n📋 Configuration Summary:" -ForegroundColor Cyan
Write-Host "Web App Name: $WebAppName" -ForegroundColor White
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "Location: $Location" -ForegroundColor White

$confirm = Read-Host "`nDo you want to proceed? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Setup cancelled." -ForegroundColor Yellow
    exit 0
}

# Create Resource Group
Write-Host "`n🔧 Creating Resource Group..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create Resource Group" -ForegroundColor Red
    exit 1
}

# Create App Service Plan
Write-Host "🔧 Creating App Service Plan..." -ForegroundColor Yellow
az appservice plan create --name "$WebAppName-plan" --resource-group $ResourceGroupName --location $Location --sku B1 --is-linux

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create App Service Plan" -ForegroundColor Red
    exit 1
}

# Create Web App
Write-Host "🔧 Creating Web App..." -ForegroundColor Yellow
az webapp create --resource-group $ResourceGroupName --plan "$WebAppName-plan" --name $WebAppName --runtime "DOTNETCORE:8.0"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to create Web App" -ForegroundColor Red
    exit 1
}

# Configure Web App
Write-Host "🔧 Configuring Web App..." -ForegroundColor Yellow
az webapp config set --resource-group $ResourceGroupName --name $WebAppName --startup-file "dotnet TestAzureActionGithub.dll"

# Get publish profile
Write-Host "🔧 Getting publish profile..." -ForegroundColor Yellow
$publishProfile = az webapp deployment list-publishing-profiles --resource-group $ResourceGroupName --name $WebAppName --xml 2>$null

if ($LASTEXITCODE -eq 0) {
    $publishProfile | Out-File -FilePath "publish-profile.xml" -Encoding UTF8
    Write-Host "✅ Publish profile saved to publish-profile.xml" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to get publish profile" -ForegroundColor Red
}

Write-Host "`n🎉 Setup Complete!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host "Your Azure Web App has been created successfully!" -ForegroundColor White
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Copy the content of publish-profile.xml" -ForegroundColor White
Write-Host "2. Go to your GitHub repository → Settings → Secrets → Actions" -ForegroundColor White
Write-Host "3. Add a new secret named 'AZURE_WEBAPP_PUBLISH_PROFILE'" -ForegroundColor White
Write-Host "4. Paste the publish profile content as the value" -ForegroundColor White
Write-Host "5. Update the workflow files with your Web App name: $WebAppName" -ForegroundColor White
Write-Host "6. Push your changes to trigger the deployment!" -ForegroundColor White

Write-Host "`n🔗 Useful Links:" -ForegroundColor Cyan
Write-Host "Azure Portal: https://portal.azure.com" -ForegroundColor White
Write-Host "Your Web App: https://$WebAppName.azurewebsites.net" -ForegroundColor White
