import time, cv2, pyautogui, pytesseract, json, os, re, requests, threading
import numpy as np
from difflib import SequenceMatcher
from PIL import Image, ImageEnhance

class BiomeDetector:
    def __init__(self, biome_detector_running, config_path="config.json"):
        self.set_tesseract_path()
        self.biome_detector_running = biome_detector_running
        self.config = self.load_config(config_path)
        self.detection_area = tuple(self.config.get("Biome_Region", (8,865,190,27)))
        self.current_biome = None
        self.last_detection_time = {}
        self.glitch_compare_ratio = 0.75  # 75% glitch similarity
        self.last_detected_text = None
        self.biome_keywords = {
            "Windy": r"Windy|winoy|WINDY",
            "Rainy": r"Rainy|ramy|rain|rany|RAINY",
            "Snowy": r"Snowy|snoy|snwy|snovy|SNOWY",
            "Sandstorm": r"Sandstorm|sandst|storm|sndstorm|SAND STORM|SAND|STORM",
            "Hell": r"Hell|hel|heii|HELL",
            "Starfall": r"Starfall|stafall|sarfall|strfall|STARFALL",
            "Corruption": r"Corruption|corupt|corrupton|corrup|CORRUPTION",
            "Null": r"Null|nul|nui|nll|NULL",
            "Glitched": r"\b\d\.\d{8,}\b"
        }
        
        self.biome_data = {
            "Windy": {"color": 0x9ae5ff, "duration": 120},
            "Rainy": {"color": 0x027cbd, "duration": 120},
            "Snowy": {"color": 0xDceff9, "duration": 120},
            "Sandstorm": {"color": 0x8F7057, "duration": 600},
            "Hell": {"color": 0xff4719, "duration": 660},
            "Starfall": {"color": 0x011ab7, "duration": 600},
            "Corruption": {"color": 0x6d32a8, "duration": 660},
            "Null": {"color": 0x838383, "duration": 90},
            "Glitched": {"color": 0xbfff00, "duration": 164}
        }

        # template for Glitched biome
        # self.glitched_template = cv2.imread("images/Game_UI/glitched_biome_template.png", cv2.IMREAD_GRAYSCALE)
        # self.match_threshold = 0.72  
        
        os.makedirs("images", exist_ok=True)

    def set_tesseract_path(self):
        common_paths = [
            r"C:\\Program Files\\Tesseract-OCR\\tesseract.exe",
            r"C:\\Program Files (x86)\\Tesseract-OCR\\tesseract.exe"
        ]
        for path in common_paths:
            if os.path.exists(path):
                pytesseract.pytesseract.tesseract_cmd = path
                #print(f"Set Tesseract path to: {path}")
                return
        print("Tesseract executable not found. Please reinstall Tesseract again or specify the path manually :D")

    def load_config(self, path):
        with open(path, "r") as file:
            return json.load(file)

    def capture_biome_text(self):
        screenshot = pyautogui.screenshot(region=self.detection_area)
        enhancer = ImageEnhance.Contrast(screenshot)
        screenshot = enhancer.enhance(1.65)
        enhancer = ImageEnhance.Brightness(screenshot)
        screenshot = enhancer.enhance(1.05)
        
        # Save the screenshot
        screenshot.save("images/biomefound.png")
        text = pytesseract.image_to_string(screenshot)
        return text.strip()


    def send_webhook(self, biome, message_type):
        webhook_url = self.config.get("WebhookLink", "")
        if not webhook_url:
            print("Webhook URL is missing in the config.")
            return

        biome_color = self.biome_data[biome]["color"]
        timestamp = time.strftime("[%H:%M:%S]") 
        
        # ping if message_type is "Ping"
        content = ""
        if message_type == "Ping":
            user_id = self.config.get("WebhookUserID", "")
            if user_id:
                content = f"<@{user_id}>"
        
        payload = {
            "content": content,
            "embeds": [
                {
                    "title": f"{timestamp} Biome Started",
                    "description": f"Detected Biome: **{biome}**",
                    "color": biome_color,
                    "image": {
                        "url": "attachment://biomefound.png"
                    }
                }
            ]
        }

        with open("images/biomefound.png", "rb") as image_file:
            payload_json = json.dumps(payload)
            files = {
                "file": ("biomefound.png", image_file, "image/png")
            }
            new_payload = {
                "payload_json": payload_json
            }

            try:
                response = requests.post(webhook_url, data=new_payload, files=files)
                response.raise_for_status()
                print(f"Sent {message_type} for {biome}")
            except requests.exceptions.RequestException as e:
                print(f"Failed to send webhook: {e}")

    def detect_biome(self):
        text = self.capture_biome_text()
        print(f"Detected OCR Text: {text}")

        # Extract numerical patterns in x.xxxxxxxx format for Glitched Biome detection
        numbers = re.findall(self.biome_keywords["Glitched"], text)
        #print(f"Extracted Numbers: {numbers}")

        biome = None


        if numbers and self.last_detected_text:
            similarity = SequenceMatcher(None, self.last_detected_text, text).ratio()
            #print(f"Similarity: {similarity}")

            if similarity >= self.glitch_compare_ratio:
                print("Glitched omg omg!!11!")
                biome = "Glitched"
        
        
        self.last_detected_text = text
        
        if not biome:
            for biome_key, keyword in self.biome_keywords.items():
                if re.search(keyword, text, re.IGNORECASE):
                    biome = biome_key
                    break

        # Proceed with biome detection and notifications
        if biome:
            current_time = time.time()
            duration = self.biome_data[biome]["duration"]
            last_detection = self.last_detection_time.get(biome, 0)

            if current_time - last_detection < duration:
                return

            self.last_detection_time[biome] = current_time
            if biome != self.current_biome:
                self.current_biome = biome
                print(f"Detected Biome: {self.current_biome}")

                notifier_key = f"Biome_Notifer_{biome}"
                message_type = self.config.get(notifier_key, "None")
                if message_type in ["Message", "Ping"]:
                    self.send_webhook(biome, message_type)

    def run(self):
        while self.biome_detector_running.is_set():
            self.detect_biome()
            time.sleep(1)

if __name__ == "__main__":
    running_event = threading.Event()
    running_event.set()

    detector = BiomeDetector(biome_detector_running=running_event, config_path="../config.json")
    detector.run()
