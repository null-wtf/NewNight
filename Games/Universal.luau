local Night = getgenv().Night
local Tabs = {
    Combat = Night:CreateTab({
        Name = "Combat",
        Flag = "Combat",
        Icon = "Combat"
    }),
    Movement = Night:CreateTab({
        Name = "Movement",
        Flag = "Movement",
        Icon = "Movement"
    }),
    Render = Night:CreateTab({
        Name = "Render",
        Flag = "Render",
        Icon = "Render"
    }),
    Utility = Night:CreateTab({
        Name = "Utility",
        Flag = "Utility",
        Icon = "Utility"
    })
}

local Players: Players = Night.cloneref(game:GetService("Players"))
local VirtualUser: VirtualUser = Night.cloneref(game:GetService("VirtualUser"))
local RunService: RunService = Night.cloneref(game:GetService("RunService"))
local Lighting: Lighting = Night.cloneref(game:GetService("Lighting"))
local HttpService: HttpService = Night.cloneref(game:GetService("HttpService"))
local UserInputService: UserInputService = Night.cloneref(game:GetService("UserInputService"))
local TweenService: TweenService = Night.cloneref(game:GetService("TweenService"))
local VirtualInputManager: VirtualInputManager = Night.cloneref(game:GetService("VirtualInputManager"))
local Terrain: Terrain = workspace:FindFirstChildOfClass("Terrain")

local LocalPlayer = Players.LocalPlayer :: Player
local CurrentCamera: Camera = workspace.CurrentCamera
local MainRequest = http and http.request or request

local Materials = {}
for _, Material in next, Enum.Material:GetEnumItems() do
    table.insert(Materials, Material.Name)
end

pcall(function()
	setthreadidentity(8)
end);

(function()
    local SpeedData = {
        Settings = {
            Speed = 50,
            PulseDelay = 0,
            PulseTime = 2,
            JumpDelay = 2,
            Mode = "Velocity",
            AutoJump = false,
            Pulse = false,
            WallCheck = false,
            IgnoreTerrain = false
        },
        Data = {
            LastGroundTouch = os.clock(),
            RayPram = RaycastParams.new()
        },
        OldData = {
            Walkspeed = nil
        }
    }

    local Speed = Tabs.Movement:CreateModule({
        Name = "Speed",
        Flag = "UniversalSpeed",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                if Night:IsAlive(LocalPlayer) then
                    SpeedData.OldData.Walkspeed = LocalPlayer.Character.Humanoid.WalkSpeed    
                end

                repeat
                    local Fly = Tabs.Movement.Modules.UniversalFly
                    if Night:IsAlive(LocalPlayer) and (Fly and not Fly.Enabled or not Fly) then
                        local Root: BasePart = LocalPlayer.Character.PrimaryPart
                        local Humanoid: Humanoid = LocalPlayer.Character.Humanoid

                        if Humanoid.MoveDirection.Magnitude > 0 then
                            if SpeedData.Settings.WallCheck then
                                SpeedData.Data.RayPram.FilterType = Enum.RaycastFilterType.Exclude
                                SpeedData.Data.RayPram.FilterDescendantsInstances = {LocalPlayer.Character}

                                local Ray: RaycastResult? = workspace:Raycast(Root.Position, Humanoid.MoveDirection * 5, SpeedData.Data.RayPram)
                                if Ray and (SpeedData.Settings.IgnoreTerrain and Ray.Instance ~= workspace.Terrain or not SpeedData.Settings.IgnoreTerrain) then
                                    task.wait()
                                    continue
                                end
                            end

                            if SpeedData.Settings.AutoJump then
                                if Humanoid.FloorMaterial ~= Enum.Material.Air then
                                    if (os.clock() - SpeedData.Data.LastGroundTouch) >= SpeedData.Settings.JumpDelay then
                                        SpeedData.Data.LastGroundTouch = os.clock()
                                        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                                    end
                                end
                            end

                            local IndexVal: number = 1
                            if SpeedData.Settings.Pulse then
                                IndexVal = (SpeedData.Settings.PulseTime * 80)
                                if 0 >= IndexVal then
                                    IndexVal = 1
                                end
                            end

                            local Speed: number = SpeedData.Settings.Speed
                            if SpeedData.Settings.Mode == "Velocity" then
                                local CurrentVelocity: Vector3 = Vector3.zero
                                for i = 1, IndexVal do
                                    if not self.Enabled then
                                        break
                                    end

                                    CurrentVelocity = Root.AssemblyLinearVelocity
                                    Root.AssemblyLinearVelocity = Vector3.new(Humanoid.MoveDirection.X * Speed, CurrentVelocity.Y, Humanoid.MoveDirection.Z * Speed) 
                                    if SpeedData.Settings.Pulse then
                                        task.wait(0.01)
                                    end
                                end
                            elseif SpeedData.Settings.Mode == "CFrame" then
                                for i = 1, IndexVal do
                                    Speed = (SpeedData.Settings.Speed/150)
                                    Root.CFrame += Vector3.new(Humanoid.MoveDirection.X * Speed, 0, Humanoid.MoveDirection.Z * Speed)
                                    if SpeedData.Settings.Pulse then
                                        task.wait(0.01)
                                    end
                                end
                            elseif SpeedData.Settings.Mode == "TP" then
                                for i = 1, math.clamp(IndexVal/10, 1, math.huge) do
                                    Speed = (SpeedData.Settings.Speed/60)
                                    Root.CFrame += Vector3.new(Humanoid.MoveDirection.X * Speed, 0, Humanoid.MoveDirection.Z * Speed)
                                    task.wait(0.1)
                                end
                            else
                                Humanoid.WalkSpeed = Speed
                            end

                            if SpeedData.Settings.Pulse then
                                task.wait(SpeedData.Settings.PulseDelay)
                            end
                        end
                    end
                    task.wait()
                until not self.Enabled
            else
                if Night:IsAlive(LocalPlayer) and SpeedData.OldData.Walkspeed then
                    LocalPlayer.Character.Humanoid.WalkSpeed = SpeedData.OldData.Walkspeed
                end
            end
        end
    })

    Speed:Dropdown({
        Name = "Mode",
        Flag = "UniversalSpeedMode",
        Default = "Velocity",
        Options = {"Velocity", "CFrame", "TP", "Walkspeed"},
        CallingFunction = function(self, Value: string)
            SpeedData.Settings.Mode = Value
        end
    })

    Speed:Slider({
        Name = "Speed",
        Flag = "UniversalSpeedValue",
        Default = 50,
        Min = 0,
        Max = 100,
        CallingFunction = function(self, value: number)
            SpeedData.Settings.Speed = value
        end
    })

    local PulseDelay = Speed:Slider({
        Name = "Pulse Delay",
        Flag = "UniversalPulseDelay",
        Default = 2,
        Min = 1,
        Max = 5,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            SpeedData.Settings.PulseDelay = value
        end
    })

    local PulseTime = Speed:Slider({
        Name = "Pulse Time",
        Flag = "UniversalPulseTime",
        Default = 2,
        Min = 1,
        Max = 5,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            SpeedData.Settings.PulseTime = value
        end
    })

    local JumpDelay = Speed:Slider({
        Name = "Jump Delay",
        Flag = "UniversalSpeedAutoJumpDelay",
        Default = 0,
        Min = 0,
        Max = 5,
        CallingFunction = function(self, value: number)
            SpeedData.Settings.JumpDelay = value
        end
    })
    
    Speed:MiniToggle({
        Name = "Auto Jump",
        Flag = "UniversalSpeedAutoJump",
        CallingFunction = function(self, value: boolean)
            SpeedData.Settings.AutoJump = value
            JumpDelay:SetVisiblity(value)
        end
    })

    Speed:MiniToggle({
        Name = "Pulse",
        Flag = "UniversalSpeedPulse",
        CallingFunction = function(self, value: boolean)
            SpeedData.Settings.Pulse = value

            PulseDelay:SetVisiblity(value)
            PulseTime:SetVisiblity(value)
        end
    })

    local IgnoreTerrain = Speed:MiniToggle({
        Name = "Ignore Terrain",
        Flag = "UniversalSpeedWallCheckIgnoreTerrain",
        CallingFunction = function(self, value: boolean)
            SpeedData.Settings.IgnoreTerrain = value
        end
    })

    Speed:MiniToggle({
        Name = "Wall Check",
        Flag = "UniveralSpeedWallCheck",
        Default = true,
        CallingFunction = function(self, value: boolean)
            SpeedData.Settings.WallCheck = value
            IgnoreTerrain:SetVisiblity(value)
        end
    })
end)();

(function()
    local FlyData = {
        Settings = {
            Speed = 50,
            VerticalSpeed = 80,
            PulseDelay = 2,
            PulseTime = 2,
            SpeedMode = "Velocity",
            Pulse = false
        },
        Data = {
            Vertical = 0,
            LastBoosted = os.clock()
        }
    }

    local Fly = Tabs.Movement:CreateModule({
        Name = "Fly",
        Flag = "UniversalFly",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                self:Connection(RunService.PreAnimation:Connect(function(Delta: number)
                    if Night:IsAlive(LocalPlayer) then
                        local Root: BasePart = LocalPlayer.Character.PrimaryPart
                        local Humanoid: Humanoid = LocalPlayer.Character.Humanoid

                        local IndexVal: number = 1
                        if FlyData.Settings.Pulse then
                            IndexVal = (FlyData.Settings.PulseTime * 60)
                            if 0 >= IndexVal then
                                IndexVal = 1
                            end
                        end

                        if FlyData.Settings.SpeedMode == "TP" then
                            IndexVal = math.clamp(IndexVal/10, 1, math.huge)
                        end

                        for i = 1, IndexVal do
                            local YValue: number = 0
                            local Speed: number = FlyData.Settings.Speed
                            local CurrentVelocity: Vector3 = Root.AssemblyLinearVelocity
                            local SpeedVelocity: Vector3 = CurrentVelocity

                            if FlyData.Data.Vertical ~= 0 then
                                if FlyData.Data.Vertical == 1 then
                                    YValue = FlyData.Settings.VerticalSpeed
                                elseif FlyData.Data.Vertical == -1 then
                                    YValue = -FlyData.Settings.VerticalSpeed
                                end
                            end

                            if ((os.clock() - FlyData.Data.LastBoosted) >= FlyData.Settings.PulseDelay or not FlyData.Settings.Pulse) then
                                if FlyData.Settings.SpeedMode == "Velocity" then
                                    SpeedVelocity = Vector3.new(Humanoid.MoveDirection.X * Speed, 0, Humanoid.MoveDirection.Z * Speed) 
                                elseif FlyData.Settings.SpeedMode == "CFrame" then
                                    Speed /= 150
                                    Root.CFrame += Vector3.new(Humanoid.MoveDirection.X * Speed, 0, Humanoid.MoveDirection.Z * Speed)
                                elseif FlyData.Settings.SpeedMode == "TP" then
                                    task.delay(Random.new():NextNumber(0.1, 0.3), function()
                                        Speed /= 60
                                        Root.CFrame += Vector3.new(Humanoid.MoveDirection.X * Speed, 0, Humanoid.MoveDirection.Z * Speed)
                                    end)
                                end
                            end

                            if Humanoid.MoveDirection.Magnitude <= 0 then
                                SpeedVelocity = Vector3.zero
                            end

                            Root.AssemblyLinearVelocity = Vector3.new(
                                SpeedVelocity.X,
                                YValue + (CurrentVelocity.Y > 0 and 1 or -CurrentVelocity.Y),
                                SpeedVelocity.Z
                            )

                            if FlyData.Settings.Pulse and (os.clock() - FlyData.Data.LastBoosted) >= FlyData.Settings.PulseDelay then
                                task.wait(0.01)
                            end
                        end

                        if (os.clock() - FlyData.Data.LastBoosted) >= FlyData.Settings.PulseDelay then
                            FlyData.Data.LastBoosted = os.clock()
                        end
                    end
                end))
            end
        end
    })

    Fly.Functions:KeyBind({
        Name = "Fly Up",
        MobileText = "Fly Up",
        Flag = "UniversalFlyUpKyebind",
        DestroyMobileButtonOnDisable = true,
        Default = Enum.KeyCode.Space,
        Events = {
            Began = function()
                FlyData.Data.Vertical = 1
            end,
            Ended = function()
                FlyData.Data.Vertical = 0
            end
        }
    })

    Fly.Functions:KeyBind({
        Name = "Fly Down",
        MobileText = "Fly Down",
        Flag = "UniversalFlyDownKyebind",
        DestroyMobileButtonOnDisable = true,
        Default = Enum.KeyCode.LeftControl,
        Events = {
            Began = function()
                FlyData.Data.Vertical = -1
            end,
            Ended = function()
                FlyData.Data.Vertical = 0
            end
        }
    })

    Fly:Slider({
        Name = "Speed",
        Flag = "UniversalFlySpeed",
        Default = 50,
        Min = 0,
        Max = 100,
        CallingFunction = function(self, value: number)
            FlyData.Settings.Speed = value
        end
    })

    Fly:Slider({
        Name = "Vertical Speed",
        Flag = "UniversalVerticalFlySpeed",
        Default = 70,
        Min = 0,
        Max = 130,
        CallingFunction = function(self, value: number)
            FlyData.Settings.VerticalSpeed = value
        end
    })

    local FlyPulseDelay = Fly:Slider({
        Name = "Pulse Delay",
        Flag = "UniversaFlylPulseDelay",
        Default = 2,
        Min = 1,
        Max = 5,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            FlyData.Settings.PulseDelay = value
        end
    })

    local FlyPulseTime = Fly:Slider({
        Name = "Pulse Time",
        Flag = "UniversalFlyPulseTime",
        Default = 2,
        Min = 1,
        Max = 5,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            FlyData.Settings.PulseTime = value
        end
    })

    Fly:Dropdown({
        Name = "Speed Mode",
        Flag = "UniversalFlySpeedMode",
        Default = "Velocity",
        Options = {"Velocity", "CFrame", "TP"},
        CallingFunction = function(self, Value: string)
            FlyData.Settings.SpeedMode = Value
        end
    })

    Fly:MiniToggle({
        Name = "Pulse",
        Flag = "UniversalFlySpeedPulse",
        CallingFunction = function(self, value: boolean)
            FlyData.Settings.Pulse = value

            FlyPulseDelay:SetVisiblity(value)
            FlyPulseTime:SetVisiblity(value)
        end
    })
end)();

(function()
    local OldFov: number?, NewFov: number = nil, 120
    local FovChanger = Tabs.Render:CreateModule({
        Name = "FOV",
        Flag = "UniversalFOVChanger",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                if CurrentCamera then
                    OldFov = CurrentCamera.FieldOfView
                    CurrentCamera.FieldOfView = NewFov
                    self:Connection(CurrentCamera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
                        CurrentCamera.FieldOfView = NewFov
                    end))
                end
            else
                if OldFov then
                    CurrentCamera.FieldOfView = OldFov
                end
            end
        end
    })
    
    FovChanger:Slider({
        Name = "FOV",
        Flag = "UniversalFOVValue",
        Default = 120,
        Min = 0,
        Max = 120,
        CallingFunction = function(self, value: number)
            NewFov = value
            if FovChanger.Enabled and CurrentCamera then
                CurrentCamera.FieldOfView = NewFov
            end
        end
    })
end)();

(function()
    Tabs.Utility:CreateModule({
        Name = "Anti AFK",
        Flag = "UniversalAntiAFK",
        CallingFunction = function(self, enabled: boolean)
            if getconnections then
                local Cons: {{Disable: () -> (), Enable: () -> ()}} = getconnections(LocalPlayer.Idled)
                for i,v in Cons do
                    if enabled then
                        v:Disable()
                    else
                        v:Enable()
                    end
                end
            else
                self:Connection(LocalPlayer.Idled:Connect(function()
                    VirtualUser:ClickButton2(Vector2.zero)
                end))
            end
        end
    })
end)();

