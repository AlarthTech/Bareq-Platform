#!/usr/bin/env bash
# Run from your Mac/Linux (not from CI without keys): ./deploy/deploy.sh
# Requires ~/.ssh/config Host "my-server" (Port 2265, User root, etc.)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "==> dotnet publish (linux-x64, self-contained)"
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish/linux-x64

echo "==> rsync to my-server:/var/www/cleaninghouse-api/"
rsync -avz --delete -e ssh ./publish/linux-x64/ my-server:/var/www/cleaninghouse-api/

echo "==> install systemd unit + restart service"
scp "$SCRIPT_DIR/cleaninghouse-api.service" my-server:/tmp/cleaninghouse-api.service
ssh my-server 'set -e
  install -d /var/www/cleaninghouse-api
  chmod +x /var/www/cleaninghouse-api/CleaningHouse_API
  mv /tmp/cleaninghouse-api.service /etc/systemd/system/cleaninghouse-api.service
  systemctl daemon-reload
  systemctl enable cleaninghouse-api
  systemctl restart cleaninghouse-api
  systemctl --no-pager -l status cleaninghouse-api || true
'

echo "==> Done. API should listen on http://SERVER_IP:5545 (see ASPNETCORE_URLS in unit file)."
echo "    Create /etc/cleaninghouse-api.env on the server with secrets, then add to [Service]:"
echo "    EnvironmentFile=/etc/cleaninghouse-api.env"
