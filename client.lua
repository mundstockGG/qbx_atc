local duty = false
local uiOpen = false
local currentCam = nil
local cinematic = true
local computerZoneId = nil

local spawnedPlanes = {} -- [netId] = { ent, ped, type, blip }

-- ========= Notifications =========
local function notify(msg, ntype)
  if lib and lib.notify then
    lib.notify({ title = 'ATC', description = msg, type = ntype or 'inform' })
  else
    BeginTextCommandThefeedPost('STRING'); AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, true)
  end
end

-- ========= Duty =========
local function toggleDuty(on)
  TriggerServerEvent('qbx_atc:requestDuty', on == true)
end

RegisterNetEvent('qbx_atc:dutyResult', function(isOn, count, err)
  duty = isOn
  if isOn then
    notify(('On duty as ATC (%d/%d).'):format(count, Config.MaxControllers))
  else
    if err then notify(('Cannot go on duty: %s'):format(err), 'error') end
    notify('Off duty.')
    if uiOpen then SetNuiFocus(false, false); SendNUIMessage({ action='close' }); uiOpen = false end
    if currentCam then RenderScriptCams(false, true, 500, true, false); DestroyCam(currentCam, false); currentCam=nil end
  end
end)

-- ========= ox_target Zone =========
local function registerComputerTarget()
  if computerZoneId then exports.ox_target:removeZone(computerZoneId); computerZoneId = nil end

  local box = Config.Airport.towerComputer
  computerZoneId = exports.ox_target:addBoxZone({
    coords = box.coords,
    size = box.size,
    rotation = box.rotation or 0.0,
    debug = false,
    options = {
      {
        name = 'qbx_atc_duty_on',
        icon = 'fa-solid fa-tower-broadcast',
        label = 'Go On Duty (ATC)',
        distance = 2.0,
        onSelect = function() toggleDuty(true) end,
        canInteract = function(entity, distance, coords, name)
          return not duty
        end
      },
      {
        name = 'qbx_atc_open_console',
        icon = 'fa-solid fa-desktop',
        label = 'Open ATC Console',
        distance = 2.0,
        onSelect = function() openAtcUI() end,
        canInteract = function(entity, distance, coords, name)
          return duty
        end
      },
      {
        name = 'qbx_atc_duty_off',
        icon = 'fa-solid fa-user-slash',
        label = 'Go Off Duty',
        distance = 2.0,
        onSelect = function() toggleDuty(false) end,
        canInteract = function(entity, distance, coords, name)
          return duty
        end
      }
    }
  })
end

CreateThread(registerComputerTarget)

-- ========= UI / Camera =========
function openAtcUI()
  uiOpen = true
  SetNuiFocus(true, true)
  SendNUIMessage({ action='open' })
  setAtcCamera(true)
  SendNUIMessage({ action='status', cinematic = true })
end

RegisterNUICallback('close', function(_, cb)
  uiOpen = false
  SetNuiFocus(false, false)
  if currentCam then RenderScriptCams(false, true, 500, true, false); DestroyCam(currentCam, false); currentCam=nil end
  cb(1)
end)

RegisterNUICallback('toggleCinematic', function(_, cb)
  cinematic = not cinematic
  setAtcCamera(cinematic)
  SendNUIMessage({ action='status', cinematic = cinematic })
  cb(1)
end)

RegisterNUICallback('toggleUI', function(_, cb)
  -- handled visually in app.js; nothing to do here
  cb(1)
end)

function setAtcCamera(isCinematic)
  if currentCam then
    RenderScriptCams(false, true, 500, true, false)
    DestroyCam(currentCam, false)
    currentCam = nil
  end
  local cfg = isCinematic and Config.Airport.cams.cinematic or Config.Airport.cams.normal
  currentCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
  SetCamCoord(currentCam, cfg.pos.x, cfg.pos.y, cfg.pos.z)
  SetCamRot(currentCam, cfg.rot.x, cfg.rot.y, cfg.rot.z, 2)
  SetCamFov(currentCam, cfg.fov)
  RenderScriptCams(true, true, 500, true, false)
  DisplayHud(not isCinematic)
  DisplayRadar(not isCinematic)
