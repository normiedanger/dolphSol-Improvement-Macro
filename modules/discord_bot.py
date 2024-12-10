import discord
from discord.ext import commands
import json
import threading

CONFIG_PATH = "config.json"
with open(CONFIG_PATH, "r") as file:
    config = json.load(file)

# initialize the bot
intents = discord.Intents.default()
bot = commands.Bot(command_prefix="/", intents=intents)

# update config
def update_config(key, value):
    config[key] = value
    with open(CONFIG_PATH, "w") as file:
        json.dump(config, file, indent=4)

# commands, add more if neccessary
def setup_bot(macro, running_event):
    @bot.event
    async def on_ready():
        print(f"Bot is online as {bot.user}")

    @bot.slash_command(description="Pause/Unpause the macro")
    async def pause(ctx):
        if running_event.is_set():
            running_event.clear()
            macro.stop_loop()
            await ctx.respond("Macro paused.")
        else:
            running_event.set()
            threading.Thread(target=macro.start_loop, daemon=True).start()
            await ctx.respond("Macro resumed.")

    @bot.slash_command(description="Restart macro and reconnect")
    async def rejoin(ctx):
        macro.stop_loop()
        await ctx.respond("Rejoining...")
        threading.Thread(target=macro.start_loop, daemon=True).start()

    @bot.slash_command(description="Schedule player stats update")
    async def stats(ctx):
        update_config("WebhookInventoryInterval", 0)
        await ctx.respond("Player stats scheduled to update at the end of the current cycle.")

    @bot.slash_command(description="Send a screenshot of the current screen")
    async def screenshot(ctx):
        screenshot_path = "images/macro_inv_ss.png"
        macro.send_webhook_status("Screenshot", inv_screenshots=True)
        await ctx.respond(file=discord.File(screenshot_path))

    @bot.slash_command(description="Stop the macro")
    async def stop(ctx):
        macro.stop_loop()
        running_event.clear()
        await ctx.respond("Macro stopped.")

    @bot.slash_command(description="Start the macro")
    async def start(ctx):
        running_event.set()
        threading.Thread(target=macro.start_loop, daemon=True).start()
        await ctx.respond("Macro started.")

    return bot

# start the bot
def start_bot(macro, running_event):
    bot_instance = setup_bot(macro, running_event)
    bot_thread = threading.Thread(target=lambda: bot_instance.run(config["DiscordBotToken"]), daemon=True)
    bot_thread.start()
