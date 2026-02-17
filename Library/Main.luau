local Night: {[string]: any} = getgenv().Night
local DefaultConfig: {[string]: any} = {
    ConfigName = "Default",
    Modules = {},
    Sliders = {},
    ColorSliders = {},
    Dropdowns = {},
    TextBoxes = {},
    Keybinds = {},
    MiniToggles = {},
    Others = {
        MobileButtonPosition = {},
        TabData = {}
    }
}

local function DeepClone(Clone: {[any]: any})
    local RealClone = table.clone(Clone)
    for i,v in RealClone do
        if typeof(v) == "table" then
            RealClone[i] = DeepClone(v)
        end
    end

    return RealClone
end

Night.CurrentConfig = DeepClone(DefaultConfig)
local cloneref = cloneref or function(Reference: Instance): Instance
    return Reference
end

local Players : Players = cloneref(game:GetService("Players"))
local TweenService : TweenService = cloneref(game:GetService("TweenService"))
local HttpService : HttpService = cloneref(game:GetService("HttpService"))
local Workspace : Workspace = cloneref(game:GetService("Workspace"))
local UserInputService : UserInputService = cloneref(game:GetService("UserInputService"))
local TextService: TextService = cloneref(game:GetService("TextService"))

local RequestFunc = (request or http and http.request)
local Camera: Camera = Workspace.CurrentCamera
local LocalPlayer : Player = Players.LocalPlayer

local Assets = {}
local UIData = {
    UIOpen = false,
    Windows = {
        Windows = {},
        Dragging = nil :: Frame?,
        DraggingSpeed = 0.05
    },
    TargetHud = nil,
    DashButtons = {},
    MobileButtons = {},
    Notifications = {},
    ConfigButtons = {},
    ArrayListEntries = {},
    CustomizableItems = {
        Modules = {} :: {any},
        Other = {} :: {any}
    },
    Theme = {
        ModuleTheme = {Color3.fromRGB(26, 95, 181), Color3.fromRGB(21, 80, 152)},
        Other = Color3.fromRGB(26, 95, 181)
    },
    NotificationsSettings = {
        All = true,
        Modules = true,
        Other = true,
        Alignment = "Bottom"
    },
    Icons = {
        Configs = "rbxassetid://8992031246" :: string,
        Close = "rbxassetid://17895651193" :: string,
        Settings = "rbxassetid://8992031056" :: string,
        TabSettings = "rbxassetid://75988696107576" :: string,
        Arrow = "rbxassetid://11421095840" :: string,
        Config = "rbxassetid://8992030918" :: string,
        Trash = "rbxassetid://10747362241" :: string,
        Combat = "rbxassetid://104133331585248" :: string,
        Movement = "rbxassetid://121899433518557" :: string,
        Render = "rbxassetid://127386420152841" :: string,
        Utility = "rbxassetid://110186208471082" :: string,
        Premium = "rbxassetid://94522713973114" :: string
    },
    Fonts = {
        BuilderExtended = {Checked = false, Font = "rbxassetid://16658237174"},
        BuilderSans = {Checked = true, Font = "rbxasset://fonts/families/BuilderSans.json"},
        BuilderMono = {Checked = false, Font = "rbxassetid://16658246179"}
    },
    InputFuncs = {
        Changed = function(Input: InputObject) end,
        Ended = function(Input: InputObject) end
    }
}

Night.UIData = UIData
Night.Assets = Assets

local UIScale: UIScale = Instance.new("UIScale")
UIScale.Scale = Night.Scale

do
    Assets.Functions = {}
    Assets.Functions.cloneref = cloneref
    Assets.Functions.DeepClone = DeepClone
    Assets.Functions.clonefunction = clonefunction or function(func: () -> ()) : () -> ()
        return func
    end

    Assets.Functions.gethui = gethui or function(): PlayerGui?
        return LocalPlayer:FindFirstChildWhichIsA("PlayerGui")
    end

    Assets.Functions.newcclosure = newcclosure and Assets.Functions.clonefunction(newcclosure) or function(func: () -> ())
        return func
    end

    function Assets.Functions:SearchTable(Search: {}, Value: any, Searched: {}, Results: {})
        Searched = Searched or {}
        Results = Results or {}

        for i,v in next, Search do
            if typeof(v) == "table" then
                if not table.find(Searched, v) then
                    table.insert(Searched, v)
                    Assets.Functions:SearchTable(v, Value, Searched, Results)
                end
            else
                local OldMT = nil
                if typeof(v) == "userdata" and getrawmetatable and getrawmetatable(v) and setrawmetatable then
                    OldMT = getrawmetatable(v)
                    setrawmetatable(v, {})
                end

                if tostring(v):lower() == Value then
                    table.insert(Results, v)
                else
                    if OldMT then
                        setrawmetatable(v, OldMT)
                    end
                end
            end

            if typeof(i) == "table" then
                if not table.find(Searched, i) then
                    table.insert(Searched, i)
                    Assets.Functions:SearchTable(i, Value, Searched, Results)
                end
            else
                local OldMT = nil
                if typeof(i) == "userdata" and getrawmetatable and getrawmetatable(i) and setrawmetatable then
                    OldMT = getrawmetatable(i)
                    setrawmetatable(i, {})
                end

                if tostring(i):lower() == Value then
                    table.insert(Results, i)
                else
                    if OldMT then
                        setrawmetatable(i, OldMT)
                    end
                end
            end
        end
        
        return Results
    end

    function Assets.Functions:IsAlive(Player: Player | Model, IsCharacter: boolean?): boolean
        if (not IsCharacter and Player and Player.Character) or IsCharacter then
            local Char: Model = Player
            if not IsCharacter then
                Char = Char.Character
            end

            local Humanoid = Char:FindFirstChild("Humanoid") :: Humanoid
            if Humanoid and (Humanoid:GetState() ~= Enum.HumanoidStateType.Dead or Humanoid.Health > 0.05) then
                if Char.PrimaryPart then
                    return true
                end
            end
        end

        return false
    end

    function Assets.Functions:GetDistanceFrom(Point: Vector3, To: Vector3, IgnoreY: boolean?): number
        if not IgnoreY then
            return (Point - To).Magnitude
        else
            return (Point - Vector3.new(To.X, Point.Y, To.Z)).Magnitude
        end
    end

    function Assets.Functions:GetClosestPlayer(Data: {Player: Player, TeamCheck: boolean?}): { Distance: number, Player: Player? }
        local RealData = {
            Player = nil,
            Distance = math.huge
        }

        if not Data.Player then
            Data.Player = LocalPlayer
        end

        if Assets.Functions:IsAlive(Data.Player) then
            for i,v : Player in Players:GetPlayers() do
                if Assets.Functions:IsAlive(v) and v ~= LocalPlayer and (Data.TeamCheck and v.Team and v.Team ~= Data.Player.Team or not v.Team or not Data.TeamCheck) then
                    local Root: BasePart = v.Character.PrimaryPart
                    local PlayerRoot: BasePart = Data.Player.Character.PrimaryPart

                    local Distance: number = Assets.Functions:GetDistanceFrom(PlayerRoot.Position, Root.Position)
                    if RealData.Distance >= Distance then
                        RealData = {
                            Player = v,
                            Distance = Distance
                        }
                    end
                end
            end
        end

        return RealData
    end

    function Assets.Functions:GetNerestPlayerToMouse(Data: {TeamCheck: boolean, Distance: number?, Exclude: {}?, Extras: {}?, Targets: {Players: boolean, Npcs: boolean}?}): { DistanceFromMouse: number, DistanceFromPlayer: number, Player: Player?, Character: Model?}
        local RealData = {
            Character = nil,
            Player = nil,
            DistanceFromMouse = math.huge,
            DistanceFromPlayer = math.huge
        }

        if not Data.Exclude then 
            Data.Exclude = {}
        end

        if not Data.Targets then
            Data.Targets = {
                Players = true,
                Npcs = true
            }
        end

        if not Data.Distance then
            Data.Distance = math.huge
        end

        local AllEntities = {}
        for i,v in Players:GetPlayers() do
            table.insert(AllEntities, v.Character)
        end

        if Data.Extras then
            for i,v in Data.Extras do
                table.insert(AllEntities, v)
            end
        end

        local Mouse: Mouse = LocalPlayer:GetMouse()
        if Mouse and Assets.Functions:IsAlive(LocalPlayer) then 
            for i,v : Model? in AllEntities do
                if Assets.Functions:IsAlive(v, true) and not table.find(Data.Exclude, v) then
                    local Player: Player = Players:GetPlayerFromCharacter(v)
                    if ((Data.Targets.Players and Player) or (Data.Targets.Npcs and not Player)) then
                        if Player and table.find(Data.Exclude, Player) then
                            continue
                        end

                        if Data.TeamCheck and (not Player or not Player.Team or Player.Team == LocalPlayer.Team) then
                            continue
                        end

                        local Root: BasePart = v.PrimaryPart
                        local MousePos: Vector3 = Mouse.Hit.Position
                        local MouseDistance: number = Assets.Functions:GetDistanceFrom(MousePos, Root.Position)
                        local PlayerDistance: number = Assets.Functions:GetDistanceFrom(LocalPlayer.Character.PrimaryPart.Position, Root.Position)

                        if RealData.DistanceFromMouse >= MouseDistance and Data.Distance >= MouseDistance then
                            RealData = {
                                Character = v,
                                Player = Player,
                                DistanceFromMouse = MouseDistance,
                                DistanceFromPlayer = PlayerDistance
                            }
                        end
                    end
                end
            end
        end

        return RealData
    end

    function Assets.Functions:GetTextBounds(Text: string, Font: Font, Size: number): Vector2
        local Params = Instance.new("GetTextBoundsParams")
        Params.Text = Text
        Params.Font = Font
        Params.Size = Size
        Params.Width = 1e9
        Params.RichText = false
        
        return TextService:GetTextBoundsAsync(Params)
    end

    function Assets.Functions:ConvertColor3toInt(RGB: Color3): {B: number, G: number, R: number}
        local R: number = math.floor(RGB.R * 255)
        local G: number = math.floor(RGB.G * 255)
        local B: number = math.floor(RGB.B * 255)

        return {R = R, G = G, B = B}
    end

    function Assets.Functions:LoadAsset(Name: string): string
        local path = "NewNight/Assets/Icons/"..Name..".png"
        local icon = ""
        if isfile and isfile(path) and getcustomasset then
            icon = getcustomasset(path)
        elseif UIData.Icons[Name] then
            icon = UIData.Icons[Name]
        end

        if not icon then
            if Name:find("rbxasset") or  Name:find("roblox.com") then
                icon = Name
            end
        end
        return icon
    end

    function Assets.Functions:GetFont(Name: string, Faces: {{Name: string, Weight: number, File: string}}): string
        local Font = UIData.Fonts[Name]
        if Font and Font.Checked or not getcustomasset or not writefile then
            return Font.Font
        end

        local FontFamily = {name = Name, faces = {}}
        for i,v in Faces do
            local FontPath = "NewNight/Assets/Fonts/"..v.File..".otf"
            if isfile and isfile(FontPath) then
                local Face = {
                    name = v.Name,
                    weight = v.Weight,
                    style = "normal",
                    assetId = getcustomasset(FontPath),
                }

                table.insert(FontFamily.faces, Face)
            else
                if Font then
                    return Font.Font
                end
            end
        end

        writefile("NewNight/Assets/Fonts/"..Name..".json", HttpService:JSONEncode(FontFamily))
        local id = getcustomasset("NewNight/Assets/Fonts/"..Name..".json")
        UIData.Fonts[Name] = {
            Checked = true,
            Font = id
        }

        return id
    end

    function Assets.Functions:Drag(Data: {Window: Frame, StartInputPos: Vector3, FrameStartPos: UDim2}, input: InputObject?)
        local Viewport : Vector2 = Camera.ViewportSize
        local Delta : Vector2 = Vector2.new(0, 0)
        local MouseStart : Vector3 = Data.StartInputPos
        local FrameStart : UDim2 = Data.FrameStartPos

        if FrameStart then
            if MouseStart and input then
                Delta = (Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(MouseStart.X, MouseStart.Y))
            end

            local XVal: number = FrameStart.X.Scale + (Delta.X / (Viewport.X / (Data.Window.Size.X.Scale + 0.8)))
            local YVal: number = FrameStart.Y.Scale + (Delta.Y / (Viewport.Y / 0.8))

            TweenService:Create(Data.Window, TweenInfo.new(UIData.Windows.DraggingSpeed), {Position = UDim2.fromScale(XVal, YVal)}):Play()
        end
    end

    Assets.Connections = {}
    function Assets.Connections:Add(Connection: RBXScriptConnection | thread | () -> (), AddTo: { {any} }): { Connection: RBXScriptConnection, Disconnect: () -> () }
        AddTo = AddTo or {}
        local ConnectionData = {
            Connection = Connection :: RBXScriptConnection | thread | () -> (),
            Disconnect = nil :: () -> ()?
        }

        if not table.find(AddTo, Night.Connections) then
            table.insert(AddTo, Night.Connections)
        end

        for i,v : {} in AddTo do
            if typeof(v) == "table" and not table.find(v, ConnectionData) then
                table.insert(v, ConnectionData)
            end
        end

        function ConnectionData:Disconnect()
            if typeof(Connection) == "RBXScriptConnection" then
                Connection:Disconnect()
            elseif typeof(Connection) == "thread" then
                task.cancel(Connection)
            elseif typeof(Connection) == "function" then
                Connection()
            end

            task.delay(0.1, function()
                for i,v in AddTo do
                    if typeof(v) == "table" and v ~= Night.Connections then
                        local ConFind = table.find(v, ConnectionData)
                        if ConFind then
                            table.remove(v, ConFind)
                        end
                    end
                end

                table.clear(ConnectionData)
            end)
        end

        return ConnectionData
    end

    function Assets.Connections:DisconnectAll()
        for i,v : {Connection: RBXScriptConnection | thread, Disconnect: (self: any) -> ()} in Night.Connections do
            if v and v.Disconnect then
                v:Disconnect()
            end
        end

        table.clear(Night.Connections)
    end
   
    Assets.Config = {}
    Assets.ArrayList = {}
    function Assets.Config:Save(Data: {}, Path: string, Directories: {}?): boolean
        local Suc, NewData = pcall(HttpService.JSONEncode, HttpService, Data)
        if not isfolder("NewNight/Configs") then
            makefolder("NewNight/Configs")
        end

        if Suc and NewData and writefile and makefolder then
            if Directories then
                for i,v in Directories do
                    if not isfolder("NewNight/Configs/"..v) then
                        makefolder("NewNight/Configs/"..v)
                    end
                end
            end

            writefile("NewNight/Configs/"..Path..".json", NewData)
            return true
        end

        return false
    end

    function Assets.Config:Load(Config: string): boolean
        local _, NewData = true, DeepClone(DefaultConfig)
        if isfile and isfile("NewNight/Configs/"..Config..".json") and readfile then
            _, NewData = pcall(HttpService.JSONDecode, HttpService, readfile("NewNight/Configs/"..Config..".json"))
        end


        -- sigma ud load 💯💯
        for i,v in NewData do
            if Night.CurrentConfig[i] then
                Night.CurrentConfig[i] = v        
            end
        end

        for i, v in UIData.Windows.Windows do
            if i ~= "MainTabWindow" then
                local Button = UIData.DashButtons[i]
                if Button then
                    if Button.Selected then
                        Button:Toggle(false, false)
                    end
                else
                    if v.Window.Visible then
                        v.Window.Visible = false
                    end
                end

                v.Window.Position = v.Data.Position
            end

            for i2, v2 in v.Modules.Modules do
                local ModuleValue = NewData.Modules[i2]
                if ModuleValue == nil then
                    if v2.Data.Default then
                        ModuleValue = v2.Data.Default
                    else
                        ModuleValue = false
                    end
                end

                v2:ToggleSettings(false)
                v2:SetValue(false, false, false)
                for i3, v3 in v2.Settings do
                    local Section = NewData[i3]
                    if Section then
                        for i4, v4 in v3 do
                            if v4.SetValue then
                                local Value = Section[i4]
                                if Value == nil then
                                    if v4.Data.Default then
                                        Value = v4.Data.Default
                                        if typeof(Value) == "Color3" then
                                            Value = Assets.Functions:ConvertColor3toInt(Value)
                                        end
                                    end
                                end

                                if i3 == "Dropdowns" then
                                    v4:ToggleSideMenu(false)
                                elseif i3 == "Keybinds" then
                                    if not Night.Mobile and Value == "Button" then
                                        Value = v4.Data.Default
                                    end
                                end

                                if Value == nil then
                                    Value = false
                                end
                                
                                v4:SetValue(Value, false, true)
                            end
                        end
                    end
                end

                v2:SetValue(ModuleValue, false, false, true)
            end
        end

        for i,v in NewData.Others do
            if i == "TabData" then
                for i2, v2 in v do
                    local Window = UIData.Windows.Windows[i2]
                    if Window then
                        local Pos = v2.Position
                        local Visible = v2.Visible

                        if Pos then
                            Window.Window.Position = UDim2.fromScale(table.unpack(Pos)) 
                        end

                        local Button = UIData.DashButtons[i2]
                        if Visible then
                            if Button then
                                Button:Toggle(Visible)
                            else
                                Window.Window.Visible = Visible
                            end
                        end
                    end
                end
            end
        end

        task.delay(0.3, function()
            for i,v in UIData.CustomizableItems.Other do
                if v.CanChange then
                    if v.Item:IsA("Frame") or v.ChangeBackground then
                        v.Item.BackgroundColor3 = UIData.Theme.Other
                    elseif v.Item:IsA("ImageButton") or v.Item:IsA("ImageLabel") then
                        v.Item.ImageColor3 = UIData.Theme.Other
                    elseif v.Item:IsA("TextLabel") or v.Item:IsA("TextButton") or v.Item:IsA("TextBox") then
                        v.Item.TextColor3 = UIData.Theme.Other
                    end
                end
            end
        end)

        for i,v: {Main: boolean, Gradient: UIGradient} in UIData.CustomizableItems.Modules do
            if v.Main then
                v.Gradient.Color =  ColorSequence.new({ColorSequenceKeypoint.new(0, UIData.Theme.ModuleTheme[1]), ColorSequenceKeypoint.new(1, UIData.Theme.ModuleTheme[2])})
            else
                local RGB, RGB2 = Assets.Functions:ConvertColor3toInt(UIData.Theme.ModuleTheme[1]), Assets.Functions:ConvertColor3toInt(UIData.Theme.ModuleTheme[2])
                local Gradients = {
                    [1] = {
                        math.clamp(RGB.R - 7, 0, 255), 
                        math.clamp(RGB.G - 24, 0, 255), 
                        math.clamp(RGB.B - 46, 0, 255)
                    },
                    [2] = {
                        math.clamp(RGB2.R - 5, 0, 255), 
                        math.clamp(RGB2.G - 19, 0, 255), 
                        math.clamp(RGB2.B - 37, 0, 255)
                    }
                }

                v.Gradient.Color =  ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(table.unpack(Gradients[1]))), ColorSequenceKeypoint.new(1, Color3.fromRGB(table.unpack(Gradients[2])))})
                table.clear(Gradients)
            end
        end
        return true
    end

    function Assets.Functions:LoadFile(Game: string, LoadConfig: boolean?, Premium: boolean?)
        local Path: string = "NewNight/Games/"..tostring(Game)..".luau"
        local PremiumPath: string = "NewNight/Premium/Games/"..tostring(Game)..".luau"

        if LoadConfig == nil then
            LoadConfig = true
        end

        local suc, err = pcall(function()
            if Night.Dev and isfile and isfile(Path) and readfile then
                loadstring(readfile(Path))()
            else
                if RequestFunc then
                    local Req = RequestFunc({
                        Url = "https://raw.githubusercontent.com/null-wtf/NewNight/refs/heads/main/Games/"..Game..".luau",
                        Method = "GET"
                    })

                    if Req.Success then
                        loadstring(Req.Body)()
                    end
                end
            end
        end)

        if not suc then
            return Assets.Functions:CreateNotification({
                Title = "Failed to load file: "..tostring(Game),
                Description = "Failed to load file: "..tostring(Game)..": "..err
            })
        end

        if Night.Premium and Game ~= "Universal" then
            local suc2, err2 = pcall(function()
                if Night.Dev and isfile and isfile(PremiumPath) and readfile then
                    loadstring(readfile(PremiumPath))()
                else
                    if RequestFunc then
                        local Req = RequestFunc({
                            Url = "https://raw.githubusercontent.com/null-wtf/NewNight/refs/heads/main/Premium/Games/"..Game..".luau",
                            Method = "GET"
                        })

                        if Req.Success then
                            loadstring(Req.Body)()
                        end
                    end
                end
            end)

            if not suc2 then
                return Assets.Functions:CreateNotification({
                    Title = "Failed to load premium file: "..tostring(Game),
                    Description = "Failed to load premium file: "..tostring(Game)..": "..err2
                })
            end
        end

        if LoadConfig and not table.find(Night.IgnoreConfigs, tostring(Game)) then
            local ConfigPath: string = tostring(Game)
            if not isfolder("NewNight/Configs/"..ConfigPath) and not table.find(Night.IgnoreConfigs, tostring(Night.Game)) then
                ConfigPath = tostring(Night.Game)
            end

            if ConfigPath then
                if isfile("NewNight/Configs/"..ConfigPath.."/LastUsed.txt") then
                    ConfigPath = ConfigPath.."/"..readfile("NewNight/Configs/"..ConfigPath.."/LastUsed.txt")
                else
                    ConfigPath = ConfigPath.."/Default"
                    writefile("NewNight/Configs/"..ConfigPath.."/LastUsed.txt", "Default")
                end
            end

            if ConfigPath then
                Assets.Config:Load(ConfigPath)
            end
        end

        return
    end
