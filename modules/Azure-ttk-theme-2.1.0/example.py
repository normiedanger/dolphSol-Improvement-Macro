import tkinter as tk
from tkinter import ttk
import os

class DiscordMacroUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Improvement Sol's v1.4.2 (heavily inspired by dolphSol)")
        self.root.configure(bg="#2C2F33")  # Default to dark mode background
        self.dark_mode = True  # Start in dark mode

        # Apply the Azure theme
        theme_path = os.path.join("Azure-ttk-theme-2.1.0", "azure.tcl")
        self.root.tk.call("source", theme_path)
        self.root.tk.call("set_theme", "dark")  # Start in dark theme

        # Styling for a more compact design
        style = ttk.Style()
        style.configure("TLabelFrame", padding=10, font=("Helvetica", 10))
        style.configure("TButton", font=("Helvetica", 10), padding=(6, 4))
        style.configure("TCheckbutton", font=("Helvetica", 10), padding=(6, 4))
        style.configure("TRadiobutton", font=("Helvetica", 10))
        
        # Custom style for switch appearance
        style.configure("Switch.TCheckbutton", font=("Helvetica", 10), padding=5)
        
        # Adjust UI for a more readable layout
        self.setup_tabs()
        self.setup_main_tab()
        self.auto_resize()

    def setup_tabs(self):
        # Create tab control
        self.tab_control = ttk.Notebook(self.root)

        # Define frames for each tab
        self.main_tab = ttk.Frame(self.tab_control)
        self.crafting_tab = ttk.Frame(self.tab_control)
        self.webhook_tab = ttk.Frame(self.tab_control)
        self.settings_tab = ttk.Frame(self.tab_control)

        # Add tabs to the notebook
        self.tab_control.add(self.main_tab, text="Main")
        self.tab_control.add(self.crafting_tab, text="Crafting")
        self.tab_control.add(self.webhook_tab, text="Webhook")
        self.tab_control.add(self.settings_tab, text="Settings")
        
        # Pack the tab control to expand and fill the window
        self.tab_control.pack(expand=1, fill="both")

    def setup_main_tab(self):
        # Obby Section
        self.obby_frame = ttk.LabelFrame(self.main_tab, text="Obby")
        self.obby_frame.grid(column=0, row=0, padx=10, pady=10, sticky="w")
        
        self.do_obby = ttk.Checkbutton(self.obby_frame, text="Do Obby (Every 2 Mins)")
        self.do_obby.state(['!alternate'])  # Remove third state
        self.do_obby.grid(column=0, row=0, sticky="w")
        
        self.check_obby_buff = ttk.Checkbutton(self.obby_frame, text="Check for Obby Buff Effect")
        self.check_obby_buff.state(['!alternate'])  # Remove third state
        self.check_obby_buff.grid(column=0, row=1, sticky="w")

        # Auto Equip Section
        self.auto_equip_frame = ttk.LabelFrame(self.main_tab, text="Auto Equip")
        self.auto_equip_frame.grid(column=1, row=0, padx=10, pady=10, sticky="w")

        self.enable_auto_equip = ttk.Checkbutton(self.auto_equip_frame, text="Enable Auto Equip")
        self.enable_auto_equip.state(['!alternate'])  # Remove third state
        self.enable_auto_equip.grid(column=0, row=0, sticky="w")
        
        # Increase button width to prevent cutoff
        self.configure_search_button = ttk.Button(self.auto_equip_frame, text="Configure Search", width=16)
        self.configure_search_button.grid(column=1, row=0, padx=5, pady=5)

        # Item Collecting Section
        self.item_collecting_frame = ttk.LabelFrame(self.main_tab, text="Item Collecting")
        self.item_collecting_frame.grid(column=0, row=1, columnspan=2, padx=10, pady=10, sticky="w")

        self.collect_items = ttk.Checkbutton(self.item_collecting_frame, text="Collect Items Around the Map")
        self.collect_items.state(['!alternate'])  # Remove third state
        self.collect_items.grid(column=0, row=0, sticky="w")

        # Path Radio Buttons
        self.path_label = ttk.Label(self.item_collecting_frame, text="Collect Path:")
        self.path_label.grid(column=0, row=1, sticky="w")
        
        self.path_niko = ttk.Radiobutton(self.item_collecting_frame, text="Niko", value=1)
        self.path_niko.grid(column=1, row=1, sticky="w")
        
        self.path_default = ttk.Radiobutton(self.item_collecting_frame, text="Default", value=2)
        self.path_default.grid(column=2, row=1, sticky="w")

        # Collect from spots checkboxes
        self.spots_frame = ttk.Frame(self.item_collecting_frame)
        self.spots_frame.grid(column=0, row=2, columnspan=3, sticky="w", pady=2)

        # List of spot labels
        spot_labels = ["1", "2", "3", "4", "5", "6", "7", "8*"]
        for idx, spot in enumerate(spot_labels):
            spot_checkbox = ttk.Checkbutton(self.spots_frame, text=spot)
            spot_checkbox.state(['!alternate'])  # Remove third state
            spot_checkbox.grid(row=0, column=idx, sticky="w")

        # Bottom Buttons (Start, Pause, Stop)
        self.bottom_frame = ttk.Frame(self.root, padding=5)
        self.bottom_frame.pack(fill="x")

        self.start_button = ttk.Button(self.bottom_frame, text="F1 - Start", width=10)
        self.start_button.grid(row=0, column=0, padx=5)

        self.pause_button = ttk.Button(self.bottom_frame, text="F2 - Pause", width=10)
        self.pause_button.grid(row=0, column=1, padx=5)

        self.stop_button = ttk.Button(self.bottom_frame, text="F3 - Stop", width=10)
        self.stop_button.grid(row=0, column=2, padx=5)

        # Dark Mode Switch
        self.dark_mode_switch = ttk.Checkbutton(self.bottom_frame, text="Dark Mode", style="Switch.TCheckbutton", command=self.toggle_dark_mode)
        self.dark_mode_switch.state(['!alternate'])  # Remove third state
        self.dark_mode_switch.grid(row=0, column=3, padx=5)

    def toggle_dark_mode(self):
        # Toggle between dark and light themes
        if self.dark_mode:
            self.root.tk.call("set_theme", "light")
            self.root.configure(bg="#FFFFFF")  # Set light background
            self.dark_mode_switch.config(text="Light Mode")
        else:
            self.root.tk.call("set_theme", "dark")
            self.root.configure(bg="#2C2F33")  # Set dark background
            self.dark_mode_switch.config(text="Dark Mode")
        self.dark_mode = not self.dark_mode

    def auto_resize(self):
        # Automatically resize window based on content
        self.root.update_idletasks()
        self.root.geometry(f"{self.root.winfo_width()}x{self.root.winfo_height()}")

# Run the application
if __name__ == "__main__":
    root = tk.Tk()
    app = DiscordMacroUI(root)
    root.mainloop()