end

-- ========= NUI Plane Commands =========
RegisterNUICallback('requestArrival', function(_, cb)
  spawnArrivalPlane()
  cb(1)
end)
RegisterNUICallback('requestDeparture', function(_, cb)
  spawnDeparturePlane()
  cb(1)
end)
RegisterNUICallback('commandPlane', function(data, cb)
  local netId = data.netId
  local cmd   = data.command
  local ent = NetworkGetEntityFromNetworkId(netId)
  if not DoesEntityExist(ent) then cb(0); return end

  if cmd == 'land' then
    atcCmd_Land(ent, netId)
  elseif cmd == 'taxi' then
    atcCmd_TaxiToHangar(ent, netId)
  elseif cmd == 'hold' then
    atcCmd_Hold(ent, netId)
  elseif cmd == 'takeoff' then
    atcCmd_Takeoff(ent, netId)
  end
  cb(1)
end)

-- ========= Plane Spawning / Logic =========
local function requestModelBlocking(model)
  if not IsModelInCdimage(model) then return false end
  RequestModel(model)
  local tries = 0
  while not HasModelLoaded(model) and tries < 200 do
    Wait(25); tries += 1
  end
  return HasModelLoaded(model)
end

local function makePlane(model, coords, isArrival)
  if not requestModelBlocking(model) then return nil end
  local plane = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w or 0.0, true, true)
  SetVehicleEngineOn(plane, true, true, false)
  SetVehicleDoorsLocked(plane, 4)
  SetEntityAsMissionEntity(plane, true, true)
  local pilot = CreatePedInsideVehicle(plane, 1, `s_m_m_pilot_01`, -1, true, false)
  SetBlockingOfNonTemporaryEvents(pilot, true)
  TaskVehicleDriveWander(pilot, plane, 10.0, 786603)

  local netId = NetworkGetNetworkIdFromEntity(plane)
  SetNetworkIdCanMigrate(netId, true)

  local blip = AddBlipForEntity(plane)
  SetBlipSprite(blip, isArrival and 90 or 16)
  SetBlipColour(blip, isArrival and 2 or 5)
  BeginTextCommandSetBlipName('STRING'); AddTextComponentString(isArrival and 'Arrival' or 'Departure'); EndTextCommandSetBlipName(blip)

  spawnedPlanes[netId] = { ent = plane, ped = pilot, type = isArrival and 'arrival' or 'departure', blip = blip }
  TriggerServerEvent('qbx_atc:registerPlane', netId, isArrival and 'arrival' or 'departure')

  SendNUIMessage({ action = 'planeList:add', plane = { netId = netId, kind = isArrival and 'arrival' or 'departure' } })

  return netId
end

function table.count(t) local c=0 for _ in pairs(t) do c=c+1 end return c end

