# qbx_atc — Air Traffic Control Job for Qbox 🛫

Turn LSIA into a living airport. **qbx_atc** adds an **Air Traffic Control** job using the latest **Qbox/qbx_core** patterns, **ox_target** interactions for an in-world computer, an immersive **NUI console** (with LSIA logo), **cinematic/normal tower cameras**, and **NPC traffic** you coordinate for landings, taxi, and takeoffs. Controllers earn cash for each safe arrival/parking or departure/takeoff. Duty slots are capped so only **20** can control at once.  

> Works out of the box at LSIA. Config is clean and extendable for Sandy Shores and Grapeseed. 🌴

---

## ✨ Features

- 🧑‍✈️ **ATC Duty System** — Toggle on/off with a hard cap of **20** controllers (server-side enforced).
- 🎯 **ox_target Computer** — Context menu at the tower computer: **Go On Duty / Open ATC Console / Go Off Duty**.
- 🎥 **Immersive Cameras** — Scripted camera with **Cinematic** and **Normal** views; toggle from the UI.
- 🖥️ **NUI Console** — Minimal control panel with traffic list, commands, and status. LSIA logo in the header.
- ✈️ **NPC Plane Traffic**:
  - 🛬 **Arrivals** → Clear to Land → Taxi to Hangar → **Payout**.
  - 🛫 **Departures** → Taxi to Runway → Clear Takeoff → Climb-out → **Payout**.
  - 🌐 Optional ambient spawner with concurrency cap.
- 💸 **Economy Hooks** — Pays via `Player.Functions.AddMoney('cash', amount, 'ATC')` (qbx_core style).
- 🧰 **Clean Config** — Routes, cameras, models, payments, and spawn timing all in `config.lua`.

---

## 📦 Resource Structure

```
qbx_atc/
  fxmanifest.lua
  config.lua
  client.lua
  server.lua
  html/
    index.html
    style.css
    app.js
```

---

## 🔌 Requirements

- qbx_core
- ox_lib
- ox_target
- (Optional) oxmysql (already referenced; not strictly required in v1)

---

## 🚀 Installation

1. Drop the folder into your resources:  
   `resources/[jobs]/qbx_atc`
2. Ensure dependencies **start before** this resource:
   ```cfg
   ensure ox_lib
   ensure ox_target
   ensure qbx_core
   ensure qbx_atc
   ```
3. (Optional) Adjust the **tower computer** location in `config.lua`:
   ```lua
   Config.Airport.towerComputer = {
     coords   = vec3(-1036.95, -2736.57, 20.17), -- place it at your desk/tower
     size     = vec3(1.2, 1.2, 1.2),
     rotation = 0.0
   }
   ```

---

## ⚙️ Configuration (config.lua) 🛠️

```lua
Config.MaxControllers = 20          -- max ATC on duty 👥
Config.PayArrival   = 250           -- payout for parked arrival 💵
Config.PayDeparture = 300           -- payout for successful takeoff 💵

-- Cameras 🎥
Config.Airport.cams.cinematic       -- default wide view of LSIA
Config.Airport.cams.normal          -- closer, practical view

-- Traffic & Routes 🛤️
Config.Airport.arrival              -- spawn, touchdown, taxi route, hangar
Config.Airport.departure            -- gate -> lineup -> runway -> climb
Config.Airport.planeModels          -- stable models: shamal, velum, luxor, dodo
Config.Airport.traffic              -- min/max interval + maxSimultaneous NPCs
```

> Tip: If you add heavier jets, increase distances & wait times in the tasks. 🛩️➡️🛬

---

## 🕹️ Usage

- Go to the **tower computer** (configured `coords`) 🖱️.
- Use **ox_target** options:
  - ✅ **Go On Duty (ATC)**
  - 🖥️ **Open ATC Console**
  - 📴 **Go Off Duty**

In the **ATC Console (NUI)**:
- 🛬 **Spawn Arrival** / 🛫 **Spawn Departure**.
- Select a plane from the list and issue commands:
  - **Arrivals**: `Clear to Land` → `Taxi to Hangar` (pays on **parked**).
  - **Departures**: `Hold` / `Clear Takeoff` (pays when **airborne**).
- Toggle **Cinematic / Normal** cameras 🎥.
- **Hide UI** for clean views; **Close** to exit the console.

---

## 🔑 Commands

- `/atc_off` — quick failsafe to go off duty if you’re stuck. 🆘

---

## 🧠 Events & Callbacks (for devs) 💻

**Client → Server**
- `qbx_atc:requestDuty(bool)` — request on/off duty.
- `qbx_atc:registerPlane(netId, "arrival"|"departure")` — register spawned plane.
- `qbx_atc:updatePlaneState(netId, "parked"|"airborne")` — payout triggers.

**Server → Client**
- `qbx_atc:dutyResult(isOn, count, err?)` — duty state response.
- `qbx_atc:notify(msg)` — small notify helper.

**Callbacks (ox_lib)**
- `qbx_atc:getDutyCount()` → returns `(count, max)`.
- `qbx_atc:isController(source)` → boolean.

---

## 🧩 Customization Ideas 🎯

- **Job Whitelist**: In `ox_target` options, add `canInteract` checks for player job/grade via qbx_core. 👮‍♂️
- **Multiple Airports**: Duplicate `Config.Airport` blocks (Sandy/Grapeseed) and register more zones/cameras. 🗺️
- **Ranks & XP**: Store handled planes in DB and scale payouts/traffic density. 📊
- **Collision/Conflicts**: Add simple segment occupancy checks; penalize simultaneous runway/taxiway usage. ⚠️💥
- **Delays**: Per-plane timers; reduce payout if the operation takes too long. ⏱️
- **Weather/Events**: Random visibility/fuel issues → require different routing or spacing. 🌧️⛽

---

## 🛠️ Troubleshooting 🐛

- **UI doesn’t open**  
  Check `ui_page` and files in `fxmanifest.lua`. Look at F8 for CORS/NUI errors.
- **ox_target options not showing**  
  Verify the `coords/size/rotation` box overlaps your desk. Toggle `debug=true` in `addBoxZone` temporarily.
- **No payouts**  
  Confirm `qbx_core:GetPlayer` and `Player.Functions.AddMoney` exist; adjust `addMoney` helper for your economy.
- **Planes not moving**  
  Increase waits, use lighter models, or ensure spawn points aren’t obstructed by map mods.

---

## 📜 License

MIT — do what you like, keep the attribution. 📎

---

## 🗺️ Roadmap

- ✅ **v1.1.0**: ox_target integration, LSIA logo header, stability pass  
- ⏭️ **v1.2**: multi-airport config, job whitelist, segment conflict system  
- ⏭️ **v1.3**: stats persistence (oxmysql), rank tiers, configurable penalties

---

## ❤️ Credits

- You (design direction & UI logo) 🙌  
- JD (implementation) 🧩  
- Qbox / Overextended teams for **qbx_core**, **ox_lib**, **ox_target** 💙
