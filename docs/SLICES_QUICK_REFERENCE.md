# Slices.Network Quick Reference

Fast lookup guide for common operational tasks.

## Service Management

```bash
# Check status
systemctl status slices-network-slices-api
systemctl status slices-network-slices-frontend
systemctl status postgresql

# View logs (last 50 lines)
journalctl -u slices-network-slices-api -n 50

# Real-time logs
journalctl -u slices-network-slices-api -f

# Restart service
sudo systemctl restart slices-network-slices-api

# Restart all Slices services
sudo systemctl restart slices-network-slices-{api,frontend}
```

## Database Operations

```bash
# Connect to database
psql postgresql://slices_user@localhost/slices

# Check database size
psql -c "SELECT pg_size_pretty(pg_database_size('slices'));"

# List tables
psql -c "\dt"

# Check table sizes
psql -c "SELECT relname, pg_size_pretty(pg_total_relation_size(oid))
         FROM pg_class ORDER BY pg_total_relation_size(oid) DESC;"

# List active connections
psql -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"

# Backup database
pg_dump postgresql://slices_user@localhost/slices > backup.sql

# Restore database
psql postgresql://slices_user@localhost/slices < backup.sql

# Run migrations manually
sqlx migrate run --database-url "postgresql://slices_user@localhost/slices"

# Clean up logs table (manually)
psql -c "DELETE FROM logs WHERE created_at < NOW() - INTERVAL '30 days';"
```

## Configuration Changes

```bash
# Edit NixOS configuration
sudo nano /etc/nixos/configuration.nix

# Check syntax
sudo nix flake check

# Build new configuration
sudo nixos-rebuild dry-run

# Apply changes
sudo nixos-rebuild switch

# Rollback to previous generation
sudo nixos-rebuild rollback

# List all generations
nix-env --list-generations -p /nix/var/nix/profiles/system
```

## Health Checks

```bash
# API health
curl http://localhost:3000/xrpc/network.slices.slice.stats

# Jetstream status
curl http://localhost:3000/xrpc/network.slices.slice.getJetstreamStatus

# Frontend availability
curl http://localhost:8080

# Database connection
psql -c "SELECT version();"

# Redis connection
redis-cli ping

# PostgreSQL connections
psql -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"
```

## Monitoring

```bash
# Watch service status (updates every 2 seconds)
watch -n 2 'systemctl status slices-network-slices-api | head -20'

# Monitor database connections in real-time
watch -n 1 'psql -c "SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;"'

# Top resource consumers
ps aux --sort=-%mem | head -10
ps aux --sort=-%cpu | head -10

# Disk usage
df -h
du -sh /var/lib/postgresql
du -sh /var/lib/slices
du -sh /var/backup/postgresql

# Network connections
ss -tlnp | grep -E "3000|8080|5432|6379"
```

## Secret Management (agenix)

```bash
# Edit a secret file
agenix -e secrets/db-password.age

# Rekey all secrets (when SSH keys change)
agenix --rekey

# View secret content (only on system with keys)
cat /run/secrets/slices-db-password
```

## Multi-Tenant Operations

```bash
# Check tenant configuration
cat /var/lib/slices/tenant-config.json

# Per-tenant database
psql postgresql://tenant1_user@localhost/slices_tenant1

# Per-tenant logs
journalctl -u slices-network-slices-api | grep "tenant1"

# Inspect tenant metrics (via API)
curl -H "X-Tenant-ID: tenant1" http://localhost:3000/xrpc/network.slices.slice.stats
```

## Troubleshooting

```bash
# Full service logs (last hour)
journalctl -u slices-network-slices-api --since "1 hour ago"

# Logs with full output (not truncated)
journalctl -u slices-network-slices-api -o verbose

# Export logs to file
journalctl -u slices-network-slices-api > /tmp/api-logs.txt

# Test database connection with timeout
timeout 5 psql "postgresql://slices_user@localhost/slices" -c "SELECT 1;" || echo "Connection failed"

# Check if ports are in use
ss -tlnp | grep -E "3000|8080"

# Verify PostgreSQL extensions
psql postgresql://slices_user@localhost/slices -c "\dx"

# Check migrations status
psql postgresql://slices_user@localhost/slices -c "SELECT * FROM _sqlx_migrations ORDER BY installed_on DESC;"
```

## Common Issues & Solutions

### Service Won't Start
```bash
# 1. Check logs
journalctl -u slices-network-slices-api -n 100

# 2. Verify database
psql postgresql://slices_user@localhost/slices -c "SELECT 1;"

# 3. Check port binding
ss -tlnp | grep 3000

# 4. Test with debug logging
RUST_LOG=debug systemctl start slices-network-slices-api
```

### Database Connection Issues
```bash
# Test connection string
psql "postgresql://slices_user@localhost/slices" -c "SELECT 1;"

# Check PostgreSQL is running
systemctl status postgresql

# View PostgreSQL logs
journalctl -u postgresql -n 50

# Verify database user permissions
psql -U postgres -c "\du"
```

