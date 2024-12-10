# PAUSE COMMAND IS COMMENTED OUT CUS PAUSING ISNT IN PYTHON VERSION IDK WHY :/

import discord # type: ignore
import json
import threading
import pyautogui
import requests
import os

from discord.ext import commands # type: ignore
from discord import app_commands # type: ignore
from datetime import datetime

CONFIG_PATH = "config.json"
with open(CONFIG_PATH, "r") as file:
    config = json.load(file)

intents = discord.Intents.default()
bot = commands.Bot(command_prefix="/", intents=intents)

def update_config(key, value):
    config[key] = value
    with open(CONFIG_PATH, "w") as file:
        json.dump(config, file, indent=4)

# setup bot and register commands
def setup_bot(macro, running_event):
    @bot.event
    async def on_ready():
        print(f"Bot is online as {bot.user}")
        try:
            synced = await bot.tree.sync()
            print(f"Synced {len(synced)} commands with Discord.")
        except Exception as e:
            print(f"Error syncing commands: {e}")
        if not config.get("DiscordBot_UserID"):
            print("Warning: No User ID configured. Commands will not be executable until a valid User ID is set.")
            webhook_url = config.get("WebhookLink")
            if webhook_url:
                embeds = [{
                    "title": "WARNING",
                    "description": f"User ID Not Specified\nPlease specify your Discord User ID to run commands.",
                    "color": 7289397
                }]
            else:
                local_embed = discord.Embed(
                    title="WARNING",
                    description="Webhook URL is not configured.\nPlease configure your webhook", 
                    color=discord.Color.from_rgb(128, 128, 128)
                )
                await ctx.send(embed=local_embed, ephemeral=True) # type: ignore

    # define commands

    #@app_commands.command(name="pause", description="Pause/Unpause the macro")
    #async def pause(ctx: discord.Interaction):
    #    if running_event.is_set():
    #        running_event.clear()
    #        macro.stop_loop()
    #        await ctx.response.send_message("Macro paused.")
    #    else:
    #        running_event.set()
    #        threading.Thread(target=macro.start_loop, daemon=True).start()
    #        await ctx.response.send_message("Macro resumed.")

    @app_commands.command(name="rejoin", description="Restart macro and reconnect")
    async def rejoin(ctx: discord.Interaction):
        await ctx.reponse.send_message("This command has not been developed yet. Please wait for the next release.", ephemeral="True")

    #    user_id = ctx.user.id

    #    if not config.get("DiscordBot_UserID"):
    #        await ctx.response.send_message("No User ID is configured. Please set your User ID in the bot settings to use commands.", ephemeral=True)
    #        return

    #    if str(user_id) != str(config.get("DiscordBot_UserID")):
    #        await ctx.response.send_message("You do not have permission to use this command. Ensure the correct User ID is set.", ephemeral=True)
    #        return

    #    macro.stop_loop()
    #    await ctx.response.send_message("Rejoining...", ephemeral=True)
    #    threading.Thread(target=macro.start_loop, daemon=True).start()

    @app_commands.command(name="stats", description="Schedule player stats update")
    async def stats(ctx: discord.Interaction):
        user_id = ctx.user.id

        if not config.get("DiscordBot_UserID"):
            await ctx.response.send_message("No User ID is configured. Please set your User ID in the bot settings to use commands.", ephemeral=True)
            return

        if str(user_id) != str(config.get("DiscordBot_UserID")):
            await ctx.response.send_message("You do not have permission to use this command. Ensure the correct User ID is set.", ephemeral=True)
            return

        macro.immediate_stats_update = True
        await ctx.response.send_message(
            "Player stats update has been scheduled for the end of the current cycle.",
            ephemeral=True,
        )

    @app_commands.command(name="screenshot", description="Take a screenshot of the current screen")
    async def screenshot(ctx: discord.Interaction):
        user_id = ctx.user.id

        if not config.get("DiscordBot_UserID"):
            await ctx.response.send_message("No User ID is configured. Please set your User ID in the bot settings to use commands.", ephemeral=True)
            return

        if str(user_id) != str(config.get("DiscordBot_UserID")):
            await ctx.response.send_message("You do not have permission to use this command. Ensure the correct User ID is set.", ephemeral=True)
            return
        
        await ctx.response.defer(ephemeral=True)

        try:
            os.makedirs("images", exist_ok=True)

            screenshot_path = "images/current_screen.png"
            screenshot = pyautogui.screenshot()
            screenshot.save(screenshot_path)

            current_time = datetime.now().strftime("%H:%M:%S")
            webhook_url = config.get("WebhookLink")
            
            if webhook_url:
                embeds = [{
                    "title": "Screenshot Captured",
                    "description": f"Screenshot taken at {current_time}",
                    "color": 7289397,
                    "image": {"url": f"attachment://{os.path.basename(screenshot_path)}"}
                }]

                with open(screenshot_path, "rb") as image_file:
                    payload = {
                        "payload_json": json.dumps({
                            "embeds": embeds
                        })
                    }
                    files = {"file": (os.path.basename(screenshot_path), image_file, "image/png")}
                    webhook_response = requests.post(
                        webhook_url,
                        data=payload,
                        files=files
                    )

                if webhook_response.status_code in [200, 204]:
                    local_embed = discord.Embed(
                        description="Screenshot sent successfully.", 
                        color=discord.Color.from_rgb(128, 128, 128)
                    )
                    await ctx.followup.send(embed=local_embed, ephemeral=True)
                else:
                    local_embed = discord.Embed(
                        description=f"Failed to send screenshot. Status code: {webhook_response.status_code}", 
                        color=discord.Color.from_rgb(128, 128, 128)
                    )
                    await ctx.followup.send(embed=local_embed, ephemeral=True)
            else:
                local_embed = discord.Embed(
                    description="Webhook URL is not configured.", 
                    color=discord.Color.from_rgb(128, 128, 128)
                )
                await ctx.followup.send(embed=local_embed, ephemeral=True)
        except Exception as e:
            local_embed = discord.Embed(
                description=f"Error taking screenshot: {e}", 
                color=discord.Color.from_rgb(128, 128, 128)
            )
            await ctx.followup.send(embed=local_embed, ephemeral=True)

    @app_commands.command(name="stop", description="Stop the macro")
    async def stop(ctx: discord.Interaction):
        user_id = ctx.user.id

        if not config.get("DiscordBot_UserID"):
            await ctx.response.send_message("No User ID is configured. Please set your User ID in the bot settings to use commands.", ephemeral=True)
            return

        if str(user_id) != str(config.get("DiscordBot_UserID")):
            await ctx.response.send_message("You do not have permission to use this command. Ensure the correct User ID is set.", ephemeral=True)
            return
        
        macro.stop_loop()
        running_event.clear()
        local_embed = discord.Embed(
            description="Macro stopped.", 
            color=discord.Color.from_rgb(128, 128, 128)
        )
        await ctx.followup.send(embed=local_embed, ephemeral=True)

    @app_commands.command(name="start", description="Start the macro")
    async def start(ctx: discord.Interaction):
        user_id = ctx.user.id

        if not config.get("DiscordBot_UserID"):
            await ctx.response.send_message("No User ID is configured. Please set your User ID in the bot settings to use commands.", ephemeral=True)
            return

        if str(user_id) != str(config.get("DiscordBot_UserID")):
            await ctx.response.send_message("You do not have permission to use this command. Ensure the correct User ID is set.", ephemeral=True)
            return
        
        running_event.set()
        threading.Thread(target=macro.start_loop, daemon=True).start()
        local_embed = discord.Embed(
            description="Macro started.", 
            color=discord.Color.from_rgb(128, 128, 128)
        )
        await ctx.followup.send(embed=local_embed, ephemeral=True)

    # add commands to tree
    #bot.tree.add_command(pause)
    bot.tree.add_command(rejoin)
    bot.tree.add_command(stats)
    bot.tree.add_command(screenshot)
    bot.tree.add_command(stop)
    bot.tree.add_command(start)

# start the bot
def start_bot(macro, running_event):
    setup_bot(macro, running_event)
    bot.run(config["DiscordBotToken"])