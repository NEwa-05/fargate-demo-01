#!/usr/bin/env bash

KEYCLOAK_URL=http://keycloak.mageekbox.eu:8080/auth

# get admin token
ADMIN_PASSWORD="traefikee"

ADMIN_TOKEN=$(curl -L -X POST $KEYCLOAK_URL/realms/master/protocol/openid-connect/token  \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" \
  -d "username=admin" \
  -d "password=$ADMIN_PASSWORD" | jq -r '.access_token')

# create traefiklabs realm
curl -L -X POST $KEYCLOAK_URL/admin/realms \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d @data/realm-export.json

# get clientId
CLIENT_ID=$(curl -L $KEYCLOAK_URL/admin/realms/traefiklabs/clients \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[] | select(.clientId=="demo-app") | .id')

# update demo-app client secret
CLIENT_SECRET=$(curl -L -X POST $KEYCLOAK_URL/admin/realms/traefiklabs/clients/$CLIENT_ID/client-secret \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.value')

# create user
curl -L -X POST $KEYCLOAK_URL/admin/realms/traefiklabs/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d @data/user.json

# get userId
USER_ID=$(curl -L $KEYCLOAK_URL/admin/realms/traefiklabs/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq -r '.[] | select(.username=="traefik") | .id')

# update user password
USER_PASSWORD=$(pwgen -s 16 1)
curl -L -X PUT $KEYCLOAK_URL/admin/realms/traefiklabs/users/$USER_ID/reset-password \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"type\": \"password\", \"temporary\": \"false\", \"value\": \"$USER_PASSWORD\"}"

# get roleId
ROLE_ID=$(curl -L $KEYCLOAK_URL/admin/realms/traefiklabs/roles \
  -H "Authorization: Bearer $ADMIN_TOKEN"| jq -r '.[] | select(.name=="admin") | .id')

# assign role
curl -L -X POST $KEYCLOAK_URL/admin/realms/traefiklabs/users/$USER_ID/role-mappings/realm \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "[{\"id\": \"$ROLE_ID\", \"name\": \"admin\"}]"

echo "demo-app client secret: $CLIENT_SECRET"
echo "traefik user password: $USER_PASSWORD"
