import threading, time, win32gui, win32con, os, json, re, requests, base64, io, pytesseract
import concurrent.futures
import numpy as np
import pygetwindow as gw
import pyautogui, cv2
from ahk import AHK
from PIL import Image, ImageGrab
from modules.aura_detector import AuraDetector
from modules.record_path import RecordPath
from modules.biome_detector import BiomeDetector

ahk = AHK(executable_path=r"C:\Program Files\AutoHotkey\AutoHotkey.exe")
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
print("Current working directory:", os.getcwd())


class MacroLoop:
    BASE_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'MAIN_PATHS'))
    
    def __init__(self):
        self.running = threading.Event()
        self.thread = None
        # self.aura_detector_running = threading.Event()
        # self.aura_detector_thread = None
        # self.aura_detector = AuraDetector()
        
        self.biome_detector_running = threading.Event()
        self.biome_detector_thread = None
        self.biome_detector = BiomeDetector(self.biome_detector_running)
        
        self.image_dir = "images/Game_UI"
        self.original_resolution = (1920, 1080)
        
        #~ Predefined game menu
        self.aura_storage_coords = (40, 373) 
        self.search_bar_coords = (808, 359) 
        self.aura_slot_coords = (818, 423)
        self.equip_button_coords = (565, 644)
        
        self.collection_button_coords = (40, 430)
        self.equip_tab_coords = {
            "special": (1200, 327),
            "regular": (914, 332)
        }
        
        #~ Predefined game menu
        
        # Sub-paths replay
        self.record_path_instance = RecordPath(running_event=self.running)
        self.subpaths_count = 8  # Total number of subpaths
        self.paths_per_subpath = 5  # Number of paths within each subpath
        
        # obby path stuff
        self.last_obby_run = time.time() - 240
        self.obby_cooldown = 240  # 4 minutes cd
        
        # Item scheduler tracking
        self.item_last_used = {}
        
        # quest claim cooldown
        self.last_quest_claim = time.time() - 1800
        self.quest_cooldown = 1800
    
    def get_subpath_json(self, subpath_index, small_path_num):
        sub_path_folder = os.path.join(self.BASE_PATH, "EON1_New", f"EON1_SubPath{subpath_index}")
        json_filename = f"path_{small_path_num}_record.json"
        json_path = os.path.join(sub_path_folder, json_filename)

        if not os.path.exists(json_path):
            json_path = self.find_file(json_filename, self.BASE_PATH)
            if not json_path:
                raise FileNotFoundError(f"Macro subpath not found: {json_filename} in {self.BASE_PATH}")
            
        return json_path
    
    def find_file(self, filename, search_folder=None):
        if not search_folder:
            search_folder = os.getcwd()

        for root, _, files in os.walk(search_folder):
            if filename in files:
                return os.path.join(root, filename)

        return None

    def macro_click(self, x, y):
        ahk.mouse_move(x, y)
        ahk.click(x, y, button="left", coord_mode="Screen")
        time.sleep(0.35)
    

    def send_webhook_status(self, status, color=None, inv_screenshots=False):
        try:
            with open("config.json", "r") as config_file:
                config = json.load(config_file)

            if config.get("Webhook_Enabled", 0) != 1:
                return

            webhook_url = config.get("WebhookLink")
            if not webhook_url:
                print("Webhook URL not configured.")
                return

            # Default embed color
            default_color = 3066993 if "started" in status.lower() else 15158332
            embed_color = color if color is not None else default_color
            screenshot_path = "images/macro_inv_ss.png"
            os.makedirs("images", exist_ok=True)


            if inv_screenshots:
                try:
                    roblox_window = None
                    for window in gw.getAllTitles():
                        if "Roblox" in window:
                            roblox_window = gw.getWindowsWithTitle(window)[0]
                            break

                    if not roblox_window: return
                    roblox_left, roblox_top = roblox_window.left, roblox_window.top
                    roblox_width, roblox_height = roblox_window.width, roblox_window.height

                    coords_mapping = {
                        "Aura Storage": [
                            config.get("aura_storage_coords", [0, 0]),
                            config.get("equip_tab_normal", [0, 0])
                        ],
                        "Item Inventory": [
                            config.get("inv_menu_coords", [0, 0]),
                            config.get("inv_itemtab_button_coords", [0, 0])
                        ],
                        "Quest Menu": [
                            config.get("quest_menu_coords", [0, 0]),
                            config.get("quest_dailytab_coords", [0, 0])
                        ],
                    }

                    for title, coord_list in coords_mapping.items():
                        try:
                            if not self.running.is_set(): return
                            
                            # first coordinate
                            primary_coords = coord_list[0]
                            self.macro_click(*primary_coords)

                            # second coordinate
                            if len(coord_list) > 1:
                                secondary_coords = coord_list[1]
                                self.macro_click(*secondary_coords)
                                time.sleep(0.25)


                            screenshot = pyautogui.screenshot()
                            cropped_screenshot = screenshot.crop((
                                roblox_left,
                                roblox_top + 25,
                                roblox_left + (roblox_width - 50),
                                roblox_top + (roblox_height - 50)
                            ))
                            
                            cropped_screenshot.save(screenshot_path)

                            embeds = [{
                                "title": f"{title}",
                                "description": f"**[{time.strftime('%H:%M:%S')}] {status}**",
                                "color": embed_color,
                                "footer": {
                                    "text": "Improvement Sol's",
                                },
                                "image": {"url": f"attachment://{os.path.basename(screenshot_path)}"}
                            }]


                            with open(screenshot_path, "rb") as image_file:
                                files = {"file": (os.path.basename(screenshot_path), image_file, "image/png")}
                                response = requests.post(
                                    webhook_url,
                                    data={"payload_json": json.dumps({"embeds": embeds})},
                                    files=files
                                )
                                response.raise_for_status()
                                print(f"Webhook sent successfully for {title}: {response.status_code}")

                        except Exception as e:
                            print(f"Error capturing or sending screenshot for {title}: {e}")

                except Exception as e:
                    print(f"Error capturing or sending inventory screenshots: {e}")
                    return

            else:
                # basic status update
                embeds = [{
                    "title": "Macro Status",
                    "description": f"**[{time.strftime('%H:%M:%S')}] {status}**",
                    "color": embed_color,
                    "footer": {
                        "text": "Improvement Sol's",
                    }
                }]
                response = requests.post(
                    webhook_url,
                    data={"payload_json": json.dumps({"embeds": embeds})}
                )
                response.raise_for_status()

        except requests.exceptions.RequestException as e:
            print(f"Failed to send webhook: {e}")
        except Exception as e:
            print(f"An error occurred in send_webhook_status: {e}")
    

    def send_merchant_webhook(self, merchant_name, screenshot_path):
        with open("config.json", "r") as config_file:
            config = json.load(config_file)

        merchant_webhooks = config.get("Merchant_Webhook", [])
        
        merchant_thumbnails = {
            "Mari": "https://static.wikia.nocookie.net/sol-rng/images/d/df/Mari_cropped.png/revision/latest?cb=20241015111527",
            "Jester": "https://static.wikia.nocookie.net/sol-rng/images/d/db/Headshot_of_Jester.png/revision/latest?cb=20240630142936"
        }
        
        if not merchant_webhooks:
            print("No webhooks configured.")
            return

        def send_webhook(webhook):
            webhook_url = webhook.get("url")
            if not webhook_url:
                print("No webhook URL found for an entry.")
                return

            # Determine the ping based on the merchant name
            ping_id = webhook.get(f"{merchant_name.lower()}_ping", "")
            content = f"<@{ping_id}>" if ping_id else ""
            ps_link = webhook.get("ps_link", "No PS link available (or this person doesn't include their PS link in the config)")

            embeds = [{
                "title": f"{merchant_name} Detected!",
                "description": f"{merchant_name} has been detected on your screen.\n**Item screenshot**\n \nMerchant PS Link: {ps_link}",
                "color": 11753 if merchant_name == "Mari" else 8595632,
                "image": {"url": f"attachment://{os.path.basename(screenshot_path)}"},
                "thumbnail": {"url": merchant_thumbnails.get(merchant_name, "")}
            }]

            with open(screenshot_path, "rb") as image_file:
                files = {"file": (os.path.basename(screenshot_path), image_file, "image/png")}
                response = requests.post(
                    webhook_url,
                    data={
                        "payload_json": json.dumps({
                            "content": content,
                            "embeds": embeds
                        })
                    },
                    files=files
                )
                response.raise_for_status()
                print(f"Webhook sent successfully for {merchant_name} to {webhook['alias']}: {response.status_code}")

        # send webhooks in threads (yes, I know)
        with concurrent.futures.ThreadPoolExecutor() as executor:
            executor.map(send_webhook, merchant_webhooks)
    
    def ahk_scroll_up(self, lines=15):
        ahk.run_script(f"""
            Loop {lines} {{
                Send, {{WheelUp}}
                Sleep, 10
            }}
        """)
        

    def ahk_scroll_down(self, lines=15):
        ahk.run_script(f"""
            Loop {lines} {{
                Send, {{WheelDown}}
                Sleep, 10
            }}
        """)
        
    def ahk_hold_left_click(self, posX, posY, holdTime=3300):
        ahk.run_script(f"""
            MouseMove, {posX}, {posY}
            Sleep, 250

            if !GetKeyState("LButton", "P")
            {{
                Click Down
            }}

            totalSleepTime := 0
            interval := 50
            while (totalSleepTime < {holdTime}) {{
                Sleep, %interval%
                totalSleepTime += interval
                if !GetKeyState("LButton", "P") 
                {{
                    Click Down
                }}
            }}

            Click Up
        """)
    
    def check_obby_path(self):
        try:
            with open("config.json", "r") as config_file:
                config = json.load(config_file)

            if config.get("DoObby") == 1:
                current_time = time.time()

                if current_time - self.last_obby_run >= self.obby_cooldown:
                    obby_json_path = self.find_file("obby_path_record.json", self.BASE_PATH)
                    
                    if obby_json_path:
                        print("Starting obby path...")
                        ahk.send_input("{Esc}")
                        time.sleep(0.4)
                        ahk.send_input("r")
                        time.sleep(0.4)
                        ahk.send_input("{Enter}")
                        time.sleep(0.5)
                        
                        self.record_path_instance.load_recording(obby_json_path)
                        self.record_path_instance.replay_actions()
                        
                        ahk.send_input("{Esc}")
                        time.sleep(0.4)
                        ahk.send_input("r")
                        time.sleep(0.4)
                        ahk.send_input("{Enter}")
                        time.sleep(0.5)
                        
                        self.last_obby_run = current_time
                    else:
                        print("Obby path 'obby_path_record.json' not found. Ensure it's placed under MAIN_PATHS folder")
                        
        except FileNotFoundError:
            print("Error: config.json file not found.")
        except Exception as e:
            print(f"An unexpected error occurred in 'check_obby_path': {e}")

    def potion_crafting_loop(self):
        try:
            with open("config.json", "r") as config_file:
                config = json.load(config_file)

            if not config.get("AutomaticPotionCrafting", False): return

            crafting_slots = [f"CraftingSlot{i}" for i in range(1, 7)]  # Slots 1 to 6
            craft_interval = config.get("CraftInterval", 10) * 60
            current_time = time.time()

            if not hasattr(self, "slot_craft_timestamps"):
                self.slot_craft_timestamps = {slot: 0 for slot in crafting_slots}

            # Find and load the potion path
            potion_json_path = self.find_file("potion_path_record.json", self.BASE_PATH)
            if not potion_json_path: return

            if self.running.is_set():
                print("Starting potion path...")
                
                ahk.send_input("{Esc}")
                time.sleep(0.4)
                ahk.send_input("r")
                time.sleep(0.4)
                ahk.send_input("{Enter}")
                time.sleep(0.5)
                
                self.record_path_instance.load_recording(potion_json_path)
                self.record_path_instance.replay_actions()

            for slot_key in crafting_slots:
                if not self.running.is_set(): return

                last_craft_time = self.slot_craft_timestamps.get(slot_key, 0)
                potion_name = config.get(slot_key, "None")

                # Check if the slot has a valid potion and if it's time to craft
                if potion_name and potion_name != "None":
                    if current_time - last_craft_time >= craft_interval:
                        print(f"Starting crafting for {slot_key} - {potion_name}...")

                        try:
                            print("Opening potion crafting menu...")
                            ahk.send_input("F") 
                            time.sleep(1)

                            self.craft_potions(config, slot_key)
                            self.slot_craft_timestamps[slot_key] = time.time()

                        except Exception as e:
                            print(f"Error crafting {slot_key}: {e}")

                        print(f"Waiting for {craft_interval / 60} minutes before crafting the next potion...")
                        return

            print("Potion crafting loop completed for this cycle.")

        except FileNotFoundError:
            print("Error: config.json file not found.")
        except KeyError as e:
            print(f"Configuration error: Missing key {e}.")
        except Exception as e:
            print(f"An unexpected error occurred: {e}")

            
    
    def craft_potions(self, config, slot_key):
        potion_name = config.get(slot_key, "None")

        #! Retrieve the total amount slot from this map #
        
        ingredient_map = {
            "Fortune Potion I": {
                "Lucky Potion": [1, 5, 10], 
                "Uncommon": [1],
                "Rare": [1, 3, 5, 10],
                "Gilded": [1, 3],
            },
            "Fortune Potion II": {
                "Fortune Potion I": [1],
                "Lucky Potion": [1, 5, 10],
                "Uncommon": [1, 3, 5],
                "Rare": [1, 5, 15],
                "Gilded": [1, 5],
            },
            "Fortune Potion III": {
                "Fortune Potion II": [1],
                "Lucky Potion": [1, 5, 15],
                "Uncommon": [3, 5, 10],
                "Rare": [3, 5, 10, 15],
                "Gilded": [1, 3, 5],
            },
            
            "Haste Potion I": {
                "Speed Potion": [1, 5, 10],
                "Uncommon": [1, 3, 5],
                "Rare": [3, 5, 10],
                "Wind": [1],
            },
            "Haste Potion II": {
                "Haste Potion I": [1],
                "Speed Potion": [5, 7, 10],
                "Uncommon": [3, 5, 10],
                "Rare": [3, 5, 10],
                "Wind": [1, 2],
            },
            
            "Haste Potion III": {
                "Haste Potion II": [1],
                "Speed Potion": [3, 5, 15, 20],
                "Uncommon": [5, 10, 15],
                "Rare": [5, 10, 15, 25],
                "Wind": [1, 2, 4],
            },
            
            "Heavenly Potion I": {
                "Lucky Potion": [15, 40, 80, 100],
                "Divinus": [5, 10, 25, 40, 50],
                "Gilded": [1, 5, 15, 20],
                "Celestial": [1],
            },
            "Heavenly Potion II": {
                "Heavenly Potion I": [1, 2],
                "Lucky Potion": [25, 65, 85, 125],
                "Divinus": [15, 25, 45, 75],
                "Gilded": [5, 15, 25, 50],
                "Exotic": [1],
            },
            
            "Warp Potion": {
                "Arcane": [1],
                "Comet": [1, 2, 5],
                "Permafrost": [1, 3, 7],
                "Powered": [5, 15, 35, 75, 100],
                "Lunar": [5, 15, 35, 125, 200],
                "Speed Potion": [250, 450, 750, 1000],
            },
        }

        if potion_name and potion_name != "None":
            print(f"Crafting potion: {potion_name} (Slot: {slot_key})")

            # Search for the potion
            if not self.running.is_set(): return
            search_coords = config["potion_sbar_coords"]
            ahk.click(*search_coords, button="left", coord_mode="Screen")

            time.sleep(0.2)
            ahk.send_input("")
            time.sleep(0.1)
            ahk.send("{DELETE}")
            time.sleep(0.1)
            ahk.send(potion_name)
            time.sleep(0.5)

            # Scroll to potion
            if not self.running.is_set(): return
            scroll_coords = config["potion_firstpotion_coords"]
            ahk.mouse_move(*scroll_coords)
            self.ahk_scroll_up(10)
            time.sleep(0.5)

            # Select first potion
            if not self.running.is_set(): return
            first_potion_coords = config["potion_firstpotion_coords"]
            ahk.click(*first_potion_coords)
            time.sleep(0.5)

            # Click craft and auto button
            if not self.running.is_set(): return
            craft_button_coords = config["potion_craft_coords"]
            ahk.click(*craft_button_coords)
            time.sleep(0.5)
            ahk.click(*config["potion_autobutton_coords"])
            time.sleep(0.5)

            # Scroll to manual ingredient boxes
            manual_scroll_coords = config["potion_1manualbox_coords"]
            ahk.mouse_move(*manual_scroll_coords)
            time.sleep(0.5)
            self.ahk_scroll_up(7)
            time.sleep(0.5)

            # Add ingredients manually
            ingredients = ingredient_map.get(potion_name, {})
            manual_box_coords = [
                config["potion_1manualbox_coords"],
                config["potion_2manualbox_coords"],
                config["potion_3manualbox_coords"],
                config["potion_4manualbox_coords"],
                config["potion_5manualbox_coords"],
                config["potion_6manualbox_coords"],
            ]
            manual_add_coords = [(coords[0] + 65, coords[1] + 5) for coords in manual_box_coords]

            for i, (ingredient, amounts) in enumerate(ingredients.items()):
                if not self.running.is_set(): return

                if i >= 3:
                    print(f"Scrolling down for slot {i + 1}...")
                    ahk.mouse_move(*manual_box_coords[i])
                    time.sleep(0.2)
                    self.ahk_scroll_down(7)
                    time.sleep(0.5)

                print(f"Adding ingredients for {ingredient}...")
                for amount in amounts:
                    if not self.running.is_set(): return

                    # Enter manual amount
                    ahk.click(*manual_box_coords[i])
                    time.sleep(0.2)
                    ahk.send("^a")
                    time.sleep(0.1)
                    ahk.send("{DELETE}")
                    time.sleep(0.1)
                    ahk.send(str(amount))
                    time.sleep(0.2)

                    # Click "Add" button
                    ahk.click(*manual_add_coords[i])
                    time.sleep(0.4)
                    print(f"Added {amount} to {ingredient}.")

            print(f"Finished crafting: {potion_name}")


                    
    def use_item_scheduler(self):
        with open("config.json", "r") as config_file:
            config = json.load(config_file)

        current_time = time.time()
        item_scheduler = config.get("item_scheduler", [])
        current_biome = self.biome_detector.current_biome
        enable_auto_merchant = config.get("EnableAutoMerchant", 0)

        for entry in item_scheduler:
            if not self.running.is_set(): return
            
            item_name = entry["item"]
            quantity = entry["quantity"]
            frequency = entry["frequency"]
            frequency_unit = entry["frequency_unit"].lower()
            biome = entry["biome"]

            if frequency_unit == "seconds":
                cooldown = frequency
            elif frequency_unit == "minutes":
                cooldown = frequency * 60
            elif frequency_unit == "hours":
                cooldown = frequency * 3600
            else:
                print(f"Unknown frequency unit '{frequency_unit}' for item '{item_name}'")
                continue

            # Check cooldown
            last_used_time = self.item_last_used.get(item_name, 0)
            if current_time - last_used_time < cooldown:
                continue

            # Check biome condition
            if biome.lower() != "any" and biome != current_biome:
                #print(f"Skipping item '{item_name}': Current biome '{current_biome}' does not match required biome '{biome}'")
                continue

            # Use item
            print(f"Using item '{item_name}' in biome '{biome}' with quantity {quantity}")
            self.Inventory(item_name, quantity)
            self.item_last_used[item_name] = current_time

            if not self.running.is_set(): return
            
            # Auto Merchant
            if item_name == "Merchant Teleport" and enable_auto_merchant == 1:
                self.Merchant_Handler()


    def Merchant_Handler(self):
        with open("config.json", "r") as config_file:
            config = json.load(config_file)

        merchant_name_ocr_pos = config["merchant_name_ocr_pos"]
        merchant_open_button = config["merchant_open_button"]
        first_item_slot_pos = config["first_item_slot_pos"]
        item_name_ocr_pos = config["item_name_ocr_pos"]
        merchant_dialogue_box = config["merchant_dialogue_box"]
        
        merchant_name = ""
        
        
        if not hasattr(self, 'last_merchant_interaction'):
            self.last_merchant_interaction = 0
            
        merchant_cooldown_time = 180
        current_time = time.time()
        
        if current_time - self.last_merchant_interaction < merchant_cooldown_time:
            return
        
        for _ in range(4):
            ahk.send_input("e")
            time.sleep(0.3)
            
        self.ahk_hold_left_click(merchant_dialogue_box[0], merchant_dialogue_box[1], holdTime=2500)
            
        for _ in range(5):
            if not self.running.is_set(): return
            
            x, y, w, h = merchant_name_ocr_pos
            screenshot = pyautogui.screenshot(region=(x, y, w, h))
            merchant_name_text = pytesseract.image_to_string(screenshot)
            
            #print(merchant_name_text)
            
            # merchant debugging
            # debug_screenshot_path = f"debug_merchant.png"
            # screenshot.save(debug_screenshot_path)
            
            if any(name in merchant_name_text for name in ["Mori", "Marl", "Mar1", "MarI", "Mar!", "Maori"]):
                merchant_name = "Mari"
                print("[Merchant Detection]: Mari name found!")
                break
            elif "Jester" in merchant_name_text:
                merchant_name = "Jester"
                print("[Merchant Detection]: Jester name found!")
                break

            time.sleep(0.35)


        if merchant_name:
            print(f"Opening merchant interface for {merchant_name}")
            
            x, y = merchant_open_button
            ahk.click(x, y, button="left", coord_mode="Screen", click_count=3)
            time.sleep(0.73)

            # Take a screenshot for the webhook
            item_screenshot = pyautogui.screenshot()
            screenshot_path = f"images/merchant_screenshot.png"
            item_screenshot.save(screenshot_path)
            
            self.send_merchant_webhook(merchant_name, screenshot_path)

            auto_buy_items = config.get(f"{merchant_name}_AutoBuyItems", {})
            if not auto_buy_items:
                return

            purchased_items = set()

            # Loop through item slots
            for slot_index in range(5):
                if not self.running.is_set(): return
                
                x, y = first_item_slot_pos
                slot_x = x + (slot_index * 185)
                ahk.click(slot_x, y, button="left", coord_mode="Screen", click_count=2)
                time.sleep(0.35)

                # OCR - item name
                x, y, w, h = item_name_ocr_pos
                screenshot = pyautogui.screenshot(region=(x, y, w, h))
                item_text = pytesseract.image_to_string(screenshot, config='--psm 6').strip().lower()
                normalized_item_text = item_text.replace("1", "i").replace("2", "ii").replace("3", "iii").replace("|", "i").strip()

                # mari "geor" -> "gear" (gear a/b typo)
                if "geor" in normalized_item_text:
                    normalized_item_text = normalized_item_text.replace("geor", "gear")

                print(f"OCR result: {item_text}, Normalized: {normalized_item_text}")

                # Regex search
                for item_name, quantity in auto_buy_items.items():
                    normalized_item_name = item_name.lower().replace("1", "i").replace("2", "ii").replace("3", "iii").strip()
                    print(f"Normalized item name: {normalized_item_name}")
                    
                    if re.search(r'\b' + re.escape(normalized_item_name) + r'\b', normalized_item_text) and item_name not in purchased_items:
                        print(f"Item '{item_name}' found. Proceeding to buy {quantity}.")
                        
                        purchase_amount_button = config["purchase_amount_button"]
                        purchase_button = config["purchase_button"]

                        ahk.click(*purchase_amount_button, button="left", coord_mode="Screen")
                        ahk.send_input(str(quantity))
                        time.sleep(0.25)

                        ahk.click(*purchase_button, button="left", coord_mode="Screen")
                        time.sleep(0.75)
                        self.ahk_hold_left_click(merchant_dialogue_box[0], merchant_dialogue_box[1], holdTime=2130)

                        purchased_items.add(item_name)
                        break
                    
            # Update last merchant autobuy
            self.last_merchant_interaction = current_time
        else:
            print("No merchant detected.")

    def start_loop(self):
        if not self.running.is_set():
            print("Starting macro loop...")
            self.send_webhook_status("Macro started", color=0x64ff5e, inv_screenshots=False)
            self.running.set()
            self.thread = threading.Thread(target=self.loop_process)
            self.thread.start()

            # if not self.aura_detector_running.is_set():
            #     self.aura_detector_running.set()
            #     self.aura_detector_thread = threading.Thread(target=self.run_aura_detector)
            #     self.aura_detector_thread.start()
                
            if not self.biome_detector_running.is_set():
                self.biome_detector_running.set()
                self.biome_detector_thread = threading.Thread(target=self.run_biome_detector)
                self.biome_detector_thread.start()

    def stop_loop(self):
        if self.running.is_set():
            print("Stopping macro loop...")
            self.send_webhook_status("Macro stopped", color=0xff0000, inv_screenshots=False)
            self.running.clear()
            if self.thread is not None:
                self.thread.join(timeout=2) 
                self.thread = None
                

        # if self.aura_detector_running.is_set():
        #     print("Stopping aura detector...")
        #     self.aura_detector_running.clear()
        #     if self.aura_detector_thread is not None:
        #         self.aura_detector_thread.join(timeout=2)
        #         self.aura_detector_thread = None
                
        if self.biome_detector_running.is_set():
            print("Stopping biome detector...")
            self.biome_detector_running.clear()
            if self.biome_detector_thread is not None:
                self.biome_detector_thread.join(timeout=2)
                self.biome_detector_thread = None
                

    def get_roblox_window_resolution(self):
        roblox_window = None
        for window in gw.getAllTitles():
            if "Roblox" in window:
                roblox_window = gw.getWindowsWithTitle(window)[0]
                break

        if roblox_window:
            if win32gui.IsIconic(roblox_window._hWnd):
                win32gui.ShowWindow(roblox_window._hWnd, win32con.SW_RESTORE)
            
            
            win32gui.SetForegroundWindow(roblox_window._hWnd)

            left, top, right, bottom = win32gui.GetWindowRect(roblox_window._hWnd)
            window_width = right - left
            window_height = bottom - top
            return window_width, window_height
        else:
            print("Roblox window not found. Make sure the game is running and visible.")
            return self.original_resolution


    def get_scaled_coordinates(self, original_x, original_y):
        current_width, current_height = self.get_roblox_window_resolution()
        original_width, original_height = self.original_resolution
        x_scale = current_width / original_width
        y_scale = current_height / original_height
        return int(original_x * x_scale), int(original_y * y_scale)

    
    def equipAura(self, aura_name="Glock"):
        with open("config.json", "r") as config_file:
            config = json.load(config_file)

        aura_storage_coords = config.get("aura_storage_coords", [0, 0])
        search_bar_coords = config.get("search_bar_coords", [0, 0])
        equip_tab_coords = {
            "regular": config.get("equip_tab_normal", [0, 0]),
            "special": config.get("equip_tab_special", [0, 0])
        }
        first_aura_coords = config.get("first_aura_coords", [0, 0])
        
        if not config.get("Enabled_AutoEquip", 0): return

        # Set aura and tab preference
        equipped_aura = config.get("Equipped_Aura", aura_name)
        is_special_aura = config.get("Special_Aura", 0) == 1

        # Click the aura storage button
        ahk.mouse_move(aura_storage_coords[0], aura_storage_coords[1])
        time.sleep(0.45)
        ahk.click()
        time.sleep(0.55)

        # Select the appropriate aura tab (special or regular)
        tab_x, tab_y = equip_tab_coords["special" if is_special_aura else "regular"]
        ahk.click(tab_x, tab_y, coord_mode="Screen")
        time.sleep(0.55)

        # Click on the search bar and type the aura name
        ahk.click(search_bar_coords[0], search_bar_coords[1], coord_mode="Screen")
        time.sleep(0.55)
        print(f"Typing aura name: {equipped_aura}")
        ahk.send_input(equipped_aura)
        time.sleep(0.3)


        # Click the first aura slot
        ahk.mouse_move(first_aura_coords[0], first_aura_coords[1])
        self.ahk_scroll_up(lines=15)
        ahk.click()
        time.sleep(0.55)

        # Equip the aura
        equip_button_coords = config.get("equip_button_coords", [0, 0])
        ahk.click(equip_button_coords[0], equip_button_coords[1], coord_mode="Screen")
        time.sleep(0.5)

        # Clear the search bar
        ahk.click(search_bar_coords[0], search_bar_coords[1], coord_mode="Screen", click_count=2)
        time.sleep(0.2)

        # close aura storage
        ahk.click(aura_storage_coords[0], aura_storage_coords[1], coord_mode="Screen")

    def collection_align(self):
        with open("config.json", "r") as config_file:
            config = json.load(config_file)

        collection_button_coords = config.get("collection_button_coords", [0, 0])
        collection_back_button_coords = config.get("collection_back_button_coords", [0, 0])
        
        ahk.mouse_move(collection_button_coords[0], collection_button_coords[1])
        time.sleep(0.12)
        ahk.click()
        time.sleep(0.5)
        
        ahk.click(collection_back_button_coords[0], collection_back_button_coords[1], button="left", coord_mode="Screen")
        
        time.sleep(0.75)
        ahk.mouse_drag(collection_back_button_coords[0], collection_back_button_coords[1] + 50, button="right", coord_mode="Screen")

    def align_and_initialize(self):
        self.equipAura()           # Equip aura
        if not self.running.is_set(): return
        self.collection_align()     # Align collection
        time.sleep(2.3) # wait a moment before proceed the macro loop
          
        
    def Inventory(self, item_name="Strange Controller", amount=1):
        with open("config.json", "r") as config_file:
            config = json.load(config_file)

        self.inv_menu_coords = config.get("inv_menu_coords", [0, 0])
        self.inv_item_tab_coords = config.get("inv_itemtab_button_coords", [0, 0])
        self.inv_searchbar = config.get("inv_sbar_button_coords", [0, 0])
        self.inv_firstitem_coords = config.get("inv_firstitem_coords", [0, 0])
        self.inv_amountbox_coords = config.get("inv_amountbox_coords", [0, 0])
        self.inv_use_button_coords = config.get("inv_use_button_coords", [0, 0])

        ahk.click(self.inv_menu_coords[0], self.inv_menu_coords[1], button="left", coord_mode="Screen")
        time.sleep(0.35)

        ahk.click(self.inv_item_tab_coords[0], self.inv_item_tab_coords[1], button="left", coord_mode="Screen")
        time.sleep(0.35)

        ahk.click(self.inv_searchbar[0], self.inv_searchbar[1], button="left", coord_mode="Screen")
        time.sleep(0.35)

        ahk.send_input(item_name)
        time.sleep(0.35)
        
        ahk.click(self.inv_firstitem_coords[0], self.inv_firstitem_coords[1], button="left", coord_mode="Screen")
        time.sleep(0.35)

        ahk.click(self.inv_amountbox_coords[0], self.inv_amountbox_coords[1], button="left", coord_mode="Screen")
        time.sleep(0.35)

        # ctrl + a
        ahk.send_input("^a")
        time.sleep(0.25)
        ahk.send_input("{BACKSPACE}")
        time.sleep(0.3)

        ahk.send_input(str(amount))
        time.sleep(0.35)

        ahk.click(self.inv_use_button_coords[0], self.inv_use_button_coords[1], button="left", coord_mode="Screen")
        time.sleep(0.35)
        
        ahk.click(self.inv_searchbar[0], self.inv_searchbar[1], button="left", coord_mode="Screen")
        time.sleep(0.35)

        # Close the inv menu
        ahk.click(self.inv_menu_coords[0], self.inv_menu_coords[1], button="left", coord_mode="Screen")
        time.sleep(0.2)
    
    def Quest(self):
        with open("config.json", "r") as config_file:
            config = json.load(config_file)

        quest_menu_coords = config.get("quest_menu_coords", [0, 0])
        quest_dailytab_coords = config.get("quest_dailytab_coords", [0, 0])
        quest_firstquest_coords = config.get("quest_firstquest_coords", [0, 0])
        quest_claim_button_coords = config.get("quest_claim_button_coords", [0, 0])
        
        if config.get("AutoClaimDailyQuests"):
            current_time = time.time()

            if current_time - self.last_quest_claim >= self.quest_cooldown:
                ahk.click(quest_menu_coords[0], quest_menu_coords[1], button="left", coord_mode="Screen")
                time.sleep(0.35)

                ahk.click(quest_dailytab_coords[0], quest_dailytab_coords[1], button="left", coord_mode="Screen")
                time.sleep(0.35)

                ahk.click(quest_firstquest_coords[0], quest_firstquest_coords[1], button="left", coord_mode="Screen")
                time.sleep(0.35)

                ahk.click(quest_claim_button_coords[0], quest_claim_button_coords[1], button="left", coord_mode="Screen")
                time.sleep(0.35)

                second_quest_coords = (quest_firstquest_coords[0], quest_firstquest_coords[1] + 80)
                ahk.click(second_quest_coords[0], second_quest_coords[1], button="left", coord_mode="Screen")
                time.sleep(0.35)

                ahk.click(quest_claim_button_coords[0], quest_claim_button_coords[1], button="left", coord_mode="Screen")
                time.sleep(0.35)

                third_quest_coords = (quest_firstquest_coords[0], quest_firstquest_coords[1] + 140)
                ahk.click(third_quest_coords[0], third_quest_coords[1], button="left", coord_mode="Screen")
                time.sleep(0.35)

                ahk.click(quest_claim_button_coords[0], quest_claim_button_coords[1], button="left", coord_mode="Screen")
                time.sleep(0.35)
                
                self.last_quest_claim = current_time


    def schedule_one_time_stats_update(self):
        self.one_time_stats_update = True
    
        
    def macro_periodical_screenshot(self):
        try:
            with open("config.json", "r") as config_file:
                config = json.load(config_file)

            if not config.get("WebhookInventory", False):
                return

            webhook_interval = config.get("WebhookInventoryInterval", 5) * 60
            current_time = time.time()

            if not hasattr(self, 'last_inventory_webhook_time'):
                self.last_inventory_webhook_time = current_time - webhook_interval

            if self.one_time_stats_update or (current_time - self.last_inventory_webhook_time >= webhook_interval):
                try:
                    self.send_webhook_status(
                        status="Inventory Status",
                        color=3106929,
                        inv_screenshots=True
                    )
                    self.last_inventory_webhook_time = current_time
                    self.one_time_stats_update = False
                except Exception as e:
                    print(f"Failed to send inventory status: {e}")

        except FileNotFoundError:
            print("Error: config.json file not found.")


            
    def loop_process(self):
        with open("config.json", "r") as config_file:
            config = json.load(config_file)

        collect_items_enabled = config.get("CollectItems", 0) == 1

        enabled_subpaths = [
            index + 1 for index, is_enabled in enumerate(config["Sub_ItemSpot"]) if is_enabled == 1
        ]

        ## ~ALIGNMENT ##
        self.get_roblox_window_resolution()
        time.sleep(1.5)
        self.align_and_initialize()
        ## ~ALIGNMENT ##

        while self.running.is_set():
            self.macro_periodical_screenshot()
            self.Quest()
            self.use_item_scheduler()
            self.check_obby_path()
            self.potion_crafting_loop()

            if collect_items_enabled:
                for subpath_index in enabled_subpaths:
                    if not self.running.is_set():
                        return

                    for small_path_num in range(1, self.paths_per_subpath + 1):
                        if not self.running.is_set():
                            return
                        try:
                            json_path = self.get_subpath_json(subpath_index, small_path_num)
                            
                            self.record_path_instance.running_event = self.running
                            self.record_path_instance.load_recording(json_path)
                            self.record_path_instance.replay_actions()
                            
                        except FileNotFoundError as e:
                            continue
                        
                        # reset
                        ahk.send_input("{Esc}")
                        time.sleep(0.3)
                        ahk.send_input("r")
                        time.sleep(0.3)
                        ahk.send_input("{Enter}")
                        time.sleep(0.5)

                        # if macro loop was stopped externally (like user pressed f3 or close it)
                        if not self.running.is_set():
                            return
                          

    # def run_aura_detector(self):
    #     while self.aura_detector_running.is_set():
    #         self.aura_detector.run()
            
    def run_biome_detector(self):
        while self.biome_detector_running.is_set():
            self.biome_detector.run()