### Jetstream Not Connecting
```bash
# Check status
curl http://localhost:3000/xrpc/network.slices.slice.getJetstreamStatus

# Verify cursor position
psql -c "SELECT * FROM jetstream_cursor;"

# Check logs for connection errors
journalctl -u slices-network-slices-api | grep -i jetstream

# Note: Service auto-reconnects with exponential backoff
```

### OAuth Login Fails
```bash
# Verify configuration
echo "Client ID: $OAUTH_CLIENT_ID"
echo "Redirect URI should be: https://slices.example.com/oauth/callback"

# Check OAuth endpoint
curl https://auth.example.com/.well-known/oauth-authorization-server

# View frontend logs for details
journalctl -u slices-network-slices-frontend | grep -i oauth
```

## Backup Procedures

```bash
# Manual full backup
pg_dump "postgresql://slices_user@localhost/slices" \
  | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Backup all databases (multi-tenant)
pg_dump -h localhost -U postgres -a -b --no-owner \
  | gzip > full_backup_$(date +%Y%m%d).sql.gz

# Backup specific table
pg_dump -t record "postgresql://slices_user@localhost/slices" \
  > records_backup.sql

# Verify backup integrity
gunzip -c backup_20251107.sql.gz | head -50

# Restore from backup
psql postgresql://slices_user@localhost/slices < backup.sql

# Restore from compressed backup
gunzip -c backup_20251107.sql.gz | \
  psql postgresql://slices_user@localhost/slices
```

## Performance Tuning

```bash
# Check slow queries
psql -c "SELECT query, calls, mean_exec_time FROM pg_stat_statements
         ORDER BY mean_exec_time DESC LIMIT 10;"

# Analyze query plan
psql -c "EXPLAIN ANALYZE SELECT * FROM record WHERE did = 'did:example';"

# Check index usage
psql -c "SELECT schemaname, tablename, indexname, idx_scan
         FROM pg_stat_user_indexes ORDER BY idx_scan;"

# Force vacuum and analyze
psql -c "VACUUM ANALYZE;"

# Check statistics
psql -c "SELECT relname, last_vacuum, last_autovacuum
         FROM pg_stat_user_tables WHERE schemaname = 'public';"
```

## Useful Commands Cheat Sheet

| Task | Command |
|------|---------|
| API status | `curl http://localhost:3000/xrpc/network.slices.slice.stats` |
| Frontend status | `curl http://localhost:8080` |
| DB connection | `psql postgresql://slices_user@localhost/slices -c "SELECT 1;"` |
| Service logs | `journalctl -u slices-network-slices-api -f` |
| Disk usage | `du -sh /var/lib/{postgresql,slices}` |
| Active connections | `psql -c "SELECT count(*) FROM pg_stat_activity;"` |
| Recent logs | `psql -c "SELECT * FROM logs ORDER BY created_at DESC LIMIT 20;"` |
| Job queue status | `psql -c "SELECT COUNT(*) FROM mq_msgs;"` |
| Jetstream cursor | `psql -c "SELECT * FROM jetstream_cursor;"` |
| Restart API | `sudo systemctl restart slices-network-slices-api` |
| Restart all | `sudo systemctl restart slices-network-slices-{api,frontend}` |
| Full backup | `pg_dump postgresql://slices_user@localhost/slices \| gzip > backup_$(date +%Y%m%d).sql.gz` |
| Configuration | `sudo nano /etc/nixos/configuration.nix && sudo nixos-rebuild switch` |

## Emergency Procedures

### Service Completely Down

```bash
# 1. Check if database is running
systemctl status postgresql

# 2. Start PostgreSQL if needed
sudo systemctl start postgresql

# 3. Wait 10 seconds
sleep 10

# 4. Start services manually
sudo systemctl start slices-network-slices-api
sudo systemctl start slices-network-slices-frontend

# 5. Monitor recovery
journalctl -u slices-network-slices-api -f
```

### Out of Disk Space

```bash
# 1. Check disk usage
df -h

# 2. Find large files
du -sh /* | sort -rh

# 3. Clean old logs
psql -c "DELETE FROM logs WHERE created_at < NOW() - INTERVAL '7 days';"

# 4. Vacuum database
psql -c "VACUUM ANALYZE;"

# 5. Check /tmp and /var/tmp
sudo rm -rf /tmp/*
```

### Database Corruption

```bash
# 1. Stop services
sudo systemctl stop slices-network-slices-api slices-network-slices-frontend

# 2. Restore from backup
psql postgresql://slices_user@localhost/slices < backup.sql

# 3. Verify integrity
psql -c "SELECT COUNT(*) FROM record;"

# 4. Restart services
sudo systemctl start slices-network-slices-api
sudo systemctl start slices-network-slices-frontend
```

---

For detailed information, see [SLICES_NIXOS_DEPLOYMENT_GUIDE.md](SLICES_NIXOS_DEPLOYMENT_GUIDE.md)
