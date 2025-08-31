# TestAzureActionGithub

A .NET 8.0 Blazor application with automated deployment to Azure Web App using GitHub Actions.

## Features

- .NET 8.0 Blazor Server application
- Automated CI/CD pipeline with GitHub Actions
- Azure Web App deployment
- Pull request validation
- Automated testing

## Prerequisites

- .NET 8.0 SDK
- Azure subscription
- GitHub repository

## Setup Instructions

You have two options for setting up Azure resources:

### **Option A: Automated Setup (Recommended)**
Use the PowerShell script for quick, automated Azure resource creation.
- **Best for**: Developers who want fast setup, have Azure CLI installed
- **Time**: ~5-10 minutes
- **Requirements**: Azure CLI, PowerShell, Azure permissions
- **Note**: Free F1 tier available for development/testing (limited resources, may have quota restrictions)

### **Option B: Manual Setup**
Follow the step-by-step instructions to create resources manually in Azure Portal.
- **Best for**: Learning Azure, troubleshooting, or when PowerShell isn't available
- **Time**: ~15-20 minutes
- **Requirements**: Azure Portal access, Azure permissions

---

### **Option A: Automated Setup with PowerShell Script**

**New in this version**: The script now **always prompts for all values** instead of using defaults, making it more interactive and user-friendly!

**Prerequisites:**
- Azure CLI installed ([Download here](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli))
- Logged in to Azure (`az login`)
- Active Azure subscription

**Steps:**
1. **Run the setup script:**
   ```powershell
   .\setup-azure-deployment.ps1
   ```
   
   **Note**: The script will now prompt you for all values interactively. You can still use parameters if desired:
   ```powershell
   .\setup-azure-deployment.ps1 -WebAppName "myapp-prod" -ResourceGroupName "myapp-rg" -Location "Central US" -Sku "F1"
   ```
   
   **Script Execution Options:**
   - **PowerShell**: `.\setup-azure-deployment.ps1`
   - **Command Prompt**: `powershell -ExecutionPolicy Bypass -File setup-azure-deployment.ps1`
   - **With Parameters**: Add `-WebAppName`, `-ResourceGroupName`, `-Location`, `-Sku` to skip specific prompts

2. **The script will interactively prompt you for:**
   - **Region Selection**: Choose from popular regions (East US, West US 2, Central US, Europe, Asia, etc.) or enter custom ones
   - **Region Tier Support Check**: Option to find regions that support specific tiers (especially useful for Free F1 tier which often has quota restrictions)
   - **Web App Name**: Enter a globally unique name for your Azure Web App
   - **Resource Group Name**: Enter a name for organizing your Azure resources
   - **App Service Plan Tier**: Choose from Free (F1), Basic (B1), Standard (S1), or Premium (P1V2) tiers
   
   **Then automatically:**
   - Create Resource Group
   - Create App Service Plan
   - Create Azure Web App
   - Download publish profile
   - Save it as `publish-profile.xml`

3. **Interactive Features Explained:**
   
   **Region Selection Options:**
   - **Options 1-7**: Popular regions with descriptions (East US, West US 2, Central US, North Europe, West Europe, East Asia, Southeast Asia)
   - **Option 8**: **Find regions with specific tier support** - This feature tests multiple regions to find which ones support your desired tier (especially useful for Free F1 tier which has quota restrictions)
   - **Option 9**: Enter a custom region name
   
   **Tier Selection:**
   - **F1 (Free)**: $0/month, shared resources, 1GB RAM, 60 minutes/day CPU - May have quota restrictions
   - **B1 (Basic)**: ~$12-15/month, dedicated resources, 1.75GB RAM, unlimited CPU
   - **S1 (Standard)**: ~$70-80/month, dedicated resources, 1.75GB RAM, unlimited CPU
   - **P1V2 (Premium)**: ~$140-160/month, dedicated resources, 2GB RAM, unlimited CPU
   - **Custom**: Enter any other SKU (e.g., B2, S2, P2V2)

4. **After script completion:**
   - **Copy the entire content** from `publish-profile.xml` file:
     - Open the `publish-profile.xml` file in any text editor (Notepad, VS Code, etc.)
     - Select **all content** (Ctrl+A) and copy it (Ctrl+C)
     - The content should start with `<?xml version="1.0"` and contain the complete publish profile XML
     - **Important**: Copy the entire XML content, not just individual values

5. **Configure GitHub Secrets:**
   - Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**
   - Click **New repository secret**
   - Add the following secret:
     - **Name**: `AZURE_WEBAPP_PUBLISH_PROFILE`
     - **Value**: Paste the **entire XML content** from the `publish-profile.xml` file you copied
   - Click **Add secret**
   - **Note**: The secret value should start with `<?xml version="1.0"` and contain the complete publish profile XML

