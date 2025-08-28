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

### 2. Get Publish Profile

1. In your Azure Web App, go to **Overview** → **Get publish profile**
2. Download the `.publishsettings` file
3. Open the file and copy the `publishUrl`, `userName`, and `userPWD` values

### 3. Configure GitHub Secrets

1. Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**
2. Add the following secret:
   - **Name**: `AZURE_WEBAPP_PUBLISH_PROFILE`
   - **Value**: Paste the entire content of the `.publishsettings` file

### 4. Update Workflow Configuration

1. Edit `.github/workflows/azure-deploy.yml`
2. Change `AZURE_WEBAPP_NAME` to match your Azure Web App name:
   ```yaml
   env:
     AZURE_WEBAPP_NAME: your-actual-webapp-name
   ```

### 5. Push to Main Branch

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
2. **Deployment failures**: Verify the publish profile secret is correctly set
3. **Azure authentication**: Check that the publish profile has the correct permissions

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