(function()
    local AimbotData = {
        Settings = {
            Smoothness = 0,
            CircleSize = 80,
            Distance = 50,
            CircleEnabled = true,
            TeamCheck = false,
            TriggerDistance = false,
            WallCheck = false,
            UseTriggerButton = false,
            TargetPart = "HumanoidRootPart",
            CircleColor = Color3.fromRGB(255, 0, 0)
        },
        Data = {
            RayParams = RaycastParams.new(),
            Circle = nil,
            HoldingTrigger = false,
        }
    }

    local function IsPathClear(target, TargetPart: Part?): boolean
        if not AimbotData.Settings.WallCheck then
            return true 
        end

        local Excluded: {Model} = {LocalPlayer.Character}
        for i,v in Players:GetPlayers() do
            if v ~= LocalPlayer and Night:IsAlive(v) then
                table.insert(Excluded, v.Character)
            end
        end

        AimbotData.Data.RayParams.FilterType = Enum.RaycastFilterType.Exclude
        AimbotData.Data.RayParams.FilterDescendantsInstances = Excluded

        local Start: Vector3 = CurrentCamera.CFrame.Position + CurrentCamera.CFrame.LookVector * 1
        if TargetPart then
            local Direction: Vector3 = (TargetPart.Position - Start)
            local Distance: number = Direction.Magnitude
            Direction = Direction.Unit * math.min(Distance, 1000)
            local Ray: RaycastResult? = workspace:Raycast(Start, Direction, AimbotData.Data.RayParams)
            
            if not Ray or (Ray.Instance and Ray.Instance:IsDescendantOf(target)) then
                table.clear(Excluded)
                return true
            end
        end

        table.clear(Excluded)
        return false
    end

    local Aimbot = Tabs.Combat:CreateModule({
        Name = "Aimbot",
        Flag = "UniversalAimbot",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                if AimbotData.Settings.CircleEnabled and not AimbotData.Data.Circle then
                    local Circle = Drawing.new("Circle")
                    Circle.Visible = true
                    Circle.Color = AimbotData.Settings.CircleColor
                    Circle.Radius = AimbotData.Settings.CircleSize
                    Circle.Thickness = 2
                    Circle.Filled = false
                    Circle.Transparency = 0.8
                    AimbotData.Data.Circle = Circle
                end

                self:Connection(RunService.PreRender:Connect(function(Delta: number)
                    if not Night:IsAlive(LocalPlayer) then 
                        return 
                    end

                    if AimbotData.Data.Circle then
                        AimbotData.Data.Circle.Position = UserInputService:GetMouseLocation()
                    end

                    if not AimbotData.Data.HoldingTrigger and AimbotData.Settings.UseTriggerButton then return end

                    local NearestToMouse: {DistanceFromMouse: number, DistanceFromPlayer: number, Player: Player?, Character: Model?} = Night:GetNerestPlayerToMouse({
                        TeamCheck = AimbotData.Settings.TeamCheck,
                        Exclude = {LocalPlayer},
                    })

                    if NearestToMouse.Player and NearestToMouse.Character then
                        local Target = NearestToMouse.Character
                        local TargetPart = Target:FindFirstChild(AimbotData.Settings.TargetPart) or Target.PrimaryPart
                        if TargetPart then
                            local Pos, OnScreen = CurrentCamera:WorldToViewportPoint(TargetPart.Position)
                            local MousePos = UserInputService:GetMouseLocation()
                            local DistToMouse = (Vector2.new(Pos.X, Pos.Y) - MousePos).Magnitude

                            if OnScreen and (DistToMouse <= AimbotData.Settings.CircleSize or not AimbotData.Settings.CircleEnabled) then
                                if AimbotData.Settings.TriggerDistance and NearestToMouse.DistanceFromPlayer >= AimbotData.Settings.Distance then
                                    return
                                end
                                
                                if not IsPathClear(Target, TargetPart) then 
                                    return 
                                end

                                local NewCF = CFrame.new(CurrentCamera.CFrame.Position, TargetPart.Position)
                                if AimbotData.Settings.Smoothness == 100 then
                                    CurrentCamera.CFrame = NewCF
                                else
                                    CurrentCamera.CFrame = CurrentCamera.CFrame:Lerp(NewCF, AimbotData.Settings.Smoothness * Delta)
                                end
                            end
                        end
                    end
                end))
            else
                if AimbotData.Data.Circle then
                    AimbotData.Data.Circle:Destroy()
                    AimbotData.Data.Circle = nil
                end
            end
        end
    })

    local KeyTrigger = Aimbot.Functions:KeyBind({
        Name = "Trigger",
        MobileText = "Trigger",
        Flag = "UniversalAimbotTrigger",
        DestroyMobileButtonOnDisable = true,
        Default = Enum.UserInputType.MouseButton2,
        Events = {
            Began = function()
                AimbotData.Data.HoldingTrigger = true
            end,
            Ended = function()
                AimbotData.Data.HoldingTrigger = false
            end
        }
    })

    local AimParts: {string} = {"HumanoidRootPart", "Head"}
    if LocalPlayer.Character then
        for i,v in LocalPlayer.Character:GetChildren() do
            if (v:IsA("Part") or v:IsA("MeshPart")) and not table.find(AimParts, v.Name) then
                table.insert(AimParts, v.name)
            end
        end
    end

    Aimbot:Dropdown({
        Name = "Part",
        Flag = "AimbotPart",
        Default = "Head",
        Options = AimParts,
        CallingFunction = function(self, Value: string)
            AimbotData.Settings.TargetPart = Value
        end
    })

    Aimbot:Slider({
        Name = "Aim Speed",
        Flag = "AimbotSpeed",
        Default = 100,
        Min = 10,
        Max = 100,
        CallingFunction = function(self, value: number)
            AimbotData.Settings.Smoothness = value
        end
    })

    local FovSize = Aimbot:Slider({
        Name = "FOV Size",
        Flag = "AimbotFOVSize",
        Default = 80,
        Min = 1,
        Max = 450,
        CallingFunction = function(self, value: number)
            AimbotData.Settings.CircleSize = value
            if AimbotData.Data.Circle then
                AimbotData.Data.Circle.Radius = value
            end
        end
    })

    Aimbot:Slider({
        Name = "Distance",
        Flag = "AimbotDistance",
        Default = 50,
        Min = 1,
        Max = 100,
        CallingFunction = function(self, value: number)
            AimbotData.Settings.Distance = value
        end
    })

    local FovColor = Aimbot:ColorSlider({
        Name = "FOV Color",
        Flag = "AimbotFOVCircleColor",
        Default = Color3.fromRGB(255, 0, 0),
        CallingFunction = function(self, Color: Color3)
            AimbotData.Settings.CircleColor = Color
            if AimbotData.Data.Circle then
                AimbotData.Data.Circle.Color = Color
            end
        end
    })

    Aimbot:MiniToggle({
        Name = "FOV",
        Default = true,
        Flag = "AimbotFOV",
        CallingFunction = function(self, value: boolean)
            AimbotData.Settings.CircleEnabled = value

            FovColor:SetVisiblity(value)
            FovSize:SetVisiblity(value)
            if not AimbotData.Data.Circle then
                if Aimbot.Enabled then
                    local Circle = Drawing.new("Circle")
                    Circle.Visible = true
                    Circle.Color = AimbotData.Settings.CircleColor
                    Circle.Radius = AimbotData.Settings.CircleSize
                    Circle.Thickness = 2
                    Circle.Filled = false
                    Circle.Transparency = 0.8
                    AimbotData.Data.Circle = Circle
                end
            else
                if not value then
                    AimbotData.Data.Circle:Destroy()
                    AimbotData.Data.Circle = nil
                end
            end
        end
    })

    Aimbot:MiniToggle({
        Name = "Team Check",
        Flag = "AimbotTeamCheck",
        CallingFunction = function(self, value: boolean)
            AimbotData.Settings.TeamCheck = value
        end
    })

    Aimbot:MiniToggle({
        Name = "Distance Check",
        Flag = "AimbotDistanceCheck",
        CallingFunction = function(self, value: number)
            AimbotData.Settings.TriggerDistance = value
        end
    })

    Aimbot:MiniToggle({
        Name = "Wall Check",
        Flag = "AimbotWallCheck",
        CallingFunction = function(self, value: boolean)
            AimbotData.Settings.WallCheck = value
        end
    })

    Aimbot:MiniToggle({
        Name = "Trigger Button",
        Flag = "UniversalAimbotTriggerButton",
        CallingFunction = function(self, value: boolean)
            AimbotData.Settings.UseTriggerButton = value
            KeyTrigger:SetVisiblity(value)
        end
    })
end)();

(function()
    local OldTime = Lighting.ClockTime
    Tabs.Render:CreateModule({
        Name = "Night",
        Flag = "UniversalNight",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                OldTime = Lighting.ClockTime
                Lighting.ClockTime = 0
            else
                Lighting.ClockTime = OldTime
            end
        end
    })
end)();

