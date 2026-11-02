Config = {}

Config.Framework = 'auto'

-- Check the latest published GitHub release at resource startup.
-- Set to false to disable the version checker.
Config.EnableVersionCheck = true
Config.DefaultDuration = 5000
Config.MaxDuration = 15000
Config.Position = 'top-right'
Config.MaxVisible = 5

Config.Commands = {
    enabled = true,
    test = 'qnotify',
    help = 'qnotifyhelp'
}

Config.Types = {
    success = { label = 'SUCCESS' },
    info = { label = 'INFO' },
    warning = { label = 'WARNING' },
    error = { label = 'ERROR' }
}
