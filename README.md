# 🎵 Discord Relay & Cleanup Bot (Auto-Hosted)


## 🧠 Kako deluje skripta?

Glavna skripta (`bot.py`) deluje na treh nivojih:

1. **Preusmerjanje (Relaying):** * Uporabniki v glavnem klepetu (Lobbyju) vpišejo ukaz, npr. `m!play eminem`.
   * Bot to zazna, preko knjižnice `yt-dlp` v ozadju preveri pravi naslov pesmi in ta ukaz preusmeri v read-only kanal `#music`.
2. **Strogo čiščenje (Strict Cleanup):**
   * Bot iz Lobbyja takoj izbriše vse glasbene ukaze in napačne vnose (npr. `/play`).
   * Prav tako zazna obvestila drugih botov (npr. ko Jockie Music zapusti kanal) in jih po nekaj sekundah avtomatsko izbriše.
3. **Samo-zaščita (Single Instance & Heartbeat):**
   * **Mutex:** Preprečuje, da bi sistem hkrati zagnal dve kopiji bota (onemogoči podvajanje procesov).
   * **Heartbeat:** Skripta vsakih 20 sekund zapiše trenutni čas v datoteko `bot.heartbeat`. Zunanja Watchdog skripta to datoteko preverja in bota ponovno zažene, če ta zamrzne.

## ⚙️ Predpogoji za izvedbo

* **Python:** Verzija 3.12 ali 3.13 (nameščena v fiksno mapo, npr. `C:\Python312`).
* **Knjižnice:** `pip install discord.py yt-dlp`
* **Discord Bot:** Ustvarjen bot na Discord Developer Portalu z omogočenim **Message Content Intent** in pridobljenim **Tokenom**.

## 🛠️ Postavitev avtomatizacije (Windows Task Scheduler)

Da bot deluje 24/7 in preživi ponovne zagone računalnika, uporabljamo Windows Opravilnik nalog (Task Scheduler).

### Koraki za konfiguracijo glavnega opravila:
1. Odprite Task Scheduler in izberite **Create Task**.
2. **Zavihek General:** * Poimenujte opravilo (npr. `DiscordBot`).
   * Obkljukajte **Run whether user is logged on or not** (da deluje v ozadju kot servis).
3. **Zavihek Triggers:**
   * Dodajte nov prožilec in izberite **At startup** (zažene takoj ob vklopu PC-ja).
4. **Zavihek Actions:**
   * **Action:** `Start a program`
   * **Program/script:** Pot do Pythona (npr. `C:\Python312\python.exe`).
   * **Add arguments:** Pot do skripte (npr. `C:\bots\bot.py`).
   * **Start in:** Mapa, kjer je skripta (npr. `C:\bots\`).
5. **Zavihek Settings (KLJUČNO):**
   * Obkljukajte *If the task fails, restart every: 1 minute*.
   * Na dnu pri *If the task is already running, then the following rule applies*, izberite **Stop the existing instance**. To zagotovi, da se ob posodobitvi kode stara verzija ugasne in nova čisto zažene.

## 🔧 Prilagoditev kode

Pred zagonom odprite `bot.py` in prilagodite osnovne nastavitve pod sekcijo `# --- KONFIGURACIJA ---`:
* `TOKEN` = Žeton vašega bota.
* `MUSIC_CHANNEL_NAME` = Ime kanala, kamor se preusmerja glasba (npr. `"music"`).
* `OTHER_BOTS` = Seznam imen botov, za katerimi naj skripta čisti.