(function()
    local ESP
    local ESPData = {
        Settings = {
            TeamCheck = false,
            TeamColor = false,
            FillBoxes = false,
            Boxes = false,
            Health = false,
            Name = false,
            BoxMode = "Box",
            ESPMode = "Dynamic",
            Color = Color3.fromRGB(255, 0, 0),
            FillColor = Color3.fromRGB(0, 0, 0),
        },
        Data = {
            BoxOutline = nil,
            BoxFill = nil,
            HealthBarOutline = nil,
            HealthBar = nil,
            NameTag = nil,
            UpdateConnection = nil,
            SkeletonLines = {},
            Instances = {}
        }
    }

    local function CreateESP(Target: Player)
        local BoxOutline = Drawing.new("Quad")
        BoxOutline.Visible = false
        BoxOutline.Thickness = 1
        BoxOutline.Transparency = 0.7
        BoxOutline.Filled = false
        BoxOutline.Color = ESPData.Settings.Color

        local BoxFill = Drawing.new("Quad")
        BoxFill.Visible = false
        BoxFill.Transparency = 0.5
        BoxFill.Filled = true
        BoxFill.Color = ESPData.Settings.FillColor

        local HealthBarOutline = Drawing.new("Line")
        HealthBarOutline.Visible = false
        HealthBarOutline.Thickness = 3
        HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)

        local HealthBar = Drawing.new("Line")
        HealthBar.Visible = false
        HealthBar.Thickness = 1.5

        local NameTag = Drawing.new("Text")
        NameTag.Visible = false
        NameTag.Center = true
        NameTag.Outline = true
        NameTag.Size = 14
        NameTag.Color = ESPData.Settings.Color

        local SkeletonLines = {}
        local function CreateBone()
            local Line = Drawing.new("Line")
            Line.Visible = false
            Line.Thickness = 2
            Line.Transparency = 1
            Line.Color = ESPData.Settings.Color
            table.insert(SkeletonLines, Line)

            return Line
        end

        local DrawPairs = {
            {"Head", "UpperTorso", "Head", "Torso", nil, CFrame.new(0, -0.2, 0)},
            {"UpperTorso", "LowerTorso", "Torso", "Torso", CFrame.new(0, 0.5, 0), CFrame.new(0, -0.5, 0)},
            {"UpperTorso", "LeftUpperArm", "Torso", "Left Arm", CFrame.new(0, 0.5, 0), CFrame.new(0, 0.5, 0)},
            {"LeftUpperArm", "LeftLowerArm", "Left Arm", "Left Arm", CFrame.new(0, 0.5, 0), CFrame.new(0, -0.5, 0)},
            {"LeftLowerArm", "LeftHand", "Left Arm", "Left Arm", nil, nil},
            {"UpperTorso", "RightUpperArm", "Torso", "Right Arm", CFrame.new(0, 0.5, 0), CFrame.new(0, 0.5, 0)},
            {"RightUpperArm", "RightLowerArm", "Right Arm", "Right Arm", CFrame.new(0, 0.5, 0), CFrame.new(0, -0.5, 0)},
            {"RightLowerArm", "RightHand", "Right Arm", "Right Arm", nil, nil},
            {"LowerTorso", "LeftUpperLeg", "Torso", "Left Leg", CFrame.new(0, -0.5, 0), CFrame.new(0, 0.5, 0)},
            {"LowerTorso", "RightUpperLeg", "Torso", "Right Leg", CFrame.new(0, -0.5, 0), CFrame.new(0, 0.5, 0)},
            {"LeftUpperLeg", "LeftLowerLeg", "Left Leg", "Left Leg", CFrame.new(0, 0.5, 0), CFrame.new(0, -0.5, 0)},
            {"RightUpperLeg", "RightLowerLeg", "Right Leg", "Right Leg", CFrame.new(0, 0.5, 0), CFrame.new(0, -0.5, 0)},
            {"LeftLowerLeg", "LeftFoot", "Left Leg", "Left Leg", nil, nil},
            {"RightLowerLeg", "RightFoot", "Right Leg", "Right Leg", nil, nil}
        }

        for _ = 1, #DrawPairs do
            CreateBone()
        end

        local function DrawCorneredBox(topLeft, topRight, bottomLeft, bottomRight, color)
            if ESPData.Settings.Boxes then
                local cornerLength = 15
                local width = math.abs(tonumber(topRight.X - topLeft.X))
                local height = math.abs(tonumber(bottomLeft.Y - topLeft.Y))
                local cornerLengthX = math.min(cornerLength, width * 0.25)
                local cornerLengthY = math.min(cornerLength, height * 0.25)

                local cornerLines = {}
                table.insert(cornerLines, {Vector2.new(topLeft.X + cornerLengthX, topLeft.Y), topLeft})
                table.insert(cornerLines, {Vector2.new(topLeft.X, topLeft.Y - cornerLengthY), topLeft})
                table.insert(cornerLines, {Vector2.new(topRight.X - cornerLengthX, topRight.Y), topRight})
                table.insert(cornerLines, {Vector2.new(topRight.X, topRight.Y - cornerLengthY), topRight})
                table.insert(cornerLines, {Vector2.new(bottomLeft.X + cornerLengthX, bottomLeft.Y), bottomLeft})
                table.insert(cornerLines, {Vector2.new(bottomLeft.X, bottomLeft.Y + cornerLengthY), bottomLeft})
                table.insert(cornerLines, {Vector2.new(bottomRight.X - cornerLengthX, bottomRight.Y), bottomRight})
                table.insert(cornerLines, {Vector2.new(bottomRight.X, bottomRight.Y + cornerLengthY), bottomRight})

                for i = 1, math.min(8, #cornerLines) do
                    local Line = SkeletonLines[i]
                    if Line then
                        local from, to = cornerLines[i][1], cornerLines[i][2]
                        Line.From = from
                        Line.To = to
                        Line.Color = color
                        Line.Visible = true
                    end
                end

                for i = 9, #SkeletonLines do
                    SkeletonLines[i].Visible = false
                end
            else
                BoxOutline.Visible = false
                for _, L in next, SkeletonLines do 
                    L.Visible = false 
                end
            end
        end

        local function Update()
            if not ESPData.Data.Instances[Target] then 
                return 
            end

            if Night:IsAlive(Target) then
                local Humanoid = Target.Character:FindFirstChildOfClass("Humanoid")
                local Root = Target.Character.PrimaryPart
                if Humanoid and Humanoid.Health > 0 then
                    if ESPData.Settings.TeamCheck and Target.Team and LocalPlayer.Team and Target.Team == LocalPlayer.Team then
                        BoxOutline.Visible = false
                        BoxFill.Visible = false
                        HealthBar.Visible = false
                        HealthBarOutline.Visible = false
                        NameTag.Visible = false
                        for _, L in next, SkeletonLines do 
                            L.Visible = false 
                        end

                        return
                    end

                    local _, OnScreen = CurrentCamera:WorldToViewportPoint(Root.Position)
                    if OnScreen then
                        if ESPData.Settings.ESPMode == "Dynamic" then
                            local Coords = {}
                            for _, Part in next, Target.Character:GetChildren() do
                                if Part:IsA("BasePart") then
                                    local Adjusted = Part.CFrame
                                    if Part.Name == "Head" then
                                        Adjusted = Part.CFrame * CFrame.new(0, Part.Size.Y / 2, 0)
                                    elseif Part == Root then
                                        Adjusted = Part.CFrame * CFrame.new(0, 0, -Part.Size.Z)
                                    elseif string.find(tostring(Part.Name), "Left") then
                                        Adjusted = Part.CFrame * CFrame.new(-Part.Size.X / 2, 0, 0)
                                    elseif string.find(tostring(Part.Name), "Right") then
                                        Adjusted = Part.CFrame * CFrame.new(Part.Size.X / 2, 0, 0)
                                    end
                                    local Screen, Visible = CurrentCamera:WorldToViewportPoint(Adjusted.Position)
                                    if Visible then
                                        table.insert(Coords, Screen)
                                    end
                                end
                            end

                            if #Coords > 0 then
                                local MinX, MaxX, MinY, MaxY = math.huge, -math.huge, math.huge, -math.huge
                                for _, Pos in next, Coords do
                                    if Pos.X < MinX then MinX = Pos.X end
                                    if Pos.X > MaxX then MaxX = Pos.X end
                                    if Pos.Y < MinY then MinY = Pos.Y end
                                    if Pos.Y > MaxY then MaxY = Pos.Y end
                                end

                                local BoxColor = (ESPData.Settings.TeamColor and Target.Team) and Target.TeamColor.Color or ESPData.Settings.Color
                                if ESPData.Settings.BoxMode == "Box" then
                                    BoxOutline.PointA = Vector2.new(MaxX + 5, MinY - 10)
                                    BoxOutline.PointB = Vector2.new(MinX - 5, MinY - 10)
                                    BoxOutline.PointC = Vector2.new(MinX - 5, MaxY + 10)
                                    BoxOutline.PointD = Vector2.new(MaxX + 5, MaxY + 10)
                                    BoxOutline.Visible = ESPData.Settings.Boxes
                                    BoxOutline.Color = BoxColor

                                    BoxFill.PointA = Vector2.new(MaxX + 5 - 1, MinY - 10 + 1)
                                    BoxFill.PointB = Vector2.new(MinX - 5 + 1, MinY - 10 + 1)
                                    BoxFill.PointC = Vector2.new(MinX - 5 + 1, MaxY + 10 - 1)
                                    BoxFill.PointD = Vector2.new(MaxX + 5 - 1, MaxY + 10 - 1)
                                    BoxFill.Visible = ESPData.Settings.FillBoxes
                                    BoxFill.Color = ESPData.Settings.FillColor

                                    for _, L in next, SkeletonLines do L.Visible = false end
                                elseif ESPData.Settings.BoxMode == "Cornered" then
                                    DrawCorneredBox(Vector2.new(MinX - 5, MaxY + 10), Vector2.new(MaxX + 5, MaxY + 10), Vector2.new(MinX - 5, MinY - 10), Vector2.new(MaxX + 5, MinY - 10), BoxColor)
                                    BoxOutline.Visible = false
                                    BoxFill.Visible = false
                                end

                                if ESPData.Settings.Health then
                                    HealthBarOutline.From = Vector2.new(MinX - 9, MinY - 10)
                                    HealthBarOutline.To = Vector2.new(MinX - 9, MaxY + 10)
                                    HealthBarOutline.Visible = true
                                    local HealthPercent = math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1)
                                    HealthBar.From = Vector2.new(MinX - 9, MaxY + 10)
                                    HealthBar.To = Vector2.new(MinX - 9, MaxY + 10 - (MaxY + 10 - (MinY - 10)) * HealthPercent)
                                    HealthBar.Color = Color3.fromRGB(255 - (255 * HealthPercent), 255 * HealthPercent, 0)
                                    HealthBar.Visible = true
                                else
                                    HealthBar.Visible = false
                                    HealthBarOutline.Visible = false
                                end

                                if ESPData.Settings.Name then
                                    local namePos = Vector2.new((MinX + MaxX) / 2, MinY - 30)
                                    NameTag.Position = namePos
                                    NameTag.Text = Target.Name
                                    NameTag.Visible = true
                                    NameTag.Color = (ESPData.Settings.TeamColor and Target.Team) and Target.TeamColor.Color or ESPData.Settings.Color
                                else
                                    NameTag.Visible = false
                                end
                            else
                                BoxOutline.Visible = false
                                BoxFill.Visible = false
                                HealthBar.Visible = false
                                HealthBarOutline.Visible = false
                                NameTag.Visible = false
                                for _, L in next, SkeletonLines do L.Visible = false end
                            end
                        elseif ESPData.Settings.ESPMode == "Classic" then
                            local hrpPos = Root.Position - Vector3.new(0, 0.2, 0)
                            local boxSize = Vector3.new(4, 7.5, 0)

                            local topRight2D, trVisible = CurrentCamera:WorldToViewportPoint(hrpPos + (CurrentCamera.CFrame.RightVector * (boxSize.X / 2)) + (-CurrentCamera.CFrame.UpVector * (boxSize.Y / 2)))
                            local topLeft2D, tlVisible = CurrentCamera:WorldToViewportPoint(hrpPos + (CurrentCamera.CFrame.RightVector * -(boxSize.X / 2)) + (-CurrentCamera.CFrame.UpVector * (boxSize.Y / 2)))
                            local bottomRight2D, brVisible = CurrentCamera:WorldToViewportPoint(hrpPos + (CurrentCamera.CFrame.RightVector * (boxSize.X / 2)) + (-CurrentCamera.CFrame.UpVector * -(boxSize.Y / 2)))
                            local bottomLeft2D, blVisible = CurrentCamera:WorldToViewportPoint(hrpPos + (CurrentCamera.CFrame.RightVector * -(boxSize.X / 2)) + (-CurrentCamera.CFrame.UpVector * -(boxSize.Y / 2)))

                            local isVisible = trVisible or tlVisible or brVisible or blVisible
                            if isVisible then
                                local tl2D = Vector2.new(topLeft2D.X, topLeft2D.Y)
                                local tr2D = Vector2.new(topRight2D.X, topRight2D.Y)
                                local bl2D = Vector2.new(bottomLeft2D.X, bottomLeft2D.Y)
                                local br2D = Vector2.new(bottomRight2D.X, bottomRight2D.Y)
                                local boxColor = (ESPData.Settings.TeamColor and Target.Team) and Target.TeamColor.Color or ESPData.Settings.Color

                                if ESPData.Settings.Boxes then
                                    if ESPData.Settings.BoxMode == "Box" then
                                        BoxOutline.PointA = tr2D
                                        BoxOutline.PointB = tl2D
                                        BoxOutline.PointC = bl2D
                                        BoxOutline.PointD = br2D
                                        BoxOutline.Visible = ESPData.Settings.Boxes
                                        BoxOutline.Color = boxColor

                                        BoxFill.PointA = Vector2.new(tr2D.X - 1, tr2D.Y + 1)
                                        BoxFill.PointB = Vector2.new(tl2D.X + 1, tl2D.Y + 1)
                                        BoxFill.PointC = Vector2.new(bl2D.X + 1, bl2D.Y - 1)
                                        BoxFill.PointD = Vector2.new(br2D.X - 1, br2D.Y - 1)
                                        BoxFill.Visible = ESPData.Settings.FillBoxes
                                        BoxFill.Color = ESPData.Settings.FillColor

                                        for _, L in next, SkeletonLines do L.Visible = false end
                                    elseif ESPData.Settings.BoxMode == "Cornered" then
                                        DrawCorneredBox(tl2D, tr2D, bl2D, br2D, boxColor)
                                        BoxOutline.Visible = false
                                        BoxFill.Visible = false
                                    end
                                else
                                    BoxOutline.Visible = false
                                    for _, L in next, SkeletonLines do L.Visible = false end
                                end

                                if ESPData.Settings.Health then
                                    HealthBarOutline.From = Vector2.new(topLeft2D.X - 4, topLeft2D.Y)
                                    HealthBarOutline.To = Vector2.new(topLeft2D.X - 4, bottomLeft2D.Y)
                                    HealthBarOutline.Visible = true
                                    
                                    local HealthPercent = math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1)
                                    HealthBar.From = Vector2.new(topLeft2D.X - 4, topLeft2D.Y)
                                    HealthBar.To = Vector2.new(topLeft2D.X - 4, topLeft2D.Y + (bottomLeft2D.Y - topLeft2D.Y) * HealthPercent)
                                    HealthBar.Color = Color3.fromRGB(255 - (255 * HealthPercent), 255 * HealthPercent, 0)
                                    HealthBar.Visible = true
                                else
                                    HealthBar.Visible = false
                                    HealthBarOutline.Visible = false
                                end
                                if ESPData.Settings.Name then
                                    local namePos = Vector2.new((topLeft2D.X + topRight2D.X) / 2, math.min(topLeft2D.Y, bottomLeft2D.Y, topRight2D.Y, bottomRight2D.Y) - 30)
                                    NameTag.Position = namePos
                                    NameTag.Text = Target.Name
                                    NameTag.Visible = true
                                    NameTag.Color = (ESPData.Settings.TeamColor and Target.Team) and Target.TeamColor.Color or ESPData.Settings.Color
                                else
                                    NameTag.Visible = false
                                end
                            else
                                BoxOutline.Visible = false
                                BoxFill.Visible = false
                                HealthBar.Visible = false
                                HealthBarOutline.Visible = false
                                NameTag.Visible = false
                                for _, L in next, SkeletonLines do L.Visible = false end
                            end
                        elseif ESPData.Settings.ESPMode == "Locked" then
                            local hrpPos = Root.Position - Vector3.new(0, 0.2, 0)
                            local boxSize = Vector3.new(4.5, 6.5, 0)

                            local topRight2D, trVisible = CurrentCamera:WorldToViewportPoint(hrpPos + (Root.CFrame.RightVector * boxSize.X / 2) + (Root.CFrame.UpVector * boxSize.Y / 2))
                            local topLeft2D, tlVisible = CurrentCamera:WorldToViewportPoint(hrpPos + (Root.CFrame.RightVector * -(boxSize.X / 2)) + (Root.CFrame.UpVector * boxSize.Y / 2))
                            local bottomRight2D, brVisible = CurrentCamera:WorldToViewportPoint(hrpPos + (Root.CFrame.RightVector * boxSize.X / 2) + (Root.CFrame.UpVector * -(boxSize.Y / 2)))
                            local bottomLeft2D, blVisible = CurrentCamera:WorldToViewportPoint(hrpPos + (Root.CFrame.RightVector * -(boxSize.X / 2)) + (Root.CFrame.UpVector * -(boxSize.Y / 2)))

                            local isVisible = trVisible or tlVisible or brVisible or blVisible
                            if isVisible then
                                local tl2D = Vector2.new(topLeft2D.X, topLeft2D.Y)
                                local tr2D = Vector2.new(topRight2D.X, topRight2D.Y)
                                local bl2D = Vector2.new(bottomLeft2D.X, bottomLeft2D.Y)
                                local br2D = Vector2.new(bottomRight2D.X, bottomRight2D.Y)
                                local BoxColor = (ESPData.Settings.TeamColor and Target.Team) and Target.TeamColor.Color or ESPData.Settings.Color

                                if ESPData.Settings.Boxes then
                                    if ESPData.Settings.BoxMode == "Box" then
                                        BoxOutline.PointA = tr2D
                                        BoxOutline.PointB = tl2D
                                        BoxOutline.PointC = bl2D
                                        BoxOutline.PointD = br2D
                                        BoxOutline.Visible = ESPData.Settings.Boxes
                                        BoxOutline.Color = BoxColor

                                        BoxFill.PointA = Vector2.new(tr2D.X - 1, tr2D.Y + 1)
                                        BoxFill.PointB = Vector2.new(tl2D.X + 1, tl2D.Y + 1)
                                        BoxFill.PointC = Vector2.new(bl2D.X + 1, bl2D.Y - 1)
                                        BoxFill.PointD = Vector2.new(br2D.X - 1, br2D.Y - 1)
                                        BoxFill.Visible = ESPData.Settings.FillBoxes
                                        BoxFill.Color = ESPData.Settings.FillColor

                                        for _, L in next, SkeletonLines do L.Visible = false end
                                    elseif ESPData.Settings.BoxMode == "Cornered" then
                                        local Flip = (tl2D.X > tr2D.X) or (bl2D.X > br2D.X)
                                        if Flip then
                                            DrawCorneredBox(br2D, bl2D, tr2D, tl2D, BoxColor)
                                        else
                                            DrawCorneredBox(bl2D, br2D, tl2D, tr2D, BoxColor)
                                        end
                                        BoxOutline.Visible = false
                                        BoxFill.Visible = false
                                    end
                                else
                                    BoxOutline.Visible = false
                                    for _, L in next, SkeletonLines do L.Visible = false end
                                end

                                if ESPData.Settings.Name then
                                    local namePos = Vector2.new((topLeft2D.X + topRight2D.X) / 2, math.min(topLeft2D.Y, bottomLeft2D.Y, topRight2D.Y, bottomRight2D.Y) - 30)
                                    NameTag.Position = namePos
                                    NameTag.Text = Target.Name
                                    NameTag.Visible = true
                                    NameTag.Color = (ESPData.Settings.TeamColor and Target.Team) and Target.TeamColor.Color or ESPData.Settings.Color
                                else
                                    NameTag.Visible = false
                                end
                            else
                                BoxOutline.Visible = false
                                BoxFill.Visible = false
                                HealthBar.Visible = false
                                HealthBarOutline.Visible = false
                                NameTag.Visible = false
                                for _, L in next, SkeletonLines do L.Visible = false end
                            end
                        elseif ESPData.Settings.ESPMode == "Skeleton" then
                            local screenCoords = {}
                            local isVisible = false
                            local isR6 = Humanoid.RigType == Enum.HumanoidRigType.R6
                            for i, pair in next, DrawPairs do
                                local Line = SkeletonLines[i]
                                local Part1, Part2
                                if isR6 then
                                    Part1 = Target.Character:FindFirstChild(pair[3])
                                    Part2 = Target.Character:FindFirstChild(pair[4])
                                else
                                    Part1 = Target.Character:FindFirstChild(pair[1])
                                    Part2 = Target.Character:FindFirstChild(pair[2])
                                end
                                if Part1 and Part2 then
                                    local pos1 = Part1.Position
                                    local pos2 = Part2.Position

                                    if isR6 and pair[5] then
                                        pos1 = (Part1.CFrame * pair[5]).p
                                    elseif not isR6 and pair[1] == "Head" then
                                        pos1 = (Part1.CFrame * CFrame.new(0, -0.2, 0)).p
                                    end

                                    if isR6 and pair[6] then
                                        pos2 = (Part2.CFrame * pair[6]).p
                                    elseif not isR6 and pair[2] == "UpperTorso" and pair[1] ~= "Head" then
                                        pos2 = (Part2.CFrame * CFrame.new(0, 0.5, 0)).p
                                    elseif not isR6 and pair[2] == "LowerTorso" then
                                        pos2 = Part2.Position
                                    end

                                    local P1, Vis1 = CurrentCamera:WorldToViewportPoint(pos1)
                                    local P2, Vis2 = CurrentCamera:WorldToViewportPoint(pos2)
                                    screenCoords[pair[1]] = screenCoords[pair[1]] or { Pos = P1, Visible = Vis1 }
                                    screenCoords[pair[2]] = screenCoords[pair[2]] or { Pos = P2, Visible = Vis2 }

                                    if Vis1 and Vis2 then
                                        Line.From = Vector2.new(P1.X, P1.Y)
                                        Line.To = Vector2.new(P2.X, P2.Y)
                                        Line.Color = (ESPData.Settings.TeamColor and Target.Team) and Target.TeamColor.Color or ESPData.Settings.Color
                                        Line.Visible = true
                                        isVisible = true
                                    else
                                        Line.Visible = false
                                    end
                                else
                                    Line.Visible = false
                                end
                            end

                            HealthBar.Visible = false
                            HealthBarOutline.Visible = false

                            if ESPData.Settings.Name and screenCoords.Head and screenCoords.Head.Visible then
                                local namePos = Vector2.new(screenCoords.Head.Pos.X, screenCoords.Head.Pos.Y - 30)
                                NameTag.Position = namePos
                                NameTag.Text = Target.Name
                                NameTag.Visible = true
                                NameTag.Color = (ESPData.Settings.TeamColor and Target.Team) and Target.TeamColor.Color or ESPData.Settings.Color
                            else
                                NameTag.Visible = false
                            end

                            BoxOutline.Visible = false
                            BoxFill.Visible = false
                            if not isVisible then
                                NameTag.Visible = false
                                for _, L in next, SkeletonLines do L.Visible = false end
                            end
                        elseif ESPData.Settings.ESPMode == "3D Box" then
                            local isVisible = false
                            local boxSize = Vector3.new(4, 6, 4)
                            local hrpPos = Root.Position - Vector3.new(0, 0.25, 0)

                            local corners = {
                                hrpPos + Vector3.new(boxSize.X / 2, boxSize.Y / 2, boxSize.X / 2),
                                hrpPos + Vector3.new(-(boxSize.X / 2), boxSize.Y / 2, boxSize.X / 2),
                                hrpPos + Vector3.new(-(boxSize.X / 2), boxSize.Y / 2, -(boxSize.X / 2)),
                                hrpPos + Vector3.new(boxSize.X / 2, boxSize.Y / 2, -(boxSize.X / 2)),
                                hrpPos + Vector3.new(boxSize.X / 2, -(boxSize.Y / 2), boxSize.X / 2),
                                hrpPos + Vector3.new(-(boxSize.X / 2), -(boxSize.Y / 2), boxSize.X / 2),
                                hrpPos + Vector3.new(-(boxSize.X / 2), -(boxSize.Y / 2), -(boxSize.X / 2)),
                                hrpPos + Vector3.new(boxSize.X / 2, -(boxSize.Y / 2), -(boxSize.X / 2))
                            }

                            local screenPos = {}
                            for i, corner in next, corners do
                                local pos, vis = CurrentCamera:WorldToViewportPoint(corner)
                                screenPos[i] = { Pos = pos, Visible = vis }
                                if vis then isVisible = true end
                            end

                            local edges = {
                                {1, 2}, {2, 3}, {3, 4}, {4, 1},
                                {5, 6}, {6, 7}, {7, 8}, {8, 5},
                                {1, 5}, {2, 6}, {3, 7}, {4, 8}
                            }

                            for i, edge in next, edges do
                                local Line = SkeletonLines[i]
                                local p1, p2 = screenPos[edge[1]], screenPos[edge[2]]
                                if p1.Visible and p2.Visible then
                                    Line.From = Vector2.new(p1.Pos.X, p1.Pos.Y)
                                    Line.To = Vector2.new(p2.Pos.X, p2.Pos.Y)
                                    Line.Color = (ESPData.Settings.TeamColor and Target.Team) and Target.TeamColor.Color or ESPData.Settings.Color
                                    Line.Visible = true
                                else
                                    Line.Visible = false
                                end
                            end

                            for i = #edges + 1, #SkeletonLines do
                                SkeletonLines[i].Visible = false
                            end

                            NameTag.Visible = false
                            HealthBar.Visible = false
                            HealthBarOutline.Visible = false
                            BoxOutline.Visible = false
                            BoxFill.Visible = false

                            if not isVisible or not ESPData.Settings.Boxes then
                                for _, L in next, SkeletonLines do L.Visible = false end
                            end
                        end
                    else
                        BoxOutline.Visible = false
                        BoxFill.Visible = false
                        HealthBar.Visible = false
                        HealthBarOutline.Visible = false
                        NameTag.Visible = false
                        for _, L in next, SkeletonLines do L.Visible = false end
                    end
                else
                    BoxOutline.Visible = false
                    BoxFill.Visible = false
                    HealthBar.Visible = false
                    HealthBarOutline.Visible = false
                    NameTag.Visible = false
                    for _, L in next, SkeletonLines do L.Visible = false end
                end
            else
                BoxOutline.Visible = false
                BoxFill.Visible = false
                HealthBar.Visible = false
                HealthBarOutline.Visible = false
                NameTag.Visible = false
                for _, L in next, SkeletonLines do L.Visible = false end
            end
        end

        ESP:Connection(RunService.RenderStepped:Connect(Update))
        ESPData.Data.Instances[Target] = {
            BoxOutline = BoxOutline,
            BoxFill = BoxFill,
            HealthBarOutline = HealthBarOutline,
            HealthBar = HealthBar,
            NameTag = NameTag,
            SkeletonLines = SkeletonLines,
        }

        return ESPData.Data
    end

    local function DestroyESP()
        for player, espData in next, ESPData.Data.Instances do
            if espData.BoxOutline then espData.BoxOutline:Destroy() end
            if espData.BoxFill then espData.BoxFill:Destroy() end
            if espData.HealthBarOutline then espData.HealthBarOutline:Destroy() end
            if espData.HealthBar then espData.HealthBar:Destroy() end
            if espData.NameTag then espData.NameTag:Destroy() end

            for _, line in next, espData.SkeletonLines do
                if line then line:Destroy() end
            end

            ESPData.Data.Instances[player] = nil
        end
        ESPData.Data.Instances = {}
    end
 
    ESP = Tabs.Render:CreateModule({
        Name = "ESP",
        Flag = "UniversalESP",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                for _, Player in next, Players:GetPlayers() do
                    if Player ~= LocalPlayer then
                        CreateESP(Player)
                    end
                end
                
                self:Connection(Players.PlayerAdded:Connect(function(NewPlayer)
                    if NewPlayer ~= LocalPlayer then
                        CreateESP(NewPlayer)
                    end
                end))
            else
                DestroyESP()
            end
        end
    })

    local Fill, FillColor, Healthbar, Name, Box
    ESP:Dropdown({
        Name = "Mode",
        Flag = "ESPMode",
        Default = "Dynamic",
        Options = {"Dynamic", "Classic", "Locked", "Skeleton", "3D Box"},
        CallingFunction = function(self, value: string)
            ESPData.Settings.ESPMode = value

            if value == "Dynamic" or value == "Classic" or value == "Locked" then
                Fill:SetVisiblity(true)
                FillColor:SetVisiblity(Fill.Enabled)
                Box:SetVisiblity(true)
            else
                Fill:SetVisiblity(false)
                FillColor:SetVisiblity(not Fill.Enabled)
                Box:SetVisiblity(false)
            end

            Healthbar:SetVisiblity(value == "Dynamic" or value == "Classic")
            Name:SetVisiblity(value ~= "3D Box")
        end
    })

    ESP:Dropdown({
        Name = "Box Type",
        Flag = "ESPBoxType",
        Default = "Box",
        Options = {"Box", "Cornered"},
        CallingFunction = function(self, value: string)
            ESPData.Settings.BoxMode = value
        end
    })

    ESP:ColorSlider({
        Name = "Color",
        Flag = "ESPColor",
        Default = Color3.fromRGB(255, 0, 0),
        CallingFunction = function(self, color: Color3)
            ESPData.Settings.Color = color
        end
    })

    FillColor = ESP:ColorSlider({
        Name = "Fill Color",
        Flag = "ESPFillColor",
        Default = Color3.fromRGB(0, 0, 0),
        CallingFunction = function(self, color: Color3)
            ESPData.Settings.FillColor = color
        end
    })

    ESP:MiniToggle({
        Name = "Team Color",
        Flag = "ESPTeamColor",
        CallingFunction = function(self, value: boolean)
            ESPData.Settings.TeamColor = value
        end
    })

    ESP:MiniToggle({
        Name = "Team Check",
        Flag = "ESPTeamCheck",
        CallingFunction = function(self, value: boolean)
            ESPData.Settings.TeamCheck = value
        end
    })

    Box = ESP:MiniToggle({
        Name = "Box",
        Flag = "ESPBox",
        Default = true,
        CallingFunction = function(self, value: boolean)
            ESPData.Settings.Boxes = value
        end
    })

    Fill = ESP:MiniToggle({
        Name = "Fill",
        Flag = "ESPFill",
        CallingFunction = function(self, value: boolean)
            ESPData.Settings.FillBoxes = value
            FillColor:SetVisiblity(value)
        end
    })

    Healthbar = ESP:MiniToggle({
        Name = "Healthbar",
        Flag = "ESPHealthbar",
        CallingFunction = function(self, value: boolean)
            ESPData.Settings.Health = value
        end
    })

    Name = ESP:MiniToggle({
        Name = "Name",
        Flag = "ESPName",
        CallingFunction = function(self, value: boolean)
            ESPData.Settings.Name = value
        end
    })
