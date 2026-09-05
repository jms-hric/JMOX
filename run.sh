#!/usr/bin/env bash

# =============================================================================
# JMO Management System — One-Touch Run Script
# =============================================================================
# Description: Starts Docker containers (PostgreSQL & Redis), runs database
#              seeding, starts FastAPI backend & React frontend, and displays
#              a live status summary with credentials.
# =============================================================================

set -e

# Terminal colors
BOLD='\033[1m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
RESET='\033[0m'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="${ROOT_DIR}/server"
WEB_DIR="${ROOT_DIR}/apps/web"

# Track PIDs for cleanup on exit
BACKEND_PID=""
FRONTEND_PID=""

cleanup() {
    echo -e "\n${YELLOW}[!] Stopping development servers...${RESET}"
    if [ -n "$BACKEND_PID" ]; then
        kill "$BACKEND_PID" 2>/dev/null || true
    fi
    if [ -n "$FRONTEND_PID" ]; then
        kill "$FRONTEND_PID" 2>/dev/null || true
    fi
    echo -e "${GREEN}[✔] Shutdown complete. Goodbye!${RESET}"
    exit 0
}

trap cleanup SIGINT SIGTERM EXIT

echo -e "${PURPLE}${BOLD}"
echo "============================================================================="
echo "        Junior Mathematics Olympiad (JMO) Management System                  "
echo "============================================================================="
echo -e "${RESET}"

# -----------------------------------------------------------------------------
# Step 1: Check Prerequisites
# -----------------------------------------------------------------------------
echo -e "${BLUE}[1/5] Checking system prerequisites...${RESET}"

DOCKER_CMD=""
if command -v docker-compose &> /dev/null; then
    DOCKER_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_CMD="docker compose"
elif command -v podman-compose &> /dev/null; then
    DOCKER_CMD="podman-compose"
else
    echo -e "${RED}[✘] Error: Neither docker-compose nor podman-compose found.${RESET}"
    exit 1
fi

if ! command -v node &> /dev/null || ! command -v npm &> /dev/null; then
    echo -e "${RED}[✘] Error: Node.js and npm are required for the web frontend.${RESET}"
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo -e "${RED}[✘] Error: Python 3 is required for the backend API.${RESET}"
    exit 1
fi

echo -e "${GREEN}[✔] Prerequisites met. Using container engine: ${DOCKER_CMD}${RESET}"

# -----------------------------------------------------------------------------
# Step 2: Start Database & Redis Containers
# -----------------------------------------------------------------------------
echo -e "\n${BLUE}[2/5] Starting PostgreSQL (5432) & Redis (6379) containers...${RESET}"
cd "$ROOT_DIR"
$DOCKER_CMD up -d

echo -n -e "${CYAN}Waiting for PostgreSQL to be ready on port 5432...${RESET}"
MAX_RETRIES=30
RETRY_COUNT=0
until python3 -c "import socket; s = socket.socket(); s.settimeout(1); s.connect(('127.0.0.1', 5432)); s.close()" 2>/dev/null; do
    echo -n "."
    sleep 1
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ "$RETRY_COUNT" -ge "$MAX_RETRIES" ]; then
        echo -e "\n${RED}[✘] Error: Timed out waiting for PostgreSQL on port 5432.${RESET}"
        exit 1
    fi
done
echo -e " ${GREEN}[Ready]${RESET}"

# -----------------------------------------------------------------------------
# Step 3: Setup Virtualenv & Seed Database
# -----------------------------------------------------------------------------
echo -e "\n${BLUE}[3/5] Seeding database schema and initial users...${RESET}"
cd "$SERVER_DIR"

VENV_PATH=""
if [ -d "${SERVER_DIR}/venv" ]; then
    VENV_PATH="${SERVER_DIR}/venv"
elif [ -d "${SERVER_DIR}/.venv" ]; then
    VENV_PATH="${SERVER_DIR}/.venv"
