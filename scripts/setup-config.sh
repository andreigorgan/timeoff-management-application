#!/bin/bash

set -eux pipefile

# Validate if NODE_ENV is set
if [ "$NODE_ENV" == "" ]; then
    echo "NODE_ENV is not set. Please set NODE_ENV."
    exit 1
fi

# Read the app.json file
json_file="/app/config/app.json"
config=$(jq -c '.' "$json_file")

# Update the JSON file with environment variables if they are present
if [ -n "$ALLOW_CREATE_NEW_ACCOUNTS" ]; then
    config=$(echo "$config" | jq --arg ALLOW_CREATE_NEW_ACCOUNTS "$ALLOW_CREATE_NEW_ACCOUNTS" '. + { "allow_create_new_accounts": ($ALLOW_CREATE_NEW_ACCOUNTS | test("true"; "i")) }')
fi

if [ -n "$SEND_EMAILS" ]; then
    config=$(echo "$config" | jq --arg SEND_EMAILS "$SEND_EMAILS" '. + { "send_emails": ($SEND_EMAILS | test("true"; "i")) }')
fi

if [ -n "$APPLICATION_SENDER_MAIL" ]; then
    config=$(echo "$config" | jq --arg APPLICATION_SENDER_MAIL "$APPLICATION_SENDER_MAIL" '. + { "application_sender_email": $APPLICATION_SENDER_MAIL }')
fi

if [ -n "$EMAIL_TRANSPORTER_HOST" ]; then
    config=$(echo "$config" | jq --arg EMAIL_TRANSPORTER_HOST "$EMAIL_TRANSPORTER_HOST" '.email_transporter.host = $EMAIL_TRANSPORTER_HOST')
fi

if [ -n "$EMAIL_TRANSPORTER_PORT" ]; then
    config=$(echo "$config" | jq --arg EMAIL_TRANSPORTER_PORT "$EMAIL_TRANSPORTER_PORT" '.email_transporter.port = ($EMAIL_TRANSPORTER_PORT | tonumber)')
fi

if [ -n "$EMAIL_TRANSPORTER_AUTH_USER" ] && [ -n "$EMAIL_TRANSPORTER_AUTH_PASS" ]; then
    config=$(echo "$config" | jq --arg EMAIL_TRANSPORTER_AUTH_USER "$EMAIL_TRANSPORTER_AUTH_USER" --arg EMAIL_TRANSPORTER_AUTH_PASS "$EMAIL_TRANSPORTER_AUTH_PASS" '.email_transporter.auth.user = $EMAIL_TRANSPORTER_AUTH_USER | .email_transporter.auth.pass = $EMAIL_TRANSPORTER_AUTH_PASS')
fi

if [ -n "$SESSION_STORE_USE_REDIS" ]; then
    config=$(echo "$config" | jq --arg SESSION_STORE_USE_REDIS "$SESSION_STORE_USE_REDIS" '.sessionStore.useRedis = ($SESSION_STORE_USE_REDIS | test("true"; "i"))')
fi

if [ -n "$SESSION_STORE_REDIS_CONNECTION_CONFIGURATION_HOST" ]; then
    config=$(echo "$config" | jq --arg SESSION_STORE_REDIS_CONNECTION_CONFIGURATION_HOST "$SESSION_STORE_REDIS_CONNECTION_CONFIGURATION_HOST" '.sessionStore.redisConnectionConfiguration.host = $SESSION_STORE_REDIS_CONNECTION_CONFIGURATION_HOST')
fi

if [ -n "$SESSION_STORE_REDIS_CONNECTION_CONFIGURATION_PORT" ]; then
    config=$(echo "$config" | jq --arg SESSION_STORE_REDIS_CONNECTION_CONFIGURATION_PORT "$SESSION_STORE_REDIS_CONNECTION_CONFIGURATION_PORT" '.sessionStore.redisConnectionConfiguration.port = ($SESSION_STORE_REDIS_CONNECTION_CONFIGURATION_PORT | tonumber)')
fi

if [ -n "$GA_ANALITICS_ON" ]; then
    config=$(echo "$config" | jq --arg GA_ANALITICS_ON "$GA_ANALITICS_ON" '. + { "ga_analytics_on": ($GA_ANALITICS_ON | test("true"; "i")) }')