end

local MainScreenGui: ScreenGui = Instance.new("ScreenGui", Assets.Functions.gethui())
MainScreenGui.ClipToDeviceSafeArea = true
MainScreenGui.IgnoreGuiInset = true
MainScreenGui.ResetOnSpawn = false
MainScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
UIScale.Parent = MainScreenGui

local Background: Frame = Instance.new("Frame", MainScreenGui)
Background.Size = UDim2.fromScale(1.2, 1.1)
Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Background.BackgroundTransparency = 0.7
Background.BorderSizePixel = 0

local MobileButtonHolder: Frame = Background:Clone()
MobileButtonHolder.Parent = MainScreenGui
MobileButtonHolder.BackgroundTransparency = 1

local NotificationHolder: Frame = Instance.new("Frame", MainScreenGui)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.BorderSizePixel = 0
NotificationHolder.Position = UDim2.fromScale(0, 0)
NotificationHolder.Size = UDim2.fromScale(1, 1)
NotificationHolder.ZIndex = 1000

local ArrayListHolder: Frame = Instance.new("Frame", MainScreenGui)
ArrayListHolder.BackgroundTransparency = 1
ArrayListHolder.BorderSizePixel = 0
ArrayListHolder.AnchorPoint = Vector2.new(1, 0)
ArrayListHolder.Position = UDim2.new(1, -10, 0, 10)
ArrayListHolder.Size = UDim2.new(0.5, 0, 1, -10)
ArrayListHolder.ZIndex = 1000

Assets.ArrayList.Font = Font.new(Assets.Functions:GetFont("ProductSans", {{
    Name = "Regular",
    Weight = 600,
    File = "Product-Sans-Regular",
}}), Enum.FontWeight.Regular)

Assets.ArrayList.TextSize = (Night.Mobile and 16) or 18
Assets.ArrayList.Color = Color3.fromRGB(255, 255, 255)

function Assets.ArrayList:Sort()
    table.sort(UIData.ArrayListEntries, function(a, b)
        local TotalTextA = a.Name
        local TotalTextB = b.Name
        
        local SizeA = Assets.Functions:GetTextBounds(TotalTextA, Assets.ArrayList.Font, Assets.ArrayList.TextSize)
        local SizeB = Assets.Functions:GetTextBounds(TotalTextB, Assets.ArrayList.Font, Assets.ArrayList.TextSize)

        return SizeA.X > SizeB.X
    end)
    
    for i,v in UIData.ArrayListEntries do
        if v.Instances.Main then
            if v.Instances.Main.Position.X.Scale > 1 then
                v.Instances.Main.Position = UDim2.new(v.Instances.Main.Position.X.Scale, 0, 0, (Assets.ArrayList.TextSize + 6) * i)
            end

            TweenService:Create(v.Instances.Main, TweenInfo.new(0.2), {Position =  UDim2.new(1, 0, 0, (Assets.ArrayList.TextSize + 6) * i)}):Play()
        end
    end
end

function Assets.ArrayList:SetColor(Color: Color3)
    for i,v in UIData.ArrayListEntries do
        if v.Instances.Line and v.Instances.Text then
            v.Instances.Line.BackgroundColor3 = Color
            v.Instances.Text.TextColor3 = Color
        end
    end
end

