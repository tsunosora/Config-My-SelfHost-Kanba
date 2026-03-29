# Self-Host Setup Guide — Kanba

> Dokumentasi ini khusus untuk setup self-hosted di server sendiri (homelab/VPS).
> Source code original: [Uaghazade1/kanba](https://github.com/Uaghazade1/kanba)

---

## Arsitektur

```
[Browser]
    │
    ▼ :3000
[Kanba App - PM2]          ← Next.js app, jalan di host
    │
    ├── REST API ──────────► [supabase-kong :8000]
    │                              │
    │              ┌───────────────┼───────────────┐
    │              ▼               ▼               ▼
    │        [supabase-auth] [supabase-rest] [supabase-realtime]
    │                              │
    └── Direct DB ────────► [supabase-db :5433]
```

**Kanba App** berjalan via **PM2** (bukan Docker) di port `3000`.
**Supabase** berjalan via **Docker Compose** di `/home/homelab/supabase/docker/`.

---

## Prasyarat

- OS: Linux (Ubuntu/Debian)
- Node.js 20+
- PM2: `npm install -g pm2`
- Docker & Docker Compose

---

## Instalasi di Server Baru

### 1. Clone repo ini

```bash
git clone https://github.com/tsunosora/Config-My-SelfHost-Kanba.git kanba-app
cd kanba-app
```

### 2. Install dependencies

```bash
npm install
```

### 3. Buat file `.env.local`

```bash
cp .env.local.example .env.local
nano .env.local   # isi sesuai server kamu
```

Nilai yang harus diubah:
| Variable | Keterangan |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | URL Supabase instance kamu |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Anon key dari Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key dari Supabase |
| `DATABASE_URL` | Ganti IP/hostname dan password sesuai server |
| `DIRECT_URL` | Sama dengan DATABASE_URL |
| `NEXT_PUBLIC_SITE_URL` | IP atau domain server kamu |
| `NEXTAUTH_URL` | IP atau domain server kamu |
| `NEXTAUTH_SECRET` | Generate dengan: `openssl rand -hex 32` |

### 4. Setup Supabase (self-hosted)

Clone dan jalankan Supabase Docker:

```bash
git clone https://github.com/supabase/supabase /home/homelab/supabase
cd /home/homelab/supabase/docker
cp .env.example .env
# edit .env sesuai kebutuhan
docker compose up -d
```

Pastikan `supabase-kong` berjalan (API gateway):
```bash
docker ps | grep kong
```

### 5. Build aplikasi

```bash
npm run build
```

### 6. Jalankan dengan PM2

```bash
pm2 start npm --name kanba -- start
pm2 save        # simpan agar otomatis start saat reboot
pm2 startup     # enable autostart
```

---

## Manajemen Sehari-hari

### Cek status

```bash
pm2 status           # status Kanba app
docker ps            # status Supabase containers
```

### Restart aplikasi

```bash
pm2 restart kanba --update-env
```

### Lihat log

```bash
pm2 logs kanba                    # log realtime
pm2 logs kanba --lines 100        # 100 baris terakhir
```

### Jika supabase-kong mati (app tidak bisa baca profil/subscription)

```bash
cd /home/homelab/supabase/docker
docker compose up -d kong
```

---

## Update dari Repo Original

Kalau ada fitur/fix baru dari [Uaghazade1/kanba](https://github.com/Uaghazade1/kanba):

```bash
git fetch upstream
git merge upstream/main
# selesaikan conflict jika ada, lalu:
npm install
npm run build
pm2 restart kanba --update-env
git push origin main
```

---

## Update Config / Kode Sendiri

Setiap ada perubahan yang kamu buat:

```bash
git add .
git commit -m "deskripsi perubahan"
git push origin main
```

---

## Troubleshooting

### Subscription status kembali ke Free / fitur Pro terkunci

**Penyebab:** `supabase-kong` tidak berjalan → Supabase API tidak bisa diakses.

```bash
# Cek apakah kong berjalan
docker ps | grep kong

# Jika tidak ada, jalankan:
cd /home/homelab/supabase/docker && docker compose up -d kong
```

### Cek status subscription langsung di database

```bash
docker exec supabase-db psql -U postgres -d postgres \
  -c "SELECT email, subscription_status FROM profiles;"
```

### Update subscription status manual (jika perlu)

```bash
docker exec supabase-db psql -U postgres -d postgres \
  -c "UPDATE profiles SET subscription_status='pro' WHERE email='your@email.com';"
```

### Port 8000 sudah dipakai (supabase-kong gagal start)

```bash
# Cari proses yang pakai port 8000
ps aux | grep "docker-proxy.*8000"

# Jika ada container lain yang pakai port 8000, stop dulu container itu
docker stop <nama-container>
docker compose up -d kong
```

### Aplikasi crash / tidak mau start

```bash
pm2 logs kanba --lines 50     # cek error log
pm2 restart kanba --update-env
```

---

## Catatan Perubahan dari Versi Original

| File | Perubahan | Alasan |
|---|---|---|
| `Dockerfile` | Tambah build args untuk `NEXT_PUBLIC_*` env vars | Agar env var tersedia saat build time |
| `docker-compose.yml` | Gunakan `supabase_default` network, hapus Coolify dependency | Coolify konflik port 8000 dengan supabase-kong |
| `.env.local.example` | File baru — template environment variables | Memudahkan setup di server baru |

---

## Git Remotes

```
origin   → https://github.com/tsunosora/Config-My-SelfHost-Kanba.git  (repo kamu)
upstream → https://github.com/Uaghazade1/kanba.git                     (repo original)
```
