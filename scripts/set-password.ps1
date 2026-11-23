param(
    [string]$Password = ""
)

if (-not $Password) {
    $pw = Read-Host -AsSecureString 'Enter your local development password:' | ConvertFrom-SecureString
    $Password = $pw
}

cd parking_management_backend
docker compose exec -e ACCOUNT_PASSWORD=$Password web python manage.py set_account_password --identifier hoang.dinh.khang@example.com
Write-Host 'Password set. Use hoang.dinh.khang@example.com with your password to login.'