function Assets.ArrayList:Push(Name: string)
    local Data = {
        Name = Name,
        Instances = {
            Main = nil,
            Text = nil,
            Line = nil
        }
    }

    local MainSize: Vector2 = Assets.Functions:GetTextBounds(Name, Assets.ArrayList.Font, Assets.ArrayList.TextSize)

    local MainFrame: Frame = Instance.new("Frame", ArrayListHolder)
    MainFrame.BackgroundTransparency = 0.35
    MainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MainFrame.BorderSizePixel = 0
    MainFrame.Size = UDim2.fromOffset(MainSize.X + 14, Assets.ArrayList.TextSize + 6)
    MainFrame.LayoutOrder = #UIData.ArrayListEntries
    MainFrame.AnchorPoint = Vector2.new(1, 1)
    MainFrame.Position = UDim2.new(1.2, 0, 0, (Assets.ArrayList.TextSize + 6) * math.clamp(#UIData.ArrayListEntries, 1, math.huge))
    Data.Instances.Main = MainFrame

    local Line: Frame = Instance.new("Frame", MainFrame)
    Line.AnchorPoint = Vector2.new(1, 0)
    Line.BackgroundColor3 = Assets.ArrayList.Color
    Line.Size = UDim2.new(0, 2, 1, 0)
    Line.Position = UDim2.fromScale(1, 0)
    Line.BorderSizePixel = 0
    Data.Instances.Line = Line

    local MainText: TextLabel = Instance.new("TextLabel", MainFrame)
    MainText.BackgroundTransparency = 1
    MainText.FontFace = Assets.ArrayList.Font
    MainText.Text = Name
    MainText.TextColor3 = Assets.ArrayList.Color
    MainText.TextSize = Assets.ArrayList.TextSize
    MainText.TextXAlignment = Enum.TextXAlignment.Left
    MainText.Size = UDim2.new(0, MainSize.X, 1, 0)
    Data.Instances.Text = MainText
    Instance.new("UIPadding", MainFrame).PaddingLeft = UDim.new(0, 6)

    function Data:Remove()
        local Tween: Tween = TweenService:Create(MainFrame, TweenInfo.new(0.2), {Position = UDim2.new(1.2, 0, 0, MainFrame.Position.Y.Offset)})
        local Index: number? = table.find(UIData.ArrayListEntries, Data)
        if Index then
            table.remove(UIData.ArrayListEntries, Index)
        end

        Tween:Play()
        Tween.Completed:Once(function() 
            MainFrame:Destroy(MainFrame)
        end)

        Assets.ArrayList:Sort()
    end

    table.insert(UIData.ArrayListEntries, Data)

    Assets.ArrayList:Sort()
    return Data
end

function Assets.Functions:Uninject()
    if Night.OnUninject then
        Night.OnUninject:Fire()
        Night.OnUninject:Destroy()
    end

    for i, v in UIData.Windows.Windows do
        for i2, v2 in v.Modules.Modules do
            v2:SetValue(false, false, false)
        end
    end

    Assets.Connections:DisconnectAll()
    MainScreenGui:Destroy()

    table.clear(Night)
    getgenv().Night = nil
end

local function CreateShadow(Obj: Instance): ImageLabel
    -- ima js do ts instead of pasting it 10 times
    local Shadow: ImageLabel = Instance.new("ImageLabel", Obj)
    Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    Shadow.BackgroundTransparency = 1
    Shadow.Position = UDim2.new(0.5, 0, 0.5, 2)
    Shadow.Size = UDim2.new(1, 127, 1, 127)
    Shadow.Image = Assets.Functions:LoadAsset("Shadow")
    Shadow.ImageColor3 = Color3.fromRGB(255, 255, 255)
    Shadow.ImageTransparency = 0.5
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(Vector2.new(85, 85), Vector2.new(427, 427))
    Shadow.SliceScale = 1

    return Shadow
end

function Assets.Functions:CreateMobileButton(Data: {Name: string, Flag: string, Events: {Began: (self: any, Input: InputObject) -> ()?, Ended: (self: any, Held: boolean, Input: InputObject) -> ()?}})
    local RealMobileButtonData = {
        Data = Data,
        DraggingData = {
            Active = false :: boolean,
            StartInputPos = nil :: Vector3?,
            FrameStartPos = nil :: UDim2?,
            Window = nil :: ImageButton?
        },
        Holding = false :: boolean,
        StartHold = nil :: number?,
        Functions = {},
        Connections = {}
    }

    local MainButton: ImageButton = Instance.new("ImageButton", MobileButtonHolder)
    MainButton.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
    MainButton.Position = UDim2.fromScale(Random.new(math.random(10000, 100000000)):NextNumber(0.5, 0.8), Random.new(math.random(10000, 100000000)):NextNumber(0.6, 0.7))
    MainButton.Size = UDim2.fromOffset(69, 61)
    MainButton.ZIndex = 2
    MainButton.AutoButtonColor = false
    MainButton.ImageTransparency = 1
    Instance.new("UICorner", MainButton).CornerRadius = UDim.new(0, 22)
    CreateShadow(MainButton)

    local ButtonText: TextLabel = Instance.new("TextLabel", MainButton)
    ButtonText.BackgroundTransparency = 1
    ButtonText.BorderSizePixel = 0
    ButtonText.AnchorPoint = Vector2.new(0.5, 0.5)
    ButtonText.Position = UDim2.fromScale(0.5, 0.5)
    ButtonText.Size = UDim2.fromOffset(54, 27)
    ButtonText.ZIndex = 2
    ButtonText.Font = Enum.Font.BuilderSansBold
    ButtonText.Text = Data.Name
    ButtonText.TextColor3 = Color3.fromRGB(210, 219, 219)
    ButtonText.TextScaled = true
    ButtonText.TextWrapped = true
    ButtonText.TextStrokeTransparency = 1

    local ButtonPosConfig = Night.CurrentConfig.Others.MobileButtonPosition[Data.Flag]
    if ButtonPosConfig then
        MainButton.Position = UDim2.fromScale(table.unpack(ButtonPosConfig))
    end

    function RealMobileButtonData.Functions:SetVisiblity(Visible: boolean)
        if Visible == nil then
            Visible = not MainButton.Visible
        end

        MainButton.Visible = Visible
    end

    function RealMobileButtonData.Functions:Destroy()
        for i,v in RealMobileButtonData.Connections do
            v:Disconnect()
        end

        table.clear(RealMobileButtonData)
        MainButton:Destroy()
    end

    Assets.Connections:Add(MainButton.InputBegan:Connect(function(Input: InputObject)
        if ((Input.UserInputType == Enum.UserInputType.MouseButton1) or (Input.UserInputType == Enum.UserInputType.Touch)) and not UIData.Windows.Dragging then
            RealMobileButtonData.StartHold = os.clock()
            RealMobileButtonData.Holding = true

            if RealMobileButtonData.Data.Events and RealMobileButtonData.Data.Events.Began then
                RealMobileButtonData.Data.Events.Began(RealMobileButtonData, Input)
            end

            UIData.InputFuncs.Ended = function(EndInput: InputObject)
                if (EndInput.UserInputType == Enum.UserInputType.MouseButton1) or (EndInput.UserInputType == Enum.UserInputType.Touch) then
                    if RealMobileButtonData.Data.Events and RealMobileButtonData.Data.Events.Ended then
                        RealMobileButtonData.Data.Events.Ended(RealMobileButtonData, RealMobileButtonData.DraggingData.Active, EndInput)
                    end

                    UIData.Windows.Dragging = nil
                    RealMobileButtonData.DraggingData = {
                        Active = false :: boolean,
                        StartInputPos = Input.Position :: Vector3,
                        FrameStartPos = MainButton.Position :: UDim2,
                        Window = MainButton :: ImageButton
                    }

                    for i,v in UIData.InputFuncs do
                        UIData.InputFuncs[i] = function() end
                    end
                    
                    RealMobileButtonData.Holding = false

                    Night.CurrentConfig.Others.MobileButtonPosition[Data.Flag] = {MainButton.Position.X.Scale, MainButton.Position.Y.Scale}
                    Assets.Config:Save(Night.CurrentConfig, tostring(Night.Game).."/"..tostring(Night.CurrentConfig.ConfigName), {tostring(Night.Game)})
                end
            end

            repeat task.wait() until os.clock() - RealMobileButtonData.StartHold >= 1.2 or not RealMobileButtonData.Holding
            if RealMobileButtonData.Holding then
                UIData.Windows.Dragging = MainButton
                RealMobileButtonData.DraggingData = {
                    Active = true :: boolean,
                    StartInputPos = Input.Position :: Vector3,
                    FrameStartPos = MainButton.Position :: UDim2,
                    Window = MainButton :: ImageButton
                }

                UIData.InputFuncs.Changed = function(ChangedInput: InputObject)
                    if (ChangedInput.UserInputType == Enum.UserInputType.MouseMovement or ChangedInput.UserInputType == Enum.UserInputType.Touch) then  
                        if RealMobileButtonData.DraggingData.Active then
                            Assets.Functions:Drag(RealMobileButtonData.DraggingData, ChangedInput)
                        end
                    end
                end
            end
        end
    end), {RealMobileButtonData.Connections})

    setmetatable(RealMobileButtonData, {
        __index = RealMobileButtonData.Functions
    })

    UIData.MobileButtons[Data.Flag] = RealMobileButtonData
    return RealMobileButtonData
end

function Assets.Functions:CreateNotification(Data: {Title: string, Description: string, Flag: string? | number?, Duration: number, Module: boolean?})
    local RealNotificationData = {
        Data = Data,
        Notification = nil :: Frame?,
        Functions = {},
        Tweens = {},
        StartTime = nil:: number?
    }

    if not UIData.NotificationsSettings.All then
        return
    end

    if not UIData.NotificationsSettings.Other and not Data.Module then
        return
    end

    local CurrentValues = 0
    for i,v in UIData.Notifications do
        local Noti: Frame? = v.Notification
        CurrentValues += 1
        if Noti then
            for i,v: Tween in v.Tweens do
                v:Cancel()
            end

            table.clear(v.Tweens)       
            local NewPos: number = Noti.Position.Y.Scale - 0.075
            if UIData.NotificationsSettings.Alignment == "Top" then
                NewPos = Noti.Position.Y.Scale + 0.075
            end

            local Tween = TweenService:Create(Noti, TweenInfo.new(0.2), {Position = UDim2.fromScale(Noti.Position.X.Scale, NewPos)})
            Tween:Play()

            table.insert(RealNotificationData.Tweens, Tween)
        end
    end

    if not RealNotificationData.Data.Flag then
        RealNotificationData.Data.Flag = math.random(100, 10000)
    end

    local Font = Font.new(Assets.Functions:GetFont("BuilderSans"), Enum.FontWeight.SemiBold)
    local Bounds = Assets.Functions:GetTextBounds(Data.Description, Font, 15).X
    local BoundsTitle = Assets.Functions:GetTextBounds(Data.Title, Font, 18).X
    local TitleBigger: boolean = false
    if BoundsTitle > Bounds then
        Bounds = BoundsTitle
        TitleBigger = true
    end

    local ShrinkText: boolean = false
    if Bounds > 900 then
        ShrinkText = true
        Bounds = 900
    elseif 160 > Bounds then
        Bounds = 160
    end

    local Notification: Frame = Instance.new("Frame", NotificationHolder)
    Notification.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
    Notification.AnchorPoint = Vector2.new(0.5, 0)
    Notification.Position = UDim2.fromScale(0.5, 0.925)
    Notification.Size = UDim2.fromOffset(Bounds + 45, 56)
    Notification.ZIndex = 1000
    Instance.new("UICorner", Notification).CornerRadius = UDim.new(0, 12)
    RealNotificationData.Notification = Notification
    CreateShadow(Notification)

    if UIData.NotificationsSettings.Alignment == "Top" then
        Notification.Position = UDim2.fromScale(0.5, 0.025)
    end

    local Title: TextLabel = Instance.new("TextLabel", Notification)
    Title.BackgroundTransparency = 1
    Title.BorderSizePixel = 0
    Title.AnchorPoint = Vector2.new(0.5, 0)
    Title.Position = UDim2.fromScale(0.5, 0.129)
    Title.Size = UDim2.fromOffset(Bounds, 19)
    Title.ZIndex = 1000
    Title.FontFace = Font
    Title.Text = Data.Title
    Title.TextColor3 = Color3.fromRGB(220, 220, 220)
    Title.TextSize = 18
    Title.TextWrapped = true
    Title.TextStrokeTransparency = 1

    local Description: TextLabel = Instance.new("TextLabel", Notification)
    Description.BackgroundTransparency = 1
    Description.AnchorPoint = Vector2.new(0.5, 0)
    Description.Position = UDim2.fromScale(0.5, 0.554)
    Description.Size = UDim2.fromOffset(Bounds, 14)
    Description.BorderSizePixel = 0
    Description.ZIndex = 1000
    Description.FontFace = Font
    Description.Text = Data.Description
    Description.TextColor3 = Color3.fromRGB(68, 78, 100)
    Description.TextSize = 15
    Description.TextWrapped = true
    Description.TextStrokeTransparency = 1
    UIData.Notifications[RealNotificationData.Data.Flag] = RealNotificationData

    if ShrinkText then
        if TitleBigger then
            Title.TextSize = 10
        end
        Description.TextSize = 12
    end

    function RealNotificationData.Functions:Destroy(Animation: boolean)
        table.clear(RealNotificationData)

        if Animation == nil then
            Animation = true
        end

        if Animation then
            local Value = 1
            if UIData.NotificationsSettings.Alignment == "Top" then
                Value = -1
            end

            local Tween = TweenService:Create(Notification, TweenInfo.new(0.15), {Position = UDim2.fromScale(Notification.Position.X.Scale, Value)})
            Tween:Play()
            
            local TCon 
            TCon = Tween.Completed:Connect(function()
                Notification:Destroy()
                TCon:Disconnect()
                TCon = nil
            end)
        else
            Notification:Destroy()
        end

        for i,v in UIData.Notifications do
            local Noti: Frame? = v.Notification
            CurrentValues += 1
            if Noti and Notification.Position.Y.Scale > Noti.Position.Y.Scale then
                if UIData.NotificationsSettings.Alignment == "Top" then
                    if Animation then
                        TweenService:Create(Noti, TweenInfo.new(0.2), {Position = UDim2.fromScale(Noti.Position.X.Scale, Noti.Position.Y.Scale - 0.075)}):Play()
                    else
                        Noti.Position = UDim2.fromScale(Noti.Position.X.Scale, Noti.Position.Y.Scale - 0.075)
                    end
                else
                    if Animation then
                        TweenService:Create(Noti, TweenInfo.new(0.2), {Position = UDim2.fromScale(Noti.Position.X.Scale, Noti.Position.Y.Scale + 0.075)}):Play()
                    else
                        Noti.Position = UDim2.fromScale(Noti.Position.X.Scale, Noti.Position.Y.Scale + 0.075)
                    end
                end
            end
        end
    end

    setmetatable(RealNotificationData, {
        __index = RealNotificationData.Functions
    })

    RealNotificationData.StartTime = os.clock()
    coroutine.wrap(function()
        -- idek ts is horrid
        repeat task.wait() until not RealNotificationData or not RealNotificationData.Notification or not RealNotificationData.StartTime or ((os.clock() - RealNotificationData.StartTime) >= RealNotificationData.Data.Duration)
        if RealNotificationData then
            RealNotificationData:Destroy()
        end
    end)()

    return RealNotificationData
end

local function CreateWindow(Data: {Name: string, Flag: string, Size: UDim2, Position: UDim2, AnchorPoint: Vector2?, DefaultPosition: UDim2, ClosePos: UDim2?, Icon: {Icon: string?, Size: UDim2?}?, Text: {Postion: UDim2?, Size: UDim2?}?, Dashboard: boolean?, Visible: boolean?, DashButton: any?, ZIndex: number?, OnClose: (self: any) -> ()?})
    local WindowData = {
        Data = Data,
        Window = nil :: Frame?,
        DefaultPos = nil :: UDim2?,
        DragData = {
            Dragging = false :: boolean,
            StartInputPos = nil :: Vector3?,
            FrameStartPos = Data.Position :: UDim2?,
            Window = nil :: Frame?
        },
        Dashboard = {
            ButtonHolder = nil :: Frame?,
            BottomButtonHolder = nil :: Frame?,
            Buttoncount = 0 :: number,
            BottomButtonCount = 0 :: number,
            LastLayout = 0 :: number,
            NextFirstButton = 0 :: number,
        },
        Modules = {
            Modules = {},
            Holder = nil :: ScrollingFrame?
        },
        Functions = {},
        Connections = {}
    }

    -- gotta do ts cuz lsp
    local TextSize: UDim2 = UDim2.fromOffset(123, 20)
    local TextPos: UDim2 = UDim2.fromScale(0.067, 0.359)
    if WindowData.Data.Text then
        if WindowData.Data.Text.Size then
            TextSize = WindowData.Data.Text.Size
        end

        if WindowData.Data.Text.Postion then
            TextPos = WindowData.Data.Text.Postion
        end
    end

    local Window: Frame = Instance.new("Frame", Background)
    Window.Size = Data.Size
    Window.Position = Data.Position
    Window.BackgroundColor3 = Color3.fromRGB(8, 10, 13)
    WindowData.Window = Window
    Instance.new("UICorner", Window).CornerRadius = UDim.new(0, 15)
    CreateShadow(Window)

    WindowData.DefaultPos = Data.DefaultPosition
    if Data.Visible ~= nil and typeof(Data.Visible) == "boolean" then 
        Window.Visible = Data.Visible
    end

    if Data.AnchorPoint then
        Window.AnchorPoint = Data.AnchorPoint
    end

    local Top: Frame = Instance.new("Frame", Window)
    Top.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
    Top.Size = UDim2.fromOffset(Data.Size.X.Offset, 59)
    Top.ZIndex = 2
    Instance.new("UICorner", Top).CornerRadius = UDim.new(0, 15)

    local CornerWorkAround: Frame = Instance.new("Frame", Top)
    CornerWorkAround.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
    CornerWorkAround.Position = UDim2.fromScale(0, 0.659)
    CornerWorkAround.Size = UDim2.fromOffset(Data.Size.X.Offset, 21)
    CornerWorkAround.BorderSizePixel = 0
    CornerWorkAround.ZIndex = 2

    local TopText = Instance.new("TextLabel", Top) :: TextLabel
    TopText.BackgroundTransparency = 1
    TopText.BorderSizePixel = 0
    TopText.Position = TextPos
    TopText.Size = TextSize
    TopText.Text = Data.Name
    TopText.TextColor3 = Color3.fromRGB(210, 219, 229)
    TopText.TextScaled = true
    TopText.TextStrokeTransparency = 1
    TopText.TextXAlignment = Enum.TextXAlignment.Left
    TopText.TextWrapped = true
    TopText.ZIndex = 2
    TopText.FontFace = Font.new(Assets.Functions:GetFont("BuilderExtended", {{
        Name = "SemiBold",
        Weight = 600,
        File = "BuilderExtended-SemiBold",
    }}), Enum.FontWeight.SemiBold)

    UIData.Windows.Windows[Data.Flag] = WindowData

    function WindowData.Functions:ChangeText(NewData: {Text: string}): string
        TopText.Name = NewData.Text
        return NewData.Text
    end

    function WindowData.Functions:ChangeName(NewData: {Name: string}): string        
        UIData.Windows.Windows[NewData.Name] = table.clone(UIData.Windows.Windows[Data.Flag])

        table.clear(UIData.Windows.Windows[Data.Flag])
        UIData.Windows.Windows[Data.Flag] = nil
        Data.Name = NewData.Name
        return NewData.Name
    end

    function WindowData.Functions:SetVisiblity(Visible: boolean, SaveConfig: boolean?): boolean
        if Visible == nil then
            Visible = not Window.Visible
        end

        if SaveConfig == nil then
            SaveConfig = true
        end

        Window.Visible = Visible

        if SaveConfig then
            Night.CurrentConfig.Others.TabData[Data.Flag] = {
                Visible = Visible,
                Position = {Window.Position.X.Scale, Window.Position.Y.Scale}
            }

            Assets.Config:Save(Night.CurrentConfig, tostring(Night.Game).."/"..tostring(Night.CurrentConfig.ConfigName), {tostring(Night.Game)})
        end
        return Visible
    end

    function WindowData.Functions:Destroy(): boolean
        Window:Destroy()
        for i,v in WindowData.Connections do
            v:Disconnect()
        end

        if WindowData.Data.DashButton then
            WindowData.Data.DashButton:Destroy()
        end

        table.clear(UIData.Windows.Windows[Data.Flag])
        table.clear(WindowData)
        UIData.Windows.Windows[Data.Flag] = nil
        return true
    end

    Assets.Connections:Add(Top.InputBegan:Connect(function(Input: InputObject)
        if ((Input.UserInputType == Enum.UserInputType.MouseButton1) or (Input.UserInputType == Enum.UserInputType.Touch)) and not UIData.Windows.Dragging then
            UIData.Windows.Dragging = Window
            WindowData.DragData = {
                Dragging = true :: boolean,
                StartInputPos = Input.Position :: Vector3,
                FrameStartPos = Window.Position :: UDim2,
                Window = Window :: Frame
            }

            UIData.InputFuncs.Changed = function(ChangedInput: InputObject)
                if (ChangedInput.UserInputType == Enum.UserInputType.MouseMovement or ChangedInput.UserInputType == Enum.UserInputType.Touch) then  
                    if WindowData.DragData.Dragging then
                        Assets.Functions:Drag(WindowData.DragData, ChangedInput)
                    end
                end
            end

            UIData.InputFuncs.Ended = function(EndInput: InputObject)
                if (EndInput.UserInputType == Enum.UserInputType.MouseButton1) or (EndInput.UserInputType == Enum.UserInputType.Touch) then
                    UIData.Windows.Dragging = nil
                    WindowData.DragData = {
                        Dragging = false :: boolean,
                        StartInputPos = Input.Position :: Vector3,
                        FrameStartPos = Window.Position :: UDim2,
                        Window = Window :: Frame
                    }

                    for i,v in UIData.InputFuncs do
                        UIData.InputFuncs[i] = function() end
                    end
                    
                    Night.CurrentConfig.Others.TabData[Data.Flag] = {
                        Visible = Window.Visible,
                        Position = {Window.Position.X.Scale, Window.Position.Y.Scale}
                    }

                    Assets.Config:Save(Night.CurrentConfig, tostring(Night.Game).."/"..tostring(Night.CurrentConfig.ConfigName), {tostring(Night.Game)})
                end
            end
        end
    end), {WindowData.Connections})

    if Data.Dashboard then
        function WindowData.Functions:MakeDashboardButton(Data: {Text: {Text: string, Color: Color3?, Obj: TextLabel?, OpenColor: Color3?}, Icon: {Name: string, Color: Color3, Obj: ImageLabel?, OpenColor: Color3?}?, Clicked: (self: any, Selected: boolean) -> (), First: boolean?, Last: boolean?, Top: boolean?, Window: string?, Order: number?, CanBeChanged: boolean?})
            local ButtonData = {
                Data = Data,
                Selected = false,
                Connections = {},
                Functions = {}
            }

            local ButtonHolder = WindowData.Dashboard.ButtonHolder :: Frame
            local BottomButtonHolder = WindowData.Dashboard.BottomButtonHolder :: Frame
            if not ButtonHolder then
                ButtonHolder = Instance.new("Frame", WindowData.Window)
                ButtonHolder.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
                ButtonHolder.Position = UDim2.fromScale(0.067, 0.166)
                ButtonHolder.Size = UDim2.fromOffset(221, 250)
                Instance.new("UICorner", ButtonHolder).CornerRadius = UDim.new(0, 10)

                local Layout: UIListLayout = Instance.new("UIListLayout", ButtonHolder)
                Layout.FillDirection = Enum.FillDirection.Vertical
                Layout.SortOrder = Enum.SortOrder.LayoutOrder
                Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                Layout.VerticalAlignment = Enum.VerticalAlignment.Top

                WindowData.Dashboard.ButtonHolder = ButtonHolder
                WindowData.Dashboard.TopButtoncount = 0
                WindowData.Dashboard.BottomButtonCount = 0
            end

            if not BottomButtonHolder then
                BottomButtonHolder = Instance.new("Frame", WindowData.Window)
                BottomButtonHolder.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
                BottomButtonHolder.Position = UDim2.fromScale(0.067, 0.749)
                BottomButtonHolder.Size = UDim2.fromOffset(221, 100)
                Instance.new("UICorner", BottomButtonHolder).CornerRadius = UDim.new(0, 10)

                local Divider: Frame = Instance.new("Frame", BottomButtonHolder)
                Divider.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
                Divider.Position = UDim2.fromScale(0.074, 0.49)
                Divider.Size = UDim2.fromOffset(186, 1)
                Divider.BorderSizePixel = 0

                WindowData.Dashboard.BottomButtonHolder = BottomButtonHolder
            end

            local FirstButton: boolean = Data.First or (Data.Top and WindowData.Dashboard.TopButtoncount == WindowData.Dashboard.NextFirstButton or not Data.Top and WindowData.Dashboard.BottomButtonCount == 0)
            local LastButton: boolean = Data.Last or (Data.Top and WindowData.Dashboard.TopButtoncount == 4 or not Data.Top and WindowData.Dashboard.BottomButtonCount == 1)

            local ButtonPos: UDim2 = UDim2.fromScale(0, 0.01)
            if not Data.Top then
                WindowData.Dashboard.BottomButtonCount += 1
                ButtonHolder = BottomButtonHolder

                if LastButton then
                    ButtonPos = UDim2.fromScale(0, 0.5)
                end
            else
                WindowData.Dashboard.TopButtoncount += 1
                if LastButton and WindowData.Dashboard.LastLayout ~= 0 then
                    LastButton = false
                end
            end

            local Button: ImageButton = Instance.new("ImageButton", ButtonHolder)
            Button.BackgroundColor3 = UIData.Theme.Other
            Button.BackgroundTransparency = 1
            Button.Size = UDim2.fromOffset(221, 50)
            Button.ImageTransparency = 1
            Button.BorderSizePixel = 0
            Button.AutoButtonColor = false
            Button.Position = ButtonPos
            if Data.Order then
                Button.LayoutOrder = Data.Order
                if Data.Order > WindowData.Dashboard.LastLayout then
                    WindowData.Dashboard.LastLayout = Data.Order
                    LastButton = true
                    FirstButton = false

                    WindowData.Dashboard.NextFirstButton += 1
                end
            end

            table.insert(UIData.CustomizableItems.Other, {
                CanChange = true,
                Item = Button,
                ChangeBackground = true
            })

            local CornerFix : Frame
            if FirstButton or LastButton then
                Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 12)

                CornerFix = Instance.new("Frame", Button) :: Frame
                CornerFix.BackgroundColor3 = UIData.Theme.Other
                CornerFix.BackgroundTransparency = 1
                CornerFix.Position = UDim2.fromScale(0, -0.013)
                CornerFix.Size = UDim2.fromOffset(221, 8)
                CornerFix.BorderSizePixel = 0
                table.insert(UIData.CustomizableItems.Other, {
                    CanChange = true,
                    Item = CornerFix
                })

                if FirstButton then
                    local Divider: Frame = Instance.new("Frame", Button)
                    Divider.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
                    Divider.BorderSizePixel = 0
                    Divider.Position = UDim2.fromScale(0.074, 1)
                    Divider.Size = UDim2.fromOffset(186, 1)

                    CornerFix.Position = UDim2.fromScale(0, 0.85)
                end
            end

            local Text: TextLabel = Instance.new("TextLabel", Button)
            Text.BackgroundTransparency = 1
            Text.Position = UDim2.fromScale(0.074, 0.3)
            Text.Size = UDim2.fromOffset(150, 18)
            Text.Font = Enum.Font.BuilderSansBold
            Text.TextColor3 = Data.Text.Color or Color3.fromRGB(46, 54, 76)
            Text.TextScaled = true
            Text.TextWrapped = true
            Text.TextXAlignment = Enum.TextXAlignment.Left
            Text.Text = Data.Text.Text
            Text.TextStrokeTransparency = 1

            if not Data.Top then
                Text.Position = UDim2.fromScale(0.178, 0.32)
                Text.Size = UDim2.fromOffset(80, 18)
            end

            if Data.CanBeChanged then
                table.insert(UIData.CustomizableItems.Other, {
                    CanChange = true,
                    Item = Text
                })
            end

            Data.Text.Obj = Text

            local Image: ImageLabel
            if Data.Icon then
                local icon: string? = Assets.Functions:LoadAsset(tostring(Data.Icon.Name))
                if icon then
                    Image = Instance.new("ImageLabel", Button)
                    Image.BackgroundTransparency = 1
                    Image.Position = UDim2.fromScale(0.054, 0.23)
                    Image.Size = UDim2.fromOffset(27, 27)
                    Image.Image = icon
                    Image.ImageColor3 = Data.Icon.Color
                    Image.BorderSizePixel = 0

                    if Data.CanBeChanged then
                        table.insert(UIData.CustomizableItems.Other, {
                            CanChange = true,
                            Item = Image
                        })
                    end

                    Data.Icon.Obj = Image
                end
            end

            function ButtonData.Functions:Destroy()
                for i,v in ButtonData.Connections do
                    v:Disconnect()
                end

                Button:Destroy()
                if Data.Top then
                    WindowData.Dashboard.TopButtoncount -= 1
                else
                    WindowData.Dashboard.BottomButtonCount -= 1
                end

                if Data.Window then
                    UIData.DashButtons[Data.Window] = nil
                else
                    UIData.DashButtons[Data.Text.Text] = nil
                end

                table.clear(ButtonData)
            end

            function ButtonData.Functions:Toggle(Toggled: boolean?, SaveConfig: boolean?)
                if Toggled == nil then
                    Toggled = not ButtonData.Selected
                end
                
                if SaveConfig == nil then
                    SaveConfig = true
                end

                ButtonData.Selected = Toggled
                if Data.Clicked then
                    Data.Clicked(ButtonData, ButtonData.Selected)
                end

                if Data.Window then
                    local TargetWindow = UIData.Windows.Windows[Data.Window]
                    if TargetWindow then
                        TargetWindow:SetVisiblity(Toggled, SaveConfig)
                    end
                end

                if Data.Top then
                    TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundTransparency = ButtonData.Selected and 0 or 1}):Play()
                    TweenService:Create(Text, TweenInfo.new(0.2), {TextColor3 = ButtonData.Selected and Color3.fromRGB(210, 219, 229) or Color3.fromRGB(46, 54, 76)}):Play()
                    if CornerFix then
                        TweenService:Create(CornerFix, TweenInfo.new(0.2), {BackgroundTransparency = ButtonData.Selected and 0 or 1}):Play()
                    end
                else
                    if Data.Icon and Data.Icon.OpenColor then
                        TweenService:Create(Image, TweenInfo.new(0.2), {ImageTransparency = ButtonData.Selected and 0 or 0.5}):Play()
                    end
                    if Data.Text.OpenColor then
                        TweenService:Create(Text, TweenInfo.new(0.2), {TextColor3 = ButtonData.Selected and Data.Text.OpenColor or Data.Text.Color}):Play()
                    end
                end
            end

            if Data.Top then
                table.insert(ButtonData.Connections, Button.MouseButton1Click:Connect(function()  
                    ButtonData.Functions.Toggle(ButtonData)
                end))
            else
                table.insert(ButtonData.Connections, Button.MouseButton1Click:Connect(function()
                    if Data.Window then
                        ButtonData.Functions.Toggle(ButtonData)
                    else
                        ButtonData.Selected = not ButtonData.Selected
                        ButtonData.Data.Clicked(ButtonData, ButtonData.Selected)
                    end
                end))
            end

            if Data.Window then
                UIData.DashButtons[Data.Window] = ButtonData
            else
                UIData.DashButtons[Data.Text.Text] = ButtonData
            end

            setmetatable(ButtonData, {
                __index = ButtonData.Functions
            })

            return ButtonData
        end
    else
        Window.ZIndex = Data.ZIndex or 90
        TopText.ZIndex = Data.ZIndex or 90
        CornerWorkAround.ZIndex = Data.ZIndex or 90
        Top.ZIndex = Data.ZIndex or 90

        if Data.Icon then
            if not Data.Icon.Size then
                Data.Icon.Size = UDim2.fromOffset(21, 21)
            end

            local Icon: string? = Assets.Functions:LoadAsset(Data.Icon.Icon)
            if Icon then
                local ImageLabelIcon = Instance.new("ImageLabel", Top) :: ImageLabel
                ImageLabelIcon.BackgroundTransparency = 1
                ImageLabelIcon.BorderSizePixel = 0
                ImageLabelIcon.Position = UDim2.fromScale(0.116, 0.53)
                ImageLabelIcon.Size = Data.Icon.Size
                ImageLabelIcon.ZIndex = 90
                ImageLabelIcon.Image = Icon
                ImageLabelIcon.ImageColor3 = Color3.fromRGB(210, 219, 229)
                ImageLabelIcon.ScaleType = Enum.ScaleType.Fit
                ImageLabelIcon.AnchorPoint = Vector2.new(0.5, 0.5)

                TopText.Position = UDim2.fromScale(0.2, 0.359)
            end
        end

        local CloseIcon: string = Assets.Functions:LoadAsset("Close")
        if not CloseIcon then
            CloseIcon = ""
        end

        -- hate this lsp
        local ClosePos: UDim2 = UDim2.fromScale(0.862, 0.377)
        if Data.ClosePos then
            ClosePos = Data.ClosePos
        end

        local CloseButton: ImageButton = Instance.new("ImageButton", Top)
        CloseButton.BackgroundTransparency = 1
        CloseButton.AutoButtonColor = false
        CloseButton.Position = ClosePos
        CloseButton.Size = UDim2.fromOffset(16, 16)
        CloseButton.Image = CloseIcon
        CloseButton.ImageColor3 = Color3.fromRGB(23, 85, 161)
        CloseButton.ScaleType = Enum.ScaleType.Stretch
        CloseButton.ZIndex = 90

        Assets.Connections:Add(CloseButton.MouseButton1Click:Connect(function()
            if WindowData.Data.DashButton then
                WindowData.Data.DashButton:Toggle(false)
            end

            if WindowData.Data.OnClose then
                WindowData.Data.OnClose(Data) -- got do ts shi cuz my lsp wont let me call it without telling me its a error
            end

            WindowData.Functions:SetVisiblity(false)
        end), {WindowData.Connections})

        function WindowData.Functions:CreateModule(ModuleData: {Name: string, Flag: string, Default: boolean?, Button: boolean?, SaveConfig: boolean, Notification: boolean?, CanBeEnabled: boolean, DefaultKeybind: Enum.KeyCode?, CallingFunction: (self: any, Enabled: boolean?) -> (), KeybindCallingFunction: (self: any, KeyCode: Enum.KeyCode?) -> ()?})
            local RealModuleData = {
                Data = ModuleData,
                Enabled = false :: boolean,
                ModuleFrame = nil :: Frame?,
                MData = {
                    SettingsOpen = false :: boolean,
                    Keybind = nil :: string?,
                    SettingKeybind = false :: boolean,
                    SettingsOpenedOnce = false :: boolean,
                    KeybindsToHide = {},
                    Tweening = false :: boolean,
                    ArrayObject = nil,
                },
                Settings = {
                    MiniToggles = {},
                    Sliders = {},
                    TextBoxes = {},
                    Dropdowns = {},
                    ColorSliders = {},
                    Keybinds = {},
                    Buttons = {}
                },
                Functions = {},
                Connections = {},
                ConnectionsToDisconnectOnDisable = {}
            }

            if RealModuleData.Data.CanBeEnabled == nil then
                RealModuleData.Data.CanBeEnabled = true
            end

            if RealModuleData.Data.SaveConfig == nil then
                RealModuleData.Data.SaveConfig = true
            end

            if RealModuleData.Data.Notification == nil then
                RealModuleData.Data.Notification = true
            end

            local ModuleHolder = WindowData.Modules.Holder :: ScrollingFrame?
            if not ModuleHolder then
                ModuleHolder = Instance.new("ScrollingFrame", Window)
                ModuleHolder.BackgroundTransparency = 1
                ModuleHolder.Position = UDim2.fromScale(0, 0.166)
                ModuleHolder.Size = UDim2.fromOffset(255, 392)
                ModuleHolder.ScrollBarThickness = 0
                ModuleHolder.CanvasSize = UDim2.fromOffset(0, 0)
                ModuleHolder.ClipsDescendants = true
                Instance.new("UICorner", ModuleHolder).CornerRadius = UDim.new(0, 15)

                local ModuleHolderLayout: UIListLayout = Instance.new("UIListLayout", ModuleHolder)
                ModuleHolderLayout.Padding = UDim.new(0, 15)
                ModuleHolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
                ModuleHolderLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center


                WindowData.Modules.Holder = ModuleHolder
            end


            ModuleHolder.CanvasSize = UDim2.fromOffset(0, ModuleHolder.CanvasSize.Y.Offset + 70)

            local RealModuleHolder = Instance.new("Frame", ModuleHolder)
            RealModuleHolder.BackgroundTransparency = 1
            RealModuleHolder.Size = UDim2.fromOffset(217, 0)
            RealModuleHolder.AutomaticSize = Enum.AutomaticSize.Y
            RealModuleHolder.Position = UDim2.fromOffset(19, 0)

            local FirstLetter: string = ModuleData.Name:sub(1, 1)
            RealModuleHolder.LayoutOrder = string.byte(FirstLetter)

            local ModuleFrame: ImageButton = Instance.new("ImageButton", RealModuleHolder)
            ModuleFrame.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
            ModuleFrame.Size = UDim2.fromOffset(217, 50)
            ModuleFrame.Position = UDim2.fromOffset(0, 0)
            ModuleFrame.ZIndex = 91
            ModuleFrame.AutoButtonColor = false
            ModuleFrame.ImageTransparency = 1
            Instance.new("UICorner", ModuleFrame).CornerRadius = UDim.new(0, 12)

            RealModuleData.ModuleFrame = ModuleFrame

            local DropShadow: Frame = Instance.new("Frame", ModuleFrame)
            DropShadow.BackgroundColor3 = Color3.fromRGB(11, 14, 18)
            DropShadow.Position = UDim2.fromScale(0.046, 0.15)
            DropShadow.Size = UDim2.fromOffset(195, 49)
            DropShadow.ZIndex = 90
            Instance.new("UICorner", DropShadow).CornerRadius = UDim.new(0, 12)

            local ModuleNameTextLabel: TextLabel = Instance.new("TextLabel", ModuleFrame)
            ModuleNameTextLabel.BackgroundTransparency = 1
            ModuleNameTextLabel.BorderSizePixel = 0
            ModuleNameTextLabel.Position = UDim2.fromScale(0.074, 0.3)
            ModuleNameTextLabel.Size = UDim2.fromOffset(138, 18)
            ModuleNameTextLabel.ZIndex = 91
            ModuleNameTextLabel.Font = Enum.Font.BuilderSansBold
            ModuleNameTextLabel.Text = ModuleData.Name
            ModuleNameTextLabel.TextColor3 = Color3.fromRGB(46, 54, 76)
            ModuleNameTextLabel.TextScaled = true
            ModuleNameTextLabel.TextWrapped = true
            ModuleNameTextLabel.TextStrokeTransparency = 1
            ModuleNameTextLabel.TextXAlignment = Enum.TextXAlignment.Left

            local SettingsButton: ImageButton = Instance.new("ImageButton", ModuleFrame)
            SettingsButton.BackgroundTransparency = 1
            SettingsButton.BorderSizePixel = 0
            SettingsButton.Position = UDim2.fromScale(0.825, 0.24)
            SettingsButton.Size = UDim2.fromOffset(25, 25)
            SettingsButton.ZIndex = 91
            SettingsButton.Image = Assets.Functions:LoadAsset("Settings") or ""
            SettingsButton.ImageColor3 = Color3.fromRGB(46, 54, 76)
            SettingsButton.ScaleType = Enum.ScaleType.Stretch

            local Color = UIData.Theme.ModuleTheme
            local RGB1, RGB2 = Assets.Functions:ConvertColor3toInt(Color[1]), Assets.Functions:ConvertColor3toInt(Color[2])
            local Gradients = {
                [1] = {
                    math.clamp(RGB1.R - 7, 0, 255), 
                    math.clamp(RGB1.G - 24, 0, 255), 
                    math.clamp(RGB1.B - 46, 0, 255)
                },
                [2] = {
                    math.clamp(RGB2.R - 5, 0, 255), 
                    math.clamp(RGB2.G - 19, 0, 255), 
                    math.clamp(RGB2.B - 37, 0, 255)
                }
            }

            local EnabledGradient: UIGradient = Instance.new("UIGradient", ModuleFrame)
            EnabledGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color[1]), ColorSequenceKeypoint.new(1, Color[2])})
            EnabledGradient.Enabled = false
            table.insert(UIData.CustomizableItems.Modules, {Main = true, Gradient = EnabledGradient})

            local DropShadowEnabledGradient: UIGradient = Instance.new("UIGradient", DropShadow)
            DropShadowEnabledGradient.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(table.unpack(Gradients[1]))), ColorSequenceKeypoint.new(1, Color3.fromRGB(table.unpack(Gradients[2])))})
            DropShadowEnabledGradient.Enabled = false
            table.insert(UIData.CustomizableItems.Modules, {Main = false, Gradient = DropShadowEnabledGradient})
            table.clear(Gradients)
            
            local SettingsHolder: ScrollingFrame = Instance.new("ScrollingFrame", RealModuleHolder)
            SettingsHolder.BackgroundColor3 = Color3.fromRGB(11, 14, 18)
            SettingsHolder.Position = UDim2.fromOffset(0, 65)
            SettingsHolder.Size = UDim2.fromOffset(217, 0)
            SettingsHolder.AutomaticSize = Enum.AutomaticSize.Y
            SettingsHolder.ScrollBarThickness = 0
            SettingsHolder.CanvasSize = UDim2.fromScale(0, 0)
            SettingsHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
            SettingsHolder.Visible = false
            SettingsHolder.ZIndex = 95
            Instance.new("UICorner", SettingsHolder).CornerRadius = UDim.new(0, 14)
            
            local SettingsLayout: UIListLayout = Instance.new("UIListLayout", SettingsHolder)
            SettingsLayout.Padding = UDim.new(0, 5)
            SettingsLayout.SortOrder = Enum.SortOrder.LayoutOrder

            local SettingsPadding: UIPadding = Instance.new("UIPadding", SettingsHolder)
            SettingsPadding.PaddingTop = UDim.new(0, 5)
            SettingsPadding.PaddingBottom = UDim.new(0, 5)

            function RealModuleData.Functions:SetValue(Toggled: boolean?, SaveConfig: boolean?, Notification: boolean?, Load: boolean?)
                if setthreadidentity then setthreadidentity(8) end
                
                if not RealModuleData.Data.CanBeEnabled then return end

                if Toggled == nil then
                    Toggled = not RealModuleData.Enabled
                end

                if SaveConfig == nil then
                    SaveConfig = true
                end

                if not RealModuleData.Data.SaveConfig then
                    SaveConfig = false
                end

                if not UIData.NotificationsSettings.Modules or not RealModuleData.Data.Notification then
                    Notification = false
                end

                RealModuleData.Enabled = Toggled

                if not Toggled then
                    for i,v in RealModuleData.ConnectionsToDisconnectOnDisable do
                        v:Disconnect()
                    end
                end
                
                if RealModuleData.Data.CallingFunction then
                    task.spawn(RealModuleData.Data.CallingFunction, RealModuleData, Toggled)
                    if Toggled then        
                        if RealModuleData.Data.Button then
                            task.delay(0.8, RealModuleData.Data.CallingFunction, RealModuleData, false)

                            RealModuleData.Enabled = false
                            if Notification then
                                Assets.Functions:CreateNotification({
                                    Title = RealModuleData.Data.Name,
                                    Description = RealModuleData.Data.Name.. " has been disabled",
                                    Duration = 1,
                                    Module = true
                                })
                            end
                            return
                        end
                    end
                end

                if Night.Mobile then
                    for i,v in RealModuleData.MData.KeybindsToHide do
                        if Toggled then
                            if not v.MobileButton then
                                v.MobileButton = Assets.Functions:CreateMobileButton({
                                    Name = v.RealText,
                                    Flag = v.Data.Flag.."MobileButton",
                                    Events = {
                                        Began = function(self, Input: InputObject)
                                            if v.Data.Events and v.Data.Events.Began then
                                                v.Data.Events.Began(v, Input)
                                            end
                                        end,
                                        Ended = function(self, Held: boolean, Input: InputObject)
                                            if v.Data.Events and v.Data.Events.Ended then
                                                v.Data.Events.Ended(v, Input)
                                            end
                                        end
                                    }
                                })
                            end
                        else
                            if v.MobileButton then
                                v.MobileButton:Destroy()
                                v.MobileButton = nil
                            end
                        end                                
                    end
                end

                if Notification then
                    Assets.Functions:CreateNotification({
                        Title = RealModuleData.Data.Name,
                        Description = RealModuleData.Data.Name.. " has been "..(Toggled and "enabled" or "disabled"),
                        Duration = 1,
                        Module = true
                    })
                end

                if SaveConfig then
                    Night.CurrentConfig.Modules[RealModuleData.Data.Flag] = Toggled
                    Assets.Config:Save(Night.CurrentConfig, tostring(Night.Game).."/"..tostring(Night.CurrentConfig.ConfigName), {tostring(Night.Game)})
                end

                if Toggled then
                    RealModuleData.MData.ArrayObject = Assets.ArrayList:Push(ModuleData.Name)
                else
                    if RealModuleData.MData.ArrayObject then
                        RealModuleData.MData.ArrayObject:Remove()
                    end
                end

                coroutine.wrap(function()
                    repeat task.wait() until not RealModuleData or not RealModuleData.MData or not RealModuleData.MData.Tweening
                    if not RealModuleData or not RealModuleData.MData then
                        return
                    end

                    RealModuleData.MData.Tweening = true
                    if Toggled then
                        EnabledGradient.Enabled = true
                        DropShadowEnabledGradient.Enabled = true
                        TweenService:Create(ModuleFrame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                        TweenService:Create(DropShadow, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                        TweenService:Create(ModuleNameTextLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(210, 219, 229)}):Play()
                        local End = TweenService:Create(SettingsButton, TweenInfo.new(0.15), {ImageColor3 = Color3.fromRGB(210, 219, 229)})
                        End:Play()
                        End.Completed:Once(function()
                            RealModuleData.MData.Tweening = false
                        end)
                    else
                        if RealModuleData.ConnectionsToDisconnectOnDisable then
                            table.clear(RealModuleData.ConnectionsToDisconnectOnDisable)
                        end

                        TweenService:Create(SettingsButton, TweenInfo.new(0.15), {ImageColor3 = Color3.fromRGB(46, 54, 76)}):Play()
                        TweenService:Create(ModuleNameTextLabel, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(46, 54, 76)}):Play()
                        TweenService:Create(DropShadow, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(11, 14, 18)}):Play()
                        local End = TweenService:Create(ModuleFrame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(14, 16, 23)})
                        task.delay(0.1, function()
                            if not RealModuleData.Enabled then
                                DropShadowEnabledGradient.Enabled = false
                                EnabledGradient.Enabled = false
                            end
                        end)

                        End:Play()
                        End.Completed:Once(function()
                            if RealModuleData and RealModuleData.MData then
                                RealModuleData.MData.Tweening = false
                            end
                        end)
                    end
                end)()
            end
            
            function RealModuleData.Functions:Connection(Connection: RBXScriptConnection | thread, AddTo: {}?)
                AddTo = AddTo or {}
                if not table.find(AddTo, RealModuleData.Connections) then
                    table.insert(AddTo, RealModuleData.Connections)
                end

                if not table.find(AddTo, WindowData.Connections) then
                    table.insert(AddTo, WindowData.Connections)
                end

                if not table.find(AddTo, RealModuleData.ConnectionsToDisconnectOnDisable) then
                    table.insert(AddTo, RealModuleData.ConnectionsToDisconnectOnDisable)
                end

                return Assets.Connections:Add(Connection, AddTo)
            end

            function RealModuleData.Functions:ToggleSettings(Open: boolean?)
                if Open == nil then
                    Open = not RealModuleData.MData.SettingsOpen
                end

                if typeof(Open) == "boolean" and RealModuleData.MData.SettingsOpen ~= Open then -- gotta do ts for my lsp to shut up fr 💔😔🥶
                    if Open then
                        SettingsHolder.Size = UDim2.fromOffset(217, 0)    
                        SettingsHolder.AutomaticSize = Enum.AutomaticSize.Y
                    end

                    local YSizeSettings: number = SettingsHolder.AbsoluteSize.Y
                    if YSizeSettings > 250 and Open then
                        YSizeSettings = 250
                        SettingsHolder.Size = UDim2.fromOffset(217, YSizeSettings)
                        SettingsHolder.AutomaticSize = Enum.AutomaticSize.None
                    end


                    SettingsHolder.Visible = Open
                    if not Open then
                        SettingsHolder.Size = UDim2.fromOffset(217, 0)
                        ModuleHolder.CanvasSize = UDim2.fromOffset(0, ModuleHolder.CanvasSize.Y.Offset - (YSizeSettings + 80))

                        for i,v in RealModuleData.Settings.Dropdowns do
                            v:ToggleSideMenu(false)
                        end
                    else
                        ModuleHolder.CanvasSize = UDim2.fromOffset(0, ModuleHolder.CanvasSize.Y.Offset + (YSizeSettings + 80))
                    end

                    RealModuleData.MData.SettingsOpenedOnce = true
                    RealModuleData.MData.SettingsOpen = Open
                end
            end

            Assets.Connections:Add(ModuleFrame.MouseButton1Click:Connect(function()
                RealModuleData.Functions:SetValue(nil, true, true)
            end), {RealModuleData.Connections, WindowData.Connections})

            Assets.Connections:Add(SettingsButton.MouseButton1Click:Connect(function()
                RealModuleData.Functions:ToggleSettings()
            end), {RealModuleData.Connections, WindowData.Connections})

            Assets.Connections:Add(ModuleFrame.MouseButton2Click:Connect(function()
                RealModuleData.Functions:ToggleSettings()
            end), {RealModuleData.Connections, WindowData.Connections})

            function RealModuleData.Functions:MiniToggle(MiniToggleData: {Name: string, Flag: string, Default: boolean?, CallingFunction: (self: any, Toggled: boolean) -> ()})
                local RealMiniToggleData = {
                    Data = MiniToggleData,
                    Enabled = false,
                    Functions = {},
                    Connections = {}
                }

                local MiniToggleBase: ImageButton = Instance.new("ImageButton", SettingsHolder)
                MiniToggleBase.BackgroundTransparency = 1
                MiniToggleBase.Size = UDim2.fromOffset(217, 30)
                MiniToggleBase.BorderSizePixel = 0
                MiniToggleBase.ZIndex = 95
                MiniToggleBase.ImageTransparency = 1

                local MiniToggleText: TextLabel = Instance.new("TextLabel", MiniToggleBase)
                MiniToggleText.BackgroundTransparency = 1
                MiniToggleText.BorderSizePixel = 0
                MiniToggleText.Position = UDim2.fromScale(0.07, 0.233)
                MiniToggleText.Size = UDim2.fromOffset(86, 16)
                MiniToggleText.Text = MiniToggleData.Name
                MiniToggleText.TextColor3 = Color3.fromRGB(68, 78, 112)
                MiniToggleText.TextScaled = true
                MiniToggleText.TextStrokeTransparency = 1
                MiniToggleText.TextXAlignment = Enum.TextXAlignment.Left
                MiniToggleText.TextWrapped = true
                MiniToggleText.FontFace = Font.new(Assets.Functions:GetFont("BuilderSans"), Enum.FontWeight.SemiBold)
                MiniToggleText.ZIndex = 96

                local MainMiniToggleFrame: Frame = Instance.new("Frame", MiniToggleBase)
                MainMiniToggleFrame.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
                MainMiniToggleFrame.Position = UDim2.fromScale(0.75, 0.167)
                MainMiniToggleFrame.Size = UDim2.fromOffset(40, 20)
                MainMiniToggleFrame.ZIndex = 95
                Instance.new("UICorner", MainMiniToggleFrame).CornerRadius = UDim.new(1, 0)
                local PlacePos = #UIData.CustomizableItems.Other + 1
                table.insert(UIData.CustomizableItems.Other, PlacePos, {
                    CanChange = false,
                    Item = MainMiniToggleFrame
                })

                local MiniToggleCircle: Frame = Instance.new("Frame", MainMiniToggleFrame)
                MiniToggleCircle.BackgroundColor3 = Color3.fromRGB(48, 56, 80)
                MiniToggleCircle.Position = UDim2.fromScale(0.125, 0.25)
                MiniToggleCircle.Size = UDim2.fromOffset(10, 10)
                MiniToggleCircle.ZIndex = 95
                Instance.new("UICorner", MiniToggleCircle).CornerRadius = UDim.new(1, 0)

                function RealMiniToggleData.Functions:SetValue(Toggled: boolean?, SaveConfig: boolean?, Load: boolean?)
                    if Toggled == nil then
                        Toggled = not RealMiniToggleData.Enabled
                    end

                    if SaveConfig == nil then
                        SaveConfig = true
                    end

                    RealMiniToggleData.Enabled = Toggled
                    RealMiniToggleData.Data.CallingFunction(RealMiniToggleData, RealMiniToggleData.Enabled)

                    UIData.CustomizableItems.Other[PlacePos].CanChange = Toggled
                    if SaveConfig then
                        Night.CurrentConfig.MiniToggles[RealMiniToggleData.Data.Flag] = Toggled
                        Assets.Config:Save(Night.CurrentConfig, tostring(Night.Game).."/"..tostring(Night.CurrentConfig.ConfigName), {tostring(Night.Game)})
                    end

                    coroutine.wrap(function()
                        if Toggled then
                            TweenService:Create(MainMiniToggleFrame, TweenInfo.new(0.15), {BackgroundColor3 = UIData.Theme.Other}):Play()
                            TweenService:Create(MiniToggleCircle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 255, 255), Position = UDim2.fromScale(0.61, 0.25)}):Play()
                        else
                            TweenService:Create(MiniToggleCircle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(48, 56, 80), Position = UDim2.fromScale(0.125, 0.25)}):Play()
                            TweenService:Create(MainMiniToggleFrame, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(14, 16, 23)}):Play()
                        end
                    end)()
                end

                function RealMiniToggleData.Functions:SetVisiblity(Visible: boolean)
                    if Visible == nil then
                        Visible = not MiniToggleBase.Visible
                    end

                    MiniToggleBase.Visible = Visible
                end

                Assets.Connections:Add(MiniToggleBase.MouseButton1Click:Connect(function()
                    RealMiniToggleData.Functions:SetValue(nil)
                end), {RealMiniToggleData.Connections, RealModuleData.Connections, WindowData.Connections})


                setmetatable(RealMiniToggleData, {
                    __index = RealMiniToggleData.Functions
                })

                RealModuleData.Settings.MiniToggles[MiniToggleData.Flag] = RealMiniToggleData
                return RealMiniToggleData
            end

            function RealModuleData.Functions:Slider(SData: {Name: string, Flag: string, Default: number, Min: number, Max: number, Increment: number, CallingFunction: (self: any, value: number) -> ()})
                local SliderData = {
                    Data = SData,
                    Value = 0 :: number,
                    Dragging = false :: boolean,
                    Functions = {},
                    Connections = {}
                }

                if not SData.Increment then
                    SliderData.Data.Increment = 1
                end

                local SliderBase: Frame = Instance.new("Frame", SettingsHolder)
                SliderBase.BackgroundTransparency = 1
                SliderBase.Size = UDim2.fromOffset(217, 54)
                SliderBase.BorderSizePixel = 0
                SliderBase.ZIndex = 95

                local NameText: TextLabel = Instance.new("TextLabel", SliderBase)
                NameText.BackgroundTransparency = 1
                NameText.BorderSizePixel = 0
                NameText.Position = UDim2.fromScale(0.07, 0.1)
                NameText.Size = UDim2.fromOffset(86, 16)
                NameText.FontFace = Font.new(Assets.Functions:GetFont("BuilderSans"), Enum.FontWeight.SemiBold)
                NameText.Text = SData.Name
                NameText.TextColor3 = Color3.fromRGB(68, 78, 112)
                NameText.TextScaled = true
                NameText.TextWrapped = true
                NameText.TextXAlignment = Enum.TextXAlignment.Left
                NameText.ZIndex = 95

                local ValueText: TextBox = Instance.new("TextBox", SliderBase)
                ValueText.BackgroundTransparency = 1
                ValueText.BorderSizePixel = 0
                ValueText.Position = UDim2.fromScale(0.55, 0.139)
                ValueText.Size = UDim2.fromOffset(84, 15)
                ValueText.ZIndex = 95
                ValueText.FontFace = Font.new(Assets.Functions:GetFont("BuilderSans"), Enum.FontWeight.SemiBold)
                ValueText.TextColor3 = Color3.fromRGB(68, 78, 112)
                ValueText.TextScaled = true
                ValueText.TextWrapped = true
                ValueText.TextXAlignment = Enum.TextXAlignment.Right
                ValueText.Text = tostring(SData.Default) or ""

                local SliderBackground: Frame = Instance.new("Frame", SliderBase)
                SliderBackground.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
                SliderBackground.Position = UDim2.fromScale(0.07, 0.6)
                SliderBackground.Size = UDim2.fromOffset(190, 4)
                SliderBackground.ZIndex = 95
                Instance.new("UICorner", SliderBackground).CornerRadius = UDim.new(1, 0)

                local SliderFilled: Frame = Instance.new("Frame", SliderBackground)
                SliderFilled.BackgroundColor3 = UIData.Theme.Other
                SliderFilled.Size = UDim2.fromOffset(77, 4)
                SliderFilled.ZIndex = 95
                Instance.new("UICorner", SliderFilled).CornerRadius = UDim.new(1, 0)
                table.insert(UIData.CustomizableItems.Other, {
                    CanChange = true,
                    Item = SliderFilled
                })

                local SliderCircle: ImageButton = Instance.new("ImageButton", SliderFilled)
                SliderCircle.BackgroundColor3 = UIData.Theme.Other
                SliderCircle.Position = UDim2.fromScale(0.95, -0.5)
                SliderCircle.Size = UDim2.fromOffset(8, 8)
                SliderCircle.ImageTransparency = 1
                SliderCircle.ZIndex = 95
                SliderCircle.AutoButtonColor = false
                Instance.new("UICorner", SliderCircle).CornerRadius = UDim.new(1, 0)
                table.insert(UIData.CustomizableItems.Other, {
                    CanChange = true,
                    Item = SliderCircle
                })

                local CircleBorder: UIStroke = Instance.new("UIStroke", SliderCircle)
                CircleBorder.Color = Color3.fromRGB(14, 16, 23)
                CircleBorder.Thickness = 2

                function SliderData.Functions:SetValue(Value: number, SaveConfig: boolean, Load: boolean?)
                    SliderData.Value = Value
                    SliderData.Data.CallingFunction(SliderData, Value)

                    if SaveConfig == nil then
                        SaveConfig = true
                    end
                    
                    if SaveConfig then
                        Night.CurrentConfig.Sliders[SliderData.Data.Flag] = Value
                        Assets.Config:Save(Night.CurrentConfig, tostring(Night.Game).."/"..tostring(Night.CurrentConfig.ConfigName), {tostring(Night.Game)})
                    end

                    coroutine.wrap(function()
                        ValueText.Text = tostring(Value)
                        TweenService:Create(SliderFilled, TweenInfo.new(0.25), {Size = UDim2.fromScale(math.clamp((Value-SliderData.Data.Min)/(SliderData.Data.Max-SliderData.Data.Min) - SliderFilled.Position.X.Scale, 0, 1), 1)}):Play()
                    end)()
                end

                function SliderData.Functions:SetVisiblity(Visible: boolean)
                    if Visible == nil then
                        Visible = not SliderBase.Visible
                    end

                    SliderBase.Visible = Visible
                end

                Assets.Connections:Add(ValueText.FocusLost:Connect(function(EnterPressed: boolean)
                    local Value: number? = tonumber(ValueText.Text)
                    if EnterPressed and Value then
                        return SliderData.Functions:SetValue(Value)
                    end

                    ValueText.Text = tostring(SliderData.Value)
                    return
                end), {SliderData.Connections, RealModuleData.Connections, WindowData.Connections})

                Assets.Connections:Add(SliderCircle.MouseButton1Down:Connect(function()
                    SliderData.Dragging = true
                    UIData.InputFuncs.Changed = function(Input: InputObject)
                        if SliderData.Dragging and (Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseMovement) then
                            local RPos: number = Input.Position.X - SliderBackground.AbsolutePosition.X
                            local Percent: number = math.clamp(RPos/(SliderBackground.AbsoluteSize.X - 20), 0, 1)
                            local DraggedValue: number = math.floor((SliderData.Data.Min + (Percent * (SliderData.Data.Max - SliderData.Data.Min)) + (SliderData.Data.Increment / 2)) / SliderData.Data.Increment) * SliderData.Data.Increment
                            
                            local DecimalFactor: number = 1 / SliderData.Data.Increment
                            local RealValue: number = math.clamp(math.floor(DraggedValue * DecimalFactor + 0.5) / DecimalFactor, SliderData.Data.Min, SliderData.Data.Max)
                            
                            SliderData.Functions:SetValue(RealValue)
                        end
                    end

                    UIData.InputFuncs.Ended = function(InputEnd: InputObject) 
                        if InputEnd.UserInputType == Enum.UserInputType.MouseButton1 or InputEnd.UserInputType == Enum.UserInputType.Touch then
                            SliderData.Dragging = false

                            for i,v in UIData.InputFuncs do
                                UIData.InputFuncs[i] = function() end
                            end
                        end
                    end
                end), {SliderData.Connections, RealModuleData.Connections, WindowData.Connections})

                setmetatable(SliderData, {
                    __index = SliderData.Functions
                })
                
                RealModuleData.Settings.Sliders[SData.Flag] = SliderData
                return SliderData
            end

            function RealModuleData.Functions:TextBox(TBData: {Name: string, Flag: string, Default: string?, CallingFunction: (self: any, data: string) -> ()})
                local RealTextBoxData = {
                    Data = TBData,
                    Value = "" :: string,
                    Functions = {},
                    Connections = {}
                }

                local MainBackground: Frame = Instance.new("Frame", SettingsHolder)
                MainBackground.BackgroundTransparency = 1
                MainBackground.BorderSizePixel = 0
                MainBackground.Size = UDim2.fromOffset(217, 57)
                MainBackground.ZIndex = 95

                local NameText: TextLabel = Instance.new("TextLabel", MainBackground)
                NameText.BackgroundTransparency = 1
                NameText.BorderSizePixel = 0
                NameText.Position = UDim2.fromScale(0.08, 0.1)
                NameText.Size = UDim2.fromOffset(140, 16)
                NameText.FontFace = Font.new(Assets.Functions:GetFont("BuilderSans"), Enum.FontWeight.SemiBold)
                NameText.Text = TBData.Name
                NameText.TextColor3 = Color3.fromRGB(68, 78, 112)
                NameText.TextScaled = true
                NameText.TextStrokeTransparency = 1
                NameText.TextXAlignment = Enum.TextXAlignment.Left
                NameText.ZIndex = 95

                local MainBox: Frame = Instance.new("Frame", MainBackground)
                MainBox.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
                MainBox.Position = UDim2.fromScale(0.08, 0.55)
                MainBox.Size = UDim2.fromOffset(185, 20)
                MainBox.ZIndex = 95
                Instance.new("UICorner", MainBox).CornerRadius = UDim.new(0, 6)

                local MainTextBox: TextBox = Instance.new("TextBox", MainBox)
                MainTextBox.BackgroundTransparency = 1
                MainTextBox.BorderSizePixel = 0
                MainTextBox.Position = UDim2.fromScale(0.02, 0.2)
                MainTextBox.Size = UDim2.fromOffset(175, 12)
                MainTextBox.ClearTextOnFocus = false
                MainTextBox.PlaceholderColor3 = Color3.fromRGB(46, 54, 76)
                MainTextBox.PlaceholderText = "Insert"
                MainTextBox.TextScaled = true
                MainTextBox.TextColor3 = UIData.Theme.Other
                MainTextBox.ZIndex = 95
                MainTextBox.FontFace = Font.new(Assets.Functions:GetFont("BuilderMono", {{
                    Name = "Bold",
                    Weight = 700,
                    File = "BuilderMono-Bold",
                }}), Enum.FontWeight.Bold)
                table.insert(UIData.CustomizableItems.Other, {
                    CanChange = true,
                    Item = MainTextBox
                })

                function RealTextBoxData.Functions:SetValue(Value: string, SaveConfig: boolean, Load: boolean?)
                    RealTextBoxData.Data.CallingFunction(RealTextBoxData, Value)
                    RealTextBoxData.Value = Value
                    MainTextBox.Text = Value

                    if SaveConfig == nil then
                        SaveConfig = true
                    end

                    if SaveConfig then
                        Night.CurrentConfig.TextBoxes[RealTextBoxData.Data.Flag] = Value
                        Assets.Config:Save(Night.CurrentConfig, tostring(Night.Game).."/"..tostring(Night.CurrentConfig.ConfigName), {tostring(Night.Game)})
                    end
                end

                function RealTextBoxData.Functions:SetVisiblity(Visible: boolean)
                    if Visible == nil then
                        Visible = not MainBackground.Visible
                    end

                    MainBackground.Visible = Visible
                end

                Assets.Connections:Add(MainTextBox.FocusLost:Connect(function(EnterPressed: boolean)
                    if EnterPressed then
                        RealTextBoxData.Functions:SetValue(MainTextBox.Text)
                    else
                        MainTextBox.Text = RealTextBoxData.Value
                    end
                end))

                setmetatable(RealTextBoxData, {
                    __index = RealTextBoxData.Functions
                })

                RealModuleData.Settings.TextBoxes[TBData.Flag] = RealTextBoxData
                return RealTextBoxData
            end
            
            function RealModuleData.Functions:ColorSlider(CSData: {Name: string, Flag: string, Default: Color3?, CallingFunction: (self: any, Color3: Color3, Color: {R: number, G: number, B: number}) -> ()})
                local RealColorSliderData = {
                    Data = CSData,
                    Value = "0, 0, 0" :: string,
                    TableValue = {R = 0, G = 0, B = 0},
                    Dragging = false :: boolean,
                    Rainbow = false :: boolean,
                    LastClicked = 0 :: number,
                    Functions = {},
                    Connections = {}
                }

                local MainBackground: Frame = Instance.new("Frame", SettingsHolder)
                MainBackground.BackgroundTransparency = 1
                MainBackground.Size = UDim2.fromOffset(217, 57)
                MainBackground.ZIndex = 95
                MainBackground.BorderSizePixel = 0

                local MainText: TextLabel = Instance.new("TextLabel", MainBackground)
                MainText.BackgroundTransparency = 1
                MainText.BorderSizePixel = 0 
                MainText.Position = UDim2.fromScale(0.09, 0.1)
                MainText.Size = UDim2.fromOffset(120, 16)
                MainText.ZIndex = 95
                MainText.FontFace = Font.new(Assets.Functions:GetFont("BuilderSans"), Enum.FontWeight.SemiBold)
                MainText.Text = CSData.Name
                MainText.TextColor3 = Color3.fromRGB(68, 78, 112)
                MainText.TextScaled = true
                MainText.TextStrokeTransparency = 1
                MainText.TextWrapped = true
                MainText.TextXAlignment = Enum.TextXAlignment.Left

                local TextBoxBackground: Frame = Instance.new("Frame", MainBackground)
                TextBoxBackground.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
                TextBoxBackground.Position = UDim2.fromScale(0.08, 0.5)
                TextBoxBackground.Size = UDim2.fromOffset(90, 20)
                TextBoxBackground.ZIndex =  95
                Instance.new("UICorner", TextBoxBackground).CornerRadius = UDim.new(0, 6)

                local MainTextBox: TextBox = Instance.new("TextBox", TextBoxBackground)
                MainTextBox.BackgroundTransparency = 1
                MainTextBox.BorderSizePixel = 0
                MainTextBox.Position = UDim2.fromScale(0.05, 0.2)
                MainTextBox.ClearTextOnFocus = true
                MainTextBox.Size = UDim2.fromOffset(80, 13)
                MainTextBox.ZIndex = 95
                MainTextBox.PlaceholderColor3 = Color3.fromRGB(46, 54, 76)
                MainTextBox.PlaceholderText = "RGB"
                MainTextBox.Text = ""
                MainTextBox.TextScaled = true
                MainTextBox.TextWrapped = true
                MainTextBox.FontFace = Font.new(Assets.Functions:GetFont("BuilderMono", {{
                    Name = "Bold",
                    Weight = 700,
                    File = "BuilderMono-Bold",
                }}), Enum.FontWeight.Bold)

                local ColorSliderBackground: Frame = Instance.new("Frame", MainBackground)
                ColorSliderBackground.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
                ColorSliderBackground.Position = UDim2.new(0.54, 0, 0.5, 8)
                ColorSliderBackground.Size = UDim2.fromOffset(84, 4)
                ColorSliderBackground.ZIndex = 95
                Instance.new("UICorner", ColorSliderBackground).CornerRadius = UDim.new(1, 0)

                local RealColorSlider: ImageButton = Instance.new("ImageButton", ColorSliderBackground)
                RealColorSlider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                RealColorSlider.Position = UDim2.fromScale(0, 0)
                RealColorSlider.Size = UDim2.fromOffset(84, 4)
                RealColorSlider.ZIndex = 95
                RealColorSlider.ImageTransparency = 1
                RealColorSlider.AutoButtonColor = false
                Instance.new("UICorner", RealColorSlider).CornerRadius = UDim.new(1, 0)

                local Circle: Frame = Instance.new("Frame", RealColorSlider)
                Circle.BackgroundTransparency = 1
                Circle.Position = UDim2.fromScale(0.498, -0.5)
                Circle.Size = UDim2.fromOffset(8, 8)
                Circle.ZIndex = 95
                Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

                local CircleStroke: UIStroke = Instance.new("UIStroke", Circle)
                CircleStroke.Color = Color3.fromRGB(190, 190, 190)
                CircleStroke.Thickness = 2

                local SliderGradient: UIGradient = Instance.new("UIGradient", RealColorSlider)
                SliderGradient.Color = ColorSequence.new(({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 98, 101)),
                    ColorSequenceKeypoint.new(0.166, Color3.fromRGB(255, 161, 98)),
                    ColorSequenceKeypoint.new(0.325, Color3.fromRGB(255, 242, 98)),
                    ColorSequenceKeypoint.new(0.503, Color3.fromRGB(121, 255, 106)),
                    ColorSequenceKeypoint.new(0.673, Color3.fromRGB(99, 102, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(169, 98, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 101, 150)),
                }))

                function RealColorSliderData.Functions:SetVisiblity(Visible: boolean)
                    if Visible == nil then
                        Visible = not MainBackground.Visible
                    end

                    MainBackground.Visible = Visible
                end

                function RealColorSliderData.Functions:SetValue(RGB: {R: number, G: number, B: number} | string, SaveConfig: boolean?, Load: boolean?)
                    if typeof(RGB) == "string" and RGB == "Rainbow" then
                        RealColorSliderData.Functions:Rainbow()
                        return
                    end
                    
                    RealColorSliderData.TableValue = RGB
                    RealColorSliderData.Value = tostring(RGB.R)..", "..tostring(RGB.G)..", "..tostring(RGB.B)
                    
                    local RGBValue: Color3 = Color3.fromRGB(RGB.R, RGB.G, RGB.B)
                    RealColorSliderData.Data.CallingFunction(RealColorSliderData, RGBValue, RGB)

                    MainTextBox.Text = RealColorSliderData.Value
                    MainTextBox.TextColor3 = RGBValue

                    if SaveConfig == nil then
                        SaveConfig = true
                    end

                    if SaveConfig then
                        Night.CurrentConfig.ColorSliders[RealColorSliderData.Data.Flag] = RGB
                        Assets.Config:Save(Night.CurrentConfig, tostring(Night.Game).."/"..tostring(Night.CurrentConfig.ConfigName), {tostring(Night.Game)})
                    end
                end

                function RealColorSliderData.Functions:Rainbow()
                    RealColorSliderData.Rainbow = true
                    Assets.Connections:Add(task.spawn(function()
                        repeat
                            local Hue: number = math.clamp((math.sin((os.clock() * 1000) / 1000) * 120 + 240) / 360, 0, 1)
                            local Color: Color3 = Color3.fromHSV(Hue, 1, 1)

                            RealColorSliderData.Functions:SetValue(Assets.Functions:ConvertColor3toInt(Color), false)
                            Circle.Position = UDim2.fromScale(Hue, -0.5)
                            task.wait()
                        until not RealColorSliderData or not RealColorSliderData.Rainbow
                    end), {RealColorSliderData.Connections})
                end

                Assets.Connections:Add(RealColorSlider.MouseButton1Down:Connect(function()
                    if 0.5 > (os.clock() - RealColorSliderData.LastClicked) then
                        RealColorSliderData.Dragging = false
                        RealColorSliderData.LastClicked = os.clock()
                        RealColorSliderData.Functions:Rainbow()

                        print("rainbow")
                        Night.CurrentConfig.ColorSliders[RealColorSliderData.Data.Flag] = "Rainbow"
                        Assets.Config:Save(Night.CurrentConfig, tostring(Night.Game).."/"..tostring(Night.CurrentConfig.ConfigName), {tostring(Night.Game)})
                        return
                    end

                    if RealColorSliderData.Rainbow then
                        Night.CurrentConfig.ColorSliders[RealColorSliderData.Data.Flag] = RealColorSliderData.TableValue
                        Assets.Config:Save(Night.CurrentConfig, tostring(Night.Game).."/"..tostring(Night.CurrentConfig.ConfigName), {tostring(Night.Game)})
                    end

                    RealColorSliderData.Rainbow = false
                    RealColorSliderData.Dragging = true
                    RealColorSliderData.LastClicked = os.clock()

                    UIData.InputFuncs.Changed = function(Input: InputObject)
                        if RealColorSliderData.Dragging and (Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseMovement) then
                            local ABX: number = RealColorSlider.AbsolutePosition.X
                            local ABS: number = RealColorSlider.AbsoluteSize.X

                            local RPos: number = Input.Position.X - ABX
                            local CRPos: number = math.clamp(RPos, 0, ABS)
                            local Hue: number = CRPos / ABS
                            local HSVValue: Color3 = Color3.fromHSV(Hue, 1, 1)

                            RealColorSliderData.Functions:SetValue(Assets.Functions:ConvertColor3toInt(HSVValue))
                            Circle.Position = UDim2.fromScale(Hue, -0.5)
                        end
                    end

                    UIData.InputFuncs.Ended = function(InputEnd: InputObject) 
                        if InputEnd.UserInputType == Enum.UserInputType.MouseButton1 or InputEnd.UserInputType == Enum.UserInputType.Touch then
                            RealColorSliderData.Dragging = false

                            for i,v in UIData.InputFuncs do
                                UIData.InputFuncs[i] = function() end
                            end
                        end
                    end
                end), {RealColorSliderData.Connections, RealModuleData.Connections, WindowData.Connections})

                Assets.Connections:Add(MainTextBox.FocusLost:Connect(function(Enter: boolean)
                    if Enter then
                        local Text: string = MainTextBox.Text
                        local RGB: {[number]: number} = {}
                        local Count: number = 0
                        for i: number, v: string in Text:split(",") do
                            local RealText: string = v:gsub(" ", "")
                            local Value: number? = tonumber(RealText)
                            if Value then
                                table.insert(RGB, Value)
                                Count += 1
                            end
                        end

                        if Count == 3 then
                            RealColorSliderData.Functions:SetValue({R = RGB[1], G = RGB[2], B = RGB[3]})
                            local Hue: number = Color3.fromRGB(table.unpack(RGB)):ToHSV()
                            if Hue == 1 then
                                Hue = 0
                            end

                            Circle.Position = UDim2.fromScale(Hue, 0.094)
                            return true
                        end
                    end

                    MainTextBox.Text = RealColorSliderData.Value
                    return false
                end), {RealColorSliderData.Connections, RealModuleData.Connections, WindowData.Connections})

                setmetatable(RealColorSliderData, {
                    __index = RealColorSliderData.Functions
                })

                RealModuleData.Settings.ColorSliders[CSData.Flag] = RealColorSliderData
                return RealColorSliderData
            end

            function RealModuleData.Functions:Dropdown(DropDownData: {Name: string, Flag: string, Default: {string}, Options: {}, MaxLimit: number?, MinLimit: boolean?, CallingFunction: (self: any, Value: string | {any}) -> ()})
                local RealDropdownData = {
                    Data = DropDownData,
                    Functions = {},
                    Selected = {},
                    RealOptions = {},
                    Connections = {},
                    SelectedAmount = 0 :: number,
                    OptionAmount = 0 :: number
                }

                if not RealDropdownData.Data.MaxLimit then
                    RealDropdownData.Data.MaxLimit = 1
                end

                if RealDropdownData.Data.MinLimit == nil then
                    RealDropdownData.Data.MinLimit = 1
                end

                local MainBg: Frame = Instance.new("Frame", SettingsHolder)
                MainBg.BackgroundTransparency = 1
                MainBg.BorderSizePixel = 0
                MainBg.Size = UDim2.fromOffset(217, 63)
                MainBg.ZIndex = 95

                local NameText: TextLabel = Instance.new("TextLabel", MainBg)
                NameText.BackgroundTransparency = 1
                NameText.Position = UDim2.fromScale(0.09, 0.1)
                NameText.Size = UDim2.fromOffset(171, 16)
                NameText.FontFace = Font.new(Assets.Functions:GetFont("BuilderSans"), Enum.FontWeight.SemiBold)
                NameText.BorderSizePixel = 0
                NameText.Text = DropDownData.Name
                NameText.TextColor3 = Color3.fromRGB(68, 78, 112)
                NameText.TextScaled = true
                NameText.TextWrapped = true
                NameText.TextXAlignment = Enum.TextXAlignment.Left
                NameText.ZIndex = 95

                local RealDropper: ImageButton = Instance.new("ImageButton", MainBg)
                RealDropper.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
                RealDropper.Position = UDim2.fromScale(0.09, 0.5)
                RealDropper.Size = UDim2.fromOffset(185, 24)
                RealDropper.ZIndex = 95
                RealDropper.ImageTransparency = 1
                RealDropper.AutoButtonColor = false
                Instance.new("UICorner", RealDropper).CornerRadius = UDim.new(0, 7)

                local DropArrow: ImageLabel = Instance.new("ImageLabel", RealDropper)
                DropArrow.BackgroundTransparency = 1
                DropArrow.BorderSizePixel = 0
                DropArrow.Position = UDim2.fromScale(0.85, 0.25)
                DropArrow.Size = UDim2.fromOffset(12, 12)
                DropArrow.ZIndex = 95
                DropArrow.Image = Assets.Functions:LoadAsset("Arrow")
                DropArrow.ImageColor3 = Color3.fromRGB(46, 54, 75)
                DropArrow.Rotation = 270

                local DropSelectedText: TextLabel = Instance.new("TextLabel", RealDropper)
                DropSelectedText.BackgroundTransparency = 1
                DropSelectedText.BorderSizePixel = 0
                DropSelectedText.Position = UDim2.fromScale(0.055, 0.208)
                DropSelectedText.Size = UDim2.fromOffset(135, 13)
                DropSelectedText.Text = "None Selected"
                DropSelectedText.TextColor3 = Color3.fromRGB(46, 54, 76)
                DropSelectedText.TextScaled = true
                DropSelectedText.TextWrapped = true
                DropSelectedText.TextXAlignment = Enum.TextXAlignment.Left
                DropSelectedText.ZIndex = 95
                DropSelectedText.FontFace = Font.new(Assets.Functions:GetFont("BuilderMono", {{
                    Name = "Regular",
                    Weight = 400,
                    File = "BuilderMono-Regular",
                }}), Enum.FontWeight.Regular)

                local MainDropdownFrame: Frame = Instance.new("Frame", Window)
                MainDropdownFrame.BackgroundColor3 = Color3.fromRGB(14, 16,23)
                MainDropdownFrame.Position = UDim2.fromScale(1.05, 0.4)
                MainDropdownFrame.Size = UDim2.fromOffset(155, 187)
                MainDropdownFrame.ZIndex = 96
                MainDropdownFrame.Visible = false
                Instance.new("UICorner", MainDropdownFrame).CornerRadius = UDim.new(0, 12)

                local OptionsFrame: ScrollingFrame = Instance.new("ScrollingFrame", MainDropdownFrame)
                OptionsFrame.BackgroundTransparency = 1
                OptionsFrame.Position = UDim2.fromScale(0.071, 0.121)
                OptionsFrame.Size = UDim2.fromOffset(133, 156)
                OptionsFrame.ZIndex = 96
                OptionsFrame.CanvasSize = UDim2.fromScale(0, 0)
                OptionsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
                OptionsFrame.ClipsDescendants = true
                OptionsFrame.ScrollBarThickness = 0
                Instance.new("UICorner", OptionsFrame).CornerRadius = UDim.new(0, 7)

                local OptionsLayout: UIListLayout = Instance.new("UIListLayout", OptionsFrame)
                OptionsLayout.Padding = UDim.new(0, 2)
                OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder

                for i,v in DropDownData.Options do
                    local DropOption = {
                        Name = v,
                        Selected = false :: boolean,
                        Functions = {}
                    }

                    local OptionBg: ImageButton = Instance.new("ImageButton", OptionsFrame)
                    OptionBg.BackgroundTransparency = 1
                    OptionBg.BorderSizePixel = 0
                    OptionBg.Size = UDim2.fromOffset(133, 14)
                    OptionBg.ZIndex = 96
                    OptionBg.ImageTransparency = 1
                    OptionBg.AutoButtonColor = false
                    
                    local OptionText: TextLabel = Instance.new("TextLabel", OptionBg)
                    OptionText.BackgroundTransparency = 1
                    OptionText.BorderSizePixel = 0
                    OptionText.Position = UDim2.fromScale(0.038, 0.071)
                    OptionText.Size = UDim2.fromOffset(114, 12)
                    OptionText.ZIndex = 96
                    OptionText.FontFace = Font.new(Assets.Functions:GetFont("BuilderSans"), Enum.FontWeight.SemiBold)
                    OptionText.Text = v
                    OptionText.TextScaled = true
                    OptionText.TextWrapped = true
                    OptionText.TextStrokeTransparency = 1
                    OptionText.TextXAlignment = Enum.TextXAlignment.Left

                    local SelectedBox: Frame = Instance.new("Frame", OptionBg)
                    SelectedBox.BackgroundColor3 = UIData.Theme.Other
                    SelectedBox.Position = UDim2.fromScale(0.045, 0.296)
                    SelectedBox.Size = UDim2.fromOffset(5, 5)
                    SelectedBox.ZIndex = 96
                    SelectedBox.Visible = false
                    Instance.new("UICorner", SelectedBox).CornerRadius = UDim.new(1, 0)
                    table.insert(UIData.CustomizableItems.Other, {
                        CanChange = true,
                        Item = SelectedBox
                    })

                    function DropOption.Functions:SetValue(selected: boolean?, saveconfig: boolean?, Load: boolean?, removemincheck: boolean?)
                        if selected == nil then
                            selected = not DropOption.Selected
                        end

                        if saveconfig == nil then
                            saveconfig = true
                        end

                        if selected ~= nil then -- gotta do the ~= nil cuz my fucking lsp wont let me js set it
                            if RealDropdownData.SelectedAmount >= RealDropdownData.Data.MaxLimit and RealDropdownData.Data.MaxLimit == 1 and selected then
                                for i,v in RealDropdownData.Selected do
                                    v:SetValue(false, saveconfig, false, true)
                                    break
                                end
                            end

                            if RealDropdownData.SelectedAmount < RealDropdownData.Data.MaxLimit or not selected then
                                if not selected and RealDropdownData.Data.MinLimit and (RealDropdownData.SelectedAmount - 1) ~= (RealDropdownData.Data.MinLimit - 1) or removemincheck or selected or 0 >= RealDropdownData.Data.MinLimit then
                                    SelectedBox.Visible = selected
                                    DropOption.Selected = selected

                                    if selected then
                                        if not RealDropdownData.Selected[v] then
                                            RealDropdownData.Selected[v] = DropOption
                                            RealDropdownData.SelectedAmount += 1
                                            OptionText.Position = UDim2.fromScale(0.143, 0.071)
                                        end
                                    else
                                        if RealDropdownData.Selected[v] then
                                            RealDropdownData.Selected[v] = nil
                                            RealDropdownData.SelectedAmount = math.clamp(RealDropdownData.SelectedAmount - 1, 0, math.huge)
                                            OptionText.Position = UDim2.fromScale(0.038, 0.071)
                                        end
                                    end

                                    local RealSelected = {}
                                    for i,v in RealDropdownData.Selected do
                                        table.insert(RealSelected, v.Name)
                                    end

                                    if RealDropdownData.Data.MaxLimit == 1 then
                                        RealDropdownData.Data.CallingFunction(RealDropdownData, RealSelected[1])
                                    else
                                        local NewFormat = {}
                                        for i,v in RealDropdownData.Selected do
                                            NewFormat[v.Name] = selected
                                        end

                                        RealDropdownData.Data.CallingFunction(RealDropdownData, NewFormat)
                                    end

                                    if saveconfig then
                                        Night.CurrentConfig.Dropdowns[RealDropdownData.Data.Flag] = RealSelected
                                        Assets.Config:Save(Night.CurrentConfig, tostring(Night.Game).."/"..tostring(Night.CurrentConfig.ConfigName), {tostring(Night.Game)})
                                    end

                                    local NewText: string = ""
                                    for i,v in RealDropdownData.Selected do
                                        local Length: number = #NewText
                                        local NewLength = Length + #i

                                        if NewLength > 24 then
                                            NewText = NewText .. ", ..."
                                            break
                                        else
                                            if NewText ~= "" then
                                                NewText = NewText .. ", " .. i
                                            else
                                                NewText = NewText .. i
                                            end
                                        end
                                    end
                                    
                                    if NewText == "" then
                                        NewText = "None Selected"
                                    end

                                    DropSelectedText.Text = NewText
                                end
                            end
                        end
                    end

                    Assets.Connections:Add(OptionBg.MouseButton1Click:Connect(function()
                        DropOption.Functions:SetValue(nil)
                    end), {RealDropdownData.Connections, RealModuleData.Connections, WindowData.Connections})

                    setmetatable(DropOption, {
                        __index = DropOption.Functions
                    })

                    RealDropdownData.RealOptions[DropOption.Name] = DropOption
                    RealDropdownData.OptionAmount += 1
                end

                function RealDropdownData.Functions:ToggleSideMenu(Visible: boolean?)
                    if Visible == nil then
                        Visible = not MainDropdownFrame.Visible 
                    end

                    if Visible ~= nil then -- lsp moment 
                        MainDropdownFrame.Visible = Visible
                        if Visible then
                            DropArrow.Rotation = 90
                        else
                            DropArrow.Rotation = 270
                        end
                    end
                end

                Assets.Connections:Add(RealDropper.MouseButton1Click:Connect(function()
                    RealDropdownData.Functions:ToggleSideMenu()
                end), {RealDropdownData.Connections, RealModuleData.Connections, WindowData.Connections})

                function RealDropdownData.Functions:SetVisiblity(Visible: boolean)
                    if Visible == nil then
                        Visible = not MainBg.Visible
                    end

                    MainBg.Visible = Visible
                end

                function RealDropdownData.Functions:SetValue(NewValue: string | {}, SetConfig: boolean?, Load: boolean?)
                    local Value = NewValue
                    if typeof(NewValue) == "string" then
                        Value = {NewValue}
                    end

                    if SetConfig == nil then
                        SetConfig = true
                    end

                    for i,v in RealDropdownData.RealOptions do
                        v:SetValue(table.find(Value, i) and true or false, SetConfig, Load)
                    end
                end

                setmetatable(RealDropdownData, {
                    __index = RealDropdownData.Functions
                })

                RealModuleData.Settings.Dropdowns[DropDownData.Flag] = RealDropdownData
                return RealDropdownData
            end

            function RealModuleData.Functions:KeyBind(KBData: {Name: string, Flag: string, MobileText: string?, DestroyMobileButtonOnDisable: boolean?, Default: Enum.KeyCode?, CallingFunction: (self: any, Bind: Enum.KeyCode?) -> ()?, Events: {Began: (data: any, Input: InputObject) -> ()?, Ended: (data: any, Input: InputObject) -> ()?}?})
                local RealKeybindData = {
                    Data = KBData,
                    Bind = nil :: Enum.KeyCode?,
                    Binding = false :: boolean,
                    RealText = "" :: string?,
                    MobileButton = nil,
                    Functions = {},
                    Connections = {}
                }

                local MainBg: Frame = Instance.new("Frame", SettingsHolder)
                MainBg.BackgroundTransparency = 1
                MainBg.BorderSizePixel = 0
                MainBg.Size = UDim2.fromOffset(217, 30)
                MainBg.ZIndex = 95

                local Text: TextLabel = Instance.new("TextLabel", MainBg)
                Text.BackgroundTransparency = 1
                Text.BorderSizePixel = 0
                Text.Position = UDim2.fromScale(0.07, 0.25)
                Text.Size = UDim2.fromOffset(80, 16)
                Text.FontFace = Font.new(Assets.Functions:GetFont("BuilderSans"), Enum.FontWeight.SemiBold)
                Text.Text = KBData.Name
                Text.TextColor3 = Color3.fromRGB(68, 78, 112)
                Text.TextScaled = true
                Text.TextWrapped = true
                Text.TextXAlignment = Enum.TextXAlignment.Left
                Text.ZIndex = 95

                local KeybindBox: ImageButton = Instance.new("ImageButton", MainBg)
                KeybindBox.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
                KeybindBox.Position = UDim2.fromScale(0.58, 0.1)
                KeybindBox.Size = UDim2.fromOffset(80, 24)
                KeybindBox.AutoButtonColor = false
                KeybindBox.ImageTransparency = 1
                KeybindBox.ZIndex = 95
                Instance.new("UICorner", KeybindBox).CornerRadius = UDim.new(0, 6)
                
                local CurrentBindText: TextLabel = Instance.new("TextLabel", KeybindBox)
                CurrentBindText.BackgroundTransparency = 1
                CurrentBindText.BorderSizePixel = 0
                CurrentBindText.Position = UDim2.fromScale(0.05, 0.24)
                CurrentBindText.Size = UDim2.fromOffset(70, 13)
                CurrentBindText.ZIndex = 95
                CurrentBindText.TextColor3 = Color3.fromRGB(46, 54, 76)
                CurrentBindText.Text = "Bind"
                CurrentBindText.TextScaled = true
                CurrentBindText.TextWrapped = true
                CurrentBindText.TextStrokeTransparency = 1
                CurrentBindText.FontFace = Font.new(Assets.Functions:GetFont("BuilderMono", {{
                    Name = "Bold",
                    Weight = 700,
                    File = "BuilderMono-Bold",
                }}), Enum.FontWeight.Bold)

                local PlacePos = #UIData.CustomizableItems.Other + 1
                table.insert(UIData.CustomizableItems.Other, PlacePos, {
                    CanChange = false,
                    Item = CurrentBindText
                })

                function RealKeybindData.Functions:SetVisiblity(Visible: boolean)
                    if Visible == nil then
                        Visible = not MainBg.Visible
                    end
                    
                    MainBg.Visible = Visible
                end

                RealKeybindData.RealText = RealKeybindData.Data.Name
                if KBData.MobileText then
                    RealKeybindData.RealText = RealKeybindData.Data.MobileText
                end

                function RealKeybindData.Functions:SetValue(KeyBind: Enum.KeyCode | string, SaveConfig: boolean, Load: boolean?, CanBeReset: boolean?)
                    local RealKeybind = KeyBind :: Enum.KeyCode
                    if typeof(KeyBind) == "string" and not Night.Mobile then
                        local HasKeybind: boolean = false
                        for i,v in Enum.KeyCode:GetEnumItems() do
                            if v.Name == KeyBind then
                                RealKeybind = v
                            end
                        end

                        if not HasKeybind then
                            for i,v in Enum.UserInputType:GetEnumItems() do
                                if v.Name == KeyBind then
                                    RealKeybind = v
                                end
                            end
                        end
                    end

                    if not RealKeybind then
                        return
                    end

                    if SaveConfig == nil then
                        SaveConfig = true
                    end

                    if Night.Mobile then
                        if RealKeybindData.Bind or not RealKeybind then
                            if CanBeReset then
                                RealKeybindData.Bind = nil 
                                CurrentBindText.TextColor3 = Color3.fromRGB(46, 54, 76)    
                                CurrentBindText.Text = "Bind" 

                                if RealKeybindData.MobileButton then
                                    RealKeybindData.MobileButton:Destroy()
                                    RealKeybindData.MobileButton = nil
                                end
                            end
                        else
                            if RealKeybind then
                                CurrentBindText.Text = "Unbind"
                                RealKeybindData.Bind = "Button"
                                CurrentBindText.TextColor3 = UIData.Theme.Other

                                if Load and not KBData.DestroyMobileButtonOnDisable or not Load then
                                    RealKeybindData.MobileButton = Assets.Functions:CreateMobileButton({
                                        Name = RealKeybindData.RealText,
                                        Flag = RealKeybindData.Data.Flag.."MobileButton",
                                        Events = {
                                            Began = function(self, Input: InputObject)
                                                if RealKeybindData.Data.Events and RealKeybindData.Data.Events.Began then
                                                    RealKeybindData.Data.Events.Began(RealKeybindData, Input)
                                                end
                                            end,
                                            Ended = function(self, Held: boolean, Input: InputObject)
                                                if RealKeybindData.Data.Events and RealKeybindData.Data.Events.Ended then
                                                    RealKeybindData.Data.Events.Ended(RealKeybindData, Input)
                                                end
                                            end
                                        }
                                    })
                                end

                                if KBData.DestroyMobileButtonOnDisable then
                                    table.insert(RealModuleData.MData.KeybindsToHide, RealKeybindData)
                                end
                            end
                        end
                    else
                        if RealKeybind and RealKeybind.Name then
                            RealKeybindData.Binding = false
                            if RealKeybind == RealKeybindData.Bind and CanBeReset then
                                RealKeybindData.Bind = nil 
                                CurrentBindText.TextColor3 = Color3.fromRGB(46, 54, 76)    
                                CurrentBindText.Text = "Bind" 
                            else
                                RealKeybindData.Bind = RealKeybind
                                CurrentBindText.TextColor3 = UIData.Theme.Other
                                CurrentBindText.Text = RealKeybind.Name                              
                            end
                        else
                            if Load then
                                RealKeybindData.Bind = nil 
                                CurrentBindText.TextColor3 = Color3.fromRGB(46, 54, 76)    
                                CurrentBindText.Text = "Bind" 
                            end
                        end
                    end   
                       
                    
                    UIData.CustomizableItems.Other[PlacePos].CanChange = RealKeybindData.Bind ~= nil
                    if RealKeybindData.Data.CallingFunction then
                        RealKeybindData.Data.CallingFunction(RealKeybindData, RealKeybindData.Bind)
                    end

                    if RealModuleData.Data.KeybindCallingFunction then
                        RealModuleData.Data.KeybindCallingFunction(ModuleData, RealKeybindData.Bind)
                    end

                    if SaveConfig then
                        local SaveName = RealKeybindData.Bind
                        if typeof(SaveName) == "EnumItem" then
                            SaveName = SaveName.Name
                        end

                        if RealKeybindData.Bind then
                            Night.CurrentConfig.Keybinds[RealKeybindData.Data.Flag] = SaveName
                        else
                            Night.CurrentConfig.Keybinds[RealKeybindData.Data.Flag] = nil
                        end
                        Assets.Config:Save(Night.CurrentConfig, tostring(Night.Game).."/"..tostring(Night.CurrentConfig.ConfigName), {tostring(Night.Game)})
                    end
                end

                Assets.Connections:Add(KeybindBox.MouseButton1Click:Connect(function()
                    if not Night.Mobile then
                        RealKeybindData.Binding = true
                        CurrentBindText.Text = "Binding"
                    else
                        RealKeybindData.Functions:SetValue("Mobile", true, false, true)
                    end
                end), {RealKeybindData.Connections, RealModuleData.Connections, WindowData.Connections})

                if not Night.Mobile then
                    Assets.Connections:Add(UserInputService.InputBegan:Connect(function(Input: InputObject)
                        if UserInputService:GetFocusedTextBox() then return end

                        if not RealKeybindData.Binding then
                            if RealKeybindData.Bind and Input.KeyCode == RealKeybindData.Bind or Input.UserInputType == RealKeybindData.Bind then
                                if RealKeybindData.Data.Events and RealKeybindData.Data.Events.Began then
                                    RealKeybindData.Data.Events.Began(RealKeybindData, Input)
                                end
                            end
                        else
                            if Input.KeyCode and Input.KeyCode.Name ~= "Unknown" or Input.UserInputType then
                                local Value = Input.KeyCode.Name ~= "Unknown" and Input.KeyCode or Input.UserInputType
                                RealKeybindData.Binded = true
                                RealKeybindData.Functions:SetValue(Value, true, false, true)
                            end
                        end
                    end), {RealKeybindData.Connections, RealModuleData.Connections, WindowData.Connections})

                    Assets.Connections:Add(UserInputService.InputEnded:Connect(function(Input: InputObject)
                        if UserInputService:GetFocusedTextBox() then return end

                        if not RealKeybindData.Binding and not RealKeybindData.Binded then
                            if RealKeybindData.Data.Events and RealKeybindData.Data.Events.Ended and RealKeybindData.Bind then
                                if Input.KeyCode == RealKeybindData.Bind or Input.UserInputType == RealKeybindData.Bind then
                                    RealKeybindData.Data.Events.Ended(RealKeybindData, Input)
                                end
                            end
                        else
                            RealKeybindData.Binded = false
                        end
                    end), {RealKeybindData.Connections, RealModuleData.Connections, WindowData.Connections}, RealModuleData.Connections, "value")
                end

                setmetatable(RealKeybindData, {
                    __index = RealKeybindData.Functions
                })

                RealModuleData.Settings.Keybinds[KBData.Flag] = RealKeybindData
                return RealKeybindData
            end

            function RealModuleData.Functions:Button(ButtonData: {Name: string, Flag: string, CallingFunction: (self: any) -> ()})
                local RealButtonData = {
                    Data = ButtonData,
                    Functions = {},
                    Connections = {}
                }

                local MainBg: Frame = Instance.new("Frame", SettingsHolder)
                MainBg.BackgroundTransparency = 1
                MainBg.BorderSizePixel = 0
                MainBg.Size = UDim2.fromOffset(217, 30)
                MainBg.ZIndex = 95

                local Text: TextLabel = Instance.new("TextLabel", MainBg)
                Text.BackgroundTransparency = 1
                Text.BorderSizePixel = 0
                Text.Position = UDim2.fromScale(0.1, 0.233)
                Text.Size = UDim2.fromOffset(86, 16)
                Text.ZIndex = 95
                Text.FontFace = Font.new(Assets.Functions:GetFont("BuilderSans"), Enum.FontWeight.SemiBold)
                Text.Text = ButtonData.Name
                Text.TextColor3 = Color3.fromRGB(68, 78, 112)
                Text.TextScaled = true
                Text.TextStrokeTransparency = 1
                Text.TextWrapped = true
                Text.TextXAlignment = Enum.TextXAlignment.Left

                local ClickBox: ImageButton = Instance.new("ImageButton", MainBg)
                ClickBox.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
                ClickBox.Position = UDim2.fromScale(0.653, 0.1)
                ClickBox.Size = UDim2.fromOffset(60, 24)
                ClickBox.ZIndex = 95
                ClickBox.AutoButtonColor = false
                ClickBox.ImageTransparency = 1
                Instance.new("UICorner", ClickBox).CornerRadius = UDim.new(0, 6)

                local ClickText: TextLabel = Instance.new("TextLabel", ClickBox)
                ClickText.BackgroundTransparency = 1
                ClickText.BorderSizePixel = 0
                ClickText.Position = UDim2.fromScale(0.145, 0.25)
                ClickText.Size = UDim2.fromOffset(39, 13)
                ClickText.ZIndex = 95
                ClickText.TextColor3 = Color3.fromRGB(46, 54, 76)
                ClickText.Text = "Click"
                ClickText.TextScaled = true
                ClickText.TextWrapped = true
                ClickText.TextStrokeTransparency = 1 
                ClickText.FontFace = Font.new(Assets.Functions:GetFont("BuilderMono", {{
                    Name = "Bold",
                    Weight = 700,
                    File = "BuilderMono-Bold",
                }}), Enum.FontWeight.Bold)

                function RealButtonData.Functions:SetVisiblity(Visible: boolean)
                    if Visible == nil then
                        Visible = not MainBg.Visible
                    end

                    MainBg.Visible = Visible
                end

                function RealButtonData.Functions:Destroy()
                    for i,v in RealButtonData.Connections do
                        v:Disconnect()
                    end

                    table.clear(RealButtonData)
                    MainBg:Destroy()
                end

                Assets.Connections:Add(ClickBox.MouseButton1Click:Connect(function()
                    RealButtonData.Data.CallingFunction(RealButtonData)
                end), {RealButtonData.Connections, RealModuleData.Connections, WindowData.Connections})

                RealModuleData.Settings.Buttons[ButtonData.Flag] = RealButtonData
                setmetatable(RealButtonData, {
                    __index = RealButtonData.Functions
                })
                
                return RealButtonData
            end

            RealModuleData.Functions:KeyBind({
                Name = "Toggle",
                MobileText = ModuleData.Name,
                Flag = RealModuleData.Data.Flag.."ModuleToggle",
                Default = ModuleData.DefaultKeybind,
                Events = {
                    Began = function()
                        RealModuleData.Functions:SetValue(nil, true, true)
                    end
                }
            })

            function RealModuleData.Functions:Destroy()
                for i,v in RealModuleData.Connections do
                    v:Disconnect()
                end

                WindowData.Modules.Modules[ModuleData.Flag] = nil
                RealModuleData.Functions:SetValue(false, false, false)
                table.clear(RealModuleData)
                RealModuleHolder:Destroy()
            end

            setmetatable(RealModuleData, {
                __index = RealModuleData.Functions
            })

            WindowData.Modules.Modules[ModuleData.Flag] = RealModuleData
            return RealModuleData
        end
    end

    setmetatable(WindowData, {
        __index = WindowData.Functions
    })

    setmetatable(WindowData.Modules, {
        __index = WindowData.Modules.Modules
    })

    return WindowData
