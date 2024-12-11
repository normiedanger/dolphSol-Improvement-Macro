import cv2
import numpy as np
import time
import os
from datetime import datetime
from PIL import ImageGrab

class AuraDetector:
    def __init__(self):
        # Define RGB color centers for different auras, categorized by rarity, with color tolerances
        self.auras = {
            "10k+": {
                "Comet": {"color": np.array([190, 210, 255]), "tolerance": 50},
            },
            "1m+": {
                "Poseidon": {"color": np.array([14, 97, 136]), "tolerance": 35},
            },
            "10m+": {
                "Chromatic": {"color": np.array([255, 45, 46]), "tolerance": 30},
                "Ethereal": {"color": np.array([207, 191, 255]), "tolerance": 30},
                "Exotic Apex": {"color": np.array([56, 198, 217]), "tolerance": 45},
            },
            "100m+": {
                "Overture": {"color": np.array([61, 101, 211]), "tolerance": 60},
                "Overture History": {"color": np.array([89, 255, 150]), "tolerance": 60}
            }
        }

        # Load star shape references
        self.star_ref_4_corner = cv2.imread("images/4_corner_star.png", cv2.IMREAD_GRAYSCALE)
        self.star_ref_8_corner = cv2.imread("images/8_corner_star.png", cv2.IMREAD_GRAYSCALE)

        if self.star_ref_4_corner is None or self.star_ref_8_corner is None:
            raise FileNotFoundError("Star reference images not found in 'images' folder.")

        os.makedirs("images", exist_ok=True)
        self.previous_aura_name = None
        self.last_detection_time = 0  # Cooldown timer
        self.ignored_4_corner_count = 0  # Counter for ignored 4-corner detections
        self.max_ignored_threshold = 2  # Threshold for switching to 8-corner detection

    def is_pure_black_background(self, image, bbox):
        x, y, w, h = bbox
        tolerance = 10  # Allow small variation from pure black

        # Sample the four corners inside the bounding box
        corners = [
            image[y, x - 10],  # Top-left
            image[y, x + w - 10],  # Top-right
            image[y + h - 10, x],  # Bottom-left
            image[y + h - 10, x + w - 10]  # Bottom-right
        ]

        # Check if all corners are close to black
        for corner in corners:
            if not np.all(corner < tolerance):  # Non-black pixel found
                return False
        return True

    def detect_star_shape(self, image):
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Perform template matching for both 8-corner and 4-corner stars
        res_8_corner = cv2.matchTemplate(gray, self.star_ref_8_corner, cv2.TM_CCOEFF_NORMED)
        res_4_corner = cv2.matchTemplate(gray, self.star_ref_4_corner, cv2.TM_CCOEFF_NORMED)
        
        threshold_8_corner = 0.75
        threshold_4_corner = 0.75

        loc_8 = np.where(res_8_corner >= threshold_8_corner)
        loc_4 = np.where(res_4_corner >= threshold_4_corner)

        max_confidence_8 = np.max(res_8_corner) if len(loc_8[0]) > 0 else 0
        max_confidence_4 = np.max(res_4_corner) if len(loc_4[0]) > 0 else 0

        # Check if we should skip 4-corner detection due to repeated non-black backgrounds
        if self.ignored_4_corner_count >= self.max_ignored_threshold:
            if max_confidence_8 >= threshold_8_corner:
                for pt in zip(*loc_8[::-1]):
                    return (pt[0], pt[1], self.star_ref_8_corner.shape[1], self.star_ref_8_corner.shape[0]), "8_corners"
            return None, None  # No valid 8-corner star found

        # Proceed with normal detection
        if max_confidence_8 > max_confidence_4 and max_confidence_8 >= threshold_8_corner:
            for pt in zip(*loc_8[::-1]):
                return (pt[0], pt[1], self.star_ref_8_corner.shape[1], self.star_ref_8_corner.shape[0]), "8_corners"
        elif max_confidence_4 >= threshold_4_corner:
            for pt in zip(*loc_4[::-1]):
                bbox = (pt[0], pt[1], self.star_ref_4_corner.shape[1], self.star_ref_4_corner.shape[0])

                # Check for pure black background around the detected 4-corner star
                if self.is_pure_black_background(image, bbox):
                    self.ignored_4_corner_count = 0  # Reset the counter if a valid 4-corner is found
                    return bbox, "4_corners"
                else:
                    self.ignored_4_corner_count += 1  # Increment ignored counter for non-black background
                    
        return None, None

    def adjust_brightness(self, image, factor=1.2):
        hsv_image = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        hsv_image[:, :, 2] = np.clip(hsv_image[:, :, 2] * factor, 0, 255).astype(np.uint8)
        return cv2.cvtColor(hsv_image, cv2.COLOR_HSV2BGR)

    def detect_aura(self, image):
        # Check cooldown
        current_time = time.time()
        if current_time - self.last_detection_time < 15:  # 15s cooldown
            return None

        image_adjusted = self.adjust_brightness(image, factor=1.12)
        star_bbox, star_type = self.detect_star_shape(image_adjusted)
        if star_bbox is None:
            return None

        x, y, w, h = star_bbox
        center_x, center_y = x + w // 2, y + h // 2
        cv2.rectangle(image_adjusted, (x, y), (x + w, y + h), (0, 255, 0), 2)
        debug_image_path = f"images/debug_{star_type}_box.png"
        cv2.imwrite(debug_image_path, image_adjusted)
        print(f"Debug image with green box saved: {debug_image_path}")
        
        screenshot = ImageGrab.grab()
        colors = [
            screenshot.getpixel((center_x + dx, center_y + dy))
            for dx in range(-1, 2) for dy in range(-1, 2)
        ]
        center_color = np.mean(colors, axis=0).astype(int)
        print(f"Detected color RGB at center: {tuple(center_color)}")

        # Convert to HSV for better comparison
        detected_hsv = cv2.cvtColor(np.uint8([[center_color]]), cv2.COLOR_RGB2HSV)[0][0]
        
        # Determine the correct aura group based on the star type
        if star_type == "8_corners":
            aura_group = {**self.auras["1m+"], **self.auras["10m+"], **self.auras["100m+"]}
        else:
            aura_group = self.auras["10k+"]

        best_aura = None
        min_distance = float('inf')

        for aura_name, aura_info in aura_group.items():
            aura_rgb = aura_info["color"]
            tolerance = aura_info["tolerance"]

            # Convert aura RGB to HSV for comparison
            aura_hsv = cv2.cvtColor(np.uint8([[aura_rgb]]), cv2.COLOR_RGB2HSV)[0][0]
            distance = np.linalg.norm(detected_hsv - aura_hsv)
            print(f"{aura_name}: Distance = {distance}, Tolerance = {tolerance}")

            if distance < min_distance and distance < tolerance:
                min_distance = distance
                best_aura = aura_name

        if best_aura:
            if best_aura != self.previous_aura_name:
                self.save_image(image_adjusted, best_aura, star_type)
                self.previous_aura_name = best_aura
                self.last_detection_time = current_time  # Reset cooldown timer
            print(f"Detected Aura: {best_aura}")
        else:
            print("No auras detected.")


    def save_image(self, image, aura_name, star_type):
        filename = f"images/{aura_name}_{star_type}.png"
        cv2.imwrite(filename, image)
        print(f"Saved aura image: {filename}")

    def run(self, interval=1):
        while True:
            screenshot = ImageGrab.grab()
            image = cv2.cvtColor(np.array(screenshot), cv2.COLOR_RGB2BGR)
            self.detect_aura(image)
            time.sleep(interval)

if __name__ == "__main__":
    detector = AuraDetector()
    detector.run()