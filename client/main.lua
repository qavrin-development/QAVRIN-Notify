local RESOURCE = GetCurrentResourceName()
local VERSION = GetResourceMetadata(RESOURCE, 'version', 0) or '1.0.0'
local detectedFramework = 'standalone'
local uiReady = false
local pending = {}

local validPositions = {
    ['top-right'] = true,
    ['top-left'] = true,
    ['bottom-right'] = true,
    ['bottom-left'] = true
}

local maxDuration = math.max(1000, math.min(math.floor(tonumber(Config.MaxDuration) or 15000), 2147483647))
local defaultDuration = math.max(1000, math.min(math.floor(tonumber(Config.DefaultDuration) or 5000), maxDuration))
local maxVisible = math.max(1, math.floor(tonumber(Config.MaxVisible) or 5))
local position = validPositions[Config.Position] and Config.Position or 'top-right'

local function resolveFramework()
    local configured = tostring(Config.Framework or 'auto'):lower()

    if configured == 'qbox' then
        return 'qbox'
    end

    if configured == 'esx' then
        return 'esx'
    end

    if configured == 'standalone' then
        return 'standalone'
    end

    if GetResourceState('qbx_core') == 'started' then
        return 'qbox'
    end

    if GetResourceState('es_extended') == 'started' then
        return 'esx'
    end

    return 'standalone'
end

local function labelFor(notificationType)
    local entry = Config.Types and Config.Types[notificationType]

    if type(entry) == 'table' and entry.label ~= nil then
        return tostring(entry.label)
    end

    return string.upper(notificationType)
end

local function typeIsValid(notificationType)
    return Config.Types ~= nil and Config.Types[notificationType] ~= nil
end

local function clampDuration(value)
    local numeric = math.floor(tonumber(value) or defaultDuration)
    return math.max(1000, math.min(numeric, maxDuration))
end

local function sendNotification(payload)
    if uiReady then
        SendNUIMessage({
            action = 'qavrin:notify',
            data = payload
        })
        return
    end

    pending[#pending + 1] = payload

    if #pending > 50 then
        table.remove(pending, 1)
    end
end

local function notify(data, description, duration)
    local options = data

    if type(options) ~= 'table' then
        options = {
            type = data,
            description = description,
            duration = duration
        }
    end

    local notificationType = tostring(options.type or 'info'):lower()

    if not typeIsValid(notificationType) then
        notificationType = 'info'
    end

    sendNotification({
        type = notificationType,
        title = tostring(options.title or labelFor(notificationType)),
        description = tostring(options.description or options.message or ''),
        duration = clampDuration(options.duration)
    })
end

local function sendConfig()
    SendNUIMessage({
        action = 'qavrin:config',
        data = {
            position = position,
            maxVisible = maxVisible,
            defaultDuration = defaultDuration,
            maxDuration = maxDuration
        }
    })
end

local function flushPending()
    for index = 1, #pending do
        SendNUIMessage({
            action = 'qavrin:notify',
            data = pending[index]
        })
    end

    pending = {}
end

RegisterNUICallback('qavrinReady', function(_, callback)
    uiReady = true
    sendConfig()
    flushPending()
    callback({ ok = true })
end)

exports('Notify', notify)
exports('ShowNotification', notify)

RegisterNetEvent('qavrin_notify:client:Notify', function(data, description, duration)
    notify(data, description, duration)
end)

if Config.Commands and Config.Commands.enabled then
    RegisterCommand(Config.Commands.test or 'qnotify', function()
        notify({
            type = 'success',
            title = 'QAVRIN Notify',
            description = 'Notification system is working.',
            duration = 5000
        })
    end, false)

    RegisterCommand(Config.Commands.help or 'qnotifyhelp', function()
        notify({
            type = 'info',
            title = 'QAVRIN Notify',
            description = ('Framework: %s'):format(detectedFramework),
            duration = 5000
        })
    end, false)
end

detectedFramework = resolveFramework()

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == 'qbx_core' or resourceName == 'es_extended' then
        detectedFramework = resolveFramework()
    end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == 'qbx_core' or resourceName == 'es_extended' then
        detectedFramework = resolveFramework()
    end
end)

CreateThread(function()
    SendNUIMessage({ action = 'qavrin:hello' })
    Wait(500)
    detectedFramework = resolveFramework()
    print(('[%s] QAVRIN Notify v%s loaded (framework: %s)'):format(RESOURCE, VERSION, detectedFramework))
end)