end

Night.MainWindow = CreateWindow({
    Name = "Night",
    Flag = "MainTabWindow",
    Size = UDim2.fromOffset(255, 470),
    Position = UDim2.fromScale(0.006, 0.085),
    DefaultPosition = UDim2.fromScale(0.006, 0.085),
    Dashboard = true
})

local NextPos = 0.01
function Assets.Functions:CreateTab(Data: {Name: string, Flag: string, Icon: string, DefaultPosX: number?, Order: number?})
    local DashButton = Night.MainWindow:MakeDashboardButton({
        Text = {Text = Data.Name},
        Top = true,
        Window = Data.Flag,
        Order = Data.Order
    })

    local Pos = Data.DefaultPosX
    if not Pos then
        NextPos += (0.115 - ((1 - UIScale.Scale)/10) + 0.01)
        Pos = NextPos
    end

    return CreateWindow({
        Name = Data.Name,
        Flag = Data.Flag,
        Size = UDim2.fromOffset(255, 470),
        Position = UDim2.fromScale(0.006, 0.085),
        DefaultPosition = UDim2.fromScale(Pos, 0.085),
        Visible = false,
        DashButton = DashButton,
        Icon = {Icon = Data.Icon}
    })
end

function Assets.Functions:Countdown(Time: number, Unit: string)
    local CountDownData = {
        MainFrame = nil :: Frame?,
        Functions = {},
    }


    local MainFrame: Frame = Instance.new("Frame", MainScreenGui)
    MainFrame.BackgroundColor3 = Color3.fromRGB(8, 10, 13)
    MainFrame.Position = UDim2.fromScale(0.006, 0.695)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0)
    MainFrame.Position = UDim2.fromScale(0.5, 0.7)
    MainFrame.Size = UDim2.fromOffset(200, 60)
    MainFrame.ZIndex = 2
    CountDownData.MainFrame = MainFrame
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 15)
    CreateShadow(MainFrame)

    local BarMain: Frame = Instance.new("Frame", MainFrame)
    BarMain.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
    BarMain.AnchorPoint = Vector2.new(0.5, 0.5)
    BarMain.Position = UDim2.fromScale(0.5, 0.45)
    BarMain.Size = UDim2.fromOffset(127, 6)
    BarMain.ZIndex = 2
    Instance.new("UICorner", BarMain).CornerRadius = UDim.new(0, 8)

    local BarFill: Frame = Instance.new("Frame", BarMain)
    BarFill.BackgroundColor3 = UIData.Theme.Other
    BarFill.Position = UDim2.fromScale(0, 0)
    BarFill.Size = UDim2.fromScale(1, 1)
    BarFill.ZIndex = 2
    Instance.new("UICorner", BarFill).CornerRadius = UDim.new(0, 8)
    table.insert(UIData.CustomizableItems.Other, {
        CanChange = true,
        Item = BarFill
    })

    local TimeLeftText: TextLabel = Instance.new("TextLabel", MainFrame)
    TimeLeftText.BackgroundTransparency = 1
    TimeLeftText.BorderSizePixel = 0
    TimeLeftText.AnchorPoint = Vector2.new(0.5, 0)
    TimeLeftText.Position = UDim2.fromScale(0.5, 0.6)
    TimeLeftText.Size = UDim2.fromOffset(99, 15)
    TimeLeftText.Font = Enum.Font.BuilderSans
    TimeLeftText.Text = tostring(Time)..(Unit or "s")
    TimeLeftText.TextColor3 = Color3.fromRGB(69, 79, 113)
    TimeLeftText.TextScaled = true
    TimeLeftText.TextWrapped = true
    TimeLeftText.ZIndex = 2

    function CountDownData.Functions:Destroy()
        MainFrame:Destroy()
        table.clear(CountDownData)
    end

    function CountDownData.Functions:SetVisiblity(Visible: boolean)
        if Visible == nil then
            Visible = not MainFrame.Visible
        end

        MainFrame.Visible = Visible        
    end

    function CountDownData.Functions:Update(NewTime: number, Unit: string)
        TimeLeftText.Text = tostring(NewTime)..(Unit or "s")
        TweenService:Create(BarFill, TweenInfo.new(0.15), {Size = UDim2.fromScale(math.clamp(tonumber(NewTime) / Time, 0, 1), 1)}):Play()
    end


    setmetatable(CountDownData, {
        __index = CountDownData.Functions
    })

    return CountDownData