end)();

(function()
    local SpinBotData = {
        Settings = {
            Mode = "CFrame",
            Speed = 30
        },
        Data = {Body = nil}
    }
    local SpinBot = Tabs.Movement:CreateModule({
        Name = "Spin Bot",
        Flag = "UniversalSpinBot",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                if SpinBotData.Settings.Mode == "CFrame" then
                    self:Connection(RunService.RenderStepped:Connect(function()
                        LocalPlayer.Character.PrimaryPart.CFrame *= CFrame.Angles(0, math.rad(SpinBotData.Settings.Speed / 5), 0)
                    end))
                elseif SpinBotData.Settings.Mode == "Angular" then
                    SpinBotData.Data.Body = Instance.new("BodyAngularVelocity", LocalPlayer.Character.PrimaryPart)
                    SpinBotData.Data.Body.AngularVelocity = Vector3.new(0, SpinBotData.Settings.Speed, 0)
                    SpinBotData.Data.Body.MaxTorque = Vector3.new(0, math.huge, 0)
                    SpinBotData.Data.Body.P = 10000
                    self:Connection(RunService.RenderStepped:Connect(function()
                        SpinBotData.Data.Body.AngularVelocity = Vector3.new(0, SpinBotData.Settings.Speed, 0)
                    end))
                end
            else
                if SpinBotData.Data.Body then
                    SpinBotData.Data.Body:Destroy()
                    SpinBotData.Data.Body = nil
                end
            end
        end
    })

    SpinBot:Dropdown({
        Name = "Mode",
        Flag = "SpinBotMode",
        Default = "CFrame",
        Options = {"CFrame", "Angular"},
        CallingFunction = function(self, Value)
            SpinBotData.Settings.Mode = Value

            local WasEnabled: boolean = SpinBot.Enabled
            SpinBot:SetValue(false, false, false)
            if WasEnabled then
                task.delay(0.1, SpinBot.SetValue, SpinBot, true, false, false)
            end
        end
    })

    SpinBot:Slider({
        Name = "Speed",
        Flag = "SpinBotSpeed",
        Default = 30,
        Min = 1,
        Max = 100,
        CallingFunction = function(self, value: number)
            SpinBotData.Settings.Speed = value
        end
    })
end)();

