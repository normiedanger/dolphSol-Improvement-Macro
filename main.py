import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import re, os, sys, json, threading, time, pyautogui, webbrowser, requests
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
import threading

from pynput import mouse, keyboard
from PIL import ImageGrab, Image, ImageDraw, ImageTk
from modules.main_loop import MacroLoop 
from modules.record_path import RecordPath
from modules.snipping import SnippingWidget
from modules.main_loop import MacroLoop
from modules.discord_bot import start_bot
        
class DiscordMacroUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Improvement Sol's v1.5.1 (EON1)")
        self.root.configure(bg="#2C2F33")
        self.dark_mode = True
        
        self.macro_loop = MacroLoop()
        self.macro_loop_listener = threading.Thread(target=self.start_key_listener, daemon=True)
        self.macro_loop_listener.start()
        self.running_event = threading.Event()
        self.running_event.set()
        
        # theme
        theme_path = os.path.join("modules/Azure-ttk-theme-2.1.0", "azure.tcl")
        self.root.tk.call("source", theme_path)
        self.root.tk.call("set_theme", "dark")

        # design
        style = ttk.Style()
        style.configure("TLabelFrame", padding=10, font=("Helvetica", 10))
        style.configure("TButton", font=("Helvetica", 10), padding=(6, 4))
        style.configure("TCheckbutton", font=("Helvetica", 10), padding=(6, 4))
        style.configure("TRadiobutton", font=("Helvetica", 10))
        style.configure("Switch.TCheckbutton", font=("Helvetica", 10), padding=5)
        self.center_window()
        
        #config and config path
        self.config_path = "config.json"
        self.config = self.load_config()

        # initialize/start the discord bot
        if self.config.get("DiscordBot_Enabled", 0):
            threading.Thread(target=start_bot, args=(self.macro_loop, self.running_event), daemon=True).start()

        # UI
        self.setup_tabs()
        self.setup_main_tab()
        self.setup_crafting_tab()
        self.setup_webhook_tab()
        self.setup_discordbot_tab()
        self.setup_settings_tab()
        self.setup_credits_tab()
        self.setup_merchant_tab()
        self.setup_extras_tab()
        self.auto_resize()

        # Variable for eon1 record and replay custom path 
        self.listener = None
        self.record_thread = None
        self.replay_thread = None
        self.is_replaying = False
        self.current_page = 0
        self.sub_paths = [f"Sub-Path {i + 1}" for i in range(8)]
        
        # item scheduler:
        self.scheduler_entries = []
        self.entry_vars = []
        self.entry_widgets = []
        self.available_items = ["Strange Controller", "Biome Randomizer", "Lucky Potion", "Speed Potion", 
                                "Fortune Potion I", "Fortune Potion II", "Fortune Potion III", 
                                "Haste Potion I", "Haste Potion II", "Haste Potion III", 
                                "Heavenly Potion I", "Heavenly Potion II", 
                                "Merchant Teleport", "Oblivion Potion"]
        
        #~ assign buttons:
        self.coord_vars = {}
        
    def system_message(self, message):
        messagebox.showinfo("Discord Macro UI", message)
           
    def load_config(self):
        try:
            with open(self.config_path, "r") as file:
                return json.load(file)
        except FileNotFoundError:
            return {}

    def update_config(self, key, value, default=None):
        if key not in self.config:
            self.config[key] = value if default is None else default
        else:
            self.config[key] = value
        self.save_config()

    def save_config(self):
        with open(self.config_path, "w") as file:
            json.dump(self.config, file, indent=4)

    def update_item_spot(self, index, var):
        item_spots = self.config.get("Sub_ItemSpot", [0] * 8)
        item_spots[index] = var.get()
        self.update_config("Sub_ItemSpot", item_spots)
        
    def import_settings(self):
        file_path = filedialog.askopenfilename(
            title="Select Config File",
            filetypes=(("JSON Files", "*.json"), ("All Files", "*.*"))
        )
        if not file_path:
            return
        try:
            with open(file_path, "r") as file:
                imported_config = json.load(file)
            self.config.update(imported_config)
            self.save_config()

            self.system_message("Settings imported successfully! Please restart the macro to take effect :3")
        except Exception as e:
            self.system_message(f"Error importing settings: {str(e)}")
        
    #?? Start and stop macro loop goober ##
    #& what kind of this fr*nch keyboard .-.
    
    def get_key_bindings(self):
        azerty_keyboard = self.config.get("AZERTY_Keyboard", False)
        if azerty_keyboard:
            return {'record_start': 'o', 'record_stop': 'p', 'replay_start': 'l', 'replay_stop': 'm'}
        return {'record_start': '[', 'record_stop': ']', 'replay_start': ';', 'replay_stop': "'"}

    def start_key_listener(self):
        def on_press(key):
            try:
                if key == keyboard.Key.f1:
                    self.on_start_macro()
                elif key == keyboard.Key.f3:
                    self.on_stop_macro()
            except Exception as e:
                print(f"Error in key listener: {e}")

        with keyboard.Listener(on_press=on_press) as listener:
            listener.join()


    #?? Equip Aura ##
    def open_aura_search(self):
        search_window = tk.Toplevel(self.root)
        search_window.title("Auto Equip Aura")
        search_window.geometry("320x170")
        tk.Label(search_window, text="Enter aura name to be used for search.\nThe first result will be equipped so be specific.").pack(pady=5)
        
        self.aura_name_var = tk.StringVar(value=self.config.get("Equipped_Aura", ""))
        aura_entry = ttk.Entry(search_window, textvariable=self.aura_name_var)
        aura_entry.pack(pady=5)

        self.special_aura_var = tk.IntVar()
        special_checkbox = ttk.Checkbutton(search_window, text="Search in Special Auras", variable=self.special_aura_var)
        special_checkbox.pack()

        # submit 
        submit_button = ttk.Button(search_window, text="Submit", command=self.save_aura_config)
        submit_button.pack(pady=5)

    def save_aura_config(self):
        aura_name = self.aura_name_var.get()
        is_special = self.special_aura_var.get()

        self.config["Equipped_Aura"] = aura_name
        self.config["Special_Aura"] = is_special

        with open("config.json", "w") as config_file:
            json.dump(self.config, config_file, indent=4)

        for widget in self.root.winfo_children():
            if isinstance(widget, tk.Toplevel):
                widget.destroy()
                
    ##? Equip Aura ## 
    
    ## ^^ ITEM SCHEDULER ^^ ##
    
    def load_from_json(self):
        try:
            with open("config.json", "r") as file:
                data = json.load(file)
                self.scheduler_entries = data.get("item_scheduler", [])
                
                for entry in self.scheduler_entries:
                    entry.setdefault("item", self.available_items[0])
                    entry.setdefault("quantity", 1)
                    entry.setdefault("frequency", 1)
                    entry.setdefault("frequency_unit", "Minutes")
                    entry.setdefault("biome", "Any")

        except (FileNotFoundError, json.JSONDecodeError):
            self.scheduler_entries = [
                {"item": self.available_items[0], "quantity": 1, "frequency": 1, "frequency_unit": "Minutes", "biome": "Any"}
            ]

        self.refresh_itemscheduler_ui()

    def save_to_json(self):
        try:
            try:
                with open("config.json", "r") as file:
                    data = json.load(file)
            except (FileNotFoundError, json.JSONDecodeError):
                data = {}

            data["item_scheduler"] = self.scheduler_entries

            with open("config.json", "w") as file:
                json.dump(data, file, indent=4)

        except Exception as e:
            print(f"Error saving to config.json: {e}")

    def refresh_itemscheduler_ui(self):
        for widgets in self.entry_widgets:
            for widget in widgets.values():
                widget.destroy()
        self.entry_widgets.clear()

        for i, entry in enumerate(self.scheduler_entries, start=1):
            self.add_entry_widgets(self.scheduler_frame, i, entry)
        self.scheduler_frame.update()
            
    ## ^^ ITEM SCHEDULER ^^ ##
            
         
    ## ~ WEBHOOK ## 

    def toggle_webhook_enabled(self):
        if self.enable_webhook.get() == 1 and not self.webhook_url_entry.get():
            messagebox.showwarning("Webhook Disabled", "Please enter a valid Discord webhook URL before enabling.")
            self.enable_webhook.set(0)
            return
        self.update_config("Webhook_Enabled", self.enable_webhook.get())

    
     ## ~ DISCORD BOT ## 

    def toggle_discordbot_enabled(self):
        if self.enable_discordbot.get() == 1 and not self.discordbot_token_entry.get():
            messagebox.showwarning("Discord Bot Disabled", "Please enter a valid Discord Bot Token before enabling.")
            self.enable_discordbot.set(0)
            return
        self.update_config("DiscordBot_Enabled", self.enable_discordbot.get())
     
    ##* Check PS link format *##
    def validate_and_save_ps_link(self, event=None):
            link = self.server_link_var.get()
            if self.is_valid_ps_link(link):
                self.config["PrivateServerLink"] = link
                with open(self.config_path, "w") as config_file:
                    json.dump(self.config, config_file, indent=4)
                self.status_label.config(text="Link saved successfully!", foreground="green")
            else:
                self.status_label.config(text="Invalid link format. Please correct it.", foreground="red")

    def is_valid_ps_link(self, link):
        if link.startswith("https://www.roblox.com/share?") and "code=" in link and "type=Server" in link:
            return True
        if link.startswith("https://www.roblox.com/games/") and "privateServerLinkCode=" in link:
            return True
        return False
    
    ##* Check PS link format *##
    
    ##& MERCHANT VARIABLES ##
    def open_merchant_calibration_window(self):
        calibration_window = tk.Toplevel(self.root)
        calibration_window.title("Merchant Calibration")
        calibration_window.geometry("650x400")

        positions = [
            ("Merchant Open Button", "merchant_open_button"),
            ("Merchant Dialogue Box", "merchant_dialogue_box"),
            ("Purchase Amount Button", "purchase_amount_button"),
            ("Purchase Button", "purchase_button"),
            ("First Item Slot Position", "first_item_slot_pos"),
            ("Merchant Name OCR Position", "merchant_name_ocr_pos"),
            ("Item Name OCR Position", "item_name_ocr_pos")
        ]

        for i, (label_text, config_key) in enumerate(positions):
            if "ocr" in config_key:
                label = ttk.Label(calibration_window, text=f"{label_text} (X, Y, W, H):")
                label.grid(row=i, column=0, padx=5, pady=5, sticky="w")

                x_var = tk.IntVar(value=self.config.get(config_key, [0, 0, 0, 0])[0])
                y_var = tk.IntVar(value=self.config.get(config_key, [0, 0, 0, 0])[1])
                w_var = tk.IntVar(value=self.config.get(config_key, [0, 0, 0, 0])[2])
                h_var = tk.IntVar(value=self.config.get(config_key, [0, 0, 0, 0])[3])
                self.coord_vars[config_key] = (x_var, y_var, w_var, h_var)

                x_entry = ttk.Entry(calibration_window, textvariable=x_var, width=6)
                x_entry.grid(row=i, column=1, padx=5, pady=5)

                y_entry = ttk.Entry(calibration_window, textvariable=y_var, width=6)
                y_entry.grid(row=i, column=2, padx=5, pady=5)

                w_entry = ttk.Entry(calibration_window, textvariable=w_var, width=6)
                w_entry.grid(row=i, column=3, padx=5, pady=5)

                h_entry = ttk.Entry(calibration_window, textvariable=h_var, width=6)
                h_entry.grid(row=i, column=4, padx=5, pady=5)

                select_button = ttk.Button(
                    calibration_window, text="Select Region",
                    command=lambda key=config_key: self.merchant_snipping(key)
                )
            else:
                label = ttk.Label(calibration_window, text=f"{label_text} (X, Y):")
                label.grid(row=i, column=0, padx=5, pady=5, sticky="w")

                x_var = tk.IntVar(value=self.config.get(config_key, [0, 0])[0])
                y_var = tk.IntVar(value=self.config.get(config_key, [0, 0])[1])
                self.coord_vars[config_key] = (x_var, y_var)

                x_entry = ttk.Entry(calibration_window, textvariable=x_var, width=6)
                x_entry.grid(row=i, column=1, padx=5, pady=5)

                y_entry = ttk.Entry(calibration_window, textvariable=y_var, width=6)
                y_entry.grid(row=i, column=2, padx=5, pady=5)

                select_button = ttk.Button(
                    calibration_window, text="Select Pos",
                    command=lambda key=config_key: self.start_capture_thread(key)
                )
            
            select_button.grid(row=i, column=5, padx=5, pady=5)

        save_button = ttk.Button(calibration_window, text="Save Calibration", command=lambda: self.save_merchant_coordinates(calibration_window))
        save_button.grid(row=len(positions), column=0, columnspan=6, pady=10)

    def merchant_snipping(self, config_key):
        def on_region_selected(region):
            x, y, w, h = region
            x_var, y_var, w_var, h_var = self.coord_vars[config_key]
            x_var.set(x)
            y_var.set(y)
            w_var.set(w)
            h_var.set(h)

        snipping_tool = SnippingWidget(self.root, config_key=config_key, callback=on_region_selected)
        snipping_tool.start()
        
        
    def open_merchant_webhook_window(self):
        webhook_window = tk.Toplevel(self.root)
        webhook_window.title("Discord Webhooks")
        webhook_window.geometry("650x400")

        webhook_frame = ttk.Frame(webhook_window)
        webhook_frame.pack(fill="both", expand=True, padx=10, pady=10)
        self.merchant_webhooks = self.config.get("Merchant_Webhook", [])

        for i, webhook in enumerate(self.merchant_webhooks):
            if isinstance(webhook, str):
                self.merchant_webhooks[i] = {"alias": f"Webhook {i+1}", "url": webhook, "mari_ping": "", "jester_ping": "", "ps_link": ""}

        def add_or_update_webhook(index=None):
            new_webhook = {
                "alias": alias_var.get(),
                "url": url_var.get(),
                "mari_ping": mari_ping_var.get(),
                "jester_ping": jester_ping_var.get(),
                "ps_link": ps_link_var.get()
            }
            if index is not None and 0 <= index < len(self.merchant_webhooks):
                self.merchant_webhooks[index] = new_webhook
            else:
                self.merchant_webhooks.append(new_webhook)
            self.update_config("Merchant_Webhook", self.merchant_webhooks)
            refresh_webhook_list()

        def refresh_webhook_list():
            for widget in webhook_list_frame.winfo_children():
                widget.destroy()

            for i, webhook in enumerate(self.merchant_webhooks):
                alias = webhook.get("alias", f"Webhook {i+1}")
                url = webhook.get("url", "")
                truncated_url = (url[:30] + '...') if len(url) > 30 else url

                ttk.Label(webhook_list_frame, text=f"{alias}: {truncated_url}", width=50).grid(row=i, column=0, sticky="w")
                ttk.Button(webhook_list_frame, text="Edit", command=lambda i=i: load_webhook_for_edit(i)).grid(row=i, column=1)
                ttk.Button(webhook_list_frame, text="Delete", command=lambda i=i: delete_webhook(i)).grid(row=i, column=2)

        def delete_webhook(index):
            if 0 <= index < len(self.merchant_webhooks):
                del self.merchant_webhooks[index]
                self.update_config("Merchant_Webhook", self.merchant_webhooks)
                refresh_webhook_list()

        def load_webhook_for_edit(index):
            if 0 <= index < len(self.merchant_webhooks):
                webhook = self.merchant_webhooks[index]
                alias_var.set(webhook.get("alias", ""))
                url_var.set(webhook.get("url", ""))
                mari_ping_var.set(webhook.get("mari_ping", ""))
                jester_ping_var.set(webhook.get("jester_ping", ""))
                ps_link_var.set(webhook.get("ps_link", ""))
                add_button.config(command=lambda: add_or_update_webhook(index))
                    
        def ping_test(ping_type):
            if ping_type == "mari":
                ping_id = mari_ping_var.get()
                color = 11753
            else:
                ping_id = jester_ping_var.get()
                color = 8595632

            webhook_url = url_var.get()
            ps_link = ps_link_var.get()
            message = f"Simulating ping to {ping_type.capitalize()} with ID: {ping_id}"
            
            screenshot = ImageGrab.grab()
            screenshot_path = f"images/merchant_screenshot.png"
            screenshot.save(screenshot_path)
            
            merchant_thumbnails = {
                "mari": "https://static.wikia.nocookie.net/sol-rng/images/d/df/Mari_cropped.png/revision/latest?cb=20241015111527",
                "jester": "https://static.wikia.nocookie.net/sol-rng/images/d/db/Headshot_of_Jester.png/revision/latest?cb=20240630142936"
            }

            embeds = [{
                "title": f"{ping_type.capitalize()} Detected!",
                "description": f"{ping_type.capitalize()} has been detected on your screen.\n**Merchant Face Screenshot**\n \n Merchant PS Link: {ps_link}",
                "color": color,
                "image": {"url": f"attachment://{os.path.basename(screenshot_path)}"},
                "thumbnail": {"url": merchant_thumbnails.get(ping_type, "")}
            }]
                    
            with open(screenshot_path, "rb") as image_file:
                files = {"file": (os.path.basename(screenshot_path), image_file, "image/png")}
                response = requests.post(
                    webhook_url,
                    data={
                        "payload_json": json.dumps({
                            "content": f"<@{ping_id}>",
                            "embeds": embeds
                        })
                    },
                    files=files
                )
                response.raise_for_status()
                print(f"Webhook sent successfully for {ping_type.capitalize()}: {response.status_code}")

        alias_var = tk.StringVar()
        url_var = tk.StringVar()
        mari_ping_var = tk.StringVar()
        jester_ping_var = tk.StringVar()
        ps_link_var = tk.StringVar()

        ttk.Label(webhook_frame, text="Webhook Alias:").grid(row=0, column=0, sticky="w")
        ttk.Entry(webhook_frame, textvariable=alias_var).grid(row=0, column=1, sticky="ew")

        ttk.Label(webhook_frame, text="Webhook URL:").grid(row=1, column=0, sticky="w")
        ttk.Entry(webhook_frame, textvariable=url_var).grid(row=1, column=1, sticky="ew")

        ttk.Label(webhook_frame, text="Ping User/Role ID (Mari):").grid(row=2, column=0, sticky="w")
        ttk.Entry(webhook_frame, textvariable=mari_ping_var).grid(row=2, column=1, sticky="ew")
        ping_mari_button = ttk.Button(webhook_frame, text="Mari Ping (Test)", command=lambda: ping_test("mari"))
        ping_mari_button.grid(row=2, column=2, padx=5)

        ttk.Label(webhook_frame, text="Ping User/Role ID (Jester):").grid(row=3, column=0, sticky="w")
        ttk.Entry(webhook_frame, textvariable=jester_ping_var).grid(row=3, column=1, sticky="ew")
        ping_jester_button = ttk.Button(webhook_frame, text="Jester Ping (Test)", command=lambda: ping_test("jester"))
        ping_jester_button.grid(row=3, column=2, padx=5)

        ttk.Label(webhook_frame, text="Merchant Private Server Link:").grid(row=4, column=0, sticky="w")
        ttk.Entry(webhook_frame, textvariable=ps_link_var).grid(row=4, column=1, sticky="ew")

        add_button = ttk.Button(webhook_frame, text="Add Webhook", command=lambda: add_or_update_webhook())
        add_button.grid(row=5, column=0, columnspan=3, pady=10)

        webhook_list_frame = ttk.Frame(webhook_frame)
        webhook_list_frame.grid(row=6, column=0, columnspan=3, sticky="nsew")

        refresh_webhook_list()
    
    def open_mari_item_settings(self):
        mari_window = tk.Toplevel(self.root)
        mari_window.title("Mari Item Settings")
        mari_window.geometry("300x565")

        items = [
            "Void Coin", "Lucky Penny", "Fortune Spoid I", "Fortune Spoid II",
            "Fortune Spoid III", "Mixed Potion", "Lucky Potion", "Lucky Potion L", "Lucky Potion XL", "Speed Potion",
            "Speed Potion L", "Speed Potion XL", "Gear A", "Gear B"
        ]

        self.mari_item_vars = {}
        saved_items = self.config.get("Mari_AutoBuyItems", {})

        for i, item_name in enumerate(items):
            var = tk.BooleanVar(value=item_name in saved_items)
            amount_var = tk.IntVar(value=saved_items.get(item_name, 1))

            checkbox = ttk.Checkbutton(mari_window, text=item_name, variable=var)
            checkbox.grid(row=i, column=0, sticky="w", padx=5, pady=2)

            amount_entry = ttk.Entry(mari_window, textvariable=amount_var, width=5)
            amount_entry.grid(row=i, column=1, padx=5, pady=2)

            self.mari_item_vars[item_name] = (var, amount_var)

        save_button = ttk.Button(mari_window, text="Save Selections", command=self.save_mari_selections)
        save_button.grid(row=len(items), column=0, columnspan=2, pady=10)

    def save_mari_selections(self):
        selections = {}
        for item_name, (var, amount_var) in self.mari_item_vars.items():
            if var.get():
                selections[item_name] = amount_var.get()

        self.config["Mari_AutoBuyItems"] = selections
        self.save_config()
        
        print("Mari Autobuy Items saved:", selections)
        
    
    def open_jester_item_settings(self):
        jester_window = tk.Toplevel(self.root)
        jester_window.title("Jester Item Settings")
        jester_window.geometry("300x655")

        items = [
            "Oblivion Potion", "Heavenly Potion I", "Heavenly Potion II",
            "Rune of Everything", "Rune of Nothing", "Rune Of Corruption",
            "Rune Of Hell", "Rune of Galaxy", "Rune of Rainstorm",
            "Rune of Frost", "Rune of Wind", "Strange Potion I",
            "Strange Potion II", "Stella's Candle", "Merchant Tracker",
            "Random Potion Sack"
        ]

        self.jester_item_vars = {}
        saved_items = self.config.get("Jester_AutoBuyItems", {})

        for i, item_name in enumerate(items):
            var = tk.BooleanVar(value=item_name in saved_items)
            amount_var = tk.IntVar(value=saved_items.get(item_name, 1))

            checkbox = ttk.Checkbutton(jester_window, text=item_name, variable=var)
            checkbox.grid(row=i, column=0, sticky="w", padx=5, pady=2)

            amount_entry = ttk.Entry(jester_window, textvariable=amount_var, width=5)
            amount_entry.grid(row=i, column=1, padx=5, pady=2)

            self.jester_item_vars[item_name] = (var, amount_var)

        save_button = ttk.Button(jester_window, text="Save Selections", command=self.save_jester_selections)
        save_button.grid(row=len(items), column=0, columnspan=2, pady=10)

    def save_jester_selections(self):
        selections = {}
        for item_name, (var, amount_var) in self.jester_item_vars.items():
            if var.get():
                selections[item_name] = amount_var.get()

        self.config["Jester_AutoBuyItems"] = selections
        self.save_config()
        
        print("Jester Autobuy Items saved:", selections)
        
    ##! Assign Button ##
    def open_assign_menu_window(self):
        self.assign_menu_window = tk.Toplevel(self.root)
        self.assign_menu_window.title("Assign Ingame Buttons Coordinates")
        self.assign_menu_window.geometry("560x580")
        self.assign_menu_window.attributes("-topmost", True)
        
        self.sections = [
            {
                "name": "Aura Equip",
                "buttons": {
                    "Aura Storage": "aura_storage_coords",
                    "Regular Aura Tab": "equip_tab_normal",
                    "Special Aura Tab": "equip_tab_special",
                    "Aura Search Bar": "search_bar_coords",
                    "First Aura Slot": "first_aura_coords",
                    "Equip Button": "equip_button_coords",
                }
            },
            {
                "name": "Alignment",
                "buttons": {
                    "Collection Menu": "collection_button_coords",
                    "Collection Exit Button": "collection_back_button_coords",
                }
            },
            {
                "name": "Inventory",
                "buttons": {
                    "Inventory Menu": "inv_menu_coords",
                    "Items Tab": "inv_itemtab_button_coords",
                    "Search Bar": "inv_sbar_button_coords",
                    "First Item Slot": "inv_firstitem_coords",
                    "Amount Box": "inv_amountbox_coords",
                    "Use button": "inv_use_button_coords",
                }
            },
            {
                "name": "Quest",
                "buttons": {
                    "Quest Menu": "quest_menu_coords",
                    "Daily Tab": "quest_dailytab_coords",
                    "First Quest Slot": "quest_firstquest_coords",
                    "Claim Button": "quest_claim_button_coords",
                }
            },
            
            {
                "name": "Potion Crafting",
                "buttons": {
                    "Potion Search Bar": "potion_sbar_coords",
                    "First Potion Slot": "potion_firstpotion_coords",
                    "Craft Button": "potion_craft_coords",
                    "Auto Button": "potion_autobutton_coords"
                }
            },
            
            {
                "name": "Potion Manual Item Click",
                "buttons": {
                    "#1 manual amount box": "potion_1manualbox_coords",
                    "#2 manual amount box": "potion_2manualbox_coords",
                    "#3 manual amount box": "potion_3manualbox_coords",
                    "#4 manual amount box": "potion_4manualbox_coords",
                    "#5 manual amount box": "potion_5manualbox_coords",
                    "#6 manual amount box (warp potion)": "potion_6manualbox_coords"
                }
            }
            
            
        ]

        self.current_page = 0  # Start on the first page
        self.coord_vars = {}

        # Save and navigation buttons
        navigation_frame = ttk.Frame(self.assign_menu_window)
        navigation_frame.grid(row=10, column=0, columnspan=4, pady=10)

        self.prev_button = ttk.Button(navigation_frame, text="Previous", command=self.prev_page)
        self.prev_button.grid(row=0, column=0, padx=5)
        
        self.next_button = ttk.Button(navigation_frame, text="Next", command=self.next_page)
        self.next_button.grid(row=0, column=1, padx=5)

        save_button = ttk.Button(navigation_frame, text="Save", command=self.save_coordinates)
        save_button.grid(row=0, column=2, padx=5)


        self.display_current_page()
        
    def display_current_page(self):
        for widget in self.assign_menu_window.winfo_children():
            if isinstance(widget, ttk.LabelFrame):
                widget.destroy()

        start_index = self.current_page * 2
        end_index = min(start_index + 2, len(self.sections))
        current_sections = self.sections[start_index:end_index]

        for section_index, section in enumerate(current_sections):
            section_frame = ttk.LabelFrame(
                self.assign_menu_window, 
                text=section["name"], 
                padding=(10, 5)
            )
            section_frame.grid(
                row=section_index, 
                column=0, 
                columnspan=4, 
                padx=10, 
                pady=10, 
                sticky="w"
            )

            for index, (label_text, config_key) in enumerate(section["buttons"].items()):
                label = ttk.Label(section_frame, text=f"{label_text}:")
                label.grid(row=index, column=0, padx=10, pady=5, sticky="w")

                # Initialize coordinate variables
                coords = self.config.get(config_key, [0, 0])
                x_var = tk.IntVar(value=coords[0])
                y_var = tk.IntVar(value=coords[1])
                self.coord_vars[config_key] = (x_var, y_var)

                # X and Y coordinate entries
                x_entry = ttk.Entry(section_frame, textvariable=x_var, width=6)
                x_entry.grid(row=index, column=1, padx=5, pady=5)

                y_entry = ttk.Entry(section_frame, textvariable=y_var, width=6)
                y_entry.grid(row=index, column=2, padx=5, pady=5)

                assign_button = ttk.Button(
                    section_frame, 
                    text="Assign Click",
                    command=lambda key=config_key: self.start_capture_thread(key)
                )
                assign_button.grid(row=index, column=3, padx=5, pady=5)

        self.prev_button["state"] = "normal" if self.current_page > 0 else "disabled"
        self.next_button["state"] = "normal" if start_index + 2 < len(self.sections) else "disabled"

    def prev_page(self):
        self.current_page -= 1
        self.display_current_page()

    def next_page(self):
        self.current_page += 1
        self.display_current_page()
    

    def start_capture_thread(self, config_key):
        capture_thread = threading.Thread(target=self.capture_mouse_position, args=(config_key,))
        capture_thread.daemon = True
        capture_thread.start()


    def capture_mouse_position(self, config_key):
        if hasattr(self, "capture_window") and self.capture_window.winfo_exists():
            return

        self.capture_window = tk.Toplevel(self.root)
        self.capture_window.attributes("-fullscreen", True)
        self.capture_window.attributes("-alpha", 0.3)
        self.capture_window.config(cursor="cross")

        def on_click(event):
            x, y = event.x_root, event.y_root
            x_var, y_var = self.coord_vars[config_key]
            x_var.set(x)
            y_var.set(y)
            print(f"Captured coordinates for {config_key}: ({x}, {y})")
            self.capture_window.destroy()
            del self.capture_window

        self.capture_window.bind("<Button-1>", on_click)
    
    def save_coordinates(self):
        for config_key, (x_var, y_var) in self.coord_vars.items():
            self.config[config_key] = [x_var.get(), y_var.get()]

        self.save_config()
        self.assign_menu_window.destroy()
        
    def save_merchant_coordinates(self, window):
        for config_key, vars in self.coord_vars.items():
            if "ocr" in config_key:
                x_var, y_var, w_var, h_var = vars
                self.config[config_key] = [x_var.get(), y_var.get(), w_var.get(), h_var.get()]
            else:
                x_var, y_var = vars
                self.config[config_key] = [x_var.get(), y_var.get()]

        self.save_config()
        window.destroy()

    
    ##? Record Path ##
    def open_record_path_window(self):
        self.current_page = 0

        record_window = tk.Toplevel(self.root)
        record_window.title("Record Path")

        # Frame to hold the path sub-frames
        self.path_frame = tk.Frame(record_window)
        self.path_frame.pack(padx=10, pady=5, fill="both", expand=True)

        # Navigation buttons
        nav_frame = tk.Frame(record_window)
        nav_frame.pack(pady=10)
        prev_button = tk.Button(nav_frame, text="<", command=lambda: self.navigate_paths(-1))
        prev_button.pack(side="left", padx=5)
        next_button = tk.Button(nav_frame, text=">", command=lambda: self.navigate_paths(1))
        next_button.pack(side="right", padx=5)
        self.update_displayed_paths()

    def update_displayed_paths(self):
        for widget in self.path_frame.winfo_children():
            widget.destroy()

        misc_frame = ttk.LabelFrame(self.path_frame, text="EON1 Misc Paths")
        misc_frame.grid(row=0, column=0, padx=5, pady=5, columnspan=2)

        #Obby & Potion Path
        self.add_misc_path(misc_frame, "Obby Path", path_num="misc_obby")
        self.add_misc_path(misc_frame, F"Potion Path", path_num="misc_potion")

        start_index = self.current_page * 4
        end_index = min(start_index + 4, len(self.sub_paths))

        # 4 sub-paths/page in 2x2 grid
        for row in range(2):
            for col in range(2):
                sub_path_index = start_index + row * 2 + col
                if sub_path_index >= end_index:
                    break
                frame = ttk.LabelFrame(self.path_frame, text=self.sub_paths[sub_path_index])
                frame.grid(row=row + 1, column=col, padx=5, pady=5, ipadx=10, ipady=5)

                for small_path in range(1, 6):
                    small_path_frame = ttk.Frame(frame)
                    small_path_frame.pack(fill="x", pady=2)

                    small_path_label = tk.Label(small_path_frame, text=f"Path {sub_path_index * 5 + small_path}")
                    small_path_label.pack(side="left", padx=5)

                    record_button = ttk.Button(small_path_frame, text="Record", command=lambda idx=sub_path_index * 5 + small_path: self.bind_record_keys(idx))
                    record_button.pack(side="left", padx=5)

                    replay_button = ttk.Button(small_path_frame, text="Replay", command=lambda idx=sub_path_index * 5 + small_path: self.bind_replay_keys(idx))
                    replay_button.pack(side="left", padx=5)


    def add_misc_path(self, frame, label, path_num):
        misc_path_frame = ttk.Frame(frame)
        misc_path_frame.pack(fill="x", pady=2)
        misc_path_label = tk.Label(misc_path_frame, text=label)
        misc_path_label.pack(side="left", padx=5)
        record_button = ttk.Button(misc_path_frame, text="Record", command=lambda: self.bind_record_keys(path_num))
        record_button.pack(side="left", padx=5)
        replay_button = ttk.Button(misc_path_frame, text="Replay", command=lambda: self.bind_replay_keys(path_num))
        replay_button.pack(side="left", padx=5)
                    
                         
    
    def navigate_paths(self, direction):
        new_page = self.current_page + direction
        if 0 <= new_page <= (len(self.sub_paths) - 1) // 4:
            self.current_page = new_page
            self.update_displayed_paths()

    
    BASE_PATH = os.path.join(os.path.dirname(__file__), 'MAIN_PATHS')
    
    def find_file(self, base_path, filename):
        for root, _, files in os.walk(base_path):
            if filename in files:
                return os.path.join(root, filename)
        return None

    def bind_record_keys(self, path_num):
        if self.listener:
            self.listener.stop()

        key_bindings = self.get_key_bindings()
        record_start_key = key_bindings['record_start']
        record_stop_key = key_bindings['record_stop']

        if path_num in ["misc_obby", "misc_potion"]:
            folder_name = "EON1_Misc"
            label = "Obby Path" if path_num == "misc_obby" else "Potion Path"
        else:
            path_num = int(path_num)
            sub_path_index = (path_num - 1) // 5 + 1
            folder_name = f"EON1_New\\EON1_SubPath{sub_path_index}"
            label = f"Path {path_num}"

        # Directory and file path for recording
        directory_path = os.path.join(self.BASE_PATH, folder_name)
        os.makedirs(directory_path, exist_ok=True)
        filename = os.path.join(directory_path, f"{label.lower().replace(' ', '_')}_record.json")
        recorder = RecordPath(filename)

        self.system_message(f"Press '{record_start_key}' to start recording, press '{record_stop_key}' to stop!")

        def on_press(key):
            try:
                if key.char == record_start_key:
                    if not self.record_thread or not self.record_thread.is_alive():
                        recorder.stop_recording_flag = False
                        self.record_thread = threading.Thread(target=recorder.start_recording)
                        self.record_thread.start()
                elif key.char == record_stop_key:
                    recorder.stop_recording_flag = True
                    self.record_thread = None
                    return False
            except AttributeError:
                pass

        self.listener = keyboard.Listener(on_press=on_press)
        self.listener.start()

    def bind_replay_keys(self, path_num):
        if self.listener:
            self.listener.stop()

        key_bindings = self.get_key_bindings()
        replay_start_key = key_bindings['replay_start']
        replay_stop_key = key_bindings['replay_stop']

        if path_num in ["misc_obby", "misc_potion"]:
            folder_name = "EON1_Misc"
            label = "Obby Path" if path_num == "misc_obby" else "Potion Path"
        else:
            path_num = int(path_num)
            sub_path_index = (path_num - 1) // 5 + 1
            folder_name = f"EON1_SubPath{sub_path_index}"
            label = f"Path {path_num}"

        directory_path = os.path.join(self.BASE_PATH, folder_name)
        expected_filename = f"{label.lower().replace(' ', '_')}_record.json"
        file_path = os.path.join(directory_path, expected_filename)

        if not os.path.exists(file_path):
            file_path = self.find_file(self.BASE_PATH, expected_filename)
            if not file_path:
                self.system_message(f"No recording found for {label}")
                return

        recorder = RecordPath(file_path)
        recorder.load_recording()

        self.system_message(f"Press '{replay_start_key}' to start replaying {label}, press '{replay_stop_key}' to stop.")

        def on_press(key):
            try:
                # print(f"Key pressed: {key}")  # Debug: Print the key pressed
                # print(f"Key char: {getattr(key, 'char', None)}")  # Debug: Print the key char
                # print(f"Replay start key: {replay_start_key}")  # Debug: Print the replay start key
                # print(f"Is replaying: {self.is_replaying}")  # Debug: Print the is_replaying status

                if getattr(key, 'char', None) == replay_start_key and not self.is_replaying:
                    print("Starting replay")
                    self.is_replaying = True
                    threading.Thread(target=self.start_replay, args=(recorder,)).start()
                elif getattr(key, 'char', None) == replay_stop_key:
                    print("Stopping replay")
                    recorder.stop_replay_flag = True
                    self.is_replaying = False
                    return False
            except AttributeError:
                pass

        self.listener = keyboard.Listener(on_press=on_press)
        self.listener.start()


    def start_replay(self, recorder):
        recorder.stop_replay_flag = False
        recorder.replay_actions()
        self.is_replaying = False 

        
    def setup_tabs(self):
        self.tab_control = ttk.Notebook(self.root)
        
        # Define noteatab
        self.main_tab = ttk.Frame(self.tab_control)
        self.crafting_tab = ttk.Frame(self.tab_control)
        self.webhook_tab = ttk.Frame(self.tab_control)
        self.discordbot_tab = ttk.Frame(self.tab_control)
        self.settings_tab = ttk.Frame(self.tab_control)
        self.credits_tab = ttk.Frame(self.tab_control)
        self.extras_tab = ttk.Frame(self.tab_control)
        self.merchant_tab = ttk.Frame(self.tab_control)

        # Add tabs to the notebook
        self.tab_control.add(self.main_tab, text="Main")
        self.tab_control.add(self.crafting_tab, text="Crafting")
        self.tab_control.add(self.webhook_tab, text="Webhook")
        self.tab_control.add(self.discordbot_tab, text="Discord Bot")
        self.tab_control.add(self.settings_tab, text="Settings")
        self.tab_control.add(self.credits_tab, text="Credits")
        self.tab_control.add(self.extras_tab, text="Extras")
        self.tab_control.add(self.merchant_tab, text="Merchants")
        self.tab_control.pack(expand=1, fill="both")

    def setup_main_tab(self):
        # Obby Section
        self.obby_frame = ttk.LabelFrame(self.main_tab, text="Miscellaneous")
        self.obby_frame.grid(column=0, row=0, padx=10, pady=10, sticky="w")
        
        self.do_obby_var = tk.IntVar(value=self.config.get("DoObby", 0))
        self.do_obby = ttk.Checkbutton(self.obby_frame, text="Do Obby (Every 4 Mins)", 
                                    variable=self.do_obby_var, 
                                    command=lambda: self.update_config("DoObby", self.do_obby_var.get()))
        self.do_obby.grid(column=0, row=0, sticky="w")
            
        self.do_chalice_var = tk.IntVar(value=self.config.get("AutoChalice", 0))
        self.do_chalice = ttk.Checkbutton(self.obby_frame, text="Auto Chalice (Unfinished)", 
                                            variable=self.do_chalice_var, 
                                            command=lambda: self.update_config("AutoChalice", self.do_chalice_var.get()))
        self.do_chalice.grid(column=0, row=1, sticky="w")

        # Auto Equip Section
        self.auto_equip_frame = ttk.LabelFrame(self.main_tab, text="Auto Equip")
        self.auto_equip_frame.grid(column=1, row=0, padx=15, pady=2, sticky="w")
        
        self.enable_auto_equip_var = tk.IntVar(value=self.config.get("Enabled_AutoEquip", 0))
        self.enable_auto_equip = ttk.Checkbutton(self.auto_equip_frame, text="Enable Auto Equip",
                                                 variable=self.enable_auto_equip_var,
                                                 command=lambda: self.update_config("Enabled_AutoEquip", self.enable_auto_equip_var.get()))
        self.enable_auto_equip.grid(column=0, row=0, sticky="w")
        
        self.configure_search_button = ttk.Button(self.auto_equip_frame, text="Configure Search", width=14, command=self.open_aura_search)
        self.configure_search_button.grid(column=1, row=0, padx=5, pady=5)

        # Item Collecting Section
        self.item_collecting_frame = ttk.LabelFrame(self.main_tab, text="Item Collecting")
        self.item_collecting_frame.grid(column=0, row=1, columnspan=2, padx=10, pady=10, sticky="w")

        self.collect_items_var = tk.IntVar(value=self.config.get("CollectItems", 0))
        self.collect_items = ttk.Checkbutton(self.item_collecting_frame, text="Collect Items Around the Map",
                                             variable=self.collect_items_var,
                                            command=lambda: self.update_config("CollectItems", self.collect_items_var.get()))
        
        self.collect_items.grid(column=0, row=0, sticky="w")

        # Path Radio Buttons
        self.path_label = ttk.Label(self.item_collecting_frame, text="Collection Sub-Paths:")
        self.path_label.grid(column=0, row=1, sticky="w")
        
        
        # RECORD PATH:
        self.record_path_button = ttk.Button(self.item_collecting_frame, text="Record Path", command=self.open_record_path_window)
        self.record_path_button.grid(column=2, row=1, sticky="w", padx=5, pady=5)
        
        # Collect from spots checkboxes
        self.spots_frame = ttk.Frame(self.item_collecting_frame)
        self.spots_frame.grid(column=0, row=2, columnspan=3, sticky="w", pady=2)

        # Spot checkboxes
        spot_labels = ["1", "2", "3", "4", "5", "6", "7", "8*"]
        self.item_spots = []
        for idx, spot in enumerate(spot_labels):
            var = tk.IntVar(value=self.config.get("Sub_ItemSpot", [0]*8)[idx])
            checkbox = ttk.Checkbutton(self.spots_frame, text=spot, variable=var,
                                       command=lambda idx=idx, var=var: self.update_item_spot(idx, var))
            checkbox.grid(row=0, column=idx, sticky="w")
            self.item_spots.append(var)
            
        #! menu button
        self.assign_menu_button = ttk.Button(self.item_collecting_frame, text="Assign Menu Buttons", command=self.open_assign_menu_window)
        self.assign_menu_button.grid(column=3, row=1, sticky="w", padx=5, pady=5)

        # Bottom Buttons (Start, Pause, Stop)
        self.bottom_frame = ttk.Frame(self.root, padding=3)
        self.bottom_frame.pack(fill="x")

        self.start_button = ttk.Button(self.bottom_frame, text="F1 - Start", width=10, command=self.on_start_macro)
        self.start_button.grid(row=0, column=0, padx=5)

        self.stop_button = ttk.Button(self.bottom_frame, text="F3 - Stop", width=10, command=self.on_stop_macro)
        self.stop_button.grid(row=0, column=2, padx=5)
        
        
        # Dark Mode Switch
        self.dark_mode_switch = ttk.Checkbutton(self.bottom_frame, text="Dark Mode", style="Switch.TCheckbutton", command=self.toggle_dark_mode)
        self.dark_mode_switch.state(['!alternate'])
        self.dark_mode_switch.grid(row=0, column=3, padx=5)

    def setup_crafting_tab(self):
        crafting_frame = ttk.LabelFrame(self.crafting_tab, text="Potion Crafting")
        crafting_frame.grid(row=0, column=0, padx=10, pady=10, sticky="nsew")

        # Automatic Potion Crafting checkbox
        self.automatic_potion_var = tk.BooleanVar(value=self.config.get("AutomaticPotionCrafting", False))
        automatic_potion_check = ttk.Checkbutton(
            crafting_frame, text="Automatic Potion Crafting", variable=self.automatic_potion_var,
            command=lambda: self.update_config("AutomaticPotionCrafting", self.automatic_potion_var.get())
        )
        automatic_potion_check.grid(row=0, column=0, columnspan=2, sticky="w", padx=5, pady=5)

        # Crafting Slots frame with 2-column layout
        slots_frame = ttk.LabelFrame(crafting_frame, text="Crafting Slots")
        slots_frame.grid(row=1, column=0, padx=10, pady=10, sticky="nsew")

        # Dropdown options for each slot
        self.available_potions = [
            "Fortune Potion I", "Fortune Potion II", "Fortune Potion III",
            "Haste Potion I", "Haste Potion II", "Haste Potion III",
            "Heavenly Potion I", "Heavenly Potion II", "Warp Potion"
        ]
        
        self.crafting_slots = []
        for i in range(6):
            slot_label = ttk.Label(slots_frame, text=f"Slot {i + 1}:")
            slot_label.grid(row=i % 3, column=(i // 3) * 2, padx=5, pady=5, sticky="e")

            slot_var = tk.StringVar(value=self.config.get(f"CraftingSlot{i+1}", "None"))
            slot_dropdown = ttk.Combobox(
                slots_frame, textvariable=slot_var, values=["None"] + self.available_potions, state="readonly"
            )
            slot_dropdown.grid(row=i % 3, column=(i // 3) * 2 + 1, padx=5, pady=5, sticky="w")
            slot_dropdown.bind("<<ComboboxSelected>>", lambda e, i=i: self.update_config(f"CraftingSlot{i+1}", self.crafting_slots[i].get()))
            self.crafting_slots.append(slot_var)

        # Crafting Intervals section on the right
        intervals_frame = ttk.LabelFrame(self.crafting_tab, text="Crafting Intervals")
        intervals_frame.grid(row=0, column=1, padx=10, pady=10, sticky="nsew")

        # Craft every X minutes setting
        ttk.Label(intervals_frame, text="Craft every").grid(row=0, column=0, sticky="e", padx=5, pady=5)
        self.craft_interval_var = tk.IntVar(value=self.config.get("CraftInterval", 1))
        craft_interval_entry = ttk.Entry(intervals_frame, textvariable=self.craft_interval_var, width=5)
        craft_interval_entry.grid(row=0, column=1, sticky="w", padx=5, pady=5)
        craft_interval_entry.bind("<FocusOut>", lambda e: self.update_config("CraftInterval", self.craft_interval_var.get()))
        ttk.Label(intervals_frame, text="minutes").grid(row=0, column=2, sticky="w", padx=5, pady=5)


        # Adjust layout configurations for compactness
        self.crafting_tab.grid_columnconfigure(0, weight=1)
        self.crafting_tab.grid_columnconfigure(1, weight=1)


    def setup_webhook_tab(self):
        main_frame = ttk.Frame(self.webhook_tab)
        main_frame.pack(expand=1, fill="both", padx=10, pady=10)

        # Webhook Frame
        webhook_frame = ttk.LabelFrame(main_frame, text="Discord Webhook")
        webhook_frame.grid(column=0, row=0, padx=(5, 10), pady=5, sticky="nw")

        # Enable Webhook Checkbox
        self.enable_webhook = tk.IntVar(value=self.config.get("Webhook_Enabled", 0))
        self.enable_webhook_checkbox = ttk.Checkbutton(webhook_frame, text="Enable Webhook", variable=self.enable_webhook,
                                                    command=self.toggle_webhook_enabled)
        self.enable_webhook_checkbox.grid(column=0, row=0, columnspan=2, sticky="w")

        # Webhook URL Entry (without validation)
        self.webhook_url_label = ttk.Label(webhook_frame, text="Webhook URL:")
        self.webhook_url_label.grid(column=0, row=1, sticky="w", padx=5, pady=2)
        self.webhook_url_entry = ttk.Entry(webhook_frame, width=25)
        self.webhook_url_entry.grid(column=1, row=1, sticky="w", padx=5, pady=2)
        self.webhook_url_entry.insert(0, self.config.get("WebhookLink", ""))

        # Update URL directly on focus out
        self.webhook_url_entry.bind("<FocusOut>", lambda e: self.update_config("WebhookLink", self.webhook_url_entry.get()))

        # Discord User ID Entry
        self.discord_user_id_label = ttk.Label(webhook_frame, text="Discord User ID (Pings):")
        self.discord_user_id_label.grid(column=0, row=3, sticky="w", padx=5, pady=2)
        self.discord_user_id_entry = ttk.Entry(webhook_frame, width=25)
        self.discord_user_id_entry.grid(column=1, row=3, sticky="w", padx=5, pady=2)
        self.discord_user_id_entry.insert(0, self.config.get("WebhookUserID", ""))
        self.discord_user_id_entry.bind("<FocusOut>", lambda e: self.update_config("WebhookUserID", self.discord_user_id_entry.get()))

        # Glitch Biome Ping ID Entry
        self.glitch_ping_label = ttk.Label(webhook_frame, text="Discord User/Role ID Glitch Biome Ping:")
        self.glitch_ping_label.grid(column=0, row=4, sticky="w", padx=5, pady=2)
        self.glitch_ping_entry = ttk.Entry(webhook_frame, width=25)
        self.glitch_ping_entry.grid(column=1, row=4, sticky="w", padx=5, pady=2)
        self.glitch_ping_entry.insert(0, self.config.get("WebhookGlitchPingID", ""))
        self.glitch_ping_entry.bind("<FocusOut>", lambda e: self.update_config("WebhookGlitchPingID", self.glitch_ping_entry.get()))

        # Inventory Screenshots Section
        self.inventory_label = ttk.Label(webhook_frame, text="Inventory Screenshot Interval (mins):")
        self.inventory_label.grid(column=0, row=6, sticky="w", padx=5, pady=2)

        self.inventory_interval = ttk.Spinbox(webhook_frame, from_=1, to=150, width=6)
        self.inventory_interval.grid(column=1, row=6, sticky="w", padx=5, pady=2)
        self.inventory_interval.set(self.config.get("WebhookInventoryInterval", 10))
        self.inventory_interval.bind("<FocusOut>", lambda e: self.update_config("WebhookInventoryInterval", int(self.inventory_interval.get())))

        self.inv_screenshot_var = tk.BooleanVar(value=self.config.get("WebhookInventory", False))
        self.inv_screenshot_checkbox = ttk.Checkbutton(
            webhook_frame,
            text="Enable Inventory Screenshots",
            variable=self.inv_screenshot_var,
            command=lambda: self.update_config("WebhookInventory", self.inv_screenshot_var.get())
        )
        self.inv_screenshot_checkbox.grid(column=0, row=5, sticky="w", padx=5, pady=5)

        # Roll Detection Section
        roll_detection_frame = ttk.LabelFrame(main_frame, text="Roll Detection (unfinished)")
        roll_detection_frame.grid(column=1, row=0, sticky="nw", padx=5, pady=5)

        # Send Minimum Entry
        self.send_minimum_label = ttk.Label(roll_detection_frame, text="Send Minimum:")
        self.send_minimum_label.grid(column=0, row=0, sticky="w", padx=5, pady=2)
        self.send_minimum_entry = ttk.Entry(roll_detection_frame, width=7)
        self.send_minimum_entry.grid(column=1, row=0, padx=5, pady=2)
        self.send_minimum_entry.insert(0, self.config.get("WebhookRollSendMinimum", ""))
        self.send_minimum_entry.bind("<FocusOut>", lambda e: self.update_config("WebhookRollSendMinimum", int(self.send_minimum_entry.get())))

        # Ping Minimum Entry
        self.ping_minimum_label = ttk.Label(roll_detection_frame, text="Ping Minimum:")
        self.ping_minimum_label.grid(column=0, row=1, sticky="w", padx=5, pady=2)
        self.ping_minimum_entry = ttk.Entry(roll_detection_frame, width=7)
        self.ping_minimum_entry.grid(column=1, row=1, padx=5, pady=2)
        self.ping_minimum_entry.insert(0, self.config.get("WebhookRollPingMinimum", ""))
        self.ping_minimum_entry.bind("<FocusOut>", lambda e: self.update_config("WebhookRollPingMinimum", int(self.ping_minimum_entry.get())))

        # Aura Images Checkbox
        self.aura_images = tk.IntVar(value=self.config.get("WebhookAuraImages", 0))
        self.aura_images_checkbox = ttk.Checkbutton(roll_detection_frame, text="Aura Images", variable=self.aura_images,
                                                    command=lambda: self.update_config("WebhookAuraImages", self.aura_images.get()))
        self.aura_images_checkbox.grid(column=0, row=2, columnspan=2, sticky="w", pady=2)

    def setup_discordbot_tab(self):
        main_frame = ttk.Frame(self.discordbot_tab)
        main_frame.pack(expand=1, fill="both", padx=10, pady=10)

        # Discord Bot Frame
        discordbot_frame = ttk.LabelFrame(main_frame, text="Discord Bot")
        discordbot_frame.grid(column=0, row=0, padx=(5, 10), pady=5, sticky="nw")

        # Enable Discord Bot Checkbox
        self.enable_discordbot = tk.IntVar(value=self.config.get("DiscordBot_Enabled", 0))
        self.enable_discordbot_checkbox = ttk.Checkbutton(discordbot_frame, text="Enable Discord Bot", variable=self.enable_discordbot,
                                                    command=self.toggle_discordbot_enabled)
        self.enable_discordbot_checkbox.grid(column=0, row=0, columnspan=2, sticky="w")

        # Discord User ID
        self.discordbot_userid_label = ttk.Label(discordbot_frame, text="Your Discord ID:")
        self.discordbot_userid_label.grid(column=0, row=1, sticky="w", padx=5, pady=2)
        self.discordbot_userid_entry = ttk.Entry(discordbot_frame, width=25)
        self.discordbot_userid_entry.grid(column=1, row=1, sticky="w", padx=5, pady=2)
        self.discordbot_userid_entry.insert(0, self.config.get("DiscordBot_UserID", ""))

        # Discord Token Entry (without validation)
        self.discordbot_token_label = ttk.Label(discordbot_frame, text="Discord Bot Token:")
        self.discordbot_token_label.grid(column=0, row=2, sticky="w", padx=5, pady=2)
        self.discordbot_token_entry = ttk.Entry(discordbot_frame, width=25)
        self.discordbot_token_entry.grid(column=1, row=2, sticky="w", padx=5, pady=2)
        self.discordbot_token_entry.insert(0, self.config.get("DiscordBotToken", ""))

        # Command Info Button
        discordbot_cmd_info = ttk.Button(discordbot_frame, text="Command Info", command=self.discordbot_cmd_info_popup)
        discordbot_cmd_info.grid(column=2, row=0, padx=5, pady=2)

        # Update inputs directly on focus out
        self.discordbot_token_entry.bind("<FocusOut>", lambda e: self.update_config("DiscordBotToken", self.discordbot_token_entry.get()))
        self.discordbot_userid_entry.bind("<FocusOut>", lambda e: self.update_config("DiscordBot_UserID", self.discordbot_userid_entry.get()))

    def discordbot_cmd_info_popup(self):
        discordbot_info = tk.Toplevel(self.root)
        discordbot_info.title("Discord Bot Commands")
        discordbot_info.geometry("630x300")

        discordbot_commands = """
        /start - Starts the macro
        /stop - Stops the macro
        /pause - Toggles pause for the macro
        /rejoin - Rejoin your private server
        /stats - Gives your storage and inventory once the next interaction phase finishes
        /screenshot - Sends a screenshot of whatever is on the screen
        """
        tk.Label(discordbot_info, text="Discord Bot Commands", font=("Helvetica", 14, "bold")).pack(pady=10)
        tk.Label(discordbot_info, text=discordbot_commands, justify="left", anchor="w").pack(padx=10, pady=10, fill="both", expand=True)
        ttk.Button(discordbot_info, text="Close", command=discordbot_info.destroy).pack(pady=10)

    def setup_settings_tab(self):
        main_frame = ttk.Frame(self.settings_tab)
        main_frame.pack(expand=1, fill="both", padx=10, pady=10)
        general_frame = ttk.LabelFrame(main_frame, text="General")
        general_frame.grid(column=0, row=0, padx=5, pady=5, sticky="nw")

        # Private Server Link
        ttk.Label(general_frame, text="Private Server Link:").grid(column=0, row=0, padx=5, pady=5, sticky="w")
        self.server_link_var = tk.StringVar(value=self.config.get("PrivateServerLink", ""))
        self.server_link_entry = ttk.Entry(general_frame, textvariable=self.server_link_var, width=50)
        self.server_link_entry.grid(column=1, row=0, padx=5, pady=5, sticky="w")
        self.server_link_entry.bind("<FocusOut>", self.validate_and_save_ps_link)

        # Status message
        self.status_label = ttk.Label(general_frame, text="", foreground="red")
        self.status_label.grid(column=1, row=1, padx=5, pady=5, sticky="w")

        # Auto Claim Daily Quests Checkbox
        self.auto_claim_var = tk.BooleanVar(value=self.config.get("AutoClaimDailyQuests", False))
        self.auto_claim_checkbox = ttk.Checkbutton(
            general_frame,
            text="Auto Claim Daily Quests (30 min)",
            variable=self.auto_claim_var,
            command=lambda: self.update_config("AutoClaimDailyQuests", self.auto_claim_var.get())
        )
        self.auto_claim_checkbox.grid(column=0, row=2, padx=5, pady=5, sticky="w")
        
        # Azerty keyboard TYPE checkbox
        self.is_azerty_var = tk.BooleanVar(value=self.config.get("AZERTY_Keyboard", False))
        self.is_azerty_checkbox = ttk.Checkbutton(
            general_frame,
            text="AZERTY Keyboard Layout",
            variable=self.is_azerty_var,
            command=lambda: self.update_config("AZERTY_Keyboard", self.is_azerty_var.get())
        )
        self.is_azerty_checkbox.grid(column=0, row=3, padx=5, pady=5, sticky="w")
        
        import_button = ttk.Button(general_frame, text="Import Settings", command=self.import_settings)
        import_button.grid(column=0, row=4, padx=5, pady=5, sticky="w")
    
    def setup_credits_tab(self):
        main_frame = ttk.Frame(self.credits_tab)
        main_frame.pack(expand=1, fill="both", padx=5, pady=5)
        
        main_frame.grid_columnconfigure(0, weight=1)
        main_frame.grid_columnconfigure(1, weight=1)
        main_frame.grid_rowconfigure(0, weight=1)
        main_frame.grid_rowconfigure(1, weight=1)
        
        # Creator Section
        creator_frame = ttk.LabelFrame(main_frame, text="The Creator")
        creator_frame.grid(column=0, row=0, padx=5, pady=5, sticky="nsew")
        creator_frame.grid_columnconfigure(0, weight=1)

        creator_image = Image.open("images/Game_UI/noteab.png")
        creator_image = creator_image.resize((50, 50), Image.LANCZOS)
        creator_photo = ImageTk.PhotoImage(creator_image)
        
        creator_image_label = ttk.Label(creator_frame, image=creator_photo)
        creator_image_label.image = creator_photo 
        creator_image_label.grid(column=0, row=0, padx=5, pady=5, sticky="n")

        creator_label = ttk.Label(creator_frame, text="Noteab\n'Ordinary Solo Developer'", justify="center", font=("Helvetica", 9))
        creator_label.grid(column=0, row=1, padx=5, pady=5, sticky="n")

        # Inspired by Section
        inspired_frame = ttk.LabelFrame(main_frame, text="Inspired by")
        inspired_frame.grid(column=1, row=0, padx=5, pady=5, sticky="nsew")
        inspired_frame.grid_columnconfigure(0, weight=1)

        dolphin_image = Image.open("images/Game_UI/builderdolphin.png")
        dolphin_image = dolphin_image.resize((50, 50), Image.LANCZOS)
        dolphin_photo = ImageTk.PhotoImage(dolphin_image)
        
        dolphin_image_label = ttk.Label(inspired_frame, image=dolphin_photo)
        dolphin_image_label.image = dolphin_photo
        dolphin_image_label.grid(column=0, row=0, padx=5, pady=5, sticky="n")

        inspired_label = ttk.Label(inspired_frame, text="BuilderDolphin\n(dolphin)\n'Short project to learn AHK...'", justify="center", font=("Helvetica", 9))
        inspired_label.grid(column=0, row=1, padx=5, pady=5, sticky="n")

        # Other
        other_frame = ttk.LabelFrame(main_frame, text="Other")
        other_frame.grid(column=0, row=1, padx=5, pady=5, sticky="nsew", columnspan=2)
        
        discord_link = ttk.Label(other_frame, text="Join our Discord Server!", foreground="#1E90FF", cursor="hand2", font=("Helvetica", 9))
        discord_link.grid(column=0, row=0, padx=5, pady=5, sticky="w")
        discord_link.bind("<Button-1>", lambda e: webbrowser.open("https://discord.gg/radiant-team"))

        github_link = ttk.Label(other_frame, text="Visit the macro source code on GitHub!", foreground="#1E90FF", cursor="hand2", font=("Helvetica", 9))
        github_link.grid(column=0, row=1, padx=5, pady=5, sticky="w")
        github_link.bind("<Button-1>", lambda e: webbrowser.open("https://github.com/noteab/Improvement-Sols-Macro/tree/Noteab-Improvement"))


        extras_button = ttk.Button(other_frame, text="Extras Credit", command=self.show_extras_credit)
        extras_button.grid(column=0, row=2, padx=5, pady=5, sticky="w")

    def show_extras_credit(self):
        extras_window = tk.Toplevel(self.root)
        extras_window.title("Extras Credit")
        extras_window.geometry("450x450")

        contributors_frame = ttk.LabelFrame(extras_window, text="Contributors (Development)")
        contributors_frame.pack(fill="both", expand=True, padx=10, pady=10)

        contributors = [
            "vexthecoder -",
            "Created the Discord Bot code and functionality."
        ]

        for contributor in contributors:
            ttk.Label(contributors_frame, text=contributor).pack(pady=2)
        
        testers_frame = ttk.LabelFrame(extras_window, text="Macro Testers (Discord)")
        testers_frame.pack(fill="both", expand=True, padx=10, pady=10)

        testers = [
            "!|CaCO3|! Suggestions dweller - criticize.",
            "『❖』SmileNightOFC - smile.night",
            "Allan - _justalin",
            "Cataster - catast3r",
            "DiEgO - diego696969",
            "Dolphinatorツ - wtr_dolphinator",
            "enzo | Ping and i'll answer - enzomtp",
            "Garfield l LOA - garfieldthelord",
            "glen - g._tch",
            "justimon. - imonjusty",
            "ManasAarohi - manasaarohi",
            "Pach | Minn Worshiper - pachulin911",
            "Parham - parham125",
            "Perfectionista Minn | yln fan - kurugurui",
            "root da war veteran - taachyon",
            "ZekeDaYes - zekedayes"
        ]

        for tester in testers:
            ttk.Label(testers_frame, text=tester).pack(pady=2)

    def setup_merchant_tab(self):
        main_frame = ttk.Frame(self.merchant_tab)
        main_frame.pack(expand=1, fill="both", padx=10, pady=10)
        
        # Mari
        mari_frame = ttk.LabelFrame(main_frame, text="Mari")
        mari_frame.grid(column=1, row=0, padx=10, pady=10, sticky="nsew")

        mari_settings_button = ttk.Button(mari_frame, text="Mari Item Settings", command=self.open_mari_item_settings)
        mari_settings_button.grid(column=0, row=0, padx=5, pady=5)

        # Jester
        jester_frame = ttk.LabelFrame(main_frame, text="Jester")
        jester_frame.grid(column=2, row=0, padx=10, pady=10, sticky="nsew")

        jester_settings_button = ttk.Button(jester_frame, text="Jester Item Settings", command=self.open_jester_item_settings)
        jester_settings_button.grid(column=0, row=0, padx=5, pady=5)

        item_exchange_var = tk.IntVar(value=self.config.get("ItemExchangeJester", 0))
        item_exchange_checkbox = ttk.Checkbutton(
            jester_frame, text="Item Exchange (Jester)", variable=item_exchange_var,
            command=lambda: self.update_config("ItemExchangeJester", item_exchange_var.get())
        )
        item_exchange_checkbox.grid(column=0, row=1, padx=5, pady=5, sticky="w")

        # Merchant Options
        options_frame = ttk.LabelFrame(main_frame, text="Merchant Options")
        options_frame.grid(column=0, row=0, padx=10, pady=10, sticky="nsew")

        enable_auto_merchant_var = tk.IntVar(value=self.config.get("EnableAutoMerchant", 0))
        enable_auto_merchant_checkbox = ttk.Checkbutton(
            options_frame, text="Enable Auto Merchant", variable=enable_auto_merchant_var,
            command=lambda: self.update_config("EnableAutoMerchant", enable_auto_merchant_var.get())
        )
        enable_auto_merchant_checkbox.grid(column=0, row=0, padx=5, pady=5, sticky="w")

        merchant_calibrations_button = ttk.Button(
            options_frame, text="Merchant Calibrations", command=self.open_merchant_calibration_window
        )
        merchant_calibrations_button.grid(column=0, row=1, padx=5, pady=5)

        merchant_webhooks_button = ttk.Button(
            options_frame, text="Merchant Webhooks", command=self.open_merchant_webhook_window
        )
        merchant_webhooks_button.grid(column=0, row=2, padx=5, pady=5)

        self.merchant_tab.grid_columnconfigure(0, weight=1)
        self.merchant_tab.grid_columnconfigure(1, weight=1)
        self.merchant_tab.grid_columnconfigure(2, weight=1)
        
        
    def setup_extras_tab(self):
        main_frame = ttk.Frame(self.extras_tab)
        main_frame.pack(expand=1, fill="both", padx=10, pady=10)
        general_frame = ttk.LabelFrame(main_frame, text="General")
        general_frame.grid(column=0, row=0, padx=5, pady=5, sticky="nw")
        
        self.configure_biomes_button = ttk.Button(general_frame, text="Configure Biomes", command=self.open_biomes_configuration)
        self.configure_biomes_button.grid(column=0, row=1, padx=10, pady=5, sticky="w")
        
        self.item_scheduler_button = ttk.Button(general_frame, text="Item Scheduler", command=self.open_item_scheduler)
        self.item_scheduler_button.grid(column=1, row=1, padx=10, pady=5, sticky="w")
        
    def open_biomes_configuration(self):
        biome_window = tk.Toplevel(self.root)
        biome_window.title("Biome Settings")
        biome_window.geometry("350x500")

        # Biome settings frame
        biome_frame = ttk.LabelFrame(biome_window, text="Biome Alerts")
        biome_frame.pack(fill="both", expand=True, padx=10, pady=10)
        self.biome_vars = {}
        
        biomes = {
            "Biome_Notifer_Windy": "Windy",
            "Biome_Notifer_Rainy": "Rainy",
            "Biome_Notifer_Snowy": "Snowy",
            "Biome_Notifer_Sandstorm": "Sandstorm",
            "Biome_Notifer_Hell": "Hell",
            "Biome_Notifer_Starfall": "Starfall",
            "Biome_Notifer_Corruption": "Corruption",
            "Biome_Notifer_Null": "Null",
            "Biome_Notifer_Glitched": "Glitched"
        }

        # Dropdown and snip button for each biome
        for i, (config_key, biome_name) in enumerate(biomes.items()):
            ttk.Label(biome_frame, text=f"{biome_name}:").grid(row=i, column=0, padx=5, pady=2, sticky="w")
            var = tk.StringVar(value=self.config.get(config_key, "None"))
            
            self.biome_vars[config_key] = var
            dropdown = ttk.OptionMenu(biome_frame, var, self.config.get(config_key, "None"), "None", "Message", "Ping")
            dropdown.grid(row=i, column=1, padx=5, pady=2, sticky="w")
            var.trace_add("write", lambda *args, key=config_key, var=var: self.update_config(key, var.get()))

        def start_snipping():
            snipping_tool = SnippingWidget(self.root, config_key="Biome_Region")
            snipping_tool.start()
            
        # set biome region using snipping tool
        snip_button = ttk.Button(biome_frame, text="Set Biome Region", command=start_snipping)
        snip_button.grid(row=len(biomes), column=0, columnspan=2, pady=20)

    
    def open_item_scheduler(self):
        scheduler_window = tk.Toplevel(self.root)
        scheduler_window.title("Auto Item Scheduler")
        scheduler_window.geometry("750x400") 

        self.scheduler_frame = ttk.Frame(scheduler_window)
        self.scheduler_frame.pack(fill="both", expand=True, padx=10, pady=10)
        self.entry_widgets = []

        # Correct header order
        headers = ["Enable", "Item", "Quantity", "Frequency", "Unit & Duration", "Biome", "Delete"]
        for col, header in enumerate(headers):
            ttk.Label(self.scheduler_frame, text=header, anchor="center").grid(row=0, column=col, padx=5, pady=5, sticky="nsew")

        self.load_from_json()

        ttk.Button(scheduler_window, text="New Entry", command=lambda: self.add_new_entry(self.scheduler_frame)).pack(pady=5)


    def add_entry_widgets(self, parent, row, entry):
        enable_var = tk.BooleanVar(value=True)
        enable_checkbox = ttk.Checkbutton(parent, variable=enable_var, command=self.save_to_json)
        enable_checkbox.grid(row=row, column=0, padx=5, pady=5)

        # Item dropdown
        item_var = tk.StringVar()
        item_var.set(entry["item"])
        item_combobox = ttk.Combobox(parent, values=self.available_items, textvariable=item_var, width=20)
        item_combobox.grid(row=row, column=1, padx=5, pady=5)
        item_combobox.bind("<<ComboboxSelected>>", lambda e: self.save_on_update())

        # Quantity spinbox
        qty_var = tk.IntVar()
        qty_var.set(entry["quantity"])
        qty_spinbox = ttk.Spinbox(parent, from_=1, to=99, textvariable=qty_var, width=5, command=self.save_on_update)
        qty_spinbox.grid(row=row, column=2, padx=5, pady=5)

        # Frequency spinbox
        freq_var = tk.IntVar()
        freq_var.set(entry["frequency"])
        freq_spinbox = ttk.Spinbox(parent, from_=1, to=999, textvariable=freq_var, width=5, command=self.save_on_update)
        freq_spinbox.grid(row=row, column=3, padx=5, pady=5)

        # Frequency unit dropdown
        freq_unit_var = tk.StringVar()
        freq_unit_var.set(entry["frequency_unit"])
        freq_unit_combobox = ttk.Combobox(parent, values=["Seconds", "Minutes", "Hours"], textvariable=freq_unit_var, width=7)
        freq_unit_combobox.grid(row=row, column=4, padx=5, pady=5)
        freq_unit_combobox.bind("<<ComboboxSelected>>", lambda e: self.save_on_update())

        # Biome dropdown
        biome_var = tk.StringVar()
        biome_var.set(entry["biome"])
        biome_combobox = ttk.Combobox(parent, values=["Any", "Windy", "Rainy", "Snowy", "Sandstorm", "Hell", "Starfall", "Corruption", "Null", "Glitched"], textvariable=biome_var, width=10)
        biome_combobox.grid(row=row, column=5, padx=5, pady=5)
        biome_combobox.bind("<<ComboboxSelected>>", lambda e: self.save_on_update())

        # Delete button
        delete_button = ttk.Button(parent, text="Delete", command=lambda row=row: self.delete_scheduler_entry(parent, row))
        delete_button.grid(row=row, column=6, padx=5, pady=5)

        # Store widget references
        self.entry_widgets.append({
            "enable": enable_checkbox,
            "item": item_combobox,
            "quantity": qty_spinbox,
            "frequency": freq_spinbox,
            "freq_unit": freq_unit_combobox,
            "biome": biome_combobox,
            "delete": delete_button
        })

        self.entry_vars.append({
            "item": item_var,
            "quantity": qty_var,
            "frequency": freq_var,
            "freq_unit": freq_unit_var,
            "biome": biome_var
        })

        parent.update_idletasks()



    def delete_scheduler_entry(self, parent, row):
        index = row - 1 
        if index < len(self.entry_widgets):
            for widget in self.entry_widgets[index].values():
                widget.grid_forget()
                widget.destroy()
            
            del self.scheduler_entries[index]
            del self.entry_widgets[index]

            for i, widgets in enumerate(self.entry_widgets, start=1):
                for key, widget in widgets.items():
                    widget.grid_configure(row=i)
                    
            self.save_to_json()

    def add_new_entry(self, parent):
        new_entry = {
            "item": self.available_items[0],
            "quantity": 1,
            "frequency": 1,
            "frequency_unit": "Minutes",
            "biome": "Any"
        }
        
        self.scheduler_entries.append(new_entry)
        row = len(self.scheduler_entries)

        self.add_entry_widgets(parent, row, new_entry)
        self.save_to_json()


    def save_on_update(self):
        self.scheduler_entries = []
        for widgets, vars in zip(self.entry_widgets, self.entry_vars):
            entry = {
                "item": vars["item"].get(),
                "quantity": vars["quantity"].get(),
                "frequency": vars["frequency"].get(),
                "frequency_unit": vars["freq_unit"].get(),
                "biome": vars["biome"].get()
            }
            self.scheduler_entries.append(entry)
        self.save_to_json()
        

    def on_start_macro(self):
        self.macro_loop.start_loop()

    def on_stop_macro(self): 
        self.macro_loop.stop_loop()
        if hasattr(self.macro_loop, 'record_path_instance'):
            self.macro_loop.record_path_instance.stop_replay_flag = True
            
            
            
        
    def toggle_dark_mode(self):
        current_geometry = self.root.geometry()
        
        if self.dark_mode:
            self.root.tk.call("set_theme", "light")
            self.root.configure(bg="#FFFFFF")
            self.dark_mode_switch.config(text="Light Mode")
        else:
            self.root.tk.call("set_theme", "dark")
            self.root.configure(bg="#2C2F33")
            self.dark_mode_switch.config(text="Dark Mode")
        
        self.root.geometry(current_geometry)
        self.dark_mode = not self.dark_mode
        
    def auto_resize(self):
        self.root.update_idletasks()
        self.root.geometry(f"{self.root.winfo_width()}x{self.root.winfo_height()}")
        
    def center_window(self):
        self.root.update_idletasks()
        width = self.root.winfo_width()
        height = self.root.winfo_height()
        
        screen_width = self.root.winfo_screenwidth()
        screen_height = self.root.winfo_screenheight()

        x = (screen_width - width) // 2
        y = (screen_height - height) // 2
        self.root.geometry(f"+{x}+{y}")
        
if __name__ == "__main__":
    root = tk.Tk()
    app = DiscordMacroUI(root)
    root.mainloop()