end

function Assets.Functions:CreateTargetHud(Data: {Player: Player?, UserData: {Name: string, DisplayName: string, ProfilePic: string?}?, Health: {Current: number, Max: number}?}?)
    if UIData.TargetHud then
        return UIData.TargetHud
    end
    
    local TargetHudData = {
        Data = Data,
        DraggingData = {
            Active = false :: boolean,
            StartInputPos = nil :: Vector3?,
            FrameStartPos = nil :: UDim2?,
            Window = nil :: Frame?
        },
        MainFrame = nil :: Frame?,
        Functions = {},
        Connections = {}
    }

    if not TargetHudData.Data then
        TargetHudData.Data = {}
    end

    if not TargetHudData.Data.UserData then
        if TargetHudData.Data.Player then
            TargetHudData.Data.UserData = {
                Name = TargetHudData.Data.Player.Name,
                DisplayName = TargetHudData.Data.Player.DisplayName,
                ProfilePic = Players:GetUserThumbnailAsync(TargetHudData.Data.Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            }
        else
            TargetHudData.Data.UserData = {
                Name = "UserName",
                DisplayName = "DisplayName",
                ProfilePic = ""
            }
        end
    end

    if not TargetHudData.Data.Health then
        TargetHudData.Data.Health = {
            Current = 100,
            Max = 100
        }
    end

    local TargetHudConfig = Night.CurrentConfig.Others.TabData.TargetHud
    local MainFrame: Frame = Instance.new("Frame", MainScreenGui)
    MainFrame.BackgroundColor3 = Color3.fromRGB(8, 10, 13)
    MainFrame.Position = UDim2.fromScale(0.006, 0.695)
    MainFrame.Size = UDim2.fromOffset(289, 120)
    MainFrame.ZIndex = 2
    TargetHudData.MainFrame = MainFrame
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 15)
    CreateShadow(MainFrame)

    if TargetHudConfig then
        if TargetHudConfig.Position then
            MainFrame.Position = UDim2.fromScale(table.unpack(TargetHudConfig.Position))            
        end

        if TargetHudConfig.Visible ~= nil then
            MainFrame.Visible = TargetHudConfig.Visible
        end
    end

    local DisplayNameText: TextLabel = Instance.new("TextLabel", MainFrame)
    DisplayNameText.BackgroundTransparency = 1
    DisplayNameText.BorderSizePixel = 0
    DisplayNameText.Position = UDim2.fromScale(0.349, 0.28)
    DisplayNameText.Size = UDim2.fromOffset(137, 20)
    DisplayNameText.Font = Enum.Font.BuilderSansBold
    DisplayNameText.Text = TargetHudData.Data.UserData.DisplayName
    DisplayNameText.TextColor3 = Color3.fromRGB(101, 116, 166)
    DisplayNameText.TextScaled = true
    DisplayNameText.TextWrapped = true
    DisplayNameText.TextXAlignment = Enum.TextXAlignment.Left
    DisplayNameText.TextStrokeTransparency = 1
    DisplayNameText.ZIndex = 2

    local UserNameText: TextLabel = Instance.new("TextLabel", MainFrame)
    UserNameText.BackgroundTransparency = 1
    UserNameText.BorderSizePixel = 0
    UserNameText.Position = UDim2.fromScale(0.349, 0.44)
    UserNameText.Size = UDim2.fromOffset(137, 17)
    UserNameText.FontFace = Font.new(Assets.Functions:GetFont("BuilderSans"), Enum.FontWeight.SemiBold)
    UserNameText.Text = "@"..TargetHudData.Data.UserData.Name
    UserNameText.TextColor3 = Color3.fromRGB(69, 79, 113)
    UserNameText.TextScaled = true
    UserNameText.TextWrapped = true
    UserNameText.TextStrokeTransparency = 1
    UserNameText.TextXAlignment = Enum.TextXAlignment.Left
    UserNameText.ZIndex = 2

    local PFPHolder: Frame = Instance.new("Frame", MainFrame)
    PFPHolder.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
    PFPHolder.Position = UDim2.fromScale(0.098, 0.225)
    PFPHolder.Size = UDim2.fromOffset(65, 65)
    PFPHolder.ZIndex = 2
    Instance.new("UICorner", PFPHolder).CornerRadius = UDim.new(0, 8)

    local ActualPFPIcon: ImageLabel = Instance.new("ImageLabel", PFPHolder)
    ActualPFPIcon.BackgroundTransparency = 1
    ActualPFPIcon.Position = UDim2.fromScale(0, -0.062)
    ActualPFPIcon.Size = UDim2.fromOffset(65, 65)
    ActualPFPIcon.Image = TargetHudData.Data.UserData.ProfilePic or ""
    ActualPFPIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    ActualPFPIcon.ZIndex = 2
    Instance.new("UICorner", ActualPFPIcon).CornerRadius = UDim.new(0, 8)

    local HealthBarMain: Frame = Instance.new("Frame", MainFrame)
    HealthBarMain.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
    HealthBarMain.Position = UDim2.fromScale(0.35, 0.63)
    HealthBarMain.Size = UDim2.fromOffset(127, 6)
    HealthBarMain.ZIndex = 2
    Instance.new("UICorner", HealthBarMain).CornerRadius = UDim.new(0, 8)

    local HealthBarFill: Frame = Instance.new("Frame", HealthBarMain)
    HealthBarFill.BackgroundColor3 = UIData.Theme.Other
    HealthBarFill.Position = UDim2.fromScale(0, 0)
    HealthBarFill.Size = UDim2.fromScale(math.clamp(TargetHudData.Data.Health.Current / TargetHudData.Data.Health.Max, 0, 1), 1)
    HealthBarFill.ZIndex = 2
    Instance.new("UICorner", HealthBarFill).CornerRadius = UDim.new(0, 8)
    table.insert(UIData.CustomizableItems.Other, {
        CanChange = true,
        Item = HealthBarFill
    })

    local HealthText: TextLabel = Instance.new("TextLabel", MainFrame)
    HealthText.BackgroundTransparency = 1
    HealthText.BorderSizePixel = 0
    HealthText.Position = UDim2.fromScale(0.369, 0.75)
    HealthText.Size = UDim2.fromOffset(99, 15)
    HealthText.Font = Enum.Font.BuilderSans
    HealthText.Text = tostring(TargetHudData.Data.Health.Current).."/"..tostring(TargetHudData.Data.Health.Max)
    HealthText.TextColor3 = Color3.fromRGB(69, 79, 113)
    HealthText.TextScaled = true
    HealthText.TextWrapped = true
    HealthText.ZIndex = 2

    function TargetHudData.Functions:Destroy()
        UIData.TargetHud = nil
        for i,v in TargetHudData.Connections do
            v:Disconnect()
        end

        MainFrame:Destroy()
        table.clear(TargetHudData)
    end

    function TargetHudData.Functions:SetVisiblity(Visible: boolean)
        if Visible == nil then
            Visible = not MainFrame.Visible
        end

        MainFrame.Visible = Visible

        Night.CurrentConfig.Others.TabData.TargetHud = {
            Visible = MainFrame.Visible,
            Position = {MainFrame.Position.X.Scale, MainFrame.Position.Y.Scale}
        }
        
        Assets.Config:Save(Night.CurrentConfig, tostring(Night.Game).."/"..tostring(Night.CurrentConfig.ConfigName), {tostring(Night.Game)})
    end

    function TargetHudData.Functions:Update(NewData: {Player: Player?, UserData: {Name: string, DisplayName: string, ProfilePic: string?}?, Health: {Current: number, Max: number}?, Visible: boolean})
        if not NewData then
            return
        end

        if not NewData.UserData then
            if NewData.Player then
                TargetHudData.Data.UserData = {
                    Name = NewData.Player.Name,
                    DisplayName = NewData.Player.DisplayName,
                    ProfilePic = Players:GetUserThumbnailAsync(NewData.Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                }
            else
                TargetHudData.Data.UserData = {
                    Name = "UserName",
                    DisplayName = "DisplayName",
                    ProfilePic = ""
                }
            end
        else
            TargetHudData.Data.UserData = NewData.UserData
        end

        if not TargetHudData.Data then return end

        DisplayNameText.Text = TargetHudData.Data.UserData.DisplayName
        UserNameText.Text = "@"..TargetHudData.Data.UserData.Name
        ActualPFPIcon.Image = TargetHudData.Data.UserData.ProfilePic

        if not NewData.Health then
            TargetHudData.Data.Health = {
                Current = 100,
                Max = 100
            }
        else
            TargetHudData.Data.Health = NewData.Health
        end


        TweenService:Create(HealthBarFill, TweenInfo.new(0.15), {Size = UDim2.fromScale(math.clamp(TargetHudData.Data.Health.Current / TargetHudData.Data.Health.Max, 0, 1), 1)}):Play()
        HealthText.Text = tostring(TargetHudData.Data.Health.Current).."/"..tostring(TargetHudData.Data.Health.Max)

        if NewData.Visible == nil then
            NewData.Visible = MainFrame.Visible
        end

        TargetHudData.Functions:SetVisiblity(NewData.Visible)
    end

    Assets.Connections:Add(MainFrame.InputBegan:Connect(function(Input: InputObject)
        if ((Input.UserInputType == Enum.UserInputType.MouseButton1) or (Input.UserInputType == Enum.UserInputType.Touch)) and not UIData.Windows.Dragging then
            UIData.Windows.Dragging = MainFrame
            TargetHudData.DraggingData = {
                Active = true :: boolean,
                StartInputPos = Input.Position :: Vector3,
                FrameStartPos = MainFrame.Position :: UDim2,
                Window = MainFrame :: Frame
            }

            UIData.InputFuncs.Changed = function(ChangedInput: InputObject)
                if (ChangedInput.UserInputType == Enum.UserInputType.MouseMovement or ChangedInput.UserInputType == Enum.UserInputType.Touch) then  
                    if TargetHudData.DraggingData.Active then
                        Assets.Functions:Drag(TargetHudData.DraggingData, ChangedInput)
                    end
                end
            end

            UIData.InputFuncs.Ended = function(EndInput: InputObject)
                if (EndInput.UserInputType == Enum.UserInputType.MouseButton1) or (EndInput.UserInputType == Enum.UserInputType.Touch) then
                    UIData.Windows.Dragging = nil
                    TargetHudData.DraggingData = {
                        Active = false :: boolean,
                        StartInputPos = Input.Position :: Vector3,
                        FrameStartPos = MainFrame.Position :: UDim2,
                        Window = MainFrame :: Frame
                    }

                    for i,v in UIData.InputFuncs do
                        UIData.InputFuncs[i] = function() end
                    end
                    
                    Night.CurrentConfig.Others.TabData.TargetHud = {
                        Visible = MainFrame.Visible,
                        Position = {MainFrame.Position.X.Scale, MainFrame.Position.Y.Scale}
                    }

                    Assets.Config:Save(Night.CurrentConfig, tostring(Night.Game).."/"..tostring(Night.CurrentConfig.ConfigName), {tostring(Night.Game)})
                end
            end

        end
    end), {TargetHudData.Connections})

    setmetatable(TargetHudData, {
        __index = TargetHudData.Functions
    })

    if UIData.TargetHud then
        UIData.TargetHud:Destroy()
    end

    UIData.TargetHud = TargetHudData
    return TargetHudData
end

-- hi, we just want to see how popular night is + see if people try to use in other games so we can add more support and get feedback
-- please dont spam
task.spawn(function()
    pcall(function()
        if RequestFunc then
            RequestFunc({
                Url = "https://nehfeauefutth2.vercel.app/execution",
                Method = "GET",
                Headers = {
                    username = tostring(LocalPlayer.Name),
                    placeid = tostring(game.PlaceId)
                }
            })
        end
    end)
end)

function Assets.Functions:GetTargetHud(Create: boolean, Data: {Player: Player?, UserData: {Name: string, DisplayName: string, ProfilePic: string?}?, Health: {Current: number, Max: number}?}?)
    local THUD = UIData.TargetHud
    if not THUD and Create then
        THUD = Assets.Functions:CreateTargetHud(Data)
    end
    
    return THUD
end

function Assets.Functions:DestroyTargetHud()
    local HUD = UIData.TargetHud
    if HUD then
        HUD:Destroy()
    end
end

local ConfigsButton = Night.MainWindow:MakeDashboardButton({
    Text = {
        Text = "Configs",
        Color = Color3.fromRGB(26, 95, 181),
    },
    Icon = {
        Name = "Configs",
        Color = Color3.fromRGB(26, 95, 181)
    },
    CanBeChanged = true,
    Window = "RealConfigTab"
})

local ConfigWindow = CreateWindow({
    Name = "Configs",
    Flag = "RealConfigTab",
    Size = UDim2.fromOffset(725, 440),
    Position = UDim2.fromScale(0.5, 0.5),
    DefaultPosition = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Text = {Postion = UDim2.fromScale(0.036, 0.371)},
    ClosePos = UDim2.fromScale(0.934, 0.343),
    Visible = false,
    DashButton = ConfigsButton
})

local ConfigList: ScrollingFrame = Instance.new("ScrollingFrame", ConfigWindow.Window)
ConfigList.BackgroundTransparency = 1
ConfigList.BorderSizePixel = 0
ConfigList.Position = UDim2.fromScale(0.034, 0.197)
ConfigList.Size = UDim2.fromOffset(672, 326)
ConfigList.ClipsDescendants = true
ConfigList.ScrollBarThickness = 0
ConfigList.CanvasSize = UDim2.fromScale(0, 0)
ConfigList.AutomaticCanvasSize = Enum.AutomaticSize.Y
ConfigList.ZIndex = 90

local ConfigLayout: UIGridLayout = Instance.new("UIGridLayout", ConfigList)
ConfigLayout.CellPadding = UDim2.fromOffset(20, 21)
ConfigLayout.CellSize = UDim2.fromOffset(210, 150)
ConfigLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

function Assets.Functions:CreateConfigOption(Data: {Name: string, New: boolean?, Default: boolean?, ConfigFolder: string?, Load: boolean?})
    local RealData = {
        Data = Data,
        Frame = nil :: ImageButton?,
        CurrentConfigName = nil :: string?,
        Selected = false,
        Functions = {},
        Connections = {}
    }

    local DescriptionText = "Load a config you made"
    if RealData.Data.New then
        DescriptionText = "Make a new config"
    end

    RealData.Flag = Data.Name.."Option"
    RealData.CurrentConfigName = RealData.Data.Name
    local MainFrame: ImageButton = Instance.new("ImageButton", ConfigList)
    MainFrame.BackgroundColor3 = Color3.fromRGB(14, 16, 23)
    RealData.Frame = MainFrame
    MainFrame.ZIndex = 90
    MainFrame.AutoButtonColor = false
    MainFrame.ImageTransparency = 1
    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

    local Icon: ImageLabel = Instance.new("ImageLabel", MainFrame)
    Icon.BackgroundTransparency = 1
    Icon.BorderSizePixel = 0
    Icon.Position = UDim2.fromScale(0.375, 0.193)
    Icon.Size = UDim2.fromOffset(50, 50)
    Icon.Image = Assets.Functions:LoadAsset("Config")
    Icon.ImageColor3 = UIData.Theme.Other
    Icon.ZIndex = 90
    Icon.ImageTransparency = 0.6
    table.insert(UIData.CustomizableItems.Other, {
        CanChange = true,
        Item = Icon
    })
    local Title: TextBox = Instance.new("TextBox", MainFrame)
    Title.BackgroundTransparency = 1
    Title.BorderSizePixel = 0
    Title.Position = UDim2.fromScale(0.065, 0.68)
    Title.Size = UDim2.fromOffset(142, 19)
    Title.Font = Enum.Font.BuilderSansBold
    Title.Text = Data.Name
    Title.PlaceholderText = "Enter Name"
    Title.PlaceholderColor3 = Color3.fromRGB(101, 116, 166)
    Title.TextColor3 = Color3.fromRGB(101, 116, 166)
    Title.TextScaled = true
    Title.TextStrokeTransparency = 1
    Title.ZIndex = 90
    Title.TextWrapped = true
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local Description: TextLabel = Instance.new("TextLabel", MainFrame)
    Description.BackgroundTransparency = 1
    Description.BorderSizePixel = 0
    Description.Position = UDim2.fromScale(0.065, 0.807)
    Description.Size = UDim2.fromOffset(120, 15)
    Description.Font = Enum.Font.BuilderSansMedium
    Description.Text = DescriptionText
    Description.TextColor3 = Color3.fromRGB(60, 69, 99)
    Description.TextScaled = true
    Description.TextStrokeTransparency = 1
    Description.TextWrapped = true
    Description.TextXAlignment = Enum.TextXAlignment.Left
    Description.ZIndex = 90

    local DeleteButton: ImageButton = Instance.new("ImageButton", MainFrame)
    DeleteButton.BackgroundTransparency = 1
    DeleteButton.BorderSizePixel = 0
    DeleteButton.Position = UDim2.fromScale(0.836, 0.773)
    DeleteButton.Size = UDim2.fromOffset(24, 24)
    DeleteButton.Image = Assets.Functions:LoadAsset("Trash")
    DeleteButton.ImageColor3 = Color3.fromRGB(180, 6, 9)
    DeleteButton.ImageTransparency = 0.4
    DeleteButton.ZIndex = 90


    function RealData.Functions:Destroy()
        for i,v in RealData.Connections do
            v:Disconnect()
        end

        UIData.ConfigButtons[RealData.Flag] = nil
        table.clear(RealData)

        MainFrame:Destroy()
    end

    function RealData.Functions:Set(Config, SetValue: string, ConfigPath: string?)
        Config.ConfigName = SetValue
        local suc, String = pcall(HttpService.JSONEncode, HttpService, Config)
        if suc and String then
            local sucwrite = pcall(writefile, "NewNight/Configs/"..tostring(RealData.Data.ConfigFolder).."/"..SetValue..".json", String)
            if not sucwrite then
                return Assets.Functions:CreateNotification({
                    Title = "Failed to make config.",
                    Description = "Failed to make config, please try again.",
                    Duration = 3
                })
            end

            if delfile and ConfigPath and isfile(ConfigPath) then
                delfile(ConfigPath)    
            end

            RealData.CurrentConfigName = SetValue
            RealData.Data.Name = SetValue
        end

        return suc
    end

    function RealData.Functions:SetSelect(Selected: boolean?, InLoop: boolean?, CanDisable: boolean?)
        if Selected == nil then
            Selected = not RealData.Selected
        end

        if not CanDisable and not Selected then
            return
        end

        RealData.Selected = Selected
        if Selected then
            if Data.Load == false then
                Assets.Config:Load(tostring(Night.Game).."/"..RealData.CurrentConfigName)
            end

            TweenService:Create(Icon, TweenInfo.new(0.15), {ImageTransparency = 0}):Play()

            if writefile then
                pcall(writefile, "NewNight/Configs/"..tostring(Night.Game).."/LastUsed.txt", RealData.CurrentConfigName)
            end
        else
            TweenService:Create(Icon, TweenInfo.new(0.15), {ImageTransparency = 0.6}):Play()
        end

        if not InLoop then
            for i,v in UIData.ConfigButtons do
                if v ~= RealData then
                    v:SetSelect(false, true, true)
                end
            end
        end

        return
    end

    function RealData.Functions:DeleteConfig()
        if RealData.Selected then
            for i,v in UIData.ConfigButtons do
                if v ~= RealData and i ~= "New ConfigOption" then
                    v:SetSelect(true, true, true)
                    break
                end
            end
        end

        local ConfigPath = "NewNight/Configs/"..RealData.Data.ConfigFolder.."/"..RealData.CurrentConfigName..".json"
        if isfile(ConfigPath) then
            delfile(ConfigPath)
        end

        RealData.Functions:Destroy()
    end

    if not RealData.Data.New then
        local NewConfigButton = UIData.ConfigButtons["New ConfigOption"]
        if NewConfigButton then
            NewConfigButton:Destroy()
        end

        Assets.Functions:CreateConfigOption({
            Name = "New Config",
            ConfigFolder = RealData.Data.ConfigFolder,
            New = true
        })
    else
        DeleteButton.Visible = false
    end

    if RealData.Data.ConfigFolder then
        Assets.Connections:Add(Title.FocusLost:Connect(function(enter: boolean)
            if enter and isfile and readfile and writefile then
                if not RealData.Data.New then
                    local ConfigPath = "NewNight/Configs/"..RealData.Data.ConfigFolder.."/"..RealData.CurrentConfigName..".json"
                    if isfile(ConfigPath)  then
                        local Contents: string = readfile(ConfigPath)
                        local Suc, JSON = pcall(HttpService.JSONDecode, HttpService, Contents)
                        if Suc and JSON then                            
                            RealData.Functions:Set(JSON, Title.Text, ConfigPath)
                            return
                        end
                    end
                else
                    local Path = "NewNight/Configs/"..tostring(RealData.Data.ConfigFolder).."/"..Title.Text..".json"
                    if not isfile(Path) then
                        RealData.Functions:Set(DeepClone(DefaultConfig), Title.Text)
                        RealData.Data.New = false
                        
                        UIData.ConfigButtons[RealData.Flag] = nil
                        RealData.Flag = Title.Text.."Option"
                        UIData.ConfigButtons[RealData.Flag] = RealData

                        DeleteButton.Visible = true
                        Assets.Functions:CreateConfigOption({
                            Name = "New Config",
                            ConfigFolder = RealData.Data.ConfigFolder,
                            New = true
                        })

                        return
                    else
                        Assets.Functions:CreateNotification({
                            Title = "Config Exists",
                            Description = "A config with this name already exists",
                            Duration = 3
                        })
                    end
                end
            end

            Title.Text = RealData.CurrentConfigName
        end), {RealData.Connections})

        Assets.Connections:Add(MainFrame.MouseButton1Click:Connect(function()
            if not RealData.Data.New then
                RealData.Functions:SetSelect()
            end
        end), {RealData.Connections})

        Assets.Connections:Add(DeleteButton.MouseButton1Click:Connect(function()
            RealData.Functions:DeleteConfig()
        end), {RealData.Connections})
    else
        Title.TextEditable = false
        Title.ClearTextOnFocus = false
    end

    if Data.Default then
        RealData.Functions:SetSelect(true)
    end

    if isfile and not isfile("NewNight/Configs/"..tostring(Night.Game).."/LastUsed.txt") and not Data.New then
        pcall(writefile, "NewNight/Configs/"..tostring(Night.Game).."/LastUsed.txt", RealData.CurrentConfigName)
    end


    setmetatable(RealData, {
        __index = RealData.Functions
    })

    Data.Load = false
    UIData.ConfigButtons[RealData.Flag] = RealData
    return RealData
end

function Assets.Functions:CreateConfigOptions(Game: string)
    for i,v in UIData.ConfigButtons do
        v:Destroy()
    end

    if isfile and listfiles and readfile then 
        local Files = listfiles("NewNight/Configs/"..tostring(Game))
        local LastUsed: string?, LastUsedPath: string = nil, "NewNight/Configs/"..tostring(Game).."/LastUsed.txt"
        if isfile(LastUsedPath) then
            LastUsed = readfile(LastUsedPath)
        end

        if #Files > 0 then
            local checked = 0
            for i,v: string in listfiles("NewNight/Configs/"..tostring(Game)) do
                local ConfigNameSplitA = v:split(tostring(Game))[2]
                if ConfigNameSplitA and ConfigNameSplitA:find(".json") then
                    checked += 1

                    local ConfigName = ConfigNameSplitA:gsub(".json", ""):gsub("/", ""):gsub("\\", "")
                    Assets.Functions:CreateConfigOption({
                        Name = ConfigName,
                        Default = ConfigName == LastUsed,
                        ConfigFolder = tostring(Game),
                        Load = true
                    })
                end
            end

            if checked == 0 then
                Assets.Functions:CreateConfigOption({
                    Name = "Default",
                    Default = true,
                    ConfigFolder = tostring(Game)
                })
            end
        else
            Assets.Functions:CreateConfigOption({
                Name = "Default",
                Default = true,
                ConfigFolder = tostring(Game),
                Load = true
            })
        end
    else
        Assets.Functions:CreateConfigOption({
            Name = "Default",
            Default = true,
            ConfigFolder = tostring(Game),
            Load = true
        })
    end
end

local SettingsDashButton = Night.MainWindow:MakeDashboardButton({
    Text = {
        Text = "Settings",
        Color = Color3.fromRGB(170, 170, 170),
        -- OpenColor = Color3.fromRGB(210, 219, 229)
    },
    Icon = {
        Name = "Settings",
        Color = Color3.fromRGB(170, 170, 170),
        OpenColor = Color3.fromRGB(210, 219, 229)
    },
    Window = "RealUISettings"
})

local UISettingsWindow = CreateWindow({
    Name = "Settings",
    Flag = "RealUISettings",
    Size = UDim2.fromOffset(255, 470),
    Position = UDim2.fromScale(0.006, 0.085),
    DefaultPosition = UDim2.fromScale(0.702, 0.085),
    Visible = false,
    DashButton = SettingsDashButton,
    Icon = {Icon = "Settings", Size = UDim2.fromOffset(25, 25)}
})

UISettingsWindow:CreateModule({
    Name = "Uninject",
    Flag = "RealUIUinject",
    Notification = false,
    SaveConfig = false,
    Button = true,
    CallingFunction = function(self, enabled: boolean)
        if enabled then
            Assets.Functions:Uninject()
        end
    end
})

UISettingsWindow:CreateModule({
    Name = "ReInject",
    Flag = "RealUiReInjectSetting",
    Notification = false,
    SaveConfig = false,
    Button = true,
    CallingFunction = function(self, enabled: boolean)
        if enabled then
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

            Assets.Functions:Uninject()
            task.delay(0.1, function()
                loadstring(Data .. [[}
                    if NightInit.Dev and isfile("NewNight/Loader.luau") then
                        loadstring(readfile("NewNight/Loader.luau"))()
                    else
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/null-wtf/NewNight/refs/heads/main/Loader.luau"))()
                    end
                ]])()
            end)
        end
    end
})