(function()
    local MouseTPData = {
        Settings = {
            Mode = "Instant",
            LerpSpeed = 10,
            TweenSpeed = 8
        }
    }

    local Modes = {
        CFrame = function(target: CFrame)
            LocalPlayer.Character.PrimaryPart.CFrame = target
        end,
        Lerp = function(target: CFrame)
            local Start = LocalPlayer.Character.PrimaryPart.CFrame
            local Alpha = 0
            while Alpha < 1 do
                Alpha += RunService.PreSimulation:Wait() * MouseTPData.Settings.LerpSpeed
                LocalPlayer.Character.PrimaryPart.CFrame = Start:Lerp(target, math.clamp(Alpha, 0, 1))
            end
        end,
        Tween = function(target: CFrame)
            local Tween = TweenService:Create(
                LocalPlayer.Character.PrimaryPart,
                TweenInfo.new(1 - MouseTPData.Settings.TweenSpeed / 10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {CFrame = target}
            )
            Tween:Play()
            Tween.Completed:Wait()
        end
    }

    local MouseTP = Tabs.Movement:CreateModule({
        Name = "Mouse TP",
        Flag = "UniversalMouseTP",
        Button = true,
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                local Mouse: Mouse? = LocalPlayer:GetMouse()
                if Mouse and Night:IsAlive(LocalPlayer) then
                    Modes[MouseTPData.Settings.Mode](Mouse.Hit)
                end
            end
        end
    })

    local LerpSpeed, TweenSpeed
    MouseTP:Dropdown({
        Name = "Mode",
        Flag = "MouseTPMode",
        Default = "CFrame",
        Options = {"CFrame", "Lerp", "Tween"},
        CallingFunction = function(self, value: string)
            MouseTPData.Settings.Mode = value
            LerpSpeed:SetVisiblity(value == "Lerp")
            TweenSpeed:SetVisiblity(value == "Tween")
        end
    })

    LerpSpeed = MouseTP:Slider({
        Name = "Speed",
        Flag = "MouseTPLerpSpeed",
        Default = 10,
        Min = 1,
        Max = 20,
        Increment = 1,
        CallingFunction = function(self, value: number)
            MouseTPData.Settings.LerpSpeed = value
        end
    })

    TweenSpeed = MouseTP:Slider({
        Name = "Speed",
        Flag = "MouseTPTweenSpeed",
        Default = 8,
        Min = 1,
        Max = 10,
        Increment = 1,
        CallingFunction = function(self, value: number)
            MouseTPData.Settings.TweenSpeed = value
        end
    })
end)();

(function()
    local Speed, Distance = 60, 5
    local Param = RaycastParams.new()
    Param.FilterType = Enum.RaycastFilterType.Exclude
    Param.RespectCanCollide = true
    Param.IgnoreWater = true

    local WallClimb = Tabs.Movement:CreateModule({
        Name = "Wall Climb",
        Flag = "UniversalWallClimb",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                repeat
                    if Night:IsAlive(LocalPlayer) then
                        local Root: BasePart = LocalPlayer.Character.PrimaryPart
                        local Humanoid: Humanoid = LocalPlayer.Character.Humanoid

                        local FilterDescendants = {}
                        for _, Player in next, Players:GetPlayers() do
                            if Player.Character then
                                table.insert(FilterDescendants, Player.Character)
                            end
                        end

                        Param.FilterDescendantsInstances = FilterDescendants
                        local Ray: RaycastResult? = workspace:Raycast(Root.Position, Humanoid.MoveDirection * Distance, Param)
                        if Ray and not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                            local CurrentVelocity: Vector3 = Root.AssemblyLinearVelocity
                            Root.AssemblyLinearVelocity = Vector3.new(CurrentVelocity.X, Speed, CurrentVelocity.Z)
                        end
                    end
                    task.wait()
                until not self.Enabled
            end
        end
    })
    
    WallClimb:Slider({
        Name = "Speed",
        Flag = "UniversalWallClimbSpeed",
        Min = 1,
        Max = 120,
        Default = 60,
        CallingFunction = function(self, value: number)
            Speed = value
        end
    })

    WallClimb:Slider({
        Name = "Distance",
        Flag = "UniversalWallClimbDistance",
        Min = 1,
        Max = 10,
        Default = 5,
        CallingFunction = function(self, value: number)
            Distance = value
        end
    })
end)();

(function()
    local NoClipData = {
        Settings = {
            Mode = "Teleport",
            Distance = 2,
            Studs = 5,
            Speed = 0.1
        },
        Data = {
            Tweening = false,
            Restore = {}
        }
    }

    local Param = RaycastParams.new()
    Param.FilterType = Enum.RaycastFilterType.Exclude

    local function Teleport(Character: Model, Direction: Vector3)
        local Torso = Character.PrimaryPart
        if not Torso then
            Torso = Character:FindFirstChild("Torso") or Character:FindFirstChild("UpperTorso")
        end
        if not Torso then return end

        if NoClipData.Settings.Mode == "Teleport" then
            Torso.CFrame = Torso.CFrame + Direction * NoClipData.Settings.Studs
        elseif NoClipData.Settings.Mode == "Slide" and not NoClipData.Data.Tweening then
            NoClipData.Data.Tweening = true
            local Tween = TweenService:Create(Torso, TweenInfo.new(NoClipData.Settings.Speed, Enum.EasingStyle.Linear), {
                CFrame = Torso.CFrame + Direction * NoClipData.Settings.Studs
            })
            Tween:Play()
            Tween.Completed:Connect(function()
                NoClipData.Data.Tweening = false
            end)
        end
    end

    local NoClip = Tabs.Movement:CreateModule({
        Name = "No Clip",
        Flag = "UniversalNoClip",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                self:Connection(RunService.PreSimulation:Connect(function()
                    if not Night:IsAlive(LocalPlayer) then return end

                    local Character = LocalPlayer.Character
                    local Humanoid: Humanoid = Character:FindFirstChildOfClass("Humanoid")

                    if NoClipData.Settings.Mode == "Collide" then
                        repeat
                            for _, v in Character:GetChildren() do
                                if (v:IsA("MeshPart") or v:IsA("Part")) and v.CanCollide then
                                    v.CanCollide = false
                                    if not table.find(NoClipData.Data.Restore, v) then
                                        table.insert(NoClipData.Data.Restore, v)
                                    end
                                end
                            end
                            task.wait(0.5)
                        until not self.Enabled or NoClipData.Settings.Mode ~= "Collide"
                    end

                    if NoClipData.Settings.Mode == "Teleport" or NoClipData.Settings.Mode == "Slide" then
                        local Filter: {Instance} = {}
                        for _, Player in next, Players:GetPlayers() do
                            if Player.Character then
                                table.insert(Filter, Player.Character)
                            end
                        end
                        Param.FilterDescendantsInstances = Filter

                        local Ray: RaycastResult? = workspace:Raycast(Character.PrimaryPart.Position, Humanoid.MoveDirection * NoClipData.Settings.Distance, Param)
                        if Ray then
                            Teleport(Character, Humanoid.MoveDirection)
                        end
                    end
                end))
            else
                for _, v in NoClipData.Data.Restore do
                    if v then v.CanCollide = true end
                end
                table.clear(NoClipData.Data.Restore)
            end
        end
    })

    local Studs, Slide
    NoClip:Dropdown({
        Name = "Mode",
        Flag = "NoClipMode",
        Default = "Teleport",
        Options = {"Teleport", "Slide", "Collide"},
        CallingFunction = function(self, value: string)
            NoClipData.Settings.Mode = value
            Studs:SetVisiblity(value == "Teleport")
            Slide:SetVisiblity(value == "Slide")
        end
    })

    NoClip:Slider({
        Name = "Distance",
        Flag = "UniversalNoClipDistance",
        Min = 1,
        Max = 5,
        Default = 2,
        CallingFunction = function(self, value: number)
            NoClipData.Settings.Distance = value
        end
    })

    Studs = NoClip:Slider({
        Name = "TP Studs",
        Flag = "UniversalNoClipStuds",
        Min = 1,
        Max = 10,
        Default = 5,
        CallingFunction = function(self, value: number)
            NoClipData.Settings.Studs = value
        end
    })

    Slide = NoClip:Slider({
        Name = "Slide Speed",
        Flag = "UniversalNoClipSlideSpeed",
        Min = 0.01,
        Max = 0.5,
        Default = 0.1,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            NoClipData.Settings.Speed = value
        end
    })
end)();

(function()
    local OldReqs, IP = {}, "127.0.0.1"
    local AntiIPLogger = Tabs.Utility:CreateModule({
        Name = "Anti IP Logger",
        Flag = "UniversalAntiIPLogger",
        Default = true,
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                if hookfunction then
                    xpcall(function()
                        if MainRequest then
                            local OldMain; OldMain = hookfunction(http.request, Night.newcclosure(function(Data, ...)
                                if typeof(Data) == "table" then
                                    local Url: string = tostring(Data.Url):lower()
                                    if Url:find("ipify") or (Url:find("api") and Url:find("ip")) then
                                        Night:CreateNotification({
                                            Title = "Anti IP Logger",
                                            Description = "Night has blocked a script attempting to run an IP logger to grab your IP address.",
                                            Duration = 20
                                        })

                                        return {
                                            StatusMessage = "OK",
                                            Success = 200,
                                            StatusCode = 200,
                                            Headers = {},
                                            Body = IP
                                        }
                                    end

                                    local Ret = OldMain(Data, ...)
                                    if Ret and typeof(Ret) == "table" then
                                        local Body: string | {} = Ret.Body
                                        if typeof(Body) == "string" then
                                            local Suc, Json = pcall(function()
                                                return HttpService:JSONDecode(Body)
                                            end)

                                            if Suc then
                                                Body = Json
                                            end
                                        end

                                        if typeof(Body) == "table" then
                                            local Results = Night:SearchTable(Body, "ip")
                                            if #Results == 0 then
                                                Results = Night:SearchTable(Body, "origin")
                                            end

                                            if #Results > 0 then
                                                local ShouldTrigger: boolean = false
                                                for i,v in Results do
                                                    if tostring(v):lower() == "ip" or tostring(v):lower():find("ip add") or tostring(v) == "origin" then
                                                        ShouldTrigger = true
                                                    end
                                                end

                                                if ShouldTrigger then
                                                    Night:CreateNotification({
                                                        Title = "Anti IP Logger",
                                                        Description = "Night has blocked a script attempting to run an IP logger to grab your IP address.",
                                                        Duration = 20
                                                    })

                                                    return {
                                                        StatusMessage = "OK",
                                                        Success = 200,
                                                        StatusCode = 200,
                                                        Headers = {},
                                                        Body = '{"ip": "'..IP..'"}'
                                                    }
                                                end
                                            end
                                        else
                                            if tostring(Body):lower():find("ip address") or tostring(Body):lower() == "ip" then
                                                Night:CreateNotification({
                                                    Title = "Anti IP Logger",
                                                    Description = "Night has blocked a script attempting to run an IP logger to grab your IP address.",
                                                    Duration = 20
                                                })

                                                return {
                                                    StatusMessage = "OK",
                                                    Success = 200,
                                                    StatusCode = 200,
                                                    Headers = {},
                                                    Body = IP
                                                }
                                            end
                                        end
                                    end
                                end
                                return OldMain(Data, ...)
                            end))

                            OldReqs[MainRequest] = OldMain
                            if request and MainRequest ~= request then
                                OldReqs[request] = hookfunction(request, MainRequest)
                            end
                        end
                    end, function(err: string)
                        task.delay(0.1, self.SetValue, self, false)
                        Night:CreateNotification({
                            Title = "Anti IP Logger",
                            Description = "An error occurred "..err..".",
                            Duration = 10
                        })  
                    end)
                else
                    task.delay(0.1, self.SetValue, self, false)
                    Night:CreateNotification({
                        Title = "Anti IP Logger",
                        Description = "Your executor does not support this module.",
                        Duration = 10
                    })  
                end 
            else
                for i,v in OldReqs do
                    hookfunction(i, v)
                end
            end
        end
    })

    AntiIPLogger:TextBox({
        Name = "IP",
        Flag = "AntiIPLoggerIPValue",
        Default = "127.0.0.1",
        CallingFunction = function(self, value: string)
            IP = value
        end
    })
end)();

(function()
    local Power, Mode = 100, "Button"
    local HighJump = Tabs.Movement:CreateModule({
        Name = "High Jump",
        Flag = "UniversalHighJump",
        Button = true,
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                if Mode == "Button" then
                    if Night:IsAlive(LocalPlayer) then
                        local Root: BasePart = LocalPlayer.Character.PrimaryPart
                        local CurrentVelocity: Vector3 = Root.AssemblyLinearVelocity
                        Root.AssemblyLinearVelocity = Vector3.new(CurrentVelocity.X, Power, CurrentVelocity.Z)
                    end
                else
                    self:Connection(UserInputService.JumpRequest:Connect(function()
                        if Night:IsAlive(LocalPlayer) then
                            local Root: BasePart = LocalPlayer.Character.PrimaryPart
                            local CurrentVelocity: Vector3 = Root.AssemblyLinearVelocity
                            Root.AssemblyLinearVelocity = Vector3.new(CurrentVelocity.X, Power, CurrentVelocity.Z)
                        end
                    end))
                end
            end
        end
    })
    
    HighJump:Slider({
        Name = "Power",
        Flag = "UniversalHighJumpPower",
        Min = 10,
        Max = 400,
        Default = 200,
        CallingFunction = function(self, value: number)
            Power = value
        end
    })

    HighJump:Dropdown({
        Name = "Mode",
        Flag = "HighJumpMode",
        Default = "Button",
        Options = {"Button", "Jump"},
        CallingFunction = function(self, value: string)
            Mode = value
            HighJump.Data.Button = (value == "Button")

            if HighJump.Enabled and value == "Button" then
                HighJump:SetValue(false)
            end
        end
    })
end)();

(function()
    local IdentityChangerData = {
        Settings = {
            Username = false,
            DisplayName = false,
            UsernameText = "night.gg",
            DisplayNameText = "night.gg"
        },
        Data = {
            Name = LocalPlayer.Name,
            DisplayName = LocalPlayer.DisplayName,
            HumanoidDisplay = nil
        },
        Connections = {}
    }

    local IdentityChanger = Tabs.Utility:CreateModule({
        Name = "Identity Changer",
        Flag = "UniverslIdentityChanger",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                LocalPlayer.Name = IdentityChangerData.Settings.Username and IdentityChangerData.Settings.UsernameText or LocalPlayer.Name
                LocalPlayer.DisplayName = IdentityChangerData.Settings.DisplayName and IdentityChangerData.Settings.DisplayNameText or LocalPlayer.DisplayName
                if Night:IsAlive(LocalPlayer) then
                    local Humanoid: Humanoid = LocalPlayer.Character.Humanoid
                    IdentityChangerData.Data.HumanoidDisplay = Humanoid.DisplayName
                    Humanoid.DisplayName = IdentityChangerData.Settings.DisplayName and IdentityChangerData.Settings.DisplayNameText or Humanoid.DisplayName
                end

                self:Connection(LocalPlayer.CharacterAdded:Connect(function(Character: Model)  
                    local Humanoid = Character:FindFirstChild("Humanoid")
                    repeat task.wait() until Humanoid

                    IdentityChangerData.Data.HumanoidDisplay = Humanoid.DisplayName
                    Humanoid.DisplayName = IdentityChangerData.Settings.DisplayName and IdentityChangerData.Settings.DisplayNameText or LocalPlayer.DisplayName
                end), {IdentityChangerData.Connections})
            else
                LocalPlayer.Name = IdentityChangerData.Data.Name
                LocalPlayer.DisplayName = IdentityChangerData.Data.DisplayName
                if IdentityChangerData.Data.HumanoidDisplay and Night:IsAlive(LocalPlayer) then
                    LocalPlayer.Character.Humanoid.DisplayName = IdentityChangerData.Data.HumanoidDisplay
                end
            end
        end
    })

    local UsernameTextBox = IdentityChanger:TextBox({
        Name = "Username",
        Flag = "IdentityChangerUsernameValue",
        Default = "night.gg",
        CallingFunction = function(self, value: string)
            IdentityChangerData.Settings.UsernameText = value

            if IdentityChangerData.Settings.Username then
                LocalPlayer.Name = value
            end
        end
    })

    local DisplayNameTextBox = IdentityChanger:TextBox({
        Name = "Display Name",
        Flag = "IdentityChangerDisplayNameValue",
        Default = "night.gg",
        CallingFunction = function(self, value: string)
            IdentityChangerData.Settings.DisplayNameText = value

            if IdentityChangerData.Settings.DisplayName then
                LocalPlayer.DisplayName = value
                if Night:IsAlive(LocalPlayer) then
                    local Humanoid: Humanoid = LocalPlayer.Character.Humanoid
                    Humanoid.DisplayName = value
                end
            end
        end
    })

    IdentityChanger:MiniToggle({
        Name = "Username",
        Flag = "IdentityChangerUsernameEnabled",
        Default = true,
        CallingFunction = function(self, value: boolean)
            IdentityChangerData.Settings.Username = value
            UsernameTextBox:SetVisiblity(value)

            if not value then
                LocalPlayer.Name = IdentityChangerData.Data.Name
            else
                LocalPlayer.Name = IdentityChangerData.Settings.UsernameText
            end
        end
    })

    IdentityChanger:MiniToggle({
        Name = "Display Name",
        Flag = "IdentityChangerDisplayNameEnabled",
        Default = true,
        CallingFunction = function(self, value: boolean)
            IdentityChangerData.Settings.DisplayName = value
            DisplayNameTextBox:SetVisiblity(value)
            
            if not value then
                for i,v in IdentityChangerData.Connections do
                    v:Disconnect()
                end
                table.clear(IdentityChangerData.Connections)

                LocalPlayer.DisplayName = IdentityChangerData.Data.DisplayName
                if Night:IsAlive(LocalPlayer) then
                    local Humanoid: Humanoid = LocalPlayer.Character.Humanoid
                    Humanoid.DisplayName = IdentityChanger.Data.HumanoidDisplay
                end
            else
                if Night:IsAlive(LocalPlayer) then
                    local Humanoid: Humanoid = LocalPlayer.Character.Humanoid
                    IdentityChangerData.Data.HumanoidDisplay = Humanoid.DisplayName
                    Humanoid.DisplayName = IdentityChangerData.Settings.DisplayName and IdentityChangerData.Settings.DisplayNameText or Humanoid.DisplayName
                end

                IdentityChanger:Connection(LocalPlayer.CharacterAdded:Connect(function(Character: Model)  
                    local Humanoid = Character:FindFirstChild("Humanoid")
                    repeat task.wait() until Humanoid

                    IdentityChangerData.Data.HumanoidDisplay = Humanoid.DisplayName
                    Humanoid.DisplayName = IdentityChangerData.Settings.DisplayName and IdentityChangerData.Settings.DisplayNameText or LocalPlayer.DisplayName
                end), {IdentityChangerData.Connections})
            end
        end
    })
end)();

(function()
    local Trails
    local TrailsData = {
        Settings = {
            Shape = "Trail",
            Lifetime = 3,
            Width = 3,
            Size = 2,
            SpawnSpeed = 0.15,
            Color = Color3.fromRGB(255, 0, 0)
        },
        Data = {
            Parts = {},
            Trail = nil,
            Atts = {}
        },
        Connections = {}
    }

    local function MakePart(CF: CFrame)
        local Part, Offset: CFrame = nil, CFrame.new()
        if TrailsData.Settings.Shape == "Plate" then
            Part = Instance.new("Part")
            Part.Size = Vector3.new(TrailsData.Settings.Size, 0.2, TrailsData.Settings.Size)
        elseif TrailsData.Settings.Shape == "Cube" then
            Part = Instance.new("Part")
            Part.Size = Vector3.new(TrailsData.Settings.Size, TrailsData.Settings.Size, TrailsData.Settings.Size)
        elseif TrailsData.Settings.Shape == "Sphere" then
            Part = Instance.new("Part")
            Part.Shape = Enum.PartType.Ball
            Part.Size = Vector3.new(TrailsData.Settings.Size, TrailsData.Settings.Size, TrailsData.Settings.Size)
        elseif TrailsData.Settings.Shape == "Circle" then
            Part = Instance.new("Part")
            Part.Size = Vector3.new(TrailsData.Settings.Size * 2, 0.2, TrailsData.Settings.Size * 2)
            local Mesh = Instance.new("CylinderMesh")
            Mesh.Parent = Part
            Offset = CFrame.Angles(math.rad(90), 0, 0)
        elseif TrailsData.Settings.Shape == "Triangle" then
            Part = Instance.new("WedgePart")
            Part.Size = Vector3.new(TrailsData.Settings.Size, TrailsData.Settings.Size, TrailsData.Settings.Size)
        else
            Part = Instance.new("Part")
            Part.Size = Vector3.new(TrailsData.Settings.Size, 0.2, TrailsData.Settings.Size)
        end

        Part.Anchored = true
        Part.CanCollide = false
        Part.Color = TrailsData.Settings.Color
        Part.Material = Enum.Material.Neon
        Part.CFrame = CF * Offset
        Part.Parent = workspace
        table.insert(TrailsData.Data.Parts, Part)

        local Tween: Tween = TweenService:Create(Part, TweenInfo.new(TrailsData.Settings.Lifetime, Enum.EasingStyle.Linear), {
            Transparency = 1,
            Size = Vector3.new(0, 0, 0)
        })

        Tween:Play()
        Trails:Connection(Tween.Completed:Connect(function()
            if Part and Part.Parent then Part:Destroy() end
            local i: number? = table.find(TrailsData.Data.Parts, Part)
            if i then table.remove(TrailsData.Data.Parts, i) end
        end))
    end

    local function MakeTrail()
        if Night:IsAlive(LocalPlayer) then
            local PrimaryPart: BasePart = LocalPlayer.Character.PrimaryPart
            local Att0: Attachment = Instance.new("Attachment", PrimaryPart)
            Att0.Position = Vector3.new(-(TrailsData.Settings.Width / 6), -2.55, 0)

            local Att1: Attachment = Instance.new("Attachment", PrimaryPart)
            Att1.Position = Vector3.new(TrailsData.Settings.Width / 6, -2.55, 0)

            local Trail: Trail = Instance.new("Trail", PrimaryPart)
            Trail.Attachment0 = Att0
            Trail.Attachment1 = Att1
            Trail.Lifetime = TrailsData.Settings.Lifetime
            Trail.Color = ColorSequence.new(TrailsData.Settings.Color)
            Trail.LightEmission = 10
            Trail.WidthScale = NumberSequence.new(TrailsData.Settings.Width)
            TrailsData.Data.Trail = Trail

            table.insert(TrailsData.Data.Atts, Att0)
            table.insert(TrailsData.Data.Atts, Att1)
        end
    end
    
    local function DestroyTrails()
        for i,v in next, TrailsData.Data.Parts do
            if v and v.Parent then 
                v:Destroy() 
            end
        end

        if TrailsData.Data.Trail then
            TrailsData.Data.Trail:Destroy()
            TrailsData.Data.Trail = nil
        end
        
        for _, att in next, TrailsData.Data.Atts do
            if att and att.Parent then 
                att:Destroy() 
            end
        end

        table.clear(TrailsData.Data.Parts)
        table.clear(TrailsData.Data.Atts)
    end

    local function MainTrail()
        if not Trails.Enabled then
            DestroyTrails()
            return
        end

        if Night:IsAlive(LocalPlayer) and Trails.Enabled then
            local PrimaryPart: BasePart = LocalPlayer.Character.PrimaryPart
            local Humanoid: Humanoid = LocalPlayer.Character.Humanoid
            if TrailsData.Settings.Shape == "Trail" then
                MakeTrail()
            else
                local Time = 0
                Trails:Connection(Humanoid.Died:Connect(function()
                    DestroyTrails()
                end))

                Trails:Connection(RunService.PreSimulation:Connect(function(dt)
                    if not Trails.Enabled then
                        DestroyTrails()
                        return
                    end

                    Time += dt
                    if Time >= TrailsData.Settings.SpawnSpeed then
                        Time = 0
                        if Night:IsAlive(LocalPlayer) then
                            MakePart(PrimaryPart.CFrame * CFrame.new(0, -3, 0))
                        end
                    end
                end), {TrailsData.Connections})
            end
        end
    end

    Trails = Tabs.Render:CreateModule({
        Name = "Trails",
        Flag = "UniversalTrails",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                MainTrail()
                self:Connection(LocalPlayer.CharacterAdded:Connect(MainTrail))
            else
                DestroyTrails()
            end
        end
    })

    local Width, Size
    Trails:Dropdown({
        Name = "Shape",
        Flag = "UniversalTrailShape",
        Default = "Trail",
        Options = {"Trail", "Plate", "Sphere", "Cube", "Circle", "Triangle"},
        CallingFunction = function(self, value: string)
            TrailsData.Settings.Shape = value
            Width:SetVisiblity(value == "Trail")
            Size:SetVisiblity(value ~= "Trail")

            for i,v in TrailsData.Connections do
                v:Disconnect()
            end

            table.clear(TrailsData.Connections)
            DestroyTrails()
            MainTrail()
        end
    })

    Trails:Slider({
        Name = "Lifetime",
        Flag = "UniversalTrailLifetime",
        Min = 1,
        Max = 5,
        Default = 3,
        CallingFunction = function(self, value: number)
            TrailsData.Settings.Lifetime = value

            DestroyTrails()
            MainTrail()
        end
    })

    Trails:Slider({
        Name = "Spawn Speed",
        Flag = "UniversalTrailSpawnSpeed",
        Min = 0.01,
        Max = 0.3,
        Default = 0.15,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            TrailsData.Settings.SpawnSpeed = value
        end
    })

    Width = Trails:Slider({
        Name = "Width",
        Flag = "UniversalTrailWidth",
        Min = 1,
        Max = 7,
        Default = 3,
        CallingFunction = function(self, value: number)
            TrailsData.Settings.Width = value

            DestroyTrails()
            MainTrail()
        end
    })

    Size = Trails:Slider({
        Name = "Size",
        Flag = "UniversalTrailSize",
        Min = 1,
        Max = 5,
        Default = 2,
        CallingFunction = function(self, value: number)
            TrailsData.Settings.Size = value

            DestroyTrails()
            MainTrail()
        end
    })

    Trails:ColorSlider({
        Name = "Color",
        Flag = "UniversalTrailColor",
        Default = Color3.fromRGB(255, 0, 0),
        CallingFunction = function(self, value: Color3)
            TrailsData.Settings.Color = value

            DestroyTrails()
            MainTrail()
        end
    })
end)();

(function()
    local ChinaHatData = {
        Settings = {
            Material = "Neon",
            Color = Color3.fromRGB(255, 0, 0),
            Transparency = 0.5,
            Size = 3
        },
        Data = {
            Mesh = nil,
            Weld = nil
        }
    }

    local function MakeHat()
        if ChinaHatData.Data.Mesh then
            ChinaHatData.Data.Mesh:Destroy()
        end

        repeat task.wait() until Night:IsAlive(LocalPlayer)
        local Mesh = Instance.new("MeshPart")
        Mesh.Name = "ChinaHat"
        Mesh.MeshId = "http://www.roblox.com/asset/?id=1778999"
        Mesh.Size = Vector3.new(ChinaHatData.Settings.Size, 0.75, ChinaHatData.Settings.Size)
        Mesh.Transparency = ChinaHatData.Settings.Transparency
        Mesh.Color = ChinaHatData.Settings.Color
        Mesh.Material = Enum.Material[ChinaHatData.Settings.Material]
        Mesh.CanCollide = false
        Mesh.Anchored = false

        local Weld = Instance.new("WeldConstraint")
        Weld.Part0 = Mesh
        pcall(function() Weld.Part1 = LocalPlayer.Character.Head end)
        Weld.Parent = Mesh

        pcall(function() Mesh.CFrame = LocalPlayer.Character.Head.CFrame * CFrame.new(0, 1, 0) end)
        Mesh.Parent = LocalPlayer.Character

        ChinaHatData.Data.Mesh = Mesh
        ChinaHatData.Data.Weld = Weld
    end

    local function UpdateHat()
        local Hat = ChinaHatData.Data.Mesh
        if Hat then
            Hat.Size = Vector3.new(ChinaHatData.Settings.Size, 0.6, ChinaHatData.Settings.Size)
            Hat.Transparency = ChinaHatData.Settings.Transparency
            Hat.Color = ChinaHatData.Settings.Color
            Hat.Material = Enum.Material[ChinaHatData.Settings.Material]
        end
    end

    local ChinaHat = Tabs.Render:CreateModule({
        Name = "China Hat",
        Flag = "UniversalChinaHat",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                self:Connection(LocalPlayer.CharacterAdded:Connect(MakeHat))
                self:Connection(RunService.PreSimulation:Connect(function()
                    if Night:IsAlive(LocalPlayer) and (not ChinaHatData.Data.Mesh or not ChinaHatData.Data.Mesh.Parent) then
                        MakeHat()
                    end
                end))
            else
                if ChinaHatData.Data.Mesh then
                    ChinaHatData.Data.Mesh:Destroy()
                end
                ChinaHatData.Data.Mesh = nil
                ChinaHatData.Data.Weld = nil
            end
        end
    })
    
    ChinaHat:Dropdown({
        Name = "Material",
        Flag = "UniversalChinaHatMaterial",
        Default = "Neon",
        Options = Materials,
        CallingFunction = function(self, value: string)
            ChinaHatData.Settings.Material = value
            UpdateHat()
        end
    })

    ChinaHat:ColorSlider({
        Name = "Color",
        Flag = "UniversalChinaHatColor",
        Default = Color3.fromRGB(255, 0, 0),
        CallingFunction = function(self, value: Color3)
            ChinaHatData.Settings.Color = value
            UpdateHat()
        end
    })

    ChinaHat:Slider({
        Name = "Size",
        Flag = "UniversalChinaHatSize",
        Min = 1,
        Max = 5,
        Default = 3,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            ChinaHatData.Settings.Size = value
            UpdateHat()
        end
    })

    ChinaHat:Slider({
        Name = "Transparency",
        Flag = "UniversalChinaHatTransparency",
        Min = 0,
        Max = 1,
        Default = 0.5,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            ChinaHatData.Settings.Transparency = value
            UpdateHat()
        end
    })
end)();

(function()
    local InfiniteJumpData = {
        Settings = {
            Mode = "Hold",
            Delay = 0
        },
        Data = {
            Jump = 0,
            Holding = false
        }
    }
    
    local InfiniteJump = Tabs.Movement:CreateModule({
        Name = "Infinite Jump",
        Flag = "UniversalInfiniteJump",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                self:Connection(UserInputService.JumpRequest:Connect(function()  
                    local LastJumped: number = (os.clock() - InfiniteJumpData.Data.Jump)
                    if LastJumped >= InfiniteJumpData.Settings.Delay and Night:IsAlive(LocalPlayer) then
                        if InfiniteJumpData.Settings.Mode ~= "Hold" and 0.1 > LastJumped then
                            return
                        end

                        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        InfiniteJumpData.Data.Jump = os.clock()
                    end
                end))
            end
        end
    })

    local Delay
    InfiniteJump:Dropdown({
        Name = "Mode",
        Flag = "UniversalInfiniteJumpMode",
        Default = "Hold",
        Options = {"Hold", "Tap"},
        CallingFunction = function(self, value: string)
            InfiniteJumpData.Settings.Mode = value
            Delay:SetVisiblity(value == "Hold")
        end
    })

    Delay = InfiniteJump:Slider({
        Name = "Jump Delay",
        Flag = "UniversalInfiniteJumpDelay",
        Min = 0,
        Max = 0.5,
        Default = 0,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            InfiniteJumpData.Settings.Delay = value
        end
    })
end)();

(function()
    local AutoClickerData = {
        ClickType = "Left",
        CPS = 10
    }

    local AutoClicker = Tabs.Combat:CreateModule({
        Name = "Auto Clicker",
        Flag = "UniversalAutoClicker",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                repeat
                    local Mouse: Mouse? = LocalPlayer:GetMouse()
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y + 8, AutoClickerData.ClickType == "Left" and 0 or 1, true, game, 1)
                    VirtualInputManager:SendMouseButtonEvent(Mouse.X, Mouse.Y + 8, AutoClickerData.ClickType == "Left" and 0 or 1, false, game, 1)
                    task.wait(1 / AutoClickerData.CPS)
                until not self.Enabled
            end
        end
    })

    AutoClicker:Dropdown({
        Name = "Click Type",
        Flag = "UniversalAutoClickerClickType",
        Default = "Left",
        Options = {"Left", "Right"},
        CallingFunction = function(self, value: string)
            AutoClickerData.ClickType = value
        end
    })

    AutoClicker:Slider({
        Name = "CPS",
        Flag = "UniversalAutoClickerCPS",
        Min = 1,
        Max = 20,
        Default = 10,
        Increment = 1,
        CallingFunction = function(self, value: number)
            AutoClickerData.CPS = value
        end
    })
end)();

