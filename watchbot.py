import subprocess, sys, time, logging
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(BASE_DIR / "watchbot.log", encoding="utf-8")
    ]
)

BOT_SCRIPT = BASE_DIR / "bot.py"
RESTART_DELAY = 1  # sekunde pred ponovnim zagonom

def main():
    logging.info("Watchbot zagnan.")
    while True:
        logging.info("Zaganjam bot.py...")
        
        proc = subprocess.Popen(
            [sys.executable, str(BOT_SCRIPT)],
            creationflags=subprocess.CREATE_NO_WINDOW  # brez okenca
        )
        
        proc.wait()  # << blokira in čaka - 0% CPU dokler bot teče
        
        logging.info(f"Bot se je ugasnil (exit code: {proc.returncode}). Čakam {RESTART_DELAY}s...")
        time.sleep(RESTART_DELAY)
        # → takoj ponovi zanko in zažene bota znova

if __name__ == "__main__":
    main()