local NotificationSettings = UISettingsWindow:CreateModule({
    Name = "Notifications",
    Flag = "RealUINotificationToggle",
    Notification = false,
    Default = true,
    CallingFunction = function(self, enabled: boolean)
        UIData.NotificationsSettings.All = enabled
    end
})

NotificationSettings:MiniToggle({
    Name = "Modules",
    Default = true,
    Flag = "GUINotificationsModules",
    CallingFunction = function(self, Enabled: boolean)
        UIData.NotificationsSettings.Modules = Enabled
    end
})

NotificationSettings:MiniToggle({
    Name = "Misc",
    Default = true,
    Flag = "GUINotificationMisc",
    CallingFunction = function(self, Enabled: boolean)
        UIData.NotificationsSettings.Other = Enabled
    end
})

NotificationSettings:Dropdown({
    Name = "Alignment",
    Flag = "GUINotificationAlignment",
    Options = {"Top", "Bottom"},
    Default = "Bottom",
    CallingFunction = function(self, Value: string)
        UIData.NotificationsSettings.Alignment = Value
    end
})

local GUISettings = UISettingsWindow:CreateModule({
    Name = "GUI",
    Flag = "RealGUISettings",
    SaveConfig = false,
    Notification = false,
    Default = true,
    DefaultKeybind = Enum.KeyCode.RightShift,
    CallingFunction = function(self: any, Enabled: boolean)
        Background.Visible = Enabled
        UIData.UIOpen = Enabled
        if UIData.TargetHud then
            UIData.TargetHud:SetVisiblity(Enabled)
        end
    end,
    KeybindCallingFunction = function(self, Keycode: Enum.KeyCode?)
        local SetValue = Keycode
        if typeof(Keycode) == "EnumItem" then
            SetValue = SetValue.Name
        end

        Night.Keybind = SetValue
    end
})

