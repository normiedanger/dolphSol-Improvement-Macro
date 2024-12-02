import autoit
import time

class CollectionPath:
    def __init__(self, is_allan_path=False):
        self.is_allan_path = is_allan_path

    def collect(self, spot_number):
        pass

    def spot1(self):
        if self.is_allan_path:
            print("Walking in Allan's path to Spot 1...")
            self.walk("w", "d", 1100, 2500)
            self.collect(1)
        else:
            print("Walking in Default path to Spot 1...")
            self.walk("s", "a", 1100, 2500)
            self.collect(1)

    def spot2(self):
        if self.is_allan_path:
            print("Walking in Allan's path to Spot 2...")
            self.walk("a", None, 3400, 0)
            self.collect(2)
        else:
            print("Walking in Default path to Spot 2...")
            self.walk("d", None, 3400, 0)
            self.collect(2)

    def walk(self, key1, key2, duration1, duration2):
        if key1:
            print(f"Press {key1} down")
            autoit.send(f"{{{key1}}}")  # Press the first key
            time.sleep(duration1 / 1000)  # Wait for the specified duration
            autoit.send(f"{{{key1} up}}")  # Release the first key
            print(f"Release {key1}")

        if key2:
            time.sleep(duration2 / 1000)  # Wait before pressing the second key if needed
            print(f"Press {key2} down")
            autoit.send(f"{{{key2}}}")  # Press the second key
            time.sleep(duration2 / 1000)
            autoit.send(f"{{{key2} up}}")  # Release the second key
            print(f"Release {key2}")
