# Testing

## Automated
TODO: created ./.github/workflows/ci.yml 

## Manual

### Start test environment with auto-highstate  
docker compose -f docker-compose.yaml -f docker-compose-test.yaml up -d

### Watch the minion auto-apply states (wait ~30 seconds)
timeout 15 docker logs salt-minion-linux-test --follow

### Clean up when done
docker compose -f docker-compose-test.yaml -f docker-compose.yaml down salt-minion-linux

## Manual Testing

### Start just the master
docker compose up -d

### Verify master is healthy
docker compose ps

### Test state syntax validation
docker exec salt-master salt-call --local state.show_sls linux.base
docker exec salt-master salt-call --local state.show_sls windows.win

### Verify packages.sls is accessible
docker exec salt-master salt-call --local cp.list_master | grep packages.sls

### Check file_roots configuration
docker exec salt-master salt-call --local config.get file_roots

If You Have a Real Minion

### Check minion keys
docker exec salt-master salt-key -L

### Test connectivity
docker exec salt-master salt '*' test.ping

## Apply states to all minions
docker exec salt-master salt '*' state.apply

### Apply to specific OS
docker exec salt-master salt 'os_family:Debian' -G state.apply