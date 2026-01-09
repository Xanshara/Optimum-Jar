#!/bin/bash
# Skrypt instalacyjny dla Optimum Bot - Ubuntu 24.04
# Autor: Sinrac

set -e  # Zatrzymaj skrypt przy błędzie

echo "═══════════════════════════════════════════════════════════"
echo "  INSTALACJA WYMAGAŃ DLA OPTIMUM BOT"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Kolory
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Aktualizacja systemu...${NC}"
apt update
apt upgrade -y

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  1/4 - INSTALACJA DOCKER${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Usuń stare wersje
apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Instalacja wymagań
apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Dodaj klucz GPG Docker
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Dodaj repozytorium Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalacja Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Sprawdź Docker
docker --version
echo -e "${GREEN}✓ Docker zainstalowany!${NC}"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  2/4 - INSTALACJA JAVA (JDK)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

apt install -y default-jdk
java -version
echo -e "${GREEN}✓ Java zainstalowane!${NC}"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  3/4 - INSTALACJA SBT (Scala Build Tool)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Dodaj klucz i repo SBT
echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list
echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list
curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add

apt update
apt install -y sbt
sbt --version
echo -e "${GREEN}✓ SBT zainstalowane!${NC}"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  4/4 - INSTALACJA POSTGRESQL (Docker)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Pull PostgreSQL image
docker pull postgres
echo -e "${GREEN}✓ PostgreSQL image pobrany!${NC}"

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ INSTALACJA ZAKOŃCZONA POMYŚLNIE!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "Zainstalowane wersje:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -n "Docker: "
docker --version
echo -n "Java: "
java -version 2>&1 | head -n 1
echo -n "SBT: "
sbt --version 2>&1 | grep "sbt version" || echo "SBT OK"
echo -n "PostgreSQL: "
docker images postgres --format "{{.Repository}}:{{.Tag}}" | head -n 1
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo -e "${YELLOW}NASTĘPNE KROKI:${NC}"
echo ""
echo "1. Skompiluj projekt:"
echo "   cd /home/ubuntu/optimum"
echo "   sbt docker:publishLocal"
echo ""
echo "2. Utwórz plik prod.env z konfiguracją:"
echo "   nano prod.env"
echo ""
echo "3. Uruchom PostgreSQL:"
echo "   docker volume create --name pgdata"
echo "   docker run --rm -d -t --env-file prod.env \\"
echo "     --hostname sqlhost --name postgres \\"
echo "     -p 5432:5432 -v pgdata:/var/lib/postgresql/data postgres"
echo ""
echo "4. Uruchom bota (po kompilacji):"
echo "   docker run --rm -d -t --env-file prod.env \\"
echo "     --link postgres:postgres --name optimum-bot <image_id>"
echo ""
echo -e "${GREEN}Powodzenia! 🚀${NC}"
