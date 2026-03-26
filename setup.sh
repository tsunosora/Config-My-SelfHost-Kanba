#!/bin/bash

# Kanba Setup Script - Automated Deployment
# Usage: bash setup.sh

set -e

echo "🚀 Kanba Setup & Deployment Script"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found. Please install Node.js 18+${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Node.js $(node -v)${NC}"

# Check npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}❌ npm not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ npm $(npm -v)${NC}"
echo ""

# Step 1: Install dependencies
echo "📦 Step 1: Installing dependencies..."
npm install --legacy-peer-deps
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Step 2: Setup .env.local
echo "⚙️  Step 2: Setting up environment variables..."
if [ ! -f .env.local ]; then
    echo "Creating .env.local from template..."
    cp .env.example .env.local

    echo -e "${YELLOW}⚠️  Please edit .env.local with your credentials:${NC}"
    echo "   - NEXT_PUBLIC_SUPABASE_URL"
    echo "   - NEXT_PUBLIC_SUPABASE_ANON_KEY"
    echo "   - SUPABASE_SERVICE_ROLE_KEY"
    echo "   - DATABASE_URL"
    echo "   - DIRECT_URL"
    echo "   - NEXTAUTH_SECRET (generate: openssl rand -base64 32)"
    echo "   - NEXT_PUBLIC_SITE_URL"
    echo "   - NEXTAUTH_URL"
    echo ""

    read -p "Press Enter when you've updated .env.local..."
fi

echo -e "${GREEN}✓ Environment variables configured${NC}"
echo ""

# Step 3: Build project
echo "🔨 Step 3: Building project..."
npm run build
echo -e "${GREEN}✓ Build completed${NC}"
echo ""

# Step 4: Check for PM2
echo "📝 Step 4: Setting up process manager..."
if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2 globally..."
    npm install -g pm2
fi

echo -e "${GREEN}✓ PM2 ready${NC}"
echo ""

# Step 5: Start with PM2
echo "🚀 Step 5: Starting Kanba with PM2..."
pm2 delete kanba 2>/dev/null || true
pm2 start "npm run start" --name "kanba" --cwd "$(pwd)"
pm2 save
echo -e "${GREEN}✓ Kanba started${NC}"
echo ""

# Step 6: Verify
echo "✅ Step 6: Verifying installation..."
sleep 2

if pm2 list | grep -q "kanba"; then
    echo -e "${GREEN}✓ Kanba is running!${NC}"
else
    echo -e "${RED}❌ Kanba failed to start${NC}"
    pm2 logs kanba
    exit 1
fi

echo ""
echo "🎉 Setup Complete!"
echo "=================================="
echo "Kanba is now running at:"
echo "  Local:  http://localhost:3000"
echo "  Domain: Check your .env.local NEXT_PUBLIC_SITE_URL"
echo ""
echo "Commands:"
echo "  pm2 logs kanba     - View logs"
echo "  pm2 restart kanba  - Restart app"
echo "  pm2 stop kanba     - Stop app"
echo "  pm2 delete kanba   - Remove from PM2"
echo ""
echo "📚 For more help, see DEPLOYMENT.md"
