# Login to Azure using Automation Run As account
$connection = Get-AutomationConnection -Name "AzureRunAsConnection"
Add-AzAccount -ServicePrincipal -TenantId $connection.TenantId `
              -ApplicationId $connection.ApplicationId `
              -CertificateThumbprint $connection.CertificateThumbprint

# Define variables
$keyVaultName = "rotation-kv"
$redisName = "redistesttromel"
$resourceGroupName = "rotation-rg"

# Generate a new secure password for Redis and SQL
$redisNewPassword = [System.Web.Security.Membership]::GeneratePassword(16, 4)

# Step 1: Update Redis password in Key Vault
$redisSecretName = "redis-password"
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $redisSecretName -SecretValue (ConvertTo-SecureString $redisNewPassword -AsPlainText -Force)

# Step 2: Update Redis Cache with the new password
$redisKeys = New-AzRedisCacheKey -ResourceGroupName $resourceGroupName -Name $redisName -RegenerateKeyType Primary
Set-AzRedisCache -ResourceGroupName $resourceGroupName -Name $redisName -RedisConfiguration @{"requirepass" = $redisNewPassword}
