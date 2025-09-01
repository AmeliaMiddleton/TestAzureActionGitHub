# Azure Deployment Setup Script
# This script creates an Azure Web App for your .NET application

Write-Host "Azure Deployment Setup Script" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# Check Azure CLI
Write-Host "Checking prerequisites..." -ForegroundColor Cyan
try {
    az --version 2>$null
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

# Get configuration details
Write-Host "`nLet's get your configuration details:" -ForegroundColor Cyan
$WebAppName = Read-Host "Enter the name for your Azure Web App"
$ResourceGroupName = Read-Host "Enter the name for your Resource Group"

# Region selection with comprehensive options
Write-Host "`nLet's choose your Azure region:" -ForegroundColor Cyan
Write-Host "Popular Azure Regions:" -ForegroundColor Cyan
Write-Host "1. East US (Virginia) - Recommended for US East Coast" -ForegroundColor White
Write-Host "2. West US 2 (Washington) - Recommended for US West Coast" -ForegroundColor White
Write-Host "3. Central US (Iowa) - Recommended for US Central" -ForegroundColor White
Write-Host "4. South Central US (Texas) - Good for US South" -ForegroundColor White
Write-Host "5. North Europe (Ireland) - Recommended for Europe" -ForegroundColor White
Write-Host "6. West Europe (Netherlands) - Good for Europe" -ForegroundColor White
Write-Host "7. East Asia (Hong Kong) - Good for Asia Pacific" -ForegroundColor White
Write-Host "8. Southeast Asia (Singapore) - Good for Asia Pacific" -ForegroundColor White
Write-Host "9. Canada Central (Toronto) - Good for Canada" -ForegroundColor White
Write-Host "10. Australia East (Sydney) - Good for Australia" -ForegroundColor White
Write-Host "11. Brazil South (Sao Paulo) - Good for South America" -ForegroundColor White
Write-Host "12. Custom - Enter your own region" -ForegroundColor White

$regionChoice = Read-Host "Select region (1-12) or enter custom region name"

switch ($regionChoice) {
    "1" { $Location = "East US" }
    "2" { $Location = "West US 2" }
    "3" { $Location = "Central US" }
    "4" { $Location = "South Central US" }
    "5" { $Location = "North Europe" }
    "6" { $Location = "West Europe" }
    "7" { $Location = "East Asia" }
    "8" { $Location = "Southeast Asia" }
    "9" { $Location = "Canada Central" }
    "10" { $Location = "Australia East" }
    "11" { $Location = "Brazil South" }
    "12" { $Location = Read-Host "Enter custom region name (e.g., Japan East, UK South)" }
    default { $Location = Read-Host "Enter region name (e.g., East US)" }
}

Write-Host "Selected region: $Location" -ForegroundColor Green

# Tier selection with comprehensive options
Write-Host "`nLet's choose your App Service Plan tier:" -ForegroundColor Cyan
Write-Host "Free Tier (Shared Resources):" -ForegroundColor Yellow
Write-Host "1. F1 - Free (Shared, 1GB RAM, 60 minutes/day CPU) - $0/month" -ForegroundColor White
Write-Host "   WARNING: May have quota restrictions, not recommended for production" -ForegroundColor Red

Write-Host "`nBasic Tiers (Dedicated Resources):" -ForegroundColor Yellow
Write-Host "2. B1 - Basic (1.75GB RAM, unlimited CPU) - ~$12-15/month" -ForegroundColor White
Write-Host "3. B2 - Basic (3.5GB RAM, unlimited CPU) - ~$24-30/month" -ForegroundColor White
Write-Host "4. B3 - Basic (7GB RAM, unlimited CPU) - ~$48-60/month" -ForegroundColor White

Write-Host "`nStandard Tiers (Dedicated Resources + Auto-scaling):" -ForegroundColor Yellow
Write-Host "5. S1 - Standard (1.75GB RAM, unlimited CPU) - ~$70-80/month" -ForegroundColor White
Write-Host "6. S2 - Standard (3.5GB RAM, unlimited CPU) - ~$140-160/month" -ForegroundColor White
Write-Host "7. S3 - Standard (7GB RAM, unlimited CPU) - ~$280-320/month" -ForegroundColor White

Write-Host "`nPremium Tiers (Dedicated Resources + Advanced Features):" -ForegroundColor Yellow
Write-Host "8. P1V2 - Premium V2 (2GB RAM, unlimited CPU) - ~$140-160/month" -ForegroundColor White
Write-Host "9. P2V2 - Premium V2 (4GB RAM, unlimited CPU) - ~$280-320/month" -ForegroundColor White
Write-Host "10. P3V2 - Premium V2 (8GB RAM, unlimited CPU) - ~$560-640/month" -ForegroundColor White

Write-Host "`nIsolated Tiers (VNet Integration):" -ForegroundColor Yellow
Write-Host "11. I1 - Isolated (2GB RAM, unlimited CPU) - ~$280-320/month" -ForegroundColor White
Write-Host "12. I2 - Isolated (4GB RAM, unlimited CPU) - ~$560-640/month" -ForegroundColor White

Write-Host "`nRecommended for:" -ForegroundColor Cyan
Write-Host "• Development/Testing: F1 (Free) or B1 (Basic)" -ForegroundColor White
Write-Host "• Small Production: B1 or S1" -ForegroundColor White
Write-Host "• Medium Production: S1 or S2" -ForegroundColor White
Write-Host "• Large Production: S2, S3, or Premium tiers" -ForegroundColor White

$tierChoice = Read-Host "Select tier (1-12) or enter custom SKU"

switch ($tierChoice) {
    "1" { $Sku = "F1" }
    "2" { $Sku = "B1" }
    "3" { $Sku = "B2" }
    "4" { $Sku = "B3" }
    "5" { $Sku = "S1" }
    "6" { $Sku = "S2" }
    "7" { $Sku = "S3" }
    "8" { $Sku = "P1V2" }
    "9" { $Sku = "P2V2" }
    "10" { $Sku = "P3V2" }
    "11" { $Sku = "I1" }
    "12" { $Sku = "I2" }
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
az appservice plan create --name "$WebAppName-plan" --resource-group $ResourceGroupName --location $Location --sku $Sku --is-linux

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create App Service Plan" -ForegroundColor Red
    Write-Host "This may be due to quota restrictions or region limitations" -ForegroundColor Yellow
    Write-Host "Try using a different region or tier (B1 instead of F1)" -ForegroundColor Yellow
    exit 1
}

Write-Host "Creating Linux Web App..." -ForegroundColor Yellow
az webapp create --resource-group $ResourceGroupName --plan "$WebAppName-plan" --name $WebAppName --runtime "DOTNETCORE:8.0"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to create Web App" -ForegroundColor Red
    exit 1
}

