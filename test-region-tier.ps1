# Test script for region tier checking
Write-Host "Testing Region Tier Support" -ForegroundColor Green
Write-Host "==========================" -ForegroundColor Green

# Function to find regions with specific tier support
function Find-RegionWithTierSupport {
    Write-Host "`nWhat tier are you looking for?" -ForegroundColor Cyan
    Write-Host "1. F1 - Free (most restrictive)" -ForegroundColor White
    Write-Host "2. B1 - Basic" -ForegroundColor White
    Write-Host "3. S1 - Standard" -ForegroundColor White
    Write-Host "4. P1V2 - Premium" -ForegroundColor White
    
    $tierToFind = Read-Host "Select tier to check (1-4) [default: F1]"
    
    switch ($tierToFind) {
        "1" { $tierToFind = "F1" }
        "2" { $tierToFind = "B1" }
        "3" { $tierToFind = "S1" }
        "4" { $tierToFind = "P1V2" }
        default { $tierToFind = "F1" }
    }
    
    Write-Host "`nSearching for regions that support $tierToFind tier..." -ForegroundColor Yellow
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
                    Write-Host "✅ $region supports $tierToFind" -ForegroundColor Green
                } else {
                    Write-Host "❌ $region does not support $tierToFind" -ForegroundColor Red
                }
                
                # Clean up temporary resources
                $null = az group delete --name $testGroupName --yes --output none 2>$null
            }
        } catch {
            Write-Host "⚠️  Could not test $region" -ForegroundColor Yellow
        }
        
        # Small delay to avoid rate limiting
        Start-Sleep -Milliseconds 500
    }
    
    Write-Host "`nRegion testing completed!" -ForegroundColor Green
    
    if ($supportedRegions.Count -gt 0) {
        Write-Host "`n🎉 Found $($supportedRegions.Count) regions that support $tierToFind" -ForegroundColor Green
        for ($i = 0; $i -lt $supportedRegions.Count; $i++) {
            Write-Host "$($i + 1). $($supportedRegions[$i])" -ForegroundColor White
        }
        
        $regionChoice = Read-Host "`nSelect a region (1-$($supportedRegions.Count)) or enter custom region name"
        
        if ($regionChoice -match '^\d+$' -and [int]$regionChoice -le $supportedRegions.Count) {
            $selectedRegion = $supportedRegions[[int]$regionChoice - 1]
            Write-Host "`nSelected region: $selectedRegion" -ForegroundColor Green
            return $selectedRegion
        } else {
            Write-Host "`nSelected region: $regionChoice" -ForegroundColor Green
            return $regionChoice
        }
    } else {
        Write-Host "`n❌ No regions found that support $tierToFind tier" -ForegroundColor Red
        Write-Host "Try using a different tier (B1 instead of F1)" -ForegroundColor Yellow
        
        $fallbackRegion = Read-Host "Enter a region to try anyway (e.g., East US)"
        if (-not $fallbackRegion) { $fallbackRegion = "East US" }
        Write-Host "`nSelected region: $fallbackRegion" -ForegroundColor Green
        return $fallbackRegion
    }
}

# Run the function
$selectedRegion = Find-RegionWithTierSupport
Write-Host "`nFinal result: $selectedRegion" -ForegroundColor Magenta
