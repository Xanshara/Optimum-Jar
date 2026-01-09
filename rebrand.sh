#!/bin/bash
# Skrypt do automatycznej zamiany Violent Bot -> Optimum Bot
# Autor nowego bota: Sinrac

echo "=== REBRAND: Violent Bot -> Optimum Bot ==="
echo "Autor: Sinrac"
echo ""

# Kolory dla lepszej czytelności
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funkcja do zamiany w pliku
replace_in_file() {
    local file="$1"
    local search="$2"
    local replace="$3"
    
    if [ -f "$file" ]; then
        sed -i "s|${search}|${replace}|g" "$file"
        echo -e "${GREEN}✓${NC} Zamieniono w: $file"
    else
        echo -e "${RED}✗${NC} Nie znaleziono pliku: $file"
    fi
}

# Funkcja do zamiany we wszystkich plikach danego typu
replace_in_all() {
    local pattern="$1"
    local search="$2"
    local replace="$3"
    
    echo -e "\n${YELLOW}Szukam: \"${search}\" -> \"${replace}\"${NC}"
    
    find tibia-bot/src -type f -name "$pattern" | while read -r file; do
        if grep -q "$search" "$file"; then
            sed -i "s|${search}|${replace}|g" "$file"
            echo -e "${GREEN}  ✓${NC} $file"
        fi
    done
}

echo "Rozpoczynam zamiany..."
echo ""

# 1. README.md
echo -e "${YELLOW}1. README.md${NC}"
replace_in_file "README.md" "Violent Bot" "Optimum Bot"
replace_in_file "README.md" "https://violentbot.xyz" ""
replace_in_file "README.md" "https://discord.gg/PNnzzs4hN3" ""
replace_in_file "README.md" "Production:" ""
replace_in_file "README.md" "- \[Website\]()" ""
replace_in_file "README.md" "- \[Discord\]()" ""
replace_in_file "README.md" "Leo32onGIT/tibia-bot" "tibia-bot"

# 2. build.sbt
echo -e "\n${YELLOW}2. build.sbt${NC}"
replace_in_file "tibia-bot/build.sbt" "violent-bot-dedicated" "optimum-bot"

# 3. Config.scala
echo -e "\n${YELLOW}3. Config.scala${NC}"
replace_in_file "tibia-bot/src/main/scala/com/tibiabot/Config.scala" "Violent Bot" "Optimum Bot"
replace_in_file "tibia-bot/src/main/scala/com/tibiabot/Config.scala" 'https://violentbot.xyz' ''
replace_in_file "tibia-bot/src/main/scala/com/tibiabot/Config.scala" 'https://discord.gg/SWMq9Pz8ud' ''
replace_in_file "tibia-bot/src/main/scala/com/tibiabot/Config.scala" 'http://donate.violentbot.xyz' ''
replace_in_file "tibia-bot/src/main/scala/com/tibiabot/Config.scala" '\[Website\]() | \[Discord\]() | \[Donate\]()' ''
replace_in_file "tibia-bot/src/main/scala/com/tibiabot/Config.scala" '\\n\\n\[Website\].*' ''
replace_in_file "tibia-bot/src/main/scala/com/tibiabot/Config.scala" '"1082484147492237515" // alpha/testing server' '"1340737877058785352" // Sinrac'\''s server'

# 4. BotListener.scala
echo -e "\n${YELLOW}4. BotListener.scala${NC}"
replace_in_file "tibia-bot/src/main/scala/com/tibiabot/BotListener.scala" "Violent Beams" "Sinrac"
replace_in_file "tibia-bot/src/main/scala/com/tibiabot/BotListener.scala" "https://www.tibia.com/community/?subtopic=characters&name=Violent+Beams" ""
replace_in_file "tibia-bot/src/main/scala/com/tibiabot/BotListener.scala" "https://github.com/Leo32onGIT.png" ""
replace_in_file "tibia-bot/src/main/scala/com/tibiabot/BotListener.scala" '.setAuthor("Sinrac", "", "")' '.setAuthor("Sinrac", null, null)'

# 5. BotApp.scala - wszystkie wystąpienia
echo -e "\n${YELLOW}5. BotApp.scala${NC}"
replace_in_all "*.scala" "Violent Bot" "Optimum Bot"
replace_in_all "*.scala" "Violent Beams" "Sinrac"
replace_in_all "*.scala" "https://www.tibia.com/community/?subtopic=characters&name=Violent+Beams" ""
replace_in_all "*.scala" "https://github.com/Leo32onGIT.png" ""
replace_in_all "*.scala" '.setAuthor("Sinrac", "", "")' '.setAuthor("Sinrac", null, null)'

# Zamiana hardcodowanych ID serwerów w BotApp.scala
echo -e "${YELLOW}  Zamiana ID serwerów...${NC}"
replace_in_file "tibia-bot/src/main/scala/com/tibiabot/BotApp.scala" "867319250708463628L" "1340737877058785352L"
replace_in_file "tibia-bot/src/main/scala/com/tibiabot/BotApp.scala" "1082484147492237515L" "1340737877058785352L"
replace_in_file "tibia-bot/src/main/scala/com/tibiabot/BotApp.scala" "Violent Bot Discords" "Optimum Bot Discords"

# 6. Opcjonalnie: discord.conf (jeśli użytkownik chce zmienić grafiki)
echo -e "\n${YELLOW}6. discord.conf (opcjonalnie)${NC}"
echo -e "${YELLOW}UWAGA: Zostawiamy obecne URL grafik. Jeśli chcesz użyć własnych, edytuj ręcznie discord.conf${NC}"
# Możesz odkomentować poniższe linie jeśli masz własne zasoby:
# replace_in_file "tibia-bot/src/main/resources/discord.conf" "Leo32onGIT/tibia-bot-resources" "your-repo/optimum-bot-resources"

echo ""
echo -e "${GREEN}=== ZAKOŃCZONO ZAMIANY ===${NC}"
echo ""
echo "Podsumowanie:"
echo "- Wszystkie 'Violent Bot' zamienione na 'Optimum Bot'"
echo "- Wszystkie 'Violent Beams' zamienione na 'Sinrac'"
echo "- Wszystkie referencje do Leo32onGIT zamienione na Sinrac"
echo "- Usunięto linki do violentbot.xyz"
echo ""
echo "Kolejne kroki:"
echo "1. Sprawdź zmiany: git diff"
echo "2. Skompiluj projekt: sbt docker:publishLocal"
echo "3. Przetestuj bota przed deploymentem"
echo ""
echo -e "${YELLOW}UWAGA: Jeśli chcesz użyć własnych grafik, edytuj plik discord.conf${NC}"
