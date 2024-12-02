import time
import json
import threading
from pynput import mouse, keyboard

class RecordPath:
    def __init__(self, filename="path_record.json", stop_key=keyboard.Key.esc, running_event=None):
        with open('config.json', 'r') as config_file:
            config = json.load(config_file)
        
        self.azerty_keyboard = config.get("AZERTY_Keyboard", False)
        self.filename = filename
        self.actions = []
        self.start_time = None
        self.recording = False
        self.stop_recording_flag = False
        self.stop_replay_flag = False
        self.stop_key = stop_key
        self.running_event = running_event
        self.pressed_keys = set()
        self.pressed_mouse_buttons = set()
        
        self.mouse_controller = mouse.Controller()
        self.keyboard_controller = keyboard.Controller()

    def convert_key_layout(self, key):
        if self.azerty_keyboard:
            azerty_map = {
                'a': 'q', 'q': 'a',
                'w': 'z', 'z': 'w',
                's': 's', 'd': 'd'
            }
            return azerty_map.get(key, key)
        return key

    def record_mouse(self, x, y, button, pressed):
        if self.recording and not self.stop_recording_flag:
            if not self.start_time:
                self.start_time = time.time()
            timestamp = time.time() - self.start_time
            action = {
                "type": "mouse",
                "x": x,
                "y": y,
                "button": str(button),
                "pressed": pressed,
                "timestamp": timestamp
            }
            self.actions.append(action)

    def record_keyboard(self, key, pressed):
        if self.recording and not self.stop_recording_flag:
            if not self.start_time:
                self.start_time = time.time()
            timestamp = time.time() - self.start_time
            action = {
                "type": "keyboard",
                "key": self.convert_key_layout(str(key).replace("'", "")),
                "pressed": pressed,
                "timestamp": timestamp
            }
            self.actions.append(action)

    def save_recording(self):
        with open(self.filename, "w") as f:
            json.dump(self.actions, f, indent=2)
        print(f"Actions saved to {self.filename}")

    def load_recording(self, filename=None):
        path_to_load = filename if filename else self.filename
        try:
            with open(path_to_load, "r") as f:
                self.actions = json.load(f)
            print(f"Actions loaded from {path_to_load}")
        except FileNotFoundError:
            print(f"No recording found at {path_to_load}")

    def replay_actions(self):
        print("Replaying actions...")
        if not self.actions:
            print("No actions recorded.")
            return

        self.stop_replay_flag = False
        start_time = time.perf_counter()

        key_map = {
            "Key.space": keyboard.Key.space,
            "Key.enter": keyboard.Key.enter,
            "Key.shift": keyboard.Key.shift,
            "Key.ctrl": keyboard.Key.ctrl,
            "Key.alt": keyboard.Key.alt,
            "Key.esc": keyboard.Key.esc,
        }

        try:
            for action in self.actions:
                if self.stop_replay_flag or (self.running_event and not self.running_event.is_set()):
                    print("Replay stopped.")
                    break

                target_time = start_time + action["timestamp"]
                while time.perf_counter() < target_time:
                    if self.stop_replay_flag or (self.running_event and not self.running_event.is_set()):
                        print("Replay stopped while waiting for next action.")
                        return

                # Replay mouse actions
                if action["type"] == "mouse":
                    x, y = action["x"], action["y"]
                    button = action["button"]
                    if action["pressed"]:
                        self.mouse_controller.position = (x, y)
                        if button == "Button.left":
                            self.pressed_mouse_buttons.add(mouse.Button.left)
                            self.mouse_controller.press(mouse.Button.left)
                        elif button == "Button.right":
                            self.pressed_mouse_buttons.add(mouse.Button.right)
                            self.mouse_controller.press(mouse.Button.right)
                    else:
                        if button == "Button.left":
                            self.mouse_controller.release(mouse.Button.left)
                            self.pressed_mouse_buttons.discard(mouse.Button.left)
                        elif button == "Button.right":
                            self.mouse_controller.release(mouse.Button.right)
                            self.pressed_mouse_buttons.discard(mouse.Button.right)

                # Replay keyboard actions
                elif action["type"] == "keyboard":
                    key_str = self.convert_key_layout(action["key"])
                    try:
                        if key_str in key_map:
                            key = key_map[key_str]
                        else:
                            key = key_str.replace("'", "")

                        if action["pressed"]:
                            self.pressed_keys.add(key)
                            self.keyboard_controller.press(key)
                        else:
                            self.keyboard_controller.release(key)
                            self.pressed_keys.discard(key)

                    except Exception as e:
                        print(f"Error replaying key {key_str}: {e}")

        finally:
            self.cleanup_pressed_inputs()
            
    def cleanup_pressed_inputs(self):
        for key in list(self.pressed_keys):
            try:
                self.keyboard_controller.release(key)
            except Exception as e:
                print(f"Error releasing key {key}: {e}")
        self.pressed_keys.clear()

        # Release all pressed mouse buttons
        for button in list(self.pressed_mouse_buttons):
            try:
                print(f"Releasing mouse button: {button}")
                self.mouse_controller.release(button)
            except Exception as e:
                print(f"Error releasing mouse button {button}: {e}")
        self.pressed_mouse_buttons.clear()

    def start_recording(self):
        self.recording = True
        self.start_time = None
        self.actions = []
        self.stop_recording_flag = False

        with mouse.Listener(on_click=self.on_click) as mouse_listener, \
            keyboard.Listener(on_press=self.on_press, on_release=self.on_release) as keyboard_listener:
            
            while not self.stop_recording_flag: time.sleep(0.1)

            mouse_listener.stop()
            keyboard_listener.stop()

        self.recording = False
        self.save_recording()

    def on_click(self, x, y, button, pressed):
        self.record_mouse(x, y, button, pressed)

    def on_press(self, key):
        self.record_keyboard(key, True)

    def on_release(self, key):
        self.record_keyboard(key, False)


# Example usage of how it work (when you run directly the file)
def main():
    record_path = RecordPath()

    def on_record_hotkey():
        print("Recording with hotkey")
        threading.Thread(target=record_path.start_recording).start()

    def on_replay_hotkey():
        print("Replaying with hotkey")
        threading.Thread(target=record_path.start_replay).start()

    # Set hotkeys with keyboard.GlobalHotKeys as example ctrl + alt + r to record. And ctrl + alt + p to replay
    with keyboard.GlobalHotKeys({
        '<ctrl>+<alt>+r': on_record_hotkey,
        '<ctrl>+<alt>+p': on_replay_hotkey
    }) as h:
        h.join()

if __name__ == "__main__":
    main()