Write-Host "Configuring Linux Web App..." -ForegroundColor Yellow
# Set the startup command for Linux web app
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

# Update workflow files with the new Web App name
Write-Host "Updating workflow files..." -ForegroundColor Yellow

# Update basic workflow file
$basicWorkflowPath = ".github/workflows/azure-deploy.yml"
if (Test-Path $basicWorkflowPath) {
    try {
        $content = Get-Content $basicWorkflowPath -Raw
        $updatedContent = $content -replace '(AZURE_WEBAPP_NAME:\s*)[^\r\n]*', "`$1$WebAppName"
        Set-Content $basicWorkflowPath $updatedContent -Encoding UTF8
        Write-Host "Updated $basicWorkflowPath with Web App name: $WebAppName" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not update $basicWorkflowPath" -ForegroundColor Yellow
    }
} else {
    Write-Host "Warning: $basicWorkflowPath not found" -ForegroundColor Yellow
}

# Update advanced workflow file
$advancedWorkflowPath = ".github/workflows/azure-deploy-advanced.yml"
if (Test-Path $advancedWorkflowPath) {
    try {
        $content = Get-Content $advancedWorkflowPath -Raw
        $updatedContent = $content -replace '(AZURE_WEBAPP_NAME:\s*)[^\r\n]*', "`$1$WebAppName"
        Set-Content $advancedWorkflowPath $updatedContent -Encoding UTF8
        Write-Host "Updated $advancedWorkflowPath with Web App name: $WebAppName" -ForegroundColor Green
    } catch {
        Write-Host "Warning: Could not update $advancedWorkflowPath" -ForegroundColor Yellow
    }
} else {
    Write-Host "Warning: $advancedWorkflowPath not found" -ForegroundColor Yellow
}

# Completion with clipboard functionality
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host "Your Azure Web App has been created successfully!" -ForegroundColor White

Write-Host "Next steps:" -ForegroundColor Cyan

# Step 1: Copy secret name to clipboard
Write-Host "1. Copying secret name to clipboard..." -ForegroundColor Yellow
$secretName = "AZURE_WEBAPP_PUBLISH_PROFILE"
Set-Clipboard -Value $secretName
Write-Host "   SUCCESS: Secret name copied to clipboard: $secretName" -ForegroundColor Green
Write-Host "   Go to GitHub → Settings → Secrets → Actions → New repository secret" -ForegroundColor White
Write-Host "   In the 'Name' field, just paste (Ctrl+V) - the secret name is already in your clipboard" -ForegroundColor White
Write-Host "   Press Enter when ready for the next step..." -ForegroundColor Cyan
Read-Host

# Step 2: Copy publish profile content to clipboard
Write-Host "2. Copying publish profile content to clipboard..." -ForegroundColor Yellow
if (Test-Path "publish-profile.xml") {
    $publishContent = Get-Content "publish-profile.xml" -Raw
    Set-Clipboard -Value $publishContent
    Write-Host "   SUCCESS: Publish profile content copied to clipboard!" -ForegroundColor Green
    Write-Host "   In the 'Value' field, just paste (Ctrl+V) - the content is already in your clipboard" -ForegroundColor White
    Write-Host "   Click 'Add secret'" -ForegroundColor White
} else {
    Write-Host "   ERROR: publish-profile.xml not found!" -ForegroundColor Red
    Write-Host "   Please manually copy the content from publish-profile.xml" -ForegroundColor Yellow
}

Write-Host "3. SUCCESS: Workflow files have been automatically updated with Web App name: $WebAppName" -ForegroundColor Green
Write-Host "4. Push your changes to trigger the deployment!" -ForegroundColor White

Write-Host "Useful Links:" -ForegroundColor Cyan
Write-Host "Azure Portal: https://portal.azure.com" -ForegroundColor White
Write-Host "Your Web App: https://$WebAppName.azurewebsites.net" -ForegroundColor White
