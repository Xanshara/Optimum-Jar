#!/bin/bash

# Skrypt budowania Optimum Bot (JAR) - ZAKTUALIZOWANY

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Optimum Bot - Budowanie JAR ===${NC}\n"

# Sprawdź czy jesteśmy w odpowiednim katalogu
if [ ! -f "build.sbt" ]; then
    echo -e "${RED}BŁĄD: Nie znaleziono build.sbt${NC}"
    echo "Uruchom skrypt z katalogu: ~/optimum-bot/tibia-bot"
    exit 1
fi

# Sprawdź czy build.sbt ma poprawną konfigurację
echo -e "${YELLOW}Sprawdzanie konfiguracji build.sbt...${NC}"

ISSUES_FOUND=0

# Sprawdzenie 1: Sterownik PostgreSQL (META-INF/services)
if grep -q 'case PathList("META-INF", "services"' build.sbt; then
    echo -e "${GREEN}✓ Sterownik PostgreSQL: OK${NC}"
else
    echo -e "${RED}✗ BRAK obsługi META-INF/services (sterownik PostgreSQL)${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Sprawdzenie 2: module-info.class (konflikt Jackson/Kotlin)
if grep -q 'module-info.class' build.sbt; then
    echo -e "${GREEN}✓ Obsługa module-info.class: OK${NC}"
else
    echo -e "${RED}✗ BRAK obsługi module-info.class (konflikt Jackson/Kotlin)${NC}"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

if [ $ISSUES_FOUND -gt 0 ]; then
    echo -e "\n${RED}build.sbt wymaga aktualizacji!${NC}\n"
    echo "Potrzebne zmiany w sekcji 'assemblyMergeStrategy':"
    echo ""
    echo "1. Dodaj obsługę sterownika PostgreSQL:"
    echo '   case PathList("META-INF", "services", xs @ _*) => MergeStrategy.concat'
    echo ""
    echo "2. Dodaj obsługę module-info.class:"
    echo '   case PathList("META-INF", "versions", xs @ _*) if xs.lastOption.contains("module-info.class") => MergeStrategy.discard'
    echo '   case "module-info.class" => MergeStrategy.discard'
    echo ""
    echo "Pełny poprawiony build.sbt znajduje się w pliku: build.sbt.final"
    echo ""
    read -p "Czy chcesz kontynuować mimo to? (t/n): " continue
    if [ "$continue" != "t" ] && [ "$continue" != "T" ]; then
        exit 1
    fi
fi

echo -e "\n${YELLOW}Krok 1: Czyszczenie...${NC}"
rm -rf target/
sbt clean

if [ $? -ne 0 ]; then
    echo -e "${RED}BŁĄD podczas czyszczenia!${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Krok 2: Pobieranie zależności...${NC}"
sbt update

if [ $? -ne 0 ]; then
    echo -e "${RED}BŁĄD podczas pobierania zależności!${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Krok 3: Kompilacja i assembly...${NC}"
sbt assembly

if [ $? -ne 0 ]; then
    echo -e "\n${RED}BŁĄD podczas kompilacji/assembly!${NC}"
    echo ""
    echo "Najczęstsze przyczyny:"
    echo "1. build.sbt nie ma poprawnej konfiguracji merge strategy"
    echo "2. Konflikt w plikach module-info.class"
    echo ""
    echo "Rozwiązanie: Zastąp build.sbt plikiem build.sbt.final"
    exit 1
fi

# Znajdź plik JAR
JAR_FILE=$(ls target/scala-2.13/optimum-bot-assembly-*.jar 2>/dev/null | head -n1)

if [ ! -f "$JAR_FILE" ]; then
    echo -e "${RED}BŁĄD: Nie znaleziono pliku JAR!${NC}"
    exit 1
fi

echo -e "\n${GREEN}✓ JAR został utworzony: $JAR_FILE${NC}"

# Weryfikacja zawartości JAR
echo -e "\n${YELLOW}Weryfikacja zawartości JAR...${NC}"

# Sprawdź sterownik PostgreSQL
if jar tf "$JAR_FILE" | grep -q "META-INF/services/java.sql.Driver"; then
    echo -e "${GREEN}✓ Sterownik PostgreSQL: OK${NC}"
else
    echo -e "${RED}✗ UWAGA: Brak sterownika PostgreSQL w JAR!${NC}"
    echo "  Bot nie będzie mógł połączyć się z bazą danych!"
    echo "  Zaktualizuj build.sbt i zbuduj ponownie"
fi

# Sprawdź pliki konfiguracyjne
if jar tf "$JAR_FILE" | grep -q "reference.conf"; then
    echo -e "${GREEN}✓ Pliki konfiguracyjne: OK${NC}"
else
    echo -e "${YELLOW}⚠ Brak reference.conf${NC}"
fi

# Sprawdź główną klasę
if jar tf "$JAR_FILE" | grep -q "com/tibiabot/BotApp.class"; then
    echo -e "${GREEN}✓ Główna klasa BotApp: OK${NC}"
else
    echo -e "${RED}✗ Brak głównej klasy!${NC}"
fi

# Rozmiar JAR
JAR_SIZE=$(du -h "$JAR_FILE" | cut -f1)
echo -e "${GREEN}✓ Rozmiar JAR: $JAR_SIZE${NC}"

# Statystyki
echo -e "\n${YELLOW}Statystyki JAR:${NC}"
echo "Liczba plików: $(jar tf "$JAR_FILE" | wc -l)"
echo "Biblioteki PostgreSQL: $(jar tf "$JAR_FILE" | grep -c 'org/postgresql')"
echo "Biblioteki Akka: $(jar tf "$JAR_FILE" | grep -c 'akka')"
echo "Biblioteki JDA (Discord): $(jar tf "$JAR_FILE" | grep -c 'net/dv8tion/jda')"

echo -e "\n${GREEN}=== Build zakończony pomyślnie! ===${NC}\n"
echo -e "${YELLOW}Następne kroki:${NC}"
echo "1. Upewnij się, że PostgreSQL działa: sudo systemctl status postgresql"
echo "2. Skonfiguruj prod.env z danymi dostępu do bazy"
echo "3. Uruchom bota: ./run-bot.sh"
echo ""
echo "Lub uruchom bezpośrednio:"
echo "java -Xmx2G -Xms512M -jar $JAR_FILE"
