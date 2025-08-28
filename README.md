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

### 1. Create Azure Web App

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