6. **Continue with [Update Workflow Configuration](#5-update-workflow-configuration)** (the script only creates Azure resources)

---

### **Option B: Manual Setup**

1. Go to the [Azure Portal](https://portal.azure.com)
2. Create a new Web App with the following settings:
   - **Runtime stack**: .NET 8 (LTS)
   - **Operating System**: Windows
   - **Region**: Choose your preferred region
   - **App Service Plan**: Create new or use existing

### 2. Enable Publishing Credentials

**Prerequisites**: 
- Ensure you have **Contributor** or **Owner** permissions on the Azure Web App resource

**Enable Publishing Credentials:**
1. Go to your Azure Web App → **Configuration** → **General settings**
2. Set **SCM Basic Auth Publishing Credentials** to **On** (this is the setting that allows downloading publish profiles)
3. **Note**: Do NOT enable "FTP Basic Auth Publishing Credentials" - that's a different setting for FTP deployment
4. Click **Save** to apply the changes

### 3. Get Publish Profile

1. In your Azure Web App, go to **Overview** → **Get publish profile**
2. Download the file (it will be named `your-app-name.publishsettings`)
3. **Important**: Copy the **entire content** of the `your-app-name.publishsettings` file (not just individual values)
4. This file contains XML content that looks like this:
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <publishData>
     <publishProfile profileName="your-webapp-name" publishMethod="MSDeploy" publishUrl="your-webapp-name.scm.azurewebsites.net:443" userName="$your-webapp-name" userPWD="password-here" destinationAppUrl="https://your-webapp-name.azurewebsites.net" />
   </publishData>
   ```
5. You'll use this entire content in the next step

**Note**: If you can't see the "Get publish profile" button or get an access denied error, ensure publishing credentials are enabled and contact your Azure administrator if you need permission changes.

### 4. Configure GitHub Secrets

1. Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add the following secret:
   - **Name**: `AZURE_WEBAPP_PUBLISH_PROFILE`
   - **Value**: Paste the **entire XML content** from the `your-app-name.publishsettings` file you downloaded
4. Click **Add secret**
5. **Note**: The secret value should start with `<?xml version="1.0"` and contain the complete publish profile XML

### 5. Update Workflow Configuration

1. Edit `.github/workflows/azure-deploy.yml`
2. Change `AZURE_WEBAPP_NAME` to match your Azure Web App name:
   ```yaml
   env:
     AZURE_WEBAPP_NAME: your-actual-webapp-name
   ```

### 6. Push to Main Branch

The workflow will automatically trigger when you push to the `main` or `master` branch.

---

## **Important Note**

**Both setup options (Automated and Manual) converge here** - after creating Azure resources and getting the publish profile, you must complete the GitHub configuration steps regardless of which setup method you used.

## Workflow Details

### Main Deployment Workflow (`azure-deploy.yml`)

- **Triggers**: Push to main/master, pull requests, manual dispatch
- **Actions**:
  - Builds the .NET application
  - Runs tests
  - Publishes the application
  - Deploys to Azure Web App

### PR Validation Workflow (`pr-validation.yml`)

- **Triggers**: Pull requests to main/master
- **Actions**:
  - Builds the application
  - Runs tests
  - Performs code analysis

## Local Development

```bash
# Clone the repository
git clone <your-repo-url>
cd TestAzureActionGithub

# Restore dependencies
dotnet restore

# Build the application
dotnet build

# Run the application
dotnet run

# Run tests
dotnet test
```

## Troubleshooting

### Common Issues

1. **Build failures**: Ensure .NET 8.0 SDK is installed
2. **Deployment failures**: 
   - Verify the publish profile secret is correctly set
   - Ensure you copied the **entire XML content**, not just individual values
   - Check that the secret name is exactly `AZURE_WEBAPP_PUBLISH_PROFILE`
3. **Azure authentication**: Check that the publish profile has the correct permissions
4. **Publish profile format**: The secret should contain the complete XML file content from your `your-app-name.publishsettings` file, starting with `<?xml version="1.0"`
5. **Access denied errors**: Ensure you have **Contributor** or **Owner** permissions on the Azure Web App resource
6. **Missing publish profile button**: Check your Azure role assignments and contact your administrator if needed

### Workflow Logs

Check the Actions tab in your GitHub repository for detailed logs and error messages.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

The PR validation workflow will automatically test your changes before merging.

## License

This project is licensed under the MIT License.
#   T r i g g e r   r e b u i l d  
 #   2 0 2 5 - 0 8 - 3 1   1 7 : 1 2 : 5 5   -   T r i g g e r   b u i l d   a f t e r   s e c r e t   u p d a t e  
 