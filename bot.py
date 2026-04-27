# Standardne knjižnice (vgrajene v Python)
import sys
import os
import time
import asyncio
import logging
from ctypes import WinDLL
from pathlib import Path

# Zunanje knjižnice (pip install)
import discord
import yt_dlp


BASE_DIR = Path(__file__).resolve().parent

# --- NASTAVITEV LOGIRANJA ---
# Zdaj bo program pravilno zapisoval dogodke v relay_bot.log
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(BASE_DIR / "relay_bot.log", encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)

# --- VARNOSTNI MEHANIZEM (Single Instance) ---
kernel32 = WinDLL("kernel32", use_last_error=True)
if not kernel32.CreateMutexW(None, True, "Global\\DiscordRelayBot_Singleton") or kernel32.GetLastError() == 183:
    sys.exit(0)

# --- ISKANJE NASLOVA (yt-dlp) ---
def get_real_title(query):
    try:
        with yt_dlp.YoutubeDL({'quiet': True, 'no_warnings': True, 'extract_flat': True}) as ydl:
            info = ydl.extract_info(query if query.startswith('http') else f"ytsearch1:{query}", download=False)
            return info['entries'][0]['title'] if 'entries' in info and info['entries'] else info.get('title', query)
    except: return query

# --- KONFIGURACIJA ---
TOKEN = ""
MUSIC_CHANNEL_NAME = "music"
LOBBY_CHANNEL_NAME = "lobby" # Kanal kjer briše obvestila ostalih botov
OTHER_BOTS = ["Jockie Music", "Chip", "DJ-bot", "Rythm"]
OWNER_ID =   # <-- TUKAJ VNESI SVOJ DISCORD USER ID ZA !restart

VALID_PREFIXES = ("m!play ", "m!p ", "m!play", "m!p")
WRONG_PREFIXES = ("!play", "#play", "$play", ".play", "-play", "ch!play", "c!play", "/play")

intents = discord.Intents.default()
intents.message_content = True 

class RelayBot(discord.Client):
    async def on_ready(self):
        logging.info(f"Bot prijavljen kot: {self.user}")

    async def on_message(self, message):
        if message.guild is None: return

        content = message.content.strip()
        lower_content = content.lower()

        # --- SMART BOOT-UP / HOT RELOAD ---
        # Ugasne skripto. Task Scheduler ali watchbot jo bo znova zagnal.
        if lower_content == "!restart" and message.author.id == OWNER_ID:
            await message.delete()
            confirm = await message.channel.send("🔄 Restartiram...")
            await asyncio.sleep(1)
            await confirm.delete()
            logging.info("Sprožen ročni restart preko Discorda (!restart).")
            os._exit(0) 

        # --- ČIŠČENJE DRUGIH BOTOV (IZKLJUČNO V LOBBY KANALU) ---
        if message.author.bot:
            if message.channel.name == LOBBY_CHANNEL_NAME:
                if any(name.lower() in message.author.name.lower() for name in OTHER_BOTS):
                    await asyncio.sleep(5)
                    try: await message.delete()
                    except: pass
            return
        
        # Ignoriramo, če pišemo v #music
        if message.channel.name == MUSIC_CHANNEL_NAME: return

        # --- ČIŠČENJE NAPAČNIH UKAZOV V LOBBYJU ---
        if message.channel.name == LOBBY_CHANNEL_NAME and any(lower_content.startswith(p) for p in WRONG_PREFIXES):
            try: await message.delete()
            except: pass
            
            msg = "izberi `/play` iz menija ali uporabi `m!play`." if "/play" in lower_content else "napačen prefix! Uporabi `m!play`."
            err_msg = await message.channel.send(f"⚠️ **{message.author.display_name}**, {msg}")
            logging.info(f"Izbrisan napačen ukaz od {message.author.name}: {content}")
            await asyncio.sleep(10)
            try: await err_msg.delete()
            except: pass
            return

        # --- PRAVILEN RELAY (m!play) ---
        if any(lower_content.startswith(p) for p in VALID_PREFIXES):
            music_channel = discord.utils.get(message.guild.text_channels, name=MUSIC_CHANNEL_NAME)
            if music_channel:
                try: await message.delete()
                except: pass

                user_query = content.split(" ", 1)[1] if " " in content else ""
                if not user_query: return

                real_title = await asyncio.to_thread(get_real_title, user_query)
                
                # Zapis v #music
                await music_channel.send(f"**{message.author.display_name}** igra: `{real_title}`")
                await music_channel.send(content)
                logging.info(f"Relayed song '{real_title}' from {message.author.name}")
                
                # Potrdilo v Lobbyju
                confirm = await message.channel.send(f"✅ **{message.author.display_name}**, skladba preusmerjena.")
                await asyncio.sleep(10)
                try: await confirm.delete()
                except: pass

def main():
    logging.info("Zaganjam bota... Varnostni zamik proti API limitom (3s).")
    time.sleep(3) # Varnost pred boot-loop API spamanjem
    client = RelayBot(intents=intents)
    client.run(TOKEN)

if __name__ == "__main__":
    main()