GUISettings:ColorSlider({
    Name = "Color",
    Flag = "GUIColorTheme",
    Default = Color3.fromRGB(26, 95, 181),
    CallingFunction = function(self, Color: Color3)
        UIData.Theme.Other = Color
        for i,v in UIData.CustomizableItems.Other do
            if v.CanChange and v.Item then
                if v.Item:IsA("Frame") or v.ChangeBackground then
                    v.Item.BackgroundColor3 = Color
                elseif v.Item:IsA("ImageButton") or v.Item:IsA("ImageLabel") then
                    v.Item.ImageColor3 = Color
                elseif v.Item:IsA("TextLabel") or v.Item:IsA("TextButton") or v.Item:IsA("TextBox") then
                    v.Item.TextColor3 = Color
                end
            end
        end
    end
})

GUISettings:ColorSlider({
    Name = "ModuleGradientStart",
    Flag = "GUIModuleGradientColorStart",
    Default = Color3.fromRGB(26, 95, 181),
    CallingFunction = function(self, Color: Color3, RGB: {R: number, G: number, B: number})
        UIData.Theme.ModuleTheme[1] = Color
        for i,v: {Main: boolean, Gradient: UIGradient} in UIData.CustomizableItems.Modules do
            if v.Main then
                v.Gradient.Color =  ColorSequence.new({ColorSequenceKeypoint.new(0, Color), ColorSequenceKeypoint.new(1, UIData.Theme.ModuleTheme[2])})
            else
                local RGB2 = Assets.Functions:ConvertColor3toInt(UIData.Theme.ModuleTheme[2])
                local Gradients = {
                    [1] = {
                        math.clamp(RGB.R - 7, 0, 255), 
                        math.clamp(RGB.G - 24, 0, 255), 
                        math.clamp(RGB.B - 46, 0, 255)
                    },
                    [2] = {
                        math.clamp(RGB2.R - 5, 0, 255), 
                        math.clamp(RGB2.G - 19, 0, 255), 
                        math.clamp(RGB2.B - 37, 0, 255)
                    }
                }

                v.Gradient.Color =  ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(table.unpack(Gradients[1]))), ColorSequenceKeypoint.new(1, Color3.fromRGB(table.unpack(Gradients[2])))})
                table.clear(Gradients)
            end
        end
    end
})

