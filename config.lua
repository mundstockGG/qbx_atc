Config = {}

-- Max controllers allowed at once
Config.MaxControllers = 20

-- Pay per completed operation (arrival parked / departure takeoff)
Config.PayArrival   = 250
Config.PayDeparture = 300

-- Airport setup (LSIA by default)
Config.Airport = {
  name = 'LSIA',

  -- The "computer" spot where ox_target options appear
  towerComputer = {
    coords = vec3(-1036.95, -2736.57, 20.17),  -- top of tower/interior desk
    size   = vec3(1.2, 1.2, 1.2),              -- target box size
    rotation = 0.0
  },

  -- Cameras: cinematic & normal
  cams = {
    cinematic = {
      pos = vec3(-1129.0, -2873.0, 44.0),
      rot = vec3(-10.0, 0.0, 35.0),
      fov = 50.0
    },
    normal = {
      pos = vec3(-1315.0, -3052.0, 60.0),
      rot = vec3(-8.0, 0.0, 65.0),
      fov = 70.0
    }
  },

  -- Spawns and routes (stable for AI)
  arrival = {
    spawn = vec4(-1331.0, -3140.0, 14.0, 60.0),
    runwayEntry = vec3(-1286.0, -2966.0, 14.0),
    taxiWaypoints = {
      vec3(-1206.0, -2827.0, 13.9),
      vec3(-1120.0, -2731.0, 13.9),
      vec3(-1041.5, -2721.5, 13.9)
    },
    hangar = vec3(-998.0, -3009.0, 13.9)
  },

  departure = {
    spawnGate = vec4(-998.0, -3009.0, 13.9, 150.0),
    lineup = vec3(-1384.0, -2645.0, 14.0),
    takeoff = vec3(-1700.0, -2140.0, 14.0),
    climb = vec3(-2150.0, -1500.0, 200.0)
  },

  -- Plane models to use (ensure streamed)
  planeModels = {
    `shamal`, `velum`, `luxor`, `dodo`
  },

  -- NPC timing
  traffic = {
    minInterval = 45,      -- seconds between spawns
    maxInterval = 90,
    maxSimultaneous = 5    -- cap concurrent NPC planes
  }
}