else
    echo -e "${YELLOW}Creating Python virtual environment...${RESET}"
    python3 -m venv venv
    VENV_PATH="${SERVER_DIR}/venv"
    source "${VENV_PATH}/bin/activate"
    PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1 pip install -r requirements.txt
fi

source "${VENV_PATH}/bin/activate"
python seed.py

# -----------------------------------------------------------------------------
# Step 4: Launch Backend & Frontend Servers
# -----------------------------------------------------------------------------
echo -e "\n${BLUE}[4/5] Launching FastAPI Backend & Vite Web Frontend...${RESET}"

# Start FastAPI Uvicorn
cd "$SERVER_DIR"
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload > /tmp/jmox-backend.log 2>&1 &
BACKEND_PID=$!

# Start Vite Web Frontend
cd "$WEB_DIR"
npm run dev -- --host 0.0.0.0 > /tmp/jmox-frontend.log 2>&1 &
FRONTEND_PID=$!

echo -n -e "${CYAN}Waiting for FastAPI Backend (http://localhost:8000/health)...${RESET}"
RETRY_COUNT=0
until curl -s http://localhost:8000/health | grep -q "healthy" 2>/dev/null; do
    echo -n "."
    sleep 1
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ "$RETRY_COUNT" -ge 20 ]; then
        echo -e "\n${RED}[✘] Backend failed to start. Check /tmp/jmox-backend.log${RESET}"
        tail -20 /tmp/jmox-backend.log
        exit 1
    fi
done
echo -e " ${GREEN}[Healthy]${RESET}"

echo -n -e "${CYAN}Waiting for Vite Web Frontend (http://localhost:5173)...${RESET}"
RETRY_COUNT=0
until curl -s http://localhost:5173/ | grep -q "html" 2>/dev/null; do
    echo -n "."
    sleep 1
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ "$RETRY_COUNT" -ge 20 ]; then
        echo -e "\n${RED}[✘] Frontend failed to start. Check /tmp/jmox-frontend.log${RESET}"
        tail -20 /tmp/jmox-frontend.log
        exit 1
    fi
done
echo -e " ${GREEN}[Ready]${RESET}"

# -----------------------------------------------------------------------------
# Step 5: Summary Banner
# -----------------------------------------------------------------------------
echo -e "\n${GREEN}${BOLD}[5/5] All services are operational!${RESET}\n"

echo -e "${CYAN}${BOLD}+-------------------------------------------------------------------------+${RESET}"
echo -e "${CYAN}${BOLD}|                 JMO SYSTEM LIVE SERVICES & ENDPOINTS                    |${RESET}"
echo -e "${CYAN}${BOLD}+-------------------------------------------------------------------------+${RESET}"
echo -e " ${BOLD}Web Frontend:${RESET}        ${BLUE}http://localhost:5173${RESET}"
echo -e " ${BOLD}FastAPI Backend:${RESET}     ${BLUE}http://localhost:8000${RESET}"
echo -e " ${BOLD}Interactive Swagger:${RESET}  ${BLUE}http://localhost:8000/docs${RESET}"
echo -e " ${BOLD}PostgreSQL Database:${RESET} ${BLUE}127.0.0.1:5432${RESET} (DB: jmox, User: jmox)"
echo -e " ${BOLD}Redis Cache:${RESET}         ${BLUE}127.0.0.1:6379${RESET}"
echo -e "${CYAN}${BOLD}+-------------------------------------------------------------------------+${RESET}"
echo -e "${CYAN}${BOLD}|                 SYSTEM ADMIN CREDENTIALS                                 |${RESET}"
echo -e "${CYAN}${BOLD}+-------------------------------------------------------------------------+${RESET}"
echo -e " ${BOLD}Super Admin:${RESET}         Email: ${YELLOW}jms.hric@gmail.com${RESET}   | Password: ${YELLOW}Mathforall@JMO369${RESET}"
echo -e "${CYAN}${BOLD}+-------------------------------------------------------------------------+${RESET}\n"

echo -e "${YELLOW}Press [CTRL+C] at any time to gracefully stop all services.${RESET}"

# Keep script running to maintain traps and process lifecycle
wait