(function()
    local TeamCheck = false
    local Distance = 30

    local TargetHud = Tabs.Render:CreateModule({
        Name = "Target HUD",
        Flag = "TargetHUD",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                local Health = {
                    Current = (LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Health")) or 0,
                    Max = (LocalPlayer.Character and LocalPlayer.Character:GetAttribute("MaxHealth")) or 0
                }

                if Night:IsAlive(LocalPlayer) then
                    local Humanoid: Humanoid = LocalPlayer.Character.Humanoid
                    Health = {
                        Current = LocalPlayer.Character:GetAttribute("Health") or Humanoid.Health,
                        Max = LocalPlayer.Character:GetAttribute("MaxHealth") or Humanoid.MaxHealth
                    }
                end

                Night:GetTargetHud(true, {Player = LocalPlayer, Health = Health})
                repeat
                    local Nearest: { Distance: number, Player: Player? } = Night:GetClosestPlayer({
                        TeamCheck = TeamCheck
                    })

                    if Nearest.Player and Distance >= Nearest.Distance then
                        Health = {
                            Current = Nearest.Player.Character:GetAttribute("Health") or 0,
                            Max = Nearest.Player.Character:GetAttribute("MaxHealth") or 0
                        }

                        if Night:IsAlive(Nearest.Player) then
                            local Humanoid: Humanoid = Nearest.Player.Character.Humanoid
                            Health = {
                                Current = (LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Health")) or Humanoid.Health,
                                Max = (LocalPlayer.Character and LocalPlayer.Character:GetAttribute("MaxHealth")) or Humanoid.MaxHealth
                            }
                        end

                        Night:GetTargetHud():Update({
                            Player = Nearest.Player,
                            Health = Health,
                            Visible = true
                        })
                    else
                        Health = {
                                Current = (LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Health")) or 0,
                                Max = (LocalPlayer.Character and LocalPlayer.Character:GetAttribute("MaxHealth")) or 0
                        }

                        if Night:IsAlive(LocalPlayer) then
                            local Humanoid: Humanoid = LocalPlayer.Character.Humanoid
                            Health = {
                                Current = LocalPlayer.Character:GetAttribute("Health") or Humanoid.Health,
                                Max = LocalPlayer.Character:GetAttribute("MaxHealth") or Humanoid.MaxHealth
                            }
                        end

                        Night:GetTargetHud():Update({
                            Player = LocalPlayer,
                            Health = Health,
                            Visible = Night.UIData.UIOpen
                        })
                    end
                    task.wait(9.5)
                until not self.Enabled
            else
                Night:DestroyTargetHud()
            end
        end
    })

    TargetHud:Slider({
        Name = "Distance",
        Flag = "TargetHUDDistance",
        Min = 1,
        Max = 100,
        Default = 30,
        CallingFunction = function(self, value: number)
            Distance = value
        end
    })

    TargetHud:MiniToggle({
        Name = "Team Check",
        Flag = "TargetHUDTeamCheck",
        Default = true,
        CallingFunction = function(self, value: boolean)
            TeamCheck = value
        end
    })
end)();

(function()
    local FPSBoostData = {
        RemoveParticles = false,
        RemoveTrails = false,
        RemoveSmoke = false,
        RemoveFire = false,
        RemoveSparkles = false,
        RemoveBeams = false,
        RemoveTextures = false,
        RemoveSurfaceAppearance = false,
        RemoveCharacterMeshes = false,
        SimplifyParts = false,
        LowerLighting = false,
        RemoveTerrainEffects = false,
        AutoClean = false
    }

    local function RemoveMaterials(inst)
        if not inst then return end
        if FPSBoostData.RemoveParticles and inst:IsA("ParticleEmitter") then
            pcall(function() inst:Destroy() end)
        elseif FPSBoostData.RemoveTrails and inst:IsA("Trail") then
            pcall(function() inst:Destroy() end)
        elseif FPSBoostData.RemoveSmoke and inst:IsA("Smoke") then
            pcall(function() inst:Destroy() end)
        elseif FPSBoostData.RemoveFire and inst:IsA("Fire") then
            pcall(function() inst:Destroy() end)
        elseif FPSBoostData.RemoveSparkles and inst:IsA("Sparkles") then
            pcall(function() inst:Destroy() end)
        elseif FPSBoostData.RemoveBeams and inst:IsA("Beam") then
            pcall(function() inst:Destroy() end)
        elseif FPSBoostData.RemoveTextures and (inst:IsA("Decal") or inst:IsA("Texture")) then
            pcall(function() inst.Transparency = 1 end)
            pcall(function() inst.Texture = "" end)
        elseif FPSBoostData.RemoveSurfaceAppearance and inst:IsA("SurfaceAppearance") then
            pcall(function() inst:Destroy() end)
        elseif FPSBoostData.RemoveCharacterMeshes and inst:IsA("CharacterMesh") then
            pcall(function() inst:Destroy() end)
        elseif FPSBoostData.SimplifyParts and inst:IsA("BasePart") then
            pcall(function() inst.CastShadow = false end)
            pcall(function() inst.Material = Enum.Material.SmoothPlastic end)
            pcall(function() inst.Reflectance = 0 end)
            if inst:IsA("MeshPart") then
                pcall(function() inst.TextureID = "" end)
            end
        end
    end

    local FPSBoost = Tabs.Render:CreateModule({
        Name = "FPS Boost",
        Flag = "FPSBoost",
        CallingFunction = function(self, enabled: boolean)
            self.OldENV = self.OldENV or {}
            if enabled then
                self.OldENV = {
                    GlobalShadows = Lighting.GlobalShadows,
                    Brightness = Lighting.Brightness,
                    OutdoorAmbient = Lighting.OutdoorAmbient,
                    Ambient = Lighting.Ambient,
                    FogStart = Lighting.FogStart,
                    FogEnd = Lighting.FogEnd,
                    Effects = {},
                    QualityLevel = settings().Rendering.QualityLevel,
                    Terrain = Terrain and {
                        WaterWaveSize = Terrain.WaterWaveSize,
                        WaterWaveSpeed = Terrain.WaterWaveSpeed,
                        WaterReflectance = Terrain.WaterReflectance,
                        WaterTransparency = Terrain.WaterTransparency
                    } or nil
                }

                for _, obj in next, Lighting:GetChildren() do
                    if obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                        self.OldENV.Effects[obj] = obj.Enabled
                    end
                    if obj:IsA("Atmosphere") or obj:IsA("Sky") then
                        obj:Destroy()
                    end
                end

                for _, v in next, workspace:GetDescendants() do
                    RemoveMaterials(v)
                end

                if FPSBoostData.AutoClean then
                    workspace.DescendantAdded:Connect(RemoveMaterials)
                end

                if FPSBoostData.LowerLighting then
                    pcall(function()
                        Lighting.GlobalShadows = false
                        Lighting.Brightness = 1
                        Lighting.OutdoorAmbient = Color3.fromRGB(130, 130, 130)
                        Lighting.Ambient = Color3.fromRGB(120, 120, 120)
                        Lighting.FogStart = 1
                        Lighting.FogEnd = 100000
                        for _, obj in next, Lighting:GetChildren() do
                            if obj:IsA("Atmosphere") or obj:IsA("Sky") or obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then
                                obj.Enabled = false
                            end
                        end
                    end)
                end

                if FPSBoostData.RemoveTerrainEffects and Terrain then
                    pcall(function()
                        Terrain.WaterWaveSize = 0
                        Terrain.WaterWaveSpeed = 0
                        Terrain.WaterReflectance = 0
                        Terrain.WaterTransparency = 1
                    end)
                end

                pcall(function()
                    settings().Rendering.QualityLevel = 1
                end)
            else
                local env = self.OldENV
                if not env then return end

                pcall(function()
                    Lighting.GlobalShadows = env.GlobalShadows
                    Lighting.Brightness = env.Brightness or 0
                    Lighting.OutdoorAmbient = env.OutdoorAmbient
                    Lighting.Ambient = env.Ambient
                    Lighting.FogStart = env.FogStart
                    Lighting.FogEnd = env.FogEnd
                    for obj, enabled in next, env.Effects do
                        if obj and obj:IsDescendantOf(Lighting) then
                            obj.Enabled = enabled
                        end
                    end
                end)

                if Terrain and env.Terrain then
                    pcall(function()
                        Terrain.WaterWaveSize = env.Terrain.WaterWaveSize
                        Terrain.WaterWaveSpeed = env.Terrain.WaterWaveSpeed
                        Terrain.WaterReflectance = env.Terrain.WaterReflectance
                        Terrain.WaterTransparency = env.Terrain.WaterTransparency
                    end)
                end

                pcall(function()
                    settings().Rendering.QualityLevel = env.QualityLevel
                end)
            end
        end
    })

    FPSBoost:MiniToggle({
        Name = "Particles",
        Flag = "FPSBoostRemoveParticles",
        Default = true,
        CallingFunction = function(self, value)
            FPSBoostData.RemoveParticles = value
        end
    })

    FPSBoost:MiniToggle({
        Name = "Trails",
        Flag = "FPSBoostRemoveTrails",
        Default = true,
        CallingFunction = function(self, value)
            FPSBoostData.RemoveTrails = value
        end
    })

    FPSBoost:MiniToggle({
        Name = "Smoke",
        Flag = "FPSBoostRemoveSmoke",
        Default = true,
        CallingFunction = function(self, value)
            FPSBoostData.RemoveSmoke = value
        end
    })

    FPSBoost:MiniToggle({
        Name = "Fire",
        Flag = "FPSBoostRemoveFire",
        Default = true,
        CallingFunction = function(self, value)
            FPSBoostData.RemoveFire = value
        end
    })

    FPSBoost:MiniToggle({
        Name = "Sparkles",
        Flag = "FPSBoostRemoveSparkles",
        Default = true,
        CallingFunction = function(self, value)
            FPSBoostData.RemoveSparkles = value
        end
    })

    FPSBoost:MiniToggle({
        Name = "Beams",
        Flag = "FPSBoostRemoveBeams",
        Default = true,
        CallingFunction = function(self, value)
            FPSBoostData.RemoveBeams = value
        end
    })

    FPSBoost:MiniToggle({
        Name = "Textures",
        Flag = "FPSBoostRemoveTextures",
        Default = true,
        CallingFunction = function(self, value)
            FPSBoostData.RemoveTextures = value
        end
    })

    FPSBoost:MiniToggle({
        Name = "Surface Appearance",
        Flag = "FPSBoostRemoveSurfaceAppearance",
        Default = true,
        CallingFunction = function(self, value)
            FPSBoostData.RemoveSurfaceAppearance = value
        end
    })

    FPSBoost:MiniToggle({
        Name = "Character Meshes",
        Flag = "FPSBoostRemoveCharacterMeshes",
        Default = true,
        CallingFunction = function(self, value)
            FPSBoostData.RemoveCharacterMeshes = value
        end
    })

    FPSBoost:MiniToggle({
        Name = "Simplify Parts",
        Flag = "FPSBoostSimplifyParts",
        Default = true,
        CallingFunction = function(self, value)
            FPSBoostData.SimplifyParts = value
        end
    })

    FPSBoost:MiniToggle({
        Name = "Lower Lighting",
        Flag = "FPSBoostLowerLighting",
        Default = true,
        CallingFunction = function(self, value)
            FPSBoostData.LowerLighting = value
        end
    })

    FPSBoost:MiniToggle({
        Name = "Terrain Effects",
        Flag = "FPSBoostRemoveTerrainEffects",
        Default = true,
        CallingFunction = function(self, value)
            FPSBoostData.RemoveTerrainEffects = value
        end
    })

    FPSBoost:MiniToggle({
        Name = "Auto Clean",
        Flag = "FPSBoostAutoClean",
        Default = true,
        CallingFunction = function(self, value)
            FPSBoostData.AutoClean = value
        end
    })
end)();

(function()
    local TriggerBotData = {
        ClickType = "Left",
        CPS = 20,
        Range = 30,
        DistanceCheck = false
    }

    local TriggerBot
    TriggerBot = Tabs.Combat:CreateModule({
        Name = "Trigger Bot",
        Flag = "TriggerBot",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                local Mouse: Mouse? = LocalPlayer:GetMouse()
                if mouse1press and mouse2press then
                    repeat
                        if Night:IsAlive(LocalPlayer) and Mouse and Mouse.Target and Mouse.Target.Parent and Mouse.Target.Parent:FindFirstChild("Humanoid") and Mouse.Target.Parent.Name ~= LocalPlayer.Name then
                            local TargetRoot: BasePart? = Mouse.Target.Parent:FindFirstChild("HumanoidRootPart")
                            local PlayerRoot: BasePart? = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

                            if TargetRoot and PlayerRoot then
                                local Dist: number = (TargetRoot.Position - PlayerRoot.Position).Magnitude
                                if TriggerBotData.DistanceCheck and Dist <= TriggerBotData.Range or not TriggerBotData.DistanceCheck then
                                    if TriggerBotData.ClickType == "Left" then
                                        mouse1press()
                                    else
                                        mouse2press()
                                    end
                                end
                            end
                        end
                        task.wait(1 / TriggerBotData.CPS)
                    until not self.Enabled
                else
                    Night:CreateNotification({
                        Title = "Trigger Bot",
                        Description = "Your executor doesn't support click functions.",
                        Duration = 10
                    })
                    TriggerBot:SetValue(false, false, false)
                end
            end
        end
    })

    TriggerBot:Dropdown({
        Name = "Click Type",
        Flag = "TriggerBotClickType",
        Default = "Left",
        Options = {"Left", "Right"},
        CallingFunction = function(self, value: string)
            TriggerBotData.ClickType = value
        end
    })

    TriggerBot:Slider({
        Name = "CPS",
        Flag = "TriggerBotCPS",
        Min = 1,
        Max = 50,
        Default = 10,
        Increment = 1,
        CallingFunction = function(self, value: number)
            TriggerBotData.CPS = value
        end
    })

    local TriggerRange
    TriggerBot:MiniToggle({
        Name = "Distance Check",
        Flag = "TriggerBotCheck",
        CallingFunction = function(self, value: boolean)
            TriggerBotData.DistanceCheck = value
            TriggerRange:SetVisiblity(value)
        end
    })

    TriggerRange = TriggerBot:Slider({
        Name = "Range",
        Flag = "TriggerBotRange",
        Min = 1,
        Max = 100,
        Default = 30,
        Increment = 1,
        CallingFunction = function(self, value: number)
            TriggerBotData.Range = value
        end
    })
end)();

(function()
    local Mode: string = "Comet"

    local OldLighting = {
        Ambient = Lighting.Ambient,
        Brightness = Lighting.Brightness,
        EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        GlobalShadows = Lighting.GlobalShadows,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ClockTime = Lighting.ClockTime,
        GeographicLatitude = Lighting.GeographicLatitude,
        ExposureCompensation = Lighting.ExposureCompensation
    }

    local Settings = {
        AmbientColor = Color3.fromRGB(100, 100, 100),
        Brightness = 1.5,
        Time = 14,
        Density = 0.5,
        CCColor = Color3.fromRGB(255, 255, 255),
        CCBrightness = 0.15,
        CCContrast = 0.03,
        CCSaturation = -0.3,
        SkyboxBk = "Skybox Back ID",
        SkyboxDn = "Skybox Down ID",
        SkyboxFt = "Skybox Front ID",
        SkyboxLf = "Skybox Left ID",
        SkyboxRt = "Skybox Right ID",
        SkyboxUp = "Skybox Up ID"
    }

    local GameAtmosphere = Tabs.Render:CreateModule({
        Name = "Atmosphere",
        Flag = "Atmosphere",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                for _, v in next, Lighting:GetChildren() do
                    if v then
                        v:Destroy()
                    end
                end

                local Atmosphere = Instance.new("Atmosphere", Lighting)
                --local Sky = Instance.new("Sky", Lighting)
                local Color = Instance.new("ColorCorrectionEffect", Lighting)

                if Mode == "Winter" then
                    Lighting.Ambient = Color3.fromRGB(110, 110, 110)
                    Lighting.Brightness = 1.8
                    Lighting.EnvironmentDiffuseScale = 0.3
                    Lighting.EnvironmentSpecularScale = 0.1
                    Lighting.GlobalShadows = false
                    Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
                    Lighting.ClockTime = 15
                    Lighting.GeographicLatitude = 40
                    Lighting.ExposureCompensation = 0.65

                    Atmosphere.Density = 0.3
                    Atmosphere.Offset = 0.25
                    Atmosphere.Color = Color3.fromRGB(255, 255, 255)

                    --[[Sky.SkyboxBk = "http://www.roblox.com/asset/?id=8139677359"
                    Sky.SkyboxDn = "http://www.roblox.com/asset/?id=8139677253"
                    Sky.SkyboxFt = "http://www.roblox.com/asset/?id=8139677111"
                    Sky.SkyboxLf = "http://www.roblox.com/asset/?id=8139676988"
                    Sky.SkyboxRt = "http://www.roblox.com/asset/?id=8139676842"
                    Sky.SkyboxUp = "http://www.roblox.com/asset/?id=8139676647"]]
                    --Sky.SunAngularSize = 10

                    Color.Brightness = 0.13
                    Color.Contrast = 0.05
                    Color.Saturation = -0.35
                    Color.TintColor = Color3.fromRGB(105, 75, 170)
                elseif Mode == "Comet" then
                    Lighting.Ambient = Color3.fromRGB(110, 110, 110)
                    Lighting.Brightness = 1.6
                    Lighting.EnvironmentDiffuseScale = 0.4
                    Lighting.EnvironmentSpecularScale = 0.7
                    Lighting.GlobalShadows = false
                    Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
                    Lighting.ClockTime = 14
                    Lighting.GeographicLatitude = 35
                    Lighting.ExposureCompensation = 0.45

                    Atmosphere.Density = 0.35
                    Atmosphere.Offset = 0.3
                    Atmosphere.Color = Color3.fromRGB(255, 255, 255)

                    --[[Sky.SkyboxBk = "http://www.roblox.com/asset/?id=16262356578"
                    Sky.SkyboxDn = "http://www.roblox.com/asset/?id=16262358026"
                    Sky.SkyboxFt = "http://www.roblox.com/asset/?id=16262360469"
                    Sky.SkyboxLf = "http://www.roblox.com/asset/?id=16262362003"
                    Sky.SkyboxRt = "http://www.roblox.com/asset/?id=16262363873"
                    Sky.SkyboxUp = "http://www.roblox.com/asset/?id=16262366016"]]
                    --Sky.SunAngularSize = 20

                    Color.Brightness = 0.18
                    Color.Contrast = 0.03
                    Color.Saturation = -0.25
                    Color.TintColor = Color3.fromRGB(110, 80, 180)
                elseif Mode == "Calm" then
                    Lighting.Ambient = Color3.fromRGB(100, 100, 100)
                    Lighting.Brightness = 1.3
                    Lighting.EnvironmentDiffuseScale = 0.3
                    Lighting.EnvironmentSpecularScale = 0.5
                    Lighting.GlobalShadows = false
                    Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 150)
                    Lighting.ClockTime = 15
                    Lighting.GeographicLatitude = 35
                    Lighting.ExposureCompensation = 0.6

                    Atmosphere.Density = 0.3
                    Atmosphere.Offset = 0.2
                    Atmosphere.Color = Color3.fromRGB(255, 255, 255)

                    --[[Sky.SkyboxBk = "http://www.roblox.com/asset/?id=4495864450"
                    Sky.SkyboxDn = "http://www.roblox.com/asset/?id=4495864887"
                    Sky.SkyboxFt = "http://www.roblox.com/asset/?id=4495865458"
                    Sky.SkyboxLf = "http://www.roblox.com/asset/?id=4495866035"
                    Sky.SkyboxRt = "http://www.roblox.com/asset/?id=4495866584"
                    Sky.SkyboxUp = "http://www.roblox.com/asset/?id=4495867486"]]
                    --Sky.SunAngularSize = 1

                    Color.Brightness = 0.13
                    Color.Contrast = 0.03
                    Color.Saturation = -0.3
                    Color.TintColor = Color3.fromRGB(120, 85, 200)
                elseif Mode == "Ocean" then
                    --loadstring(game:HttpGet("https://raw.githubusercontent.com/null-wtf/NewNight/refs/heads/main/Games/Shaders.luau"))()
                else
                    Lighting.Ambient = Settings.AmbientColor
                    Lighting.Brightness = Settings.Brightness
                    Lighting.ClockTime = Settings.Time

                    --[[Sky.SkyboxBk = "http://www.roblox.com/asset/?id=" .. Settings.SkyboxBk
                    Sky.SkyboxDn = "http://www.roblox.com/asset/?id=" .. Settings.SkyboxDn
                    Sky.SkyboxFt = "http://www.roblox.com/asset/?id=" .. Settings.SkyboxFt
                    Sky.SkyboxLf = "http://www.roblox.com/asset/?id=" .. Settings.SkyboxLf
                    Sky.SkyboxRt = "http://www.roblox.com/asset/?id=" .. Settings.SkyboxRt
                    Sky.SkyboxUp = "http://www.roblox.com/asset/?id=" .. Settings.SkyboxUp]]

                    Atmosphere.Density = Settings.Density
                    Atmosphere.Color = Color3.fromRGB(255, 255, 255)

                    Color.Brightness = Settings.CCBrightness
                    Color.Contrast = Settings.CCContrast
                    Color.Saturation = -Settings.CCSaturation
                    Color.TintColor = Settings.CCColor
                end
            else
                --[[for _, v in next, Lighting:GetChildren() do
                    if v:IsA("Atmosphere") or v:IsA("Sky") or v:IsA("ColorCorrectionEffect") then
                        v:Destroy()
                    end
                end]]

                Lighting.Ambient = OldLighting.Ambient
                Lighting.Brightness = OldLighting.Brightness
                Lighting.EnvironmentDiffuseScale = OldLighting.EnvironmentDiffuseScale
                Lighting.EnvironmentSpecularScale = OldLighting.EnvironmentSpecularScale
                Lighting.GlobalShadows = OldLighting.GlobalShadows
                Lighting.OutdoorAmbient = OldLighting.OutdoorAmbient
                Lighting.ClockTime = OldLighting.ClockTime
                Lighting.GeographicLatitude = OldLighting.GeographicLatitude
                Lighting.ExposureCompensation = OldLighting.ExposureCompensation
            end
        end
    })

    local Custom = {}
    GameAtmosphere:Dropdown({
        Name = "Theme",
        Flag = "AtmosphereTheme",
        Default = "Comet",
        Options = {"Winter", "Comet", "Calm", "Ocean", "Custom"},
        CallingFunction = function(self, value: string)
            Mode = value
            for _, v in next, Custom do
                v:SetVisiblity(value == "Custom")
            end
        end
    })

    table.insert(Custom, GameAtmosphere:ColorSlider({
        Name = "Ambient Color",
        Flag = "AtmosphereAmbient",
        Default = Color3.fromRGB(100, 100, 100),
        CallingFunction = function(self, Color: Color3)
            Settings.AmbientColor = Color
        end
    }))

    table.insert(Custom, GameAtmosphere:Slider({
        Name = "Brightness",
        Flag = "AtmosphereBrightness",
        Min = 0,
        Max = 5,
        Default = 1.5,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            Settings.Brightness = value
        end
    }))

    table.insert(Custom, GameAtmosphere:Slider({
        Name = "Time",
        Flag = "AtmosphereTime",
        Min = 1,
        Max = 24,
        Default = 14,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            Settings.Time = value
        end
    }))

    table.insert(Custom, GameAtmosphere:Slider({
        Name = "ATMSPH Density",
        Flag = "AtmosphereDensity",
        Min = 0,
        Max = 2,
        Default = 0.5,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            Settings.Density = value
        end
    }))

    table.insert(Custom, GameAtmosphere:ColorSlider({
        Name = "CC Color",
        Flag = "AtmosphereCCColor",
        Default = Color3.fromRGB(255, 255, 255),
        CallingFunction = function(self, Color: Color3)
            Settings.CCColor = Color
        end
    }))

    table.insert(Custom, GameAtmosphere:Slider({
        Name = "CC Brightness",
        Flag = "AtmosphereCCBrightness",
        Min = 0,
        Max = 0.5,
        Default = 0.15,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            Settings.CCBrightness = value
        end
    }))

    table.insert(Custom, GameAtmosphere:Slider({
        Name = "CC Contrast",
        Flag = "AtmosphereCCContrast",
        Min = 1,
        Max = 0.1,
        Default = 0.03,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            Settings.CCContrast = value
        end
    }))

    table.insert(Custom, GameAtmosphere:Slider({
        Name = "CC Saturation",
        Flag = "AtmosphereCCSaturation",
        Min = -2,
        Max = 2,
        Default = -0.3,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            Settings.CCSaturation = value
        end
    }))

    table.insert(Custom, GameAtmosphere:TextBox({
        Name = "Skybox Back ID",
        Flag = "AtmosphereSkyboxBk",
        Default = "Skybox Back ID",
        CallingFunction = function(self, value: string)
            Settings.SkyboxBk = value
        end
    }))

    table.insert(Custom, GameAtmosphere:TextBox({
        Name = "Skybox Down ID",
        Flag = "AtmosphereSkyboxDn",
        Default = "Skybox Down ID",
        CallingFunction = function(self, value: string)
            Settings.SkyboxDn = value
        end
    }))

    table.insert(Custom, GameAtmosphere:TextBox({
        Name = "Skybox Front ID",
        Flag = "AtmosphereSkyboxFt",
        Default = "Skybox Front ID",
        CallingFunction = function(self, value: string)
            Settings.SkyboxFt = value
        end
    }))

    table.insert(Custom, GameAtmosphere:TextBox({
        Name = "Skybox Left ID",
        Flag = "AtmosphereSkyboxLf",
        Default = "Skybox Left ID",
        CallingFunction = function(self, value: string)
            Settings.SkyboxLf = value
        end
    }))

    table.insert(Custom, GameAtmosphere:TextBox({
        Name = "Skybox Right ID",
        Flag = "AtmosphereSkyboxRt",
        Default = "Skybox Right ID",
        CallingFunction = function(self, value: string)
            Settings.SkyboxRt = value
        end
    }))

    table.insert(Custom, GameAtmosphere:TextBox({
        Name = "Skybox Up ID",
        Flag = "AtmosphereSkyboxUp",
        Default = "Skybox Up ID",
        CallingFunction = function(self, value: string)
            Settings.SkyboxUp = value
        end
    }))
end)();

(function()
    local Moving: boolean = false
    local Keys: {[Enum.KeyCode]: boolean} = {
        [Enum.KeyCode.W] = false,
        [Enum.KeyCode.A] = false,
        [Enum.KeyCode.S] = false,
        [Enum.KeyCode.D] = false,
        [Enum.KeyCode.Up] = false,
        [Enum.KeyCode.Down] = false,
        [Enum.KeyCode.Left] = false,
        [Enum.KeyCode.Right] = false
    }

    local function StopMoving()
        local Root: BasePart = LocalPlayer.Character.HumanoidRootPart
        local Velo: Vector3 = Root.AssemblyLinearVelocity
        Root.AssemblyLinearVelocity = Vector3.new(0, Velo.Y, 0)
        Root.AssemblyAngularVelocity = Vector3.zero
    end

    Tabs.Movement:CreateModule({
        Name = "Fast Stop",
        Flag = "UniversalFastStop",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                self:Connection(UserInputService.InputBegan:Connect(function(Input: InputObject, Event: boolean)
                    if Event then return end
                    if Keys[Input.KeyCode] ~= nil then
                        Keys[Input.KeyCode] = true
                        Moving = true
                    end
                end))

                self:Connection(UserInputService.InputEnded:Connect(function(Input: InputObject, Event: boolean)
                    if Event then return end
                    if Keys[Input.KeyCode] ~= nil then
                        Keys[Input.KeyCode] = false
                        for _, Pressed in next, Keys do
                            if Pressed then
                                return
                            end
                        end
                        Moving = false
                    end
                end))

                self:Connection(RunService.Heartbeat:Connect(function()
                    if not Moving and Night:IsAlive(LocalPlayer) then
                        StopMoving()
                    end
                end))

                if UserInputService.TouchEnabled or UserInputService.GamepadEnabled then
                    local LastPos: Vector3 = Vector3.zero
                    self:Connection(RunService.Heartbeat:Connect(function()
                        if Night:IsAlive(LocalPlayer) then
                            local MoveDir: Vector3 = LocalPlayer.Character.Humanoid.MoveDirection
                            if MoveDir.Magnitude > 0 then
                                LastPos = MoveDir
                                Moving = true
                            else
                                if Moving and LastPos.Magnitude > 0 then
                                    StopMoving()
                                    Moving = false
                                    LastPos = Vector3.zero
                                end
                            end
                        end
                    end))
                end
            end
        end
    })
end)();

(function()
    local FakeLagData = {
        Randomize = true,
        AnchorTime = 0.5,
        UnanchorTime = 0.35,
        Pause = 1,
        Jitter = 0.15,
        BurstChance = 0.25,
        BurstCountMin = 2,
        BurstCountMax = 5,
        BurstSpeedMin = 0.05,
        BurstSpeedMax = 0.12
    }

    local function Random(a: number, b: number): number
        return a + math.random() * (b - a)
    end

    local FakeLag = Tabs.Movement:CreateModule({
        Name = "Fake Lag",
        Flag = "UniversalFakeLag",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                repeat
                    local Root: BasePart? = Night:IsAlive(LocalPlayer) and LocalPlayer.Character.HumanoidRootPart
                    if Root then
                        if math.random() < FakeLagData.BurstChance then
                            local Count: number = math.random(FakeLagData.BurstCountMin, FakeLagData.BurstCountMax)
                            for _ = 1, Count do
                                Root.Anchored = true
                                task.wait(Random(FakeLagData.BurstSpeedMin, FakeLagData.BurstSpeedMax))
                                Root.Anchored = false
                                task.wait(Random(FakeLagData.BurstSpeedMin, FakeLagData.BurstSpeedMax))
                            end
                        else
                            local Anchor: number = FakeLagData.AnchorTime
                            local Unanchor: number = FakeLagData.UnanchorTime
                            local Pause: number = FakeLagData.Pause

                            if FakeLagData.Randomize then
                                Anchor = math.max(0.05, Anchor + Random(-FakeLagData.Jitter, FakeLagData.Jitter))
                                Unanchor = math.max(0.05, Unanchor + Random(-FakeLagData.Jitter, FakeLagData.Jitter))
                                Pause = math.max(0.05, Pause + Random(-FakeLagData.Jitter, FakeLagData.Jitter))
                            end

                            Root.Anchored = true
                            task.wait(Anchor)
                            Root.Anchored = false
                            task.wait(Unanchor + Pause)
                        end
                    else
                        task.wait(0.25)
                    end
                    
                    task.wait()
                until not self.Enabled
            end
        end
    })

    local Jitter
    FakeLag:MiniToggle({
        Name = "Randomize",
        Flag = "FakeLagRandomize",
        Default = true,
        CallingFunction = function(self, value: boolean)
            FakeLagData.Randomize = value
            Jitter:SetVisiblity(value)
        end
    })

    Jitter = FakeLag:Slider({
        Name = "Jitter",
        Flag = "FakeLagJitter",
        Min = 0,
        Max = 1,
        Default = 0.15,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            FakeLagData.Jitter = value
        end
    })

    FakeLag:Slider({
        Name = "Anchor Time",
        Flag = "FakeLagAnchorTime",
        Min = 0.01,
        Max = 2,
        Default = 0.5,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            FakeLagData.AnchorTime = value
        end
    })

    FakeLag:Slider({
        Name = "Unanchor Time",
        Flag = "FakeLagUnanchorTime",
        Min = 0.01,
        Max = 2,
        Default = 0.35,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            FakeLagData.UnanchorTime = value
        end
    })

    FakeLag:Slider({
        Name = "Pause",
        Flag = "FakeLagPause",
        Min = 0,
        Max = 3,
        Default = 1,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            FakeLagData.Pause = value
        end
    })

    FakeLag:Slider({
        Name = "Burst Chance",
        Flag = "FakeLagBurstChance",
        Min = 0,
        Max = 1,
        Default = 0.25,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            FakeLagData.BurstChance = value
        end
    })

    FakeLag:Slider({
        Name = "Burst Count Min",
        Flag = "FakeLagBurstCountMin",
        Min = 1,
        Max = 10,
        Default = 2,
        CallingFunction = function(self, value: number)
            FakeLagData.BurstCountMin = value
        end
    })

    FakeLag:Slider({
        Name = "Burst Count Max",
        Flag = "FakeLagBurstCountMax",
        Min = 1,
        Max = 10,
        Default = 5,
        CallingFunction = function(self, value: number)
            FakeLagData.BurstCountMax = value
        end
    })

    FakeLag:Slider({
        Name = "Burst Speed Min",
        Flag = "FakeLagBurstSpeedMin",
        Min = 0.01,
        Max = 0.2,
        Default = 0.05,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            FakeLagData.BurstSpeedMin = value
        end
    })

    FakeLag:Slider({
        Name = "Burst Speed Max",
        Flag = "FakeLagBurstSpeedMax",
        Min = 0.01,
        Max = 0.2,
        Default = 0.12,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            FakeLagData.BurstSpeedMax = value
        end
    })
end)();
