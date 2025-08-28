# Azure Deployment Configuration

This document contains the configuration settings needed for deploying your application to Azure Web App.

## Required GitHub Secrets

Add these secrets in your GitHub repository under **Settings** → **Secrets and variables** → **Actions**:

### Basic Deployment
- `AZURE_WEBAPP_PUBLISH_PROFILE` - The publish profile content from your Azure Web App

### Advanced Deployment (Multi-Environment)
- `AZURE_WEBAPP_PUBLISH_PROFILE_STAGING` - Publish profile for staging environment
- `AZURE_WEBAPP_PUBLISH_PROFILE_PRODUCTION` - Publish profile for production environment

## Environment Variables

### Basic Workflow
Update `.github/workflows/azure-deploy.yml`:
```yaml
env:
  AZURE_WEBAPP_NAME: your-actual-webapp-name
```

### Advanced Workflow
Update `.github/workflows/azure-deploy-advanced.yml`:
```yaml
env:
  AZURE_WEBAPP_NAME_STAGING: your-staging-webapp-name
  AZURE_WEBAPP_NAME_PRODUCTION: your-production-webapp-name
```

## Azure Web App Configuration

### Application Settings
Configure these in your Azure Web App under **Configuration** → **Application settings**:

```json
{
  "ASPNETCORE_ENVIRONMENT": "Production",
  "ASPNETCORE_URLS": "http://localhost:8080",
  "WEBSITES_PORT": "8080"
}
```

### Connection Strings
If your application uses databases, add connection strings under **Configuration** → **Connection strings**.

## Deployment Slots (Optional)

For zero-downtime deployments, consider using deployment slots:

1. **Staging Slot**: For testing before production
2. **Production Slot**: Live application
3. **Swap**: Exchange staging and production slots

## Monitoring and Logging

### Application Insights
Enable Application Insights for monitoring:
1. Go to your Web App → **Application Insights**
2. Enable monitoring
3. Add the instrumentation key to your application settings

### Log Streaming
Monitor real-time logs:
```bash
az webapp log tail --name your-webapp-name --resource-group your-resource-group
```

## Troubleshooting

### Common Deployment Issues

1. **Build Failures**
   - Check .NET version compatibility
   - Verify all dependencies are restored

2. **Deployment Failures**
   - Validate publish profile permissions
   - Check Azure Web App status
   - Verify application settings

3. **Runtime Errors**
   - Check application logs in Azure Portal
   - Verify environment variables
   - Check connection strings

### Useful Azure CLI Commands

```bash
# List web apps
az webapp list --resource-group your-resource-group

# Get web app details
az webapp show --name your-webapp-name --resource-group your-resource-group

# Restart web app
az webapp restart --name your-webapp-name --resource-group your-resource-group

# View logs
az webapp log tail --name your-webapp-name --resource-group your-resource-group
```

## Security Best Practices

1. **Secrets Management**
   - Never commit secrets to source control
   - Use GitHub Secrets for sensitive data
   - Rotate publish profiles regularly

2. **Network Security**
   - Configure IP restrictions if needed
   - Use private endpoints for databases
   - Enable HTTPS only

3. **Access Control**
   - Use managed identities when possible
   - Limit publish profile permissions
   - Monitor access logs
