#!/usr/bin/env bash
read -s -p "Enter your local development password: " pw
echo
cd parking_management_backend
docker compose exec -e ACCOUNT_PASSWORD="$pw" web python manage.py set_account_password --identifier hoang.dinh.khang@example.com
echo "Password set. Use hoang.dinh.khang@example.com with your password to login."