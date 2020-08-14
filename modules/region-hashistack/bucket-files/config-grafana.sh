#!/usr/bin/env bash

echo "Waiting 15 seconds for Grafana to come up..."
sleep 15
echo "Continuing..."

curl -X POST -H "Content-Type: application/json" -d @/tmp/files/grafana-datasources.json http://admin:admin@localhost:3000/api/datasources >> /var/log/config-grafana.log 2>&1

curl -X POST -H "Content-Type: application/json" -d @/tmp/files/grafana-dashboard.json http://admin:admin@localhost:3000/api/dashboards/db >> /var/log/config-grafana.log 2>&1

curl -X POST http://admin:admin@localhost:3000/api/user/stars/dashboard/1 >> /var/log/config-grafana.log 2>&1

curl -X PUT -H "Content-Type: application/json" -d @/tmp/files/grafana-preferences.json http://admin:admin@localhost:3000/api/user/preferences >> /var/log/config-grafana.log 2>&1