fi

if [ -n "$CRYPTO_SECRET" ]; then
    config=$(echo "$config" | jq --arg CRYPTO_SECRET "$CRYPTO_SECRET" '. + { "crypto_secret": $CRYPTO_SECRET }')
fi

if [ -n "$APPLICATION_DOMAIN" ]; then
    config=$(echo "$config" | jq --arg APPLICATION_DOMAIN "$APPLICATION_DOMAIN" '. + { "application_domain": $APPLICATION_DOMAIN }')
fi

if [ -n "$PROMOTION_WEBSITE_DOMAIN" ]; then
    config=$(echo "$config" | jq --arg PROMOTION_WEBSITE_DOMAIN "$PROMOTION_WEBSITE_DOMAIN" '. + { "promotion_website_domain": $PROMOTION_WEBSITE_DOMAIN }')
fi

if [ -n "$LOCALE_CODE_FOR_SORTING" ]; then
    config=$(echo "$config" | jq --arg LOCALE_CODE_FOR_SORTING "$LOCALE_CODE_FOR_SORTING" '. + { "locale_code_for_sorting": $LOCALE_CODE_FOR_SORTING }')
fi

if [ -n "$FORCE_TO_EXPLICITLY_SELECT_TYPE_WHEN_REQUESTING_NEW_LEAVE" ]; then
    config=$(echo "$config" | jq --arg FORCE_TO_EXPLICITLY_SELECT_TYPE_WHEN_REQUESTING_NEW_LEAVE "$FORCE_TO_EXPLICITLY_SELECT_TYPE_WHEN_REQUESTING_NEW_LEAVE" '. + { "force_to_explicitly_select_type_when_requesting_new_leave": ($FORCE_TO_EXPLICITLY_SELECT_TYPE_WHEN_REQUESTING_NEW_LEAVE | test("true"; "i")) }')
fi

# Write the updated config back to the file
echo "$config" > "$json_file"

echo "Configuration updated in $json_file"

# Read the second configuration file
db_config_file="/app/config/db.json"
db_config=$(jq -c '.' "$db_config_file")

# Update the database configuration based on NODE_ENV
case "$NODE_ENV" in
    "development")
        db_config=$(echo "$db_config" | jq '.development.username = $DB_USERNAME | .development.password = $DB_PASSWORD | .development.database = $DB_DATABASE | .development.host = $DB_HOST | .development.dialect = $DB_DIALECT' --arg DB_USERNAME "$DB_USERNAME" --arg DB_PASSWORD "$DB_PASSWORD" --arg DB_DATABASE "$DB_DATABASE" --arg DB_HOST "$DB_HOST" --arg DB_DIALECT "$DB_DIALECT")
        ;;
    "test")
        db_config=$(echo "$db_config" | jq '.test.username = $DB_USERNAME | .test.password = $DB_PASSWORD | .test.database = $DB_DATABASE | .test.host = $DB_HOST | .test.dialect = $DB_DIALECT' --arg DB_USERNAME "$DB_USERNAME" --arg DB_PASSWORD "$DB_PASSWORD" --arg DB_DATABASE "$DB_DATABASE" --arg DB_HOST "$DB_HOST" --arg DB_DIALECT "$DB_DIALECT")
        ;;
    "production")
        db_config=$(echo "$db_config" | jq '.production.username = $DB_USERNAME | .production.password = $DB_PASSWORD | .production.database = $DB_DATABASE | .production.host = $DB_HOST | .production.dialect = $DB_DIALECT' --arg DB_USERNAME "$DB_USERNAME" --arg DB_PASSWORD "$DB_PASSWORD" --arg DB_DATABASE "$DB_DATABASE" --arg DB_HOST "$DB_HOST" --arg DB_DIALECT "$DB_DIALECT")
        ;;
    *)
        echo "Unsupported NODE_ENV: $NODE_ENV"
        exit 1
        ;;
esac

# Write the updated database configuration back to the file
echo "$db_config" > "$db_config_file"

echo "Database configuration updated in $db_config_file"

echo "========= PRINTING CONFIGURATION ========="
cat /app/config/app.json
cat /app/config/db.json