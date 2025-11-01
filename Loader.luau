if getgenv().Night then
    return
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local cloneref = cloneref or function(Reference: Instance): Instance
    return Reference
end

local HttpService: HttpService = cloneref(game:GetService("HttpService"))
local UserInputService: UserInputService = cloneref(game:GetService("UserInputService"))
local Players: Players = cloneref(game:GetService("Players"))

local LocalPlayer: Player = Players.LocalPlayer
local Camera: Camera = workspace.CurrentCamera

local BaseGit: string = "https://github.com/null-wtf/NewNight"
local NightInit: {[any]: any} = getgenv().NightInit or {}
local Night = {
    Version = "3.05",
    BaseGit = BaseGit,
    Scale = 0.9,
    Keybind = Enum.KeyCode.RightShift,
    Game = game.PlaceId,
    Mobile = false,
    Init = NightInit,
    Connections = {},
    CurrentConfig = {},
    OnUninject = Instance.new("BindableEvent"),
    Load = {
        Start = os.clock(),
        Time = 0,
        Loaded = false,
        LoadTips = {
            "Join our Discord discord.gg/PYVuXbZ7bV to chat, report bugs & give suggestions.",
            "Always use alts, moderators can ban you at any time!",
            "You can use LCTRL + scroll to zoom in & out.",
            "Modules not working properly? Try switching executors or reporting a bug here: discord discord.gg/PYVuXbZ7bV.",
            "Not satisfied with the free plan? You can always upgrade to Premium at our discord: discord.gg/PYVuXbZ7bV!",
            "Losing to another script in a fair fight? Tell us its name in here discord.gg/PYVuXbZ7bV and we'll improve.",
            "Want to get Premium for free? We're always looking for good editors & showcasers!"
        }
    },
    Directories = {
        "NewNight",
        "NewNight/Configs",
        "NewNight/Assets",
        "NewNight/Assets/Fonts",
        "NewNight/Assets/Icons"
    }
}

getgenv().Night = Night
table.insert(Night.Directories, "NewNight/Configs/"..tostring(Night.Game))
for i,v: string in Night.Directories do
    makefolder(v)
end

for i,v in NightInit do
    Night[i] = v
end

if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
    Night.Mobile = true

    if Camera then
        if 0.4 >= (Camera.ViewportSize.X / 1000) - 0.1 then
            Night.Scale = 0.4
        else
            Night.Scale = (Camera.ViewportSize.X / 1000) - 0.2
        end
    else
        Night.Scale = 0.5
    end
end

local function DownloadAsset(DownloadPath: string, Path: string): boolean
    if writefile then
        local Suc: boolean, Resp: string = pcall(game.HttpGet, game, BaseGit..DownloadPath)
        if Suc and Resp then
            return pcall(writefile, Path, Resp)
        end
    end

    return false
end

local function DownloadDirectory(DirectoryLink: string, SavePath: string): boolean
	if writefile and makefolder and http and http.request then
        local Suc: boolean, DirData = pcall(http.request, {
            Url = BaseGit..DirectoryLink,
            Method = "GET",
            Headers = {
                Accept = "application/json"
            }
        })

        if Suc and DirData then
            local Body: string? = DirData.Body
            if (DirData.Success or DirData.StatusCode == 200) and Body then
                local SucFormat: boolean, JSON: {[any]: any} = pcall(HttpService.JSONDecode, HttpService, Body)
                if SucFormat and JSON then
                    local Payload: {[any]: any} = JSON.payload
                    if Payload and Payload.tree then
                        local Items: {[any]: any} = Payload.tree.items
                        if Items then
                            for i,v in Items do
                                if v.contentType == "directory" then
                                    if makefolder then
                                        if (isfolder and not isfolder("NewNight/"..SavePath.."/"..v.name)) or not isfolder then
                                            pcall(makefolder, "NewNight/"..SavePath.."/"..v.name)
                                        end

                                        DownloadDirectory(DirectoryLink.."/"..v.name, SavePath.."/"..v.name)
                                    end
                                else
                                    if (isfile and (not isfile("NewNight/"..SavePath.."/"..v.name) or (Night.Version == "3.05" and not isfile("NewNight/Assets/UpdatedIcons.txt")))) or not isfile then
                                        DownloadAsset("/raw/refs/heads/main/"..v.path, "NewNight/"..SavePath.."/"..v.name)
                                    end
                                end
                            end

                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

DownloadDirectory("/tree/main/Assets", "Assets")
writefile("NewNight/Assets/UpdatedIcons.txt", "")
if Night.Dev then
    loadstring(readfile("NewNight/Library/Main.luau"))()
else
    loadstring(game:HttpGet("https://raw.githubusercontent.com/null-wtf/NewNight/refs/heads/main/Library/Main.luau"))()
end

if not Night.Assets or Night.Assets and (not Night.Assets.Connections or not Night.Assets.Functions) then
    warn("Failed to load assets")
    getgenv().Night = nil
    table.clear(Night)

    return
end

Night.Assets.Functions.DownloadDirectory = DownloadDirectory
Night.Assets.Functions.DownloadAsset = DownloadAsset

Night:LoadFile("Universal")
Night:LoadFile(Night.Game)

if queue_on_teleport then
    Night.Assets.Connections:Add(LocalPlayer.OnTeleport:Connect(function(State: Enum.TeleportState)
        if State == Enum.TeleportState.InProgress then
            local Data = string.format("getgenv().NightInit = {")
            local Wrote = false
            for i,v in Night.Init do
                if Wrote then
                    Data = Data..", "..tostring(i).." = "..tostring(v)
                else
                    Data = Data..tostring(i).." = "..tostring(v)
                end

                Wrote = true
            end

            queue_on_teleport(Data .. [[}
                if NightInit.Dev and isfile("NewNight/Loader.luau") then
                    loadstring(readfile("NewNight/Loader.luau"))()
                else
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/null-wtf/NewNight/refs/heads/main/Loader.luau"))()
                end
            ]])
        end
    end))
end

if isfile then
    local Updated: boolean = false
    if not isfile("NewNight/Version.dat") then
        writefile("NewNight/Version.dat", Night.Version)
        Updated = true
    else
        if readfile then
            local UserVersion: string = readfile("NewNight/Version.dat")
            if UserVersion ~= Night.Version then
                writefile("NewNight/Version.dat", Night.Version)
                Updated = true
            end
        end
    end

    if Updated then
        local Keybind = Night.Keybind
        if typeof(Keybind) == "EnumItem" then
            Keybind = Keybind.Name
        end

        task.delay(0.2, Night.CreateNotification, Night, {
            Title = "Updated to V"..Night.Version,
            Description = string.format("Press %s to toggle the GUI", Keybind),
            Duration = 5
        })
    end
end

Night.Load.Loaded = true
Night.Load.Time = os.clock() - Night.Load.Start
local LoadTime: string = string.format("%.1fs", Night.Load.Time)
Night:CreateNotification({
    Title = "Night Loaded in " .. LoadTime,
    Description = Night.Load.LoadTips[math.random(1, #Night.Load.LoadTips)],
    Duration = 3
})
