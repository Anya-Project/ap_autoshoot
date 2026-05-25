# AP Autoshoot — Auto vehicle photo shoot

<table>
  <tr>
    <td><b>Menu Setup</b></td>
    <td><b>Discord Log</b></td>
  </tr>
  <tr>
    <td><img src="https://i.imgur.com/MmSEmsO.png" alt="Contoh Menu" width="400"/></td>
    <td><img src="https://i.imgur.com/BZmnoBe.png" alt="Contoh Log Discord" width="400"/></td>
  </tr>
</table>

## Dependencies
- **Python 3.10 or newer** (with pip added to PATH)
- **screenshot-basic** 
- **ox_lib or lation_ui** 
---

## Installation & Setup

### Step 1: Install Python Libraries
Install required Python dependencies via command prompt/terminal:
```bash
pip install flask flask-cors rembg pillow requests
```
*(If you want to use GPU for faster background removal, run: `pip install "rembg[gpu]"`)*

---

### Step 2: Start the Rembg Server
1. Open a terminal inside the resource directory (`ap_autoshoot`).
2. Run the flask proxy server:
   ```bash
   python python/rembg_server.py
   ```
Keep this window open in the background while taking vehicle photos.

---

### Step 3: Configure config.lua
Adjust the configurations inside `config.lua`:
- `Config.UseRembg`: Set to `true` to enable automated background removal.
- `Config.RembgUrl`: The endpoint URL of the Flask server (default: `"http://localhost:5000/process"`).
- `Config.Channels`: Configured Discord webhook options.
- `Config.UseRandomColors`: If `true`, applies random vehicle colors from the premium colors list.

---

### Step 4: Start Resource
Add the following to your `server.cfg`:
```cfg
ensure ap_autoshoot
```

---

## Commands & Usage

### 1. `/autoshoot`
Starts a batch photoshoot for all vehicles inside `data/vehicles_list.json`.
1. Run `/autoshoot` in-game.
2. Select your studio location and camera angle.
3. Configure AI background removal and destination Discord channel.
4. Confirm to start the batch photoshoot.

### 2. `/autoshoot_single [spawn_code]`
Performs a photoshoot for a single vehicle.
- Example: `/autoshoot_single t20`

### 3. `/autoshoot_cancel`
Cancels an active batch photoshoot process.

### 4. `/autoshoot_setup`
Utility command to setup coordinates and camera angles.
1. Park a vehicle at the desired location.
2. Run `/autoshoot_setup` to spawn a test vehicle.
3. Move your character to your preferred camera viewpoint.
4. Press **[G]** to toggle camera preview.
5. Use Arrow Keys to adjust:
   - **Up / Down**: Camera FOV (Zoom)
   - **Left / Right**: Camera Height (Z-Axis)
6. Press **[ENTER]** to copy the final coordinates to your F8 console.
7. Press **[BACKSPACE]** to exit.
