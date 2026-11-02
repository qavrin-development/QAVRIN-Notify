local RESOURCE = GetCurrentResourceName()
local GITHUB_API = 'https://api.github.com/repos/qavrin-development/QAVRIN-Notify/releases/latest'
local RELEASES_URL = 'https://github.com/qavrin-development/QAVRIN-Notify/releases'

local function parseVersion(value)
    if type(value) ~= 'string' then
        return nil
    end

    local major, minor, patch = value:match('^[vV]?(%d+)%.(%d+)%.(%d+)$')
    if not major then
        return nil
    end

    return {
        tonumber(major),
        tonumber(minor),
        tonumber(patch)
    }
end

local function compareVersions(latest, installed)
    local remote = parseVersion(latest)
    local localVersion = parseVersion(installed)

    if not remote or not localVersion then
        return nil
    end

    for index = 1, 3 do
        if remote[index] > localVersion[index] then
            return 1
        end

        if remote[index] < localVersion[index] then
            return -1
        end
    end

    return 0
end

CreateThread(function()
    Wait(5000)

    if Config.EnableVersionCheck == false then
        print('^3[QAVRIN Notify] Version check is disabled in config.lua.^7')
        return
    end

    local installedVersion = GetResourceMetadata(RESOURCE, 'version', 0)
    if type(installedVersion) ~= 'string' or installedVersion == '' then
        print('^1[QAVRIN Notify] Could not read the installed resource version.^7')
        return
    end

    print(('^5[QAVRIN Notify] Checking GitHub for updates (installed: %s)...^7')
        :format(installedVersion))

    PerformHttpRequest(GITHUB_API, function(statusCode, responseBody)
        if statusCode ~= 200 or type(responseBody) ~= 'string' then
            if statusCode == 404 then
                print('^3[QAVRIN Notify] No published GitHub release was found yet. Publish a release to enable update checks.^7')
            elseif statusCode == 403 then
                print('^3[QAVRIN Notify] GitHub rate limit reached. Update check skipped; try again after the limit resets.^7')
            else
                print(('^3[QAVRIN Notify] Update check unavailable (HTTP %s). Your resource will continue working.^7')
                    :format(tostring(statusCode)))
            end
            return
        end

        local decoded, release = pcall(json.decode, responseBody)
        if not decoded or type(release) ~= 'table' or type(release.tag_name) ~= 'string' then
            print('^3[QAVRIN Notify] GitHub returned an invalid release response. Update check skipped.^7')
            return
        end

        local latestVersion = release.tag_name
        local comparison = compareVersions(latestVersion, installedVersion)

        if comparison == nil then
            print(('^3[QAVRIN Notify] Cannot compare version tags (%s). Use tags like v1.0.0.^7')
                :format(latestVersion))
            return
        end

        if comparison > 0 then
            local releaseUrl = type(release.html_url) == 'string' and release.html_url or RELEASES_URL

            print('^3====================================================^7')
            print('^3[QAVRIN Notify] A NEW VERSION IS AVAILABLE!^7')
            print(('^7Installed version: %s'):format(installedVersion))
            print(('^2Latest version:    %s'):format(latestVersion))
            print(('^2Download: %s'):format(releaseUrl))
            print('^3====================================================^7')
        elseif comparison == 0 then
            print(('^2[QAVRIN Notify] You are up to date (version %s).^7')
                :format(installedVersion))
        else
            print(('^2[QAVRIN Notify] Installed version %s is newer than the latest published release %s.^7')
                :format(installedVersion, latestVersion))
        end
    end, 'GET', '', {
        ['Accept'] = 'application/vnd.github+json',
        ['User-Agent'] = 'QAVRIN-Notify-Version-Checker'
    })
end)
