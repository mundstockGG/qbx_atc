local ControllerSet = {}   -- [src] = true if on duty
local PlaneLedger   = {}   -- [netId] = { type='arrival'/'departure', assigned=src, state='spawned', createdAt=... }

-- qbx_core helpers
local function getPlayer(src)
  if not src then return nil end
  if exports.qbx_core and exports.qbx_core:GetPlayer then
    return exports.qbx_core:GetPlayer(src)
  end
  return nil
end

local function addMoney(src, amount, reason)
  local xPlayer = getPlayer(src)
  if not xPlayer then return end
  if xPlayer.Functions and xPlayer.Functions.AddMoney then
    xPlayer.Functions.AddMoney('cash', amount, reason or 'ATC')
  elseif xPlayer.addMoney then
    xPlayer:addMoney('cash', amount, reason or 'ATC')
  end
end

local function countControllers()
  local c = 0
  for _ in pairs(ControllerSet) do c = c + 1 end
  return c
end

RegisterNetEvent('qbx_atc:requestDuty', function(toggleOn)
  local src = source
  if toggleOn then
    if ControllerSet[src] then
      TriggerClientEvent('qbx_atc:dutyResult', src, true, countControllers())
      return
    end
    if countControllers() >= Config.MaxControllers then
      TriggerClientEvent('qbx_atc:dutyResult', src, false, countControllers(), ('Max controllers reached (%d)'):format(Config.MaxControllers))
      return
    end
    ControllerSet[src] = true
    TriggerClientEvent('qbx_atc:dutyResult', src, true, countControllers())
  else
    ControllerSet[src] = nil
    TriggerClientEvent('qbx_atc:dutyResult', src, false, countControllers())
  end
end)

AddEventHandler('playerDropped', function()
  ControllerSet[source] = nil
end)

-- Plane lifecycle registration
RegisterNetEvent('qbx_atc:registerPlane', function(planeNetId, kind)
  PlaneLedger[planeNetId] = { type = kind, state = 'spawned', assigned = source, createdAt = os.time() }
end)

RegisterNetEvent('qbx_atc:updatePlaneState', function(planeNetId, state)
  local rec = PlaneLedger[planeNetId]
  if not rec then return end
  rec.state = state

  if state == 'parked' and rec.type == 'arrival' then
    addMoney(rec.assigned, Config.PayArrival, 'ATC arrival')
    TriggerClientEvent('qbx_atc:notify', rec.assigned, ('Arrival complete +$%d'):format(Config.PayArrival))
    PlaneLedger[planeNetId] = nil
  elseif state == 'airborne' and rec.type == 'departure' then
    addMoney(rec.assigned, Config.PayDeparture, 'ATC departure')
    TriggerClientEvent('qbx_atc:notify', rec.assigned, ('Departure complete +$%d'):format(Config.PayDeparture))
    PlaneLedger[planeNetId] = nil
  end
end)

-- Callbacks
lib.callback.register('qbx_atc:getDutyCount', function()
  return countControllers(), Config.MaxControllers
end)

lib.callback.register('qbx_atc:isController', function(source)
  return ControllerSet[source] == true
end)
