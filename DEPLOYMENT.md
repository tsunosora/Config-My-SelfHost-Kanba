# Kanba Deployment & Migration Guide

## Quick Start untuk Server Baru

### Prerequisites
- Node.js 18+ & npm
- PostgreSQL 15+ (atau Docker)
- Supabase instance
- Cloudflare tunnel (optional)

### Steps

#### 1. Clone Repository
```bash
git clone https://github.com/Kanba-co/kanba.git
cd kanba
```

#### 2. Setup Environment Variables
```bash
# Copy template
cp .env.example .env.local

# Edit dengan credentials Anda
nano .env.local
```

**Variables yang perlu diupdate:**
- `NEXT_PUBLIC_SUPABASE_URL` - Supabase URL
- `NEXT_PUBLIC_SUPABASE_ANON_KEY` - Anon key dari Supabase
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key
- `DATABASE_URL` - PostgreSQL connection string
- `DIRECT_URL` - Direct database connection
- `NEXTAUTH_SECRET` - Random secret key (generate: `openssl rand -base64 32`)
- `NEXT_PUBLIC_SITE_URL` - Your domain
- `NEXTAUTH_URL` - Your domain

#### 3. Install Dependencies
```bash
npm install
```

#### 4. Build Project
```bash
npm run build
```

#### 5. Setup Database (if fresh install)
```bash
# Apply Prisma migrations
npx prisma db push

# Create auth trigger (if using Supabase)
# Run SQL dari supabase/migrations/20250101000000_emergency_fix_profiles_security.sql
```

#### 6. Setup RLS Policies (Supabase)
```bash
# If database restored from backup, re-enable RLS policies:
docker exec supabase-db psql -U postgres postgres << 'EOF'
-- Enable RLS
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Bookmarks policies
DROP POLICY IF EXISTS "Users can view own bookmarks" ON bookmarks;
DROP POLICY IF EXISTS "Users can insert own bookmarks" ON bookmarks;
DROP POLICY IF EXISTS "Users can delete own bookmarks" ON bookmarks;

CREATE POLICY "Users can view own bookmarks" ON bookmarks FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "Users can insert own bookmarks" ON bookmarks FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can delete own bookmarks" ON bookmarks FOR DELETE TO authenticated USING (user_id = auth.uid());

-- Activity logs
DROP POLICY IF EXISTS "Users can view own activities" ON activity_logs;
CREATE POLICY "Users can view own activities" ON activity_logs FOR SELECT TO authenticated USING (user_id = auth.uid());

-- Notifications
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
CREATE POLICY "Users can view own notifications" ON notifications FOR SELECT TO authenticated USING (user_id = auth.uid());

EOF
```

#### 7. Run with PM2
```bash
# Global install PM2 (if not already)
npm install -g pm2

# Start Kanba
pm2 start "npm run start" --name "kanba"

# Save PM2 startup
pm2 save
pm2 startup
```

#### 8. (Optional) Setup Cloudflare Tunnel
```bash
# Install Cloudflare tunnel
curl -L --output cloudflared.tgz https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.tgz
tar -xzf cloudflared.tgz

# Login
./cloudflared login

# Create tunnel
./cloudflared tunnel create kanba

# Route domain
./cloudflared tunnel route dns kanba kanba.yourdomain.com

# Run tunnel
./cloudflared tunnel run kanba
```

---

## Full Automation Script

Jalankan script otomatis:
```bash
bash setup.sh
```

Script ini akan:
1. ✅ Install dependencies
2. ✅ Setup environment variables (interaktif)
3. ✅ Build project
4. ✅ Setup database
5. ✅ Start with PM2
6. ✅ Verify installation

---

## Database Backup & Restore

### Backup
```bash
# Backup Supabase PostgreSQL
docker exec supabase-db pg_dump -U postgres postgres > kanba_backup.sql
```

### Restore
```bash
# Restore ke database baru
docker exec -i supabase-db psql -U postgres postgres < kanba_backup.sql
```

---

## Troubleshooting

### Mixed Content Error (HTTPS)
**Error:** `Mixed Content: HTTPS page requesting HTTP resource`

**Fix:** Update `.env.local` dengan HTTPS URLs
```bash
NEXT_PUBLIC_SUPABASE_URL=https://your-domain.com:8000
NEXTAUTH_URL=https://your-domain.com
```

### Database Connection Failed
```bash
# Check connection
docker exec supabase-db psql -U postgres postgres -c "SELECT 1;"

# Check URL format
psql postgresql://user:password@host:5432/database
```

### RLS Policy Errors
Re-run RLS policy setup dari step 6 di atas.

---

## Environment Variables Reference

| Variable | Purpose | Example |
|----------|---------|---------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase API URL | `https://supabase.volikoprint.com` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Public Supabase key | `eyJ...` |
| `SUPABASE_SERVICE_ROLE_KEY` | Server-side Supabase key | `eyJ...` |
| `DATABASE_URL` | PostgreSQL connection (pooler) | `postgresql://...` |
| `DIRECT_URL` | PostgreSQL direct connection | `postgresql://...` |
| `NEXTAUTH_SECRET` | NextAuth secret (32+ chars) | Generated via `openssl` |
| `NEXT_PUBLIC_SITE_URL` | Your domain | `https://kanba.volikoprint.com` |
| `NEXTAUTH_URL` | Auth callback URL | `https://kanba.volikoprint.com` |

---

## Support

Untuk bantuan lebih lanjut, lihat:
- [Kanba GitHub](https://github.com/Kanba-co/kanba)
- [Supabase Docs](https://supabase.com/docs)
- [Next.js Deployment](https://nextjs.org/docs/deployment)
