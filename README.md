# 🎶 Discord Music Bot (*RelayBot*)

Sistem dveh skript, zasnovan za popolnoma avtonomno delovanje na Windows okolju, kjer več ljudi hkrati želi predvajati glasbo — namesto kaosa v lobby kanalu bot ukaze tiho prestrezе, jih preusmeri v #music, in channel ostane čist.


## Arhitektura sistema

Sistem je sestavljen iz dveh delov za maksimalno stabilnost:

1.  **`bot.py` (Srce sistema):**
    * **Relaying:** Preusmerja `m!play` ukaze v namenski `#music` kanal z avtomatskim iskanjem naslovov pesmi preko `yt-dlp`.
    * **Cleanup:** V kanalu `lobby` takoj briše napačne ukaze (npr. `/play`) in po 5 sekundah odstrani obvestila drugih glasbenih botov (Jockie Music, Chip, itd.).
    * **Smart Restart:** Omogoča ukaz `!restart`, ki varno ugasne bota, da se lahko naloži nova koda.
    * **Preko yt-dlp** poišče pravi naslov pesmi preden jo zapiše. 

2.  **`watchbot.py` (Nadzornik):**
    * Njegova edina naloga je, da poganja `bot.py`.
    * Takoj ko se `bot.py` ugasne (zaradi napake ali ukaza `!restart`), ga `watchbot.py` v 1 sekundi ponovno zažene. **Ponovni zagon varira med 1–10 sekund.** 
    * S tem se izognemo daljšemu čakanju na Windows Task Scheduler – ki bi ga bili, sicer, deležni. 
    * Ni pollinga, ni timerjev — OS-level blokirajoč klic, praktično 0% CPU.

## Predpogoji

* **Python 3.12**
* **Knjižnice:** `pip install discord.py yt-dlp`
* **FFmpeg:** Potreben za pravilno delovanje `yt-dlp` (v sistemski poti).
* **Discord Bot:** Ustvarjen Bot na Discord Developer Portalu z omogočenim pravicami in pridobljenim Tokenom.
  * Bot bo potreboval potrebna dovoljenja za pravilno delovanje, ko pride v vaš Discord strežnik. Dodelijo se samo glavne stvari potrebne za delovanje. To se vse naredi v DDP (Discord Developer Portal), ob vhodu v strežnik se lahko odločite kaj naj bot obdrži.
    
  * **Pomembne funkciije so:**
    * Text Permissions; `Send Messages, Manage Messages, Read Message History`
    * General Permissions; `View Channels` 

## Nastavitev avtomatizacije

Namesto da bi v Task Scheduler dodali bota, dodamo samo **nadzornika**, ki bo nato upravljal bota.

### Windows Task Scheduler konfiguracija:
1.  **Ustvari novo opravilo (Create Task)** in ga poljubno poimenujemo npr. `watchbot`.
2.  **Triggers:**
    * **At system startup**
    * **On a schedule:** Daily, Repeat every hour, Indefinitely. (V primeru, da bi kaj zrušilo program, pogleda vsako uro in se osveži)
3.  **Actions:**
    * **Program/script:** `C:\Python312\pythonw.exe`
    * **Add arguments:** `C:\bots\watchbot.py`
    * **Start in:** `C:\bots`
4.  **Settings:** Obkljukaj "If the task fails, restart every 1 minute".
    * **Rules:** `Do not start a new instance`
    * **Odkljukaj**: `Stop running if it runs longer than 3 days`

**Rezultat:** Ob zagonu računalnika se zažene `watchbot.py`, ki takoj dvigne `bot.py`. Če želite posodobiti kodo, preprosto shranite `bot.py` in v Discordu napišete `!restart`.

## Konfiguracija (bot.py)

Pred zagonom uredi naslednje spremenljivke:
* `TOKEN`: Žeton bota, ki ga boste videli v Discord Dev Portalu, kjer je Bot narejen.  
* `OWNER_ID`: Vaš Discord User ID (za dostop do `!restart` ukaza). ID pridobite v Discordu na svojem profilu, s predpostavko da vklopite `developer mode` v nastavitvah. 
* `LOBBY_CHANNEL_NAME`: Ime kanala za čiščenje (default: `"lobby"`).
* `MUSIC_CHANNEL_NAME`: Ime kanala za preusmeritev (default: `"music"`).

## Logiranje in Diagnostika

* **`relay_bot.log`**: Tukaj vidiš, katere pesmi so bile preusmerjene in morebitne napake v delovanju bota.
* **`watchbot.log`**: Tukaj vidiš vsak ponovni zagon bota.

## Inštalacija: 
1. * Run PowerShell as Administrator
2. * Copy and Execute:
      * `Set-ExecutionPolicy Bypass -Scope Process -Force`
      * `irm https://raw.githubusercontent.com/KlemenKovacic/Discord-Music-Relay-Cleanup-Bot-Auto-Hosted-/main/setup.ps1 | iex`
3. * Vse omenjeno se bo postavilo samo ena za drugo. Kaj se postavlja lahko vidite v `setup.ps1` repo.
4. * Vse kar morate sami narediti je poskrbeti, da imate music bot-a / bote na svojemu strežniku in svoj "relaybot" kreiran na DDP, kjer se lahko ustavi lasten `TOKEN`.

## Ostalo

* ###### Ukaz: `!Restart`
* ###### Discord Portal: https://discord.com/developers/home
* ###### Inštalacija bi morala tudi delovati v Windows Sandboxu za varno testiranje.  
* ###### Music RelayBot: [https://discord.com/oauth2/authorize?client_id=1435793486141067527](https://discord.com/oauth2/authorize?client_id=1435793486141067527&permissions=76800&integration_type=0&scope=bot)
* ###### Najbolj fleksibilen music bot je **Jockie Music**, ki ni vezan preko Discordovega API–ja oz. komandne vrstice: `/`, kjer ima `RelayBot` najmanj limitaci pri music botu. Dostop do Jockie Muisc: https://www.jockiemusic.com/