function spawnArrivalPlane()
  if not duty then notify('Go on duty first.', 'error'); return end
  if table.count(spawnedPlanes) >= Config.Airport.traffic.maxSimultaneous then
    notify('Traffic saturated, wait a moment.'); return
  end
  local mdl = Config.Airport.planeModels[math.random(#Config.Airport.planeModels)]
  local id = makePlane(mdl, Config.Airport.arrival.spawn, true)
  if id then notify('Inbound plane is approaching. Clear to land when ready.') end
end

function spawnDeparturePlane()
  if not duty then notify('Go on duty first.', 'error'); return end
  if table.count(spawnedPlanes) >= Config.Airport.traffic.maxSimultaneous then
    notify('Traffic saturated, wait a moment.'); return
  end
  local mdl = Config.Airport.planeModels[math.random(#Config.Airport.planeModels)]
  local id = makePlane(mdl, Config.Airport.departure.spawnGate, false)
  if id then notify('Outbound plane at gate. Clear to taxi and takeoff.') end
end

-- Commands
function atcCmd_Land(plane, netId)
  local pRec = spawnedPlanes[netId]; if not pRec or pRec.type ~= 'arrival' then return end
  local a = Config.Airport.arrival
  TaskPlaneMission(pRec.ped, plane, 0, 0, a.runwayEntry.x, a.runwayEntry.y, a.runwayEntry.z, 4, 100.0, 0.0, 0.0, 500.0, 500.0)
  notify('Cleared to land: proceed to runway.')
end

function atcCmd_TaxiToHangar(plane, netId)
  local pRec = spawnedPlanes[netId]; if not pRec then return end
  local a = Config.Airport.arrival
  CreateThread(function()
    for _, wp in ipairs(a.taxiWaypoints) do
      TaskVehicleDriveToCoord(pRec.ped, plane, wp.x, wp.y, wp.z, 10.0, 0, GetEntityModel(plane), 786603, 5.0, true)
      Wait(5000)
    end
    TaskVehicleDriveToCoord(pRec.ped, plane, a.hangar.x, a.hangar.y, a.hangar.z, 8.0, 0, GetEntityModel(plane), 786603, 4.0, true)
    Wait(4000)
    FreezeEntityPosition(plane, true)
    TriggerServerEvent('qbx_atc:updatePlaneState', netId, 'parked')
    if pRec.blip then RemoveBlip(pRec.blip) end
    DeleteEntity(pRec.ped); DeleteVehicle(plane)
    spawnedPlanes[netId] = nil
    SendNUIMessage({ action='planeList:remove', netId = netId })
  end)
  notify('Taxi to hangar.')
end

function atcCmd_Hold(plane, netId)
  local pRec = spawnedPlanes[netId]; if not pRec then return end
  TaskVehicleTempAction(pRec.ped, plane, 27, 6000) -- stop/handbrake
  notify('Hold position.')
end

function atcCmd_Takeoff(plane, netId)
  local pRec = spawnedPlanes[netId]; if not pRec or pRec.type ~= 'departure' then return end
  local d = Config.Airport.departure
  CreateThread(function()
    TaskVehicleDriveToCoord(pRec.ped, plane, d.lineup.x, d.lineup.y, d.lineup.z, 12.0, 0, GetEntityModel(plane), 786603, 6.0, true)
    Wait(7000)
    TaskVehicleDriveToCoord(pRec.ped, plane, d.takeoff.x, d.takeoff.y, d.takeoff.z, 60.0, 0, GetEntityModel(plane), 786603, 0.0, true)
    Wait(6000)
    TaskPlaneMission(pRec.ped, plane, 0, 0, d.climb.x, d.climb.y, d.climb.z, 4, 120.0, 0.0, 0.0, 500.0, 500.0)
    Wait(5000)
    TriggerServerEvent('qbx_atc:updatePlaneState', netId, 'airborne')
    if pRec.blip then RemoveBlip(pRec.blip) end
    DeleteEntity(pRec.ped); DeleteVehicle(plane)
    spawnedPlanes[netId] = nil
    SendNUIMessage({ action='planeList:remove', netId = netId })
  end)
  notify('Cleared for takeoff.')
end

-- ========= Ambient traffic (optional) =========
CreateThread(function()
  while true do
    local minI, maxI = Config.Airport.traffic.minInterval, Config.Airport.traffic.maxInterval
    Wait(math.random(minI, maxI) * 1000)
    if duty and uiOpen and table.count(spawnedPlanes) < Config.Airport.traffic.maxSimultaneous then
      if math.random() < 0.5 then spawnArrivalPlane() else spawnDeparturePlane() end
    end
  end
end)

-- QoL command
RegisterCommand('atc_off', function()
  if duty then TriggerServerEvent('qbx_atc:requestDuty', false) end
end, false)