GUISettings:ColorSlider({
    Name = "ModuleGradientEnd",
    Flag = "GUIModuleGradientColorEnd",
    Default = Color3.fromRGB(21, 80, 152),
    CallingFunction = function(self, Color: Color3, RGB: {R: number, G: number, B: number})
        UIData.Theme.ModuleTheme[2] = Color
        for i,v: {Main: boolean, Gradient: UIGradient} in UIData.CustomizableItems.Modules do
            if v.Main then
                v.Gradient.Color =  ColorSequence.new({ColorSequenceKeypoint.new(0, UIData.Theme.ModuleTheme[1]), ColorSequenceKeypoint.new(1, Color)})
            else
                local RGB1 = Assets.Functions:ConvertColor3toInt(UIData.Theme.ModuleTheme[1])
                local Gradients = {
                    [1] = {
                        math.clamp(RGB1.R - 7, 0, 255), 
                        math.clamp(RGB1.G - 24, 0, 255), 
                        math.clamp(RGB1.B - 46, 0, 255)
                    },
                    [2] = {
                        math.clamp(RGB.R - 5, 0, 255), 
                        math.clamp(RGB.G - 19, 0, 255), 
                        math.clamp(RGB.B - 37, 0, 255)
                    }
                }

                v.Gradient.Color =  ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(table.unpack(Gradients[1]))), ColorSequenceKeypoint.new(1, Color3.fromRGB(table.unpack(Gradients[2])))})
                table.clear(Gradients)
            end
        end
    end
})

GUISettings:Slider({
    Name = "Drag Speed",
    Flag = "UIDragSpeed",
    Min = 0,
    Max = 0.3,
    Increment = 0.01,
    Default = 0.05,
    CallingFunction = function(self, value: boolean)
        UIData.Windows.DraggingSpeed = value
    end
})

local ScaleSlider = GUISettings:Slider({
    Name = "Scale",
    Flag = "GUIScaleSetting",
    Default = Night.Scale,
    Min = 0.4,
    Max = 1.5,
    Increment = 0.1,
    CallingFunction = function(self, Value: number)
        UIScale.Scale = Value
        Night.Scale = Value
    end
})

UISettingsWindow:CreateModule({
    Name = "Sort Tabs",
    Flag = "RealGUISortTabsSetting",
    SaveConfig = false,
    Notification = false,
    Button = true,
    CallingFunction = function(self: any, Enabled: boolean)
        if Enabled then
            for i,v in UIData.Windows.Windows do
                if v.DefaultPos then
                    v.Window.Position = v.DefaultPos
                    
                    Night.CurrentConfig.Others.TabData[v.Data.Flag] = {
                        Visible = v.Window.Visible,
                        Position = {v.DefaultPos.X.Scale, v.DefaultPos.Y.Scale}
                    }

                    Assets.Config:Save(Night.CurrentConfig, tostring(Night.Game).."/"..tostring(Night.CurrentConfig.ConfigName), {tostring(Night.Game)})
                end
            end
        end
    end
})

local ArrayListSetting = UISettingsWindow:CreateModule({
    Name = "Array List",
    Flag = "ArrayList",
    Default = true,
    CallingFunction = function(Self, Enabled: boolean)
        ArrayListHolder.Visible = Enabled
    end
})

ArrayListSetting:ColorSlider({
    Name = "Color",
    Flag = "ArrayListColor",
    Default = Color3.fromRGB(255, 255, 255),
    CallingFunction = function(self, color: Color3)
        Assets.ArrayList:SetColor(color)
        Assets.ArrayList.Color = color
    end
})


Assets.Functions:CreateTab({
    Name = "Premium",
    Flag = "Premium",
    Icon = "Premium",
    Order = 100
})

Assets.Connections:Add(UserInputService.InputChanged:Connect(function(Input: InputObject)
    UIData.InputFuncs.Changed(Input)
end))

Assets.Connections:Add(UserInputService.InputEnded:Connect(function(Input: InputObject)
    UIData.InputFuncs.Ended(Input)
end))

Assets.Connections:Add(Background.MouseWheelForward:Connect(function()
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        ScaleSlider:SetValue(tonumber(string.format("%.1f", math.clamp(UIScale.Scale + 0.1, 0.4, 1.5))))
    end
end))

Assets.Connections:Add(Background.MouseWheelBackward:Connect(function()
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        ScaleSlider:SetValue(tonumber(string.format("%.1f", math.clamp(UIScale.Scale - 0.1, 0.4, 1.5))))
    end
end))

Assets.Functions:CreateConfigOptions(Night.Game)

-- i am a setmetatable warrior
setmetatable(Night, {
    __index = Night.Assets
})

setmetatable(Night.Assets, {
    __index = Night.Assets.Functions
})

setmetatable(UIData, {
    __index = UIData.Windows.Windows
})
