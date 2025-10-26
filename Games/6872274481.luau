local Night = getgenv().Night
local Windows = Night.UIData
local Assets = Night.Assets
local OnUnject: BindableEvent = Night.OnUninject

local Players: Players = Night.cloneref(game:GetService("Players"))
local RunService: RunService = Night.cloneref(game:GetService("RunService"))
local ReplicatedStorage: ReplicatedStorage = Night.cloneref(game:GetService("ReplicatedStorage"))
local CollectionService: CollectionService = Night.cloneref(game:GetService("CollectionService"))
local TweenService: TweenService = Night.cloneref(game:GetService("TweenService"))
local UserInputService: UserInputService = Night.cloneref(game:GetService("UserInputService"))
local HttpService: HttpService = Night.cloneref(game:GetService("HttpService"))
local StarterGui: StarterGui = Night.cloneref(game:GetService("StarterGui"))
local Stats: Stats = Night.cloneref(game:GetService("Stats")):FindFirstChild("PerfromanceStats")

local LocalPlayer: Player = Players.LocalPlayer
local PlayerGui: PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CurrentCamera: Camera = workspace.CurrentCamera

local Knit = require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"].knit.src).KnitClient
local Flamework = require(ReplicatedStorage.rbxts_include.node_modules["@flamework"].core.out).Flamework

repeat task.wait() until Knit and Knit.Controllers and debug.getupvalue(Knit.Start, 1)

local BlockEngine = require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].out)
local GameData = {
    Utils = {
        Remotes = require(ReplicatedStorage.TS.remotes).default.Client,
        Network = require(LocalPlayer.PlayerScripts.TS.lib.network),
        DamageTypes = require(ReplicatedStorage.TS.damage["damage-type"]).DamageType,
        ItemMeta = require(ReplicatedStorage.TS.item["item-meta"]).items,
        Store = require(LocalPlayer.PlayerScripts.TS.ui.store).ClientStore,
        InventoryUtil = require(ReplicatedStorage.TS.inventory["inventory-util"]).InventoryUtil,
        ViewmodelController = Knit.Controllers.ViewmodelController,
        MatchStates = require(ReplicatedStorage.TS.match["match-state"]),
        Animation = require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["game-core"].out.shared.util["animation-util"]).AnimationUtil,
        AnimationType = require(ReplicatedStorage.TS.animation["animation-type"]).AnimationType,
        ProdAnimations = require(ReplicatedStorage.TS.animation.definitions["prod-animations"]).ProdAnimations,
        BlockEngine = BlockEngine.BlockEngine,
        BlockRemotes = BlockEngine.BlockEngineRemotes.Client,
        BlockBreaker = Knit.Controllers.BlockBreakController.blockBreaker,
        TeamUtil = require(ReplicatedStorage.TS.util["team-util"]),
        Sprint = Knit.Controllers.SprintController,
        Knockback = require(ReplicatedStorage.TS.damage["knockback-util"]).KnockbackUtil,
        Chest = Knit.Controllers.ChestController,
        App = Flamework.resolveDependency("@easy-games/game-core:client/controllers/app-controller@AppController"),
        Party = Flamework.resolveDependency('@easy-games/lobby:client/controllers/party-controller@PartyController'),
        AppIds = require(LocalPlayer.PlayerScripts.TS.ui.types["app-config"]).BedwarsAppIds,
        Projectile = Knit.Controllers.ProjectileController,
        Sound = require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["game-core"].out).SoundManager,
        ProjMeta = require(ReplicatedStorage.TS.projectile["projectile-meta"]).ProjectileMeta,
        GameQuery = require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["game-core"].out.shared["game-world-query"]["game-query-util"]).GameQueryUtil,
        TeamUpgradesController = Knit.Controllers.TeamUpgradeController,
        TeamUpgradeMeta = debug.getupvalue(require(ReplicatedStorage.TS.games.bedwars["team-upgrade"]["team-upgrade-meta"]).getTeamUpgradeMetaForQueue, 2),
        Shop = require(ReplicatedStorage.TS.games.bedwars.shop["bedwars-shop"]).BedwarsShop.ShopItems,
        BlockPlacer = require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["block-engine"].out.client.placement["block-placer"]).BlockPlacer,
        BlockClient = require(LocalPlayer.PlayerScripts.TS.lib["block-engine"]["client-block-engine"]).ClientBlockEngine,
        QueueController = Knit.Controllers.QueueController
    },
    Events = {
        Damage = Instance.new("BindableEvent"),
        Death = Instance.new("BindableEvent")
    },
    Data = {
        KillAuraTarget = nil
    }
}

local AimParts: {string} = {"HumanoidRootPart", "Head"}
if LocalPlayer.Character then
    for _, v in LocalPlayer.Character:GetChildren() do
        if (v:IsA("Part") or v:IsA("MeshPart")) and not table.find(AimParts, v.Name) then
            table.insert(AimParts, v.name)
        end
    end
end

Assets.Connections:Add(OnUnject.Event:Connect(function()
    for i,v in GameData.Events do
        v:Destroy()
    end

    task.delay(1, table.clear, GameData)
end))

Assets.Connections:Add(GameData.Utils.Network.EntityDamageEventZap.On(function(...)
    local Data = table.pack(...)
    GameData.Events.Damage:Fire({
        Damaged = Data[1],
        DamagedPlayer = Players:GetPlayerFromCharacter(Data[1]),
        Damage = Data[2],
        Type = {Value = GameData.Utils.DamageTypes[Data[3]], Number = Data[3]},
        Damager = Data[5],
        DamagerPlayer = Players:GetPlayerFromCharacter(Data[5])
    })
end))

task.spawn(function()
    Assets.Connections:Add(GameData.Utils.Remotes:Get("EntityDeathEvent"):Connect(function(Data)
        GameData.Events.Death:Fire({
            RespawnTime = Data.respawnDuration,
            Type = {Value = GameData.Utils.DamageTypes[Data.damageType], Number = Data.damageType},
            Final = Data.finalKill,
            Killed = Data.entityInstance,
            KilledPlayer = Players:GetPlayerFromCharacter(Data.entityInstance)
        })
    end))
end)

local BlockList: {Instance} = CollectionService:GetTagged("block")
CollectionService:GetInstanceAddedSignal("block"):Connect(function(inst: Instance) table.insert(BlockList, inst) end)
CollectionService:GetInstanceRemovedSignal("block"):Connect(function(inst: Instance)
    for i, v in next, BlockList do
        if v == inst then
            table.remove(BlockList, i)
            break
        end
    end
end)

local function GetInventory(Player: Player?)
    Player = Player or LocalPlayer
    return GameData.Utils.InventoryUtil.getInventory(Player)
end

local function GetSword(): {AttackSpeed: number, Damage: number, Item: Instance?, Meta: {itemType: string}}
    local Inventory = GetInventory()
    local Sword = {
        Item = nil,
        Damage = 0,
        AttackSpeed = 0,
        InvData = nil
    }

    if Inventory then
        local Items = Inventory.items
        if Items then
            for i,v in Items do
                local ItemMeta = GameData.Utils.ItemMeta[v.itemType]
                if ItemMeta then
                    local SwordData = ItemMeta.sword
                    if SwordData then
                        local Value: number = (SwordData.damage / SwordData.attackSpeed)
                        local CurValue: number = (Sword.Damage / Sword.AttackSpeed)
                        if CurValue ~= CurValue then
                            CurValue = 0
                        end

                        if Value > CurValue then
                            Sword = {
                                Item = v.tool,
                                Damage = SwordData.damage,
                                AttackSpeed = SwordData.attackSpeed,
                                InvData = v,
                                Meta = ItemMeta
                            }
                        end
                    end
                end
            end
        end
    end

    return Sword
end

local function GetItemFromShop(ItemType: string)
    for i,v in GameData.Utils.Shop do
        if v.itemType == ItemType then
            return v
        end
    end

    return
end

local function GetNextSword()
    local CurrentSword = GetSword()
    if CurrentSword.Item then
        local CurrentSwordType = CurrentSword.InvData.itemType
        local Shopitem = GetItemFromShop(CurrentSwordType)
        if Shopitem and Shopitem.superiorItems and #Shopitem.superiorItems > 0 then
            return GetItemFromShop(Shopitem.superiorItems[1]), Shopitem, Shopitem.superiorItems[1]
        end
    end

    return
end

local function GetCurrentArmor(): string
    for i,v in GetInventory().armor do 
        if typeof(v) == "table" then
            local Type: string = v.itemType
            if Type:find("_") then
                return Type:split("_")[1].."_chestplate", v
            end
        end
    end

    for i,v in GetInventory().items do
        if v.itemType:find("chestplate") then
            return v.itemType, v
        end
    end

    return
end

local function GetNextArmor()
    local CurrentArmor = GetCurrentArmor()
    if CurrentArmor then
        local Shopitem = GetItemFromShop(CurrentArmor)
        if Shopitem and Shopitem.nextTier and CurrentArmor ~= Shopitem.nextTier then
            return GetItemFromShop(Shopitem.nextTier), Shopitem, Shopitem.nextTier
        end
    end

    return GetItemFromShop("leather_chestplate"), nil, "leather_chestplate"
end

local function GetItem(Name: string)
    for i, v in GetInventory().items do
		if v.itemType == Name then
			return v
		end
	end

	return
end

local function GetUpgradeFromName(Name: string)
    for i,v in GameData.Utils.TeamUpgradeMeta do
        if v.name == Name then
            return i, v
        end
    end

    return
end

local function GetBestItemToBreakBlock(Type: string)
    local Inventory = GetInventory()
    local Data = {
        Item = nil,
        Damage = 0
    }

    if Inventory and Inventory.items then
        for i,v in Inventory.items do
            local Meta = GameData.Utils.ItemMeta[v.itemType]
            if Meta and Meta.breakBlock then
                for i2: string, v2: number in Meta.breakBlock do
                    if Type:lower():find(i2:lower()) and v2 > Data.Damage then
                        Data = {
                            Item = v.tool,
                            Damage = v2
                        }
                    end
                end

            end
        end
    end

    return Data
end

local function GetBlocks()
    local Inventory = GetInventory()
    local Data = {
        Block = nil,
        Health = math.huge,
        Amount = 0,
        Type = nil
    }

    if Inventory and Inventory.items then
        for i,v in Inventory.items do
            local Meta = GameData.Utils.ItemMeta[v.itemType]
            if Meta and Meta.block then
                local Health: number = Meta.block.health
                if Data.Health > Health or Meta.block.breakType == "wool" then
                    Data = {
                        Block = v.tool,
                        Health = Health,
                        Amount = v.amount,
                        Type = v.itemType
                    }

                    if Meta.block.breakType == "wool" then
                        return Data
                    end
                end
            end
        end
    end

    return Data
end

local function SwitchItem(Item: Instance, SwitchBack: boolean)
    local SetInvItem = GameData.Utils.Remotes:Get("SetInvItem")
    local Inventory = GetInventory()
    local CurrentItem = nil
    if Inventory and Inventory.hand then
        CurrentItem = Inventory.hand.tool
        if CurrentItem == Item then
            return
        end
    end

    local Completed: boolean = false
    SetInvItem:CallServerAsync({
        hand = Item
    }):andThen(function(suc: boolean)
        if CurrentItem and suc then
            Completed = true
        end
    end)

    repeat task.wait() until Completed
end

local function GetEntities(): {{Entity: Model, Player: Player?, Health: number, MaxHealth: number, Humanoid: Humanoid, Root: BasePart, Type: string}}
    local Entities = {}
    for i,v in CollectionService:GetTagged("entity") do
        local Humanoid: Humanoid = v:FindFirstChild("Humanoid")
        table.insert(Entities, {
            Entity = v,
            Player = Players:GetPlayerFromCharacter(v),
            Health = v:GetAttribute("Health") or Humanoid and Humanoid.Health,
            MaxHealth = v:GetAttribute("MaxHealth") or Humanoid and Humanoid.MaxHealth,
            Humanoid = Humanoid,
            Root = v.PrimaryPart,
            Type = CollectionService:GetTags(v)[3]
        })
    end

    return Entities
end

local function GetNearestEntity(TeamCheck: boolean): { Data: {Entity: Model, Player: Player?, Health: number, MaxHealth: number, Humanoid: Humanoid, Root: BasePart, Type: string}, Distance: number, Entity: Model? }
    local Entities = GetEntities()
    local Entity = {
        Entity = nil,
        Distance = math.huge,
        Data = {}
    }

    for i,v in Entities do
        if Night:IsAlive(LocalPlayer) and (TeamCheck and v.Entity:GetAttribute("Team") ~= LocalPlayer.Character:GetAttribute("Team") or not TeamCheck) then
            if Night:IsAlive(v.Entity, true) then
                local Distance: number = Night:GetDistanceFrom(LocalPlayer.Character.PrimaryPart.Position, v.Root.Position)
                if Entity.Distance >= Distance then
                    Entity = {
                        Entity = v.Entity,
                        Distance = Distance,
                        Data = v
                    }
                end
            end
        end
    end

    return Entity
end

local function GetNearestTeamUpgradeShop()
    local Data = {
        Shop = nil,
        Distance = math.huge
    }

    for i,v: Part in CollectionService:GetTagged("TeamUpgradeShopkeeper") do
        local Id: string = v:GetAttribute("Id")
        if Id and Night:IsAlive(LocalPlayer) then
            local Distance: number = Night:GetDistanceFrom(LocalPlayer.Character.PrimaryPart.Position, v.Position)
            if Data.Distance > Distance then
                Data = {
                    Shop = v,
                    Distance = Distance,
                    Id = Id
                }
            end
        end
    end

    return Data
end

local function GetNearestItemShop()
    local Data = {
        Shop = nil,
        Distance = math.huge
    }

    for i,v: Part in CollectionService:GetTagged("BedwarsItemShop") do
        local Id: string = v:GetAttribute("Id")
        if Id and Night:IsAlive(LocalPlayer) then
            local Distance: number = Night:GetDistanceFrom(LocalPlayer.Character.PrimaryPart.Position, v.Position)
            if Data.Distance > Distance then
                Data = {
                    Shop = v,
                    Distance = Distance,
                    Id = Id
                }
            end
        end
    end

    return Data
end

local function GetNearestItemDrop(Ignore: {Part})
    local Data = {
        Item = nil,
        Distance = math.huge
    }

    for i,v: Part in CollectionService:GetTagged("ItemDrop") do
        if Night:IsAlive(LocalPlayer) and not table.find(Ignore, v) then
            local Distance: number = Night:GetDistanceFrom(LocalPlayer.Character.PrimaryPart.Position, v.Position)
            if Data.Distance > Distance then
                Data = {
                    Item = v,
                    Distance = Distance
                }
            end
        end
    end

    return Data
end

local function IsPathClear(target, TargetPart: Part?, Param: RaycastParams): boolean
    local Start: Vector3 = CurrentCamera.CFrame.Position + CurrentCamera.CFrame.LookVector * 1
    if TargetPart then
        local Direction: Vector3 = (TargetPart.Position - Start)
        local Distance: number = Direction.Magnitude
        Direction = Direction.Unit * math.min(Distance, 1000)
        local Ray: RaycastResult = workspace:Raycast(Start, Direction, Param)
        
        if not Ray or (Ray.Instance and (Ray.Instance:IsDescendantOf(target) or GameData.Utils.GameQuery:isQueryIgnored(Ray.Instance))) then
            return true
        end
    end

    return false
end

local function GetAngle(CFrame: CFrame, TargetPos: Vector3)
    local LookVector: Vector3 = CFrame.LookVector * Vector3.new(1, 0, 1)
    local Position: Vector3 = CFrame.Position

    local ScaledVector: Vector3 = (TargetPos - Position) * Vector3.new(1, 0, 1)
    return math.acos(math.clamp(LookVector:Dot(ScaledVector.Unit), -1, 1))
end

local function GetViewModel(): Model?
    return GameData.Utils.ViewmodelController:getViewModel()
end

local function GetSpeedMultiplier(): number
    local Multiplier: number = 0
    for i,v in GameData.Utils.Sprint:getMovementStatusModifier().modifiers do
        if typeof(i) == "table" and i.moveSpeedMultiplier and v then
            Multiplier += i.moveSpeedMultiplier            
        end
    end
    return Multiplier
end

local function MakeClone(): { Clone: BasePart, Destroy: () -> (), PrimaryPart: BasePart }
    if Night:IsAlive(LocalPlayer) then
        local PrimaryPart: BasePart = LocalPlayer.Character.PrimaryPart

        local Clone = PrimaryPart:Clone()
        Clone.CanCollide = false
        Clone.CFrame = PrimaryPart.CFrame
        Clone.Parent = LocalPlayer.Character

        LocalPlayer.Character.PrimaryPart = Clone
        for i, v in LocalPlayer.Character:GetDescendants() do
            if v:IsA('Weld') or v:IsA('Motor6D') then
                if v.Part0 == PrimaryPart then 
                    v.Part0 = Clone 
                end

                if v.Part1 == PrimaryPart then 
                    v.Part1 = Clone 
                end
            end
        end

        return {
            Clone = Clone,
            PrimaryPart = PrimaryPart,
            Destroy = function()
                LocalPlayer.Character.PrimaryPart = PrimaryPart
                for i, v in LocalPlayer.Character:GetDescendants() do
                    if v:IsA('Weld') or v:IsA('Motor6D') then
                        if v.Part0 == Clone then 
                            v.Part0 = PrimaryPart 
                        end

                        if v.Part1 == Clone then 
                            v.Part1 = PrimaryPart 
                        end
                    end
                end

                Clone:Destroy()
            end
        }
    end

    return false
end

local function GetBlocksAroundPoint(StartPos: Vector3, Exclude: {})
    local Store = GameData.Utils.BlockEngine:getStore()
    local Blocks = {}
    for i,v in Enum.NormalId:GetEnumItems() do
        if v == Enum.NormalId.Bottom then
            continue
        end

        Blocks[v.Name] = {}
        for i2 = 0, 100 do
            local OrginalPosition = StartPos + (Vector3.fromNormalId(v) * i2)
            local Position = GameData.Utils.BlockEngine:getBlockPosition(OrginalPosition)
            local Position2 = GameData.Utils.BlockEngine:getBlockPosition(OrginalPosition + Vector3.new(0, 3, 0))

            local Block = Store:getBlockAt(Position)
            local Block2 = Store:getBlockAt(Position2)
            local BlockExists: boolean = false
            for i,v in Blocks do
                if v.Block == Block then
                    BlockExists = true
                end
            end

            if Block then
                if not BlockExists and (Exclude and not table.find(Exclude, Block) or not Exclude) then
                    table.insert(Blocks[v.Name], {
                        Block = Block,
                        OrginalPosition = OrginalPosition,
                        BlockPosition = Position,
                        HitNormal = v
                    })

                    if not Block2 then
                        break
                    end
                end
            else
                break
            end
        end
    end

    return Blocks
end

local function FindWeakestSide(Bed: Part)
    local BlocksA, BlocksB = GetBlocksAroundPoint(Bed.Position, {}), GetBlocksAroundPoint(Bed.Position + Vector3.new(0, 0, 3), {})
    local BlockASides, BlockBSides = {}, {}
    local Health, Side, ActualSide = math.huge, {}, {}

    for i, v in BlocksA do
        BlockASides[i] = 0
        for i2, v2 in v do
            if not v2.Block:GetAttribute("NoBreak") and not v2.Block:GetAttribute("Team"..tostring(GameData.Utils.TeamUtil.getPlayerTeamId(LocalPlayer).."NoBreak")) and v2.Block ~= Bed then
                local BlockData = GameData.Utils.BlockEngine:getStore():getBlockData(v2.BlockPosition)
                local BlockHealth = BlockData and BlockData:GetAttribute(GameData.Utils.BlockEngine:getDefaultHealthKey())
                if not BlockData or not BlockHealth then
                    BlockHealth = v2.Block:GetAttribute("Health")
                end

                BlockASides[i] += BlockHealth
            end
        end
    end

    for i, v in BlocksB do
        BlockBSides[i] = 0
        for i2, v2 in v do
            if not v2.Block:GetAttribute("NoBreak") and not v2.Block:GetAttribute("Team"..tostring(GameData.Utils.TeamUtil.getPlayerTeamId(LocalPlayer).."NoBreak")) and v2.Block ~= Bed then
                local BlockData = GameData.Utils.BlockEngine:getStore():getBlockData(v2.BlockPosition)
                local BlockHealth = BlockData and BlockData:GetAttribute(GameData.Utils.BlockEngine:getDefaultHealthKey())
                if not BlockData or not BlockHealth then
                    BlockHealth = v2.Block:GetAttribute("Health")
                end

                BlockBSides[i] += BlockHealth
            end
        end
    end

    for i,v in BlockASides do
        if Health > v then
            Health, Side, ActualSide = v, BlocksA, BlocksA[i]
        end
    end

    for i,v in BlockBSides do
        if Health > v then
            Health, Side, ActualSide = v, BlocksB, BlocksB[i]
        end
    end

    return ActualSide, Side, Health
end

local function GetNearestBed(): { Bed: Part, Distance: any }
    local PlayerTeamId: number = GameData.Utils.TeamUtil.getPlayerTeamId(LocalPlayer)
    local Data = {
        Bed = nil,
        Distance = math.huge
    }

    for i,v: Part in CollectionService:GetTagged("bed") do
        local TeamId = v:GetAttribute("TeamId")
        if (TeamId and TeamId ~= PlayerTeamId or not TeamId) and not v:GetAttribute("Team"..tostring(PlayerTeamId).."NoBreak") and Night:IsAlive(LocalPlayer) then
            local Distance = Night:GetDistanceFrom(LocalPlayer.Character.PrimaryPart.Position, v.Position)
            if Data.Distance > Distance then
                Data = {
                    Bed = v,
                    Distance = Distance
                }
            end
        end
    end

    return Data
end

local function GetNearestChest(Ignore: {Instance})
    local Data = {
        Chest = nil,
        Distance = math.huge
    }

    for i,v in CollectionService:GetTagged("chest") do
        if not table.find(Ignore, v) and v:FindFirstChild("ChestFolderValue") and v.ChestFolderValue.Value and Night:IsAlive(LocalPlayer) then
            local Distance = Night:GetDistanceFrom(LocalPlayer.Character.PrimaryPart.Position, v.Position)
            if Data.Distance > Distance then
                Data = {
                    Chest = v,
                    Distance = Distance,
                    ChestFolder = v.ChestFolderValue.Value
                }
            end
        end
    end

    return Data
end

local function DamageBlock(Block: Instance, Hit: Enum.NormalId)
    local Position: Vector3 = GameData.Utils.BlockEngine:getBlockPosition(Block.Position)
    if Position then
        local Result, Response: string = GameData.Utils.BlockRemotes:Get("DamageBlock"):CallServerAsync({
            blockRef = {blockPosition = Position},
            hitPosition = Position,
            hitNormal = Vector3.fromNormalId(Hit)
        }):awaitStatus()

        if Response == "damaged" then
            local BlockData = GameData.Utils.BlockEngine:getStore():getBlockData(Block.Position)
            local BlockHealth: number = BlockData and BlockData:GetAttribute(GameData.Utils.BlockEngine:getDefaultHealthKey())
            if not BlockData or not BlockHealth and Block then
                BlockHealth = Block:GetAttribute("Health")
            end

            if BlockHealth then
                local MaxHealth: number = Block:GetAttribute("MaxHealth")
                if MaxHealth then
                    GameData.Utils.BlockBreaker:updateHealthbar({blockPosition = Position}, BlockHealth, MaxHealth, 2, Block)
                end
            end
        end

        return Response, Result
    end
    return
end

Windows.Movement.Modules.UniversalSpeed:Destroy()
Windows.Movement.Modules.UniversalFly:Destroy()
Windows.Combat.Modules.UniversalAimbot:Destroy()
Windows.Movement.Modules.UniversalMouseTP:Destroy()
Windows.Render.Modules.TargetHUD:Destroy()
Windows.Movement.Modules.UniversalWallClimb:Destroy()
Windows.Utility.Modules.UniversalAntiAFK:Destroy()
Windows.Movement.Modules.UniversalNoClip:Destroy();

(function()
    local SpeedData = {
        Settings = {
            Speed = 50,
            PulseDelay = 0,
            PulseTime = 2,
            Mode = "Velocity",
            AutoJump = false,
            Pulse = false,
            UseBoost = false
        },
        Data = {
            LastGroundTouch = os.clock()
        }
    }

    local Speed = Windows.Movement:CreateModule({
        Name = "Speed",
        Flag = "Speed",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                repeat
                    local Fly = Windows.Movement.Modules.Fly
                    if Night:IsAlive(LocalPlayer) and (Fly and not Fly.Enabled or not Fly) and isnetworkowner(LocalPlayer.Character.PrimaryPart) then
                        local Root: BasePart = LocalPlayer.Character.PrimaryPart
                        local Humanoid: Humanoid = LocalPlayer.Character.Humanoid

                        if Humanoid.MoveDirection.Magnitude > 0 then
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
                            for i = 1, IndexVal do
                                if not self.Enabled then
                                    break
                                end

                                local CurrentVelocity: Vector3 = Root.AssemblyLinearVelocity
                                if SpeedData.Settings.UseBoost then
                                    local Multiplier: number = GetSpeedMultiplier()
                                    if Multiplier ~= 0 then
                                        Speed = math.clamp(Speed * Multiplier, -1000, 46)
                                    end 
                                end
                                
                                Root.AssemblyLinearVelocity = Vector3.new(Humanoid.MoveDirection.X * Speed, CurrentVelocity.Y, Humanoid.MoveDirection.Z * Speed) 
                                if SpeedData.Settings.Pulse then
                                    task.wait(0.01)
                                end
                            end

                            if SpeedData.Settings.Pulse then
                                task.wait(SpeedData.Settings.PulseDelay)
                            end
                        end
                    end
                    task.wait()
                until not self.Enabled
            end
        end
    })

    Speed:Slider({
        Name = "Speed",
        Flag = "SpeedValue",
        Default = 23,
        Min = 0,
        Max = 23,
        CallingFunction = function(self, value: number)
            SpeedData.Settings.Speed = value
        end
    })

    local PulseDelay = Speed:Slider({
        Name = "Pulse Delay",
        Flag = "SpeedPulseDelay",
        Default = 1.5,
        Min = 1,
        Max = 5,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            SpeedData.Settings.PulseDelay = value
        end
    })

    local PulseTime = Speed:Slider({
        Name = "Pulse Time",
        Flag = "SpeedPulseTime",
        Default = 1,
        Min = 0.5,
        Max = 2.5,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            SpeedData.Settings.PulseTime = value
        end
    })

    local JumpDelay = Speed:Slider({
        Name = "Jump Delay",
        Flag = "SpeedAutoJumpDelay",
        Default = 0,
        Min = 0,
        Max = 5,
        CallingFunction = function(self, value: number)
            SpeedData.Settings.JumpDelay = value
        end
    })

    Speed:MiniToggle({
        Name = "Consumable Boost",
        Flag = "SpeedConsumableBoost",
        Default = true,
        CallingFunction = function(self, value: boolean)
            SpeedData.Settings.UseBoost = value
        end
    })
    
    Speed:MiniToggle({
        Name = "Auto Jump",
        Flag = "SpeedAutoJump",
        CallingFunction = function(self, value: boolean)
            SpeedData.Settings.AutoJump = value
            JumpDelay:SetVisiblity(value)
        end
    })

    Speed:MiniToggle({
        Name = "Pulse",
        Flag = "PusleSpeed",
        CallingFunction = function(self, value: boolean)
            SpeedData.Settings.Pulse = value

            PulseDelay:SetVisiblity(value)
            PulseTime:SetVisiblity(value)
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
            Pulse = false,
            TpDown = false,
            UseBoost = false
        },
        Data = {
            Vertical = 0,
            LastBoosted = os.clock(),
            LastOnGround = os.clock(),
            Params = RaycastParams.new()
        }
    }

    FlyData.Data.Params.FilterType = Enum.RaycastFilterType.Include
    FlyData.Data.Params.FilterDescendantsInstances = BlockList

    local Fly = Windows.Movement:CreateModule({
        Name = "Fly",
        Flag = "Fly",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                if Night.Mobile then
                    local TouchGui = PlayerGui:FindFirstChild("TouchGui")
                    local TouchControl = TouchGui and TouchGui:FindFirstChild("TouchControlFrame")
                    local JumpButton = TouchControl and TouchControl:FindFirstChild("JumpButton")
                    if JumpButton then
                        self:Connection(JumpButton:GetPropertyChangedSignal("ImageRectOffset"):Connect(function()
                            FlyData.Settings.VerticalValue = JumpButton.ImageRectOffset.X == 146 and 1 or 0
                        end))
                    end
                end

                FlyData.Data.LastOnGround = os.clock()
                repeat
                    if Night:IsAlive(LocalPlayer) and isnetworkowner(LocalPlayer.Character.PrimaryPart) then
                        local Root: BasePart = LocalPlayer.Character.PrimaryPart
                        local Humanoid: Humanoid = LocalPlayer.Character.Humanoid

                        if Humanoid.FloorMaterial ~= Enum.Material.Air then
                            FlyData.Data.LastOnGround = os.clock()
                        end

                        local IndexVal: number = 1
                        if FlyData.Settings.Pulse then
                            IndexVal = (FlyData.Settings.PulseTime * 60)
                            if 0 >= IndexVal then
                                IndexVal = 1
                            end
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
                                if FlyData.Settings.UseBoost then
                                    local Multiplier: number = GetSpeedMultiplier()
                                    if Multiplier ~= 0 then
                                        Speed = math.clamp(Speed * Multiplier, -1000, 46)
                                    end 
                                end

                                SpeedVelocity = Vector3.new(Humanoid.MoveDirection.X * Speed, 0, Humanoid.MoveDirection.Z * Speed) 
                            end

                            if Humanoid.MoveDirection.Magnitude <= 0 then
                                SpeedVelocity = Vector3.zero
                            end

                            Root.AssemblyLinearVelocity = Vector3.new(
                                SpeedVelocity.X,
                                YValue + (CurrentVelocity.Y > 0 and 1 or -CurrentVelocity.Y),
                                SpeedVelocity.Z
                            )

                            if (os.clock() - FlyData.Data.LastOnGround) >= 1.9 and FlyData.Settings.TpDown then
                                local Ray: RaycastResult = workspace:Raycast(Root.Position, Vector3.new(0, -1000, 0), FlyData.Data.Params)
                                if Ray then
                                    local OldCFrame: CFrame = Root.CFrame
                                    Root.CFrame = CFrame.new(Ray.Position + Vector3.new(0,2,0))
                                    task.delay(0.1, function()
                                        Root.CFrame = OldCFrame
                                    end)
                                end
                            end

                            if FlyData.Settings.Pulse and (os.clock() - FlyData.Data.LastBoosted) >= FlyData.Settings.PulseDelay then
                                task.wait(0.01)
                            end
                        end

                        if (os.clock() - FlyData.Data.LastBoosted) >= FlyData.Settings.PulseDelay then
                            FlyData.Data.LastBoosted = os.clock()
                        end
                    end
                    task.wait()
                until not self.Enabled
            end
        end
    })

    Fly.Functions:KeyBind({
        Name = "Fly Up",
        MobileText = "Fly Up",
        Flag = "FlyUpKeybind",
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
        Flag = "FlyDownKeybind",
        DestroyMobileButtonOnDisable = true,
        Default = Enum.KeyCode.LeftShift,
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
        Flag = "FlySpeed",
        Default = 23,
        Min = 0,
        Max = 23,
        CallingFunction = function(self, value: number)
            FlyData.Settings.Speed = value
        end
    })

    Fly:Slider({
        Name = "Vertical Speed",
        Flag = "FlyVerticalSpeed",
        Default = 70,
        Min = 0,
        Max = 130,
        CallingFunction = function(self, value: number)
            FlyData.Settings.VerticalSpeed = value
        end
    })

    local FlyPulseDelay = Fly:Slider({
        Name = "Pulse Delay",
        Flag = "FlySpeedPulseDelay",
        Default = 1.5,
        Min = 1,
        Max = 5,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            FlyData.Settings.PulseDelay = value
        end
    })

    local FlyPulseTime = Fly:Slider({
        Name = "Pulse Time",
        Flag = "FlySpeedPulseTime",
        Default = 1,
        Min = 0.5,
        Max = 2.5,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            FlyData.Settings.PulseTime = value
        end
    })

    Fly:MiniToggle({
        Name = "TP Down",
        Flag = "FlyTPDown",
        Default = true,
        CallingFunction = function(self, value: boolean)
            FlyData.Settings.TpDown = value
        end
    })

    Fly:MiniToggle({
        Name = "Consumable Boost",
        Flag = "FlyConsumableBoost",
        Default = true,
        CallingFunction = function(self, value: boolean)
            FlyData.Settings.UseBoost = value
        end
    })

    Fly:MiniToggle({
        Name = "Pulse",
        Flag = "FlySpeedPulse",
        CallingFunction = function(self, value: boolean)
            FlyData.Settings.Pulse = value

            FlyPulseDelay:SetVisiblity(value)
            FlyPulseTime:SetVisiblity(value)
        end
    })
end)();

(function()
    local KillAuraData = {
        Settings = {
            Range = 20,
            Delay = 0,
            AnimationRestoreTime = 0.1,
            MaxAngle = 360,
            AutoSwitch = false,
            NoSwing = false,
            HandCheck = false,
            WallCheck = false,
            UseAnimation = false,
            Cooldown = false,
            TriggerButton = false,
            Boxes = false,
            Particles = false,
            InfRange = false,
            SelectedAnimation = "Night",
            BoxColor = Color3.fromRGB(255, 0, 0),
            ParticleColor = Color3.fromRGB(255, 0, 0),
            BoxTransparency = 0.5,
            ParticleRate = 40,
            ParticleLifeTime = 2
        },
        Data = {
            OldPlayAnimationViewModel = nil,
            AnimationPlaying = false,
            PlayerDamaged = false,
            OriginalHandPos = nil,
            TimesRanOnCooldown = 0,
            TriggerHeld = false,
            Params = RaycastParams.new(),
            LastHit = 0,
            Effects = {
                Boxes = {},
                Particles = {}
            }
        },
        Animations = {
            Night = {
                {Position = CFrame.new(0.7, -0.7, 0.65), Angle = CFrame.Angles(math.rad(-70), math.rad(60), math.rad(-70)), Duration = 0.15},
                {Position = CFrame.new(0.5, -0.7, -0.3), Angle = CFrame.Angles(math.rad(-120), math.rad(70), math.rad(-50)), Duration = 0.15}
            },
            Smooth = {
                {Position = CFrame.new(-0.01, -0.3, -1.01), Angle = CFrame.Angles(math.rad(-35), math.rad(90), math.rad(-90)), Duration = 0.45},
                {Position = CFrame.new(-0.01, -0.3, -1.01), Angle = CFrame.Angles(math.rad(-35), math.rad(70), math.rad(-90)), Duration = 0.45},
                {Position = CFrame.new(-0.01, -0.3, 0.4), Angle = CFrame.Angles(math.rad(-35), math.rad(70), math.rad(-90)), Duration = 0.32},
            },
            Funny = {
                {Position = CFrame.new(0.8, 10.7, 3.6), Angle = CFrame.Angles(math.rad(-16), math.rad(60), math.rad(-80)), Duration = 0.1},
                {Position = CFrame.new(5.7, -1.7, 5.6), Angle = CFrame.Angles(math.rad(-16), math.rad(60), math.rad(-80)), Duration = 0.15},
                {Position = CFrame.new(2.95, -5.06, -6.25), Angle = CFrame.Angles(math.rad(-180), math.rad(60), math.rad(-80)), Duration = 0.15},
            },
            Stand = {
                {Position = CFrame.new(0.7, -0.7, 0.6), Angle = CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Duration = 0.1}
            },
            Air = {
                {Position = CFrame.new(1.2, -1.5, -1), Angle = CFrame.Angles(math.rad(305), math.rad(55), math.rad(140)), Duration = 0.2},
                {Position = CFrame.new(1.2, -1.5, -1.2), Angle = CFrame.Angles(math.rad(200), math.rad(55), math.rad(230)), Duration = 0.15},
            },
            Hit = {
                {Position = CFrame.new(0, 0, -0.7), Angle = CFrame.Angles(math.rad(-60), math.rad(50), math.rad(-60)), Duration = 0.12},
                {Position = CFrame.new(0, -0.35, -0.7), Angle = CFrame.Angles(math.rad(-150), math.rad(60), math.rad(15)), Duration = 0.2},
            },
            Rise = {
                {Position = CFrame.new(1, 0, 0), Angle = CFrame.Angles(math.rad(-40), math.rad(40), math.rad(-80)), Duration = 0.15},
                {Position = CFrame.new(1, 0, -0.4), Angle = CFrame.Angles(math.rad(-80), math.rad(40), math.rad(-70)), Duration = 0.17},
            },
            Moon = {
                {Position = CFrame.new(0.85, -0.8, 0.6), Angle = CFrame.Angles(math.rad(-40), math.rad(70), math.rad(-90)), Duration = 0.15},
                {Position = CFrame.new(0.5, -0.6, 0.6), Angle = CFrame.Angles(math.rad(-50), math.rad(50), math.rad(-100)), Duration = 0.12},
            },
            Lunar = {
                {Position = CFrame.new(0.3, 0, -1.5), Angle = CFrame.Angles(math.rad(120), math.rad(120), math.rad(140)), Duration = 0.2},
                {Position = CFrame.new(0, -0.3, -1.7), Angle = CFrame.Angles(math.rad(30), math.rad(120), math.rad(190)), Duration = 0.2},
            }
        }
    }

    local function CalcPrediction(Player: Vector3, Target: Vector3, Range: number): Vector3
        local Dir: Vector3 = Target - Player
        local Dist: number = Dir.Magnitude

        if Dist <= 11.5 or Range <= 11.5 then
            return Player
        end

        return Player + Dir.Unit * (Dist - 14)
    end

    local KillAura = Windows.Combat:CreateModule({
        Name = "Kill Aura",
        Flag = "KillAura",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                coroutine.wrap(function()
                    repeat task.wait() until GameData.Utils.ViewmodelController and GameData.Utils.ViewmodelController.playAnimation
                    task.delay(0.1, function()
                        if not KillAuraData.Data.OldPlayAnimationViewModel then
                            KillAuraData.Data.OldPlayAnimationViewModel = GameData.Utils.ViewmodelController.playAnimation
                        end
                        
                        GameData.Utils.ViewmodelController.playAnimation = function(self, animation: number, ...)
                            if KillAuraData.Data.AnimationPlaying then
                                local Animation: string = GameData.Utils.AnimationType[animation]
                                if Animation and typeof(Animation) == "string" then
                                    if Animation:lower():find("swing_sword") then
                                        return
                                    end
                                end
                            end

                            return KillAuraData.Data.OldPlayAnimationViewModel(self, animation, ...)
                        end
                    end)
                end)()

                self:Connection(GameData.Events.Damage.Event:Connect(function(Data)
                    if GameData.Data.KillAuraTarget and Data.Damaged == GameData.Data.KillAuraTarget then
                        KillAuraData.Data.PlayerDamaged = true
                        task.delay(0.02, function()
                            KillAuraData.Data.PlayerDamaged = false
                        end)
                    end
                end))

                self:Connection(RunService.PreRender:Connect(function()
                    if KillAuraData.Settings.Delay > (os.clock() - KillAuraData.Data.LastHit) then
                        return
                    end

                    local Sword = GetSword()
                    if Sword.Item and GameData.Utils.Store:getState().Game.matchstate == GameData.Utils.MatchStates.RUNNING and Night:IsAlive(LocalPlayer) then                        
                        if KillAuraData.Settings.TriggerButton and not KillAuraData.Data.TriggerHeld then
                            task.wait()
                            return
                        end

                        local NearestEntity = GetNearestEntity(true)
                        if NearestEntity.Entity and (KillAuraData.Settings.Range >= NearestEntity.Distance or KillAuraData.Settings.InfRange) and Night:IsAlive(NearestEntity.Entity, true) then
                            if KillAuraData.Settings.WallCheck then
                                KillAuraData.Data.Params.FilterType = Enum.RaycastFilterType.Exclude
                                KillAuraData.Data.Params.FilterDescendantsInstances = CollectionService:GetTagged("entity")

                                if not IsPathClear(NearestEntity.Entity, NearestEntity.Entity.PrimaryPart, KillAuraData.Data.Params) then
                                    task.wait()
                                    return
                                end
                            end

                            if GetAngle(LocalPlayer.Character.PrimaryPart.CFrame, NearestEntity.Entity.PrimaryPart.Position) > (KillAuraData.Settings.MaxAngle / 2 * math.pi / 180) then
                                task.wait()
                                return
                            end 

                            local HandItem = GetInventory().hand
                            if KillAuraData.Settings.HandCheck then
                                if HandItem and HandItem.tool then
                                    local Meta = GameData.Utils.ItemMeta[HandItem.itemType]
                                    if not Meta or not Meta.sword then
                                        task.wait()
                                        return
                                    end
                                else
                                    task.wait()
                                    return
                                end
                            end

                            GameData.Data.KillAuraTarget = NearestEntity
                            if KillAuraData.Settings.AutoSwitch and (not HandItem or HandItem and (not HandItem.tool or HandItem.tool ~= Sword.Item)) then
                                SwitchItem(Sword.Item, true)
                            end

                            local Box: Part
                            if KillAuraData.Settings.Boxes then
                                coroutine.wrap(function()
                                    Box = KillAuraData.Data.Effects.Boxes[NearestEntity.Entity]
                                    if not Box then
                                        Box = Instance.new("Part", NearestEntity.Entity)
                                        Box.Size = Vector3.new(5, 6, 5)
                                        Box.Material = Enum.Material.Air
                                        Box.CanCollide = false
                                        Box.Anchored = true

                                        KillAuraData.Data.Effects.Boxes[NearestEntity.Entity] = Box
                                    end

                                    Box.CFrame = NearestEntity.Entity.PrimaryPart.CFrame
                                    Box.Transparency = KillAuraData.Settings.BoxTransparency
                                    Box.Color = KillAuraData.Settings.BoxColor
                                end)()
                            end

                            if KillAuraData.Settings.Particles then 
                                coroutine.wrap(function()
                                    local Emitter: ParticleEmitter = KillAuraData.Data.Effects.Particles[NearestEntity.Entity]
                                    if not Emitter then
                                        Emitter = Instance.new("ParticleEmitter", NearestEntity.Entity.PrimaryPart)
                                        Emitter.EmissionDirection = Enum.NormalId.Front
                                        Emitter.SpreadAngle = Vector2.new(1, 1)
                                        Emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 2.5)})

                                        KillAuraData.Data.Effects.Particles[NearestEntity.Entity] = Emitter
                                    end

                                    Emitter.Lifetime = NumberRange.new(KillAuraData.Settings.ParticleLifeTime, KillAuraData.Settings.ParticleLifeTime)
                                    Emitter.Rate = KillAuraData.Settings.ParticleRate
                                    Emitter.Color = ColorSequence.new(KillAuraData.Settings.ParticleColor)
                                end)()
                            end

                            local HitPos: Vector3 = CalcPrediction(LocalPlayer.Character.PrimaryPart.Position, NearestEntity.Entity.PrimaryPart.Position, KillAuraData.Settings.Range)
                            if KillAuraData.Settings.InfRange and NearestEntity.Distance > 28 and not KillAuraData.Data.PlayerDamaged then
                                local Old = NearestEntity.Entity.PrimaryPart.CFrame
                                NearestEntity.Entity.PrimaryPart.CFrame = LocalPlayer.Character.PrimaryPart.CFrame   
                                if Box then
                                    Box.CFrame = Old 
                                end

                                if KillAuraData.Data.PlayerDamaged then
                                    NearestEntity.Entity.PrimaryPart.CFrame = Old
                                end
                            end

                            GameData.Utils.Remotes:Get("SwordHit"):SendToServer({
                                entityInstance = NearestEntity.Entity,
                                chargedAttack = {chargeRatio = 0},
                                validate = {
                                    targetPosition = {value = NearestEntity.Data.Root.Position},
                                    raycast = {
                                        cursorDirection = {value = CFrame.lookAt(NearestEntity.Data.Root.Position, CurrentCamera.CFrame.Position)},
                                        cameraPosition = {value = HitPos}
                                    },
                                    selfPosition = {value = HitPos}
                                },
                                weapon = Sword.Item
                            })

                            if not KillAuraData.Settings.NoSwing then
                                GameData.Utils.Animation:playAnimation(LocalPlayer, GameData.Utils.ProdAnimations[GameData.Utils.AnimationType.SWORD_SWING])
                            end

                            if KillAuraData.Settings.UseAnimation then
                                coroutine.wrap(function()
                                    local ViewModel: Model = GetViewModel()
                                    local RightHand: MeshPart = ViewModel and ViewModel:FindFirstChild("RightHand")
                                    local SelectedAnimation: {[string]: {Position: CFrame, Angle: CFrame, Duration: number}} = KillAuraData.Animations[KillAuraData.Settings.SelectedAnimation]

                                    if ViewModel and RightHand and SelectedAnimation and not KillAuraData.Data.AnimationPlaying then
                                        local RightWrist: Motor6D = RightHand:FindFirstChild("RightWrist")
                                        if RightWrist then
                                            if not KillAuraData.Data.OriginalHandPos then
                                                KillAuraData.Data.OriginalHandPos = RightWrist.C0
                                            end

                                            KillAuraData.Data.AnimationPlaying = true
                                            for i,v in SelectedAnimation do
                                                local Tween: Tween = TweenService:Create(RightWrist, TweenInfo.new(v.Duration), {C0 = KillAuraData.Data.OriginalHandPos * v.Position * v.Angle})
                                                Tween:Play()
                                                Tween.Completed:Wait()

                                                if not self.Enabled or not KillAuraData.Settings.UseAnimation then
                                                    break
                                                end
                                            end
                                        end

                                        KillAuraData.Data.AnimationPlaying = false
                                    end
                                end)()
                            else
                                if not KillAuraData.Settings.NoSwing then
                                    GameData.Utils.ViewmodelController:playAnimation(15)
                                end
                            end

                            KillAuraData.Data.LastHit = os.clock()
                        else
                            GameData.Data.KillAuraTarget = nil
                            KillAuraData.Data.AnimationPlaying = false

                            for i,v in KillAuraData.Data.Effects do
                                for i2, v2 in v do
                                    v2:Destroy()
                                end

                                table.clear(v)
                            end

                            if KillAuraData.Data.OriginalHandPos then
                                local ViewModel: Model = GetViewModel()
                                local RightHand: MeshPart = ViewModel and ViewModel:FindFirstChild("RightHand")
                                if ViewModel and RightHand then
                                    local RightWrist: Motor6D = RightHand:FindFirstChild("RightWrist")
                                    if RightWrist then
                                        TweenService:Create(RightWrist, TweenInfo.new(KillAuraData.Settings.AnimationRestoreTime), {C0 = KillAuraData.Data.OriginalHandPos}):Play()
                                    end
                                end
                            end
                        end
                    end
                end))
            else
                GameData.Data.KillAuraTarget = nil
                KillAuraData.Data.AnimationPlaying = false

                for i,v in KillAuraData.Data.Effects do
                    for i2, v2 in v do
                        v2:Destroy()
                    end

                    table.clear(v)
                end

                if KillAuraData.Data.OriginalHandPos then
                    local ViewModel: Model = GetViewModel()
                    local RightHand: MeshPart = ViewModel and ViewModel:FindFirstChild("RightHand")
                    if ViewModel and RightHand then
                        local RightWrist: Motor6D = RightHand:FindFirstChild("RightWrist")
                        if RightWrist then
                            TweenService:Create(RightWrist, TweenInfo.new(KillAuraData.Settings.AnimationRestoreTime), {C0 = KillAuraData.Data.OriginalHandPos}):Play()
                        end
                    end
                end
            end
        end
    })

    local Trigger = KillAura:KeyBind({
        Name = "Trigger",
        Flag = "KillAuraTrigger",
        Default = Enum.UserInputType.MouseButton1,
        Events = {
            Began = function()
                KillAuraData.Data.TriggerHeld = true
            end,
            Ended = function()
                KillAuraData.Data.TriggerHeld = false
            end
        }
    })
    
    KillAura:Slider({
        Name = "Range",
        Flag = "KillAuraRange",
        Min = 1,
        Max = 23,
        Default = 20,
        CallingFunction = function(self, value: number)
            KillAuraData.Settings.Range = value
        end
    })

    KillAura:Slider({
        Name = "Max Angle",
        Flag = "KillAuraMaxAngle",
        Min = 1,
        Max = 360,
        Default = 360,
        CallingFunction = function(self, value: number)
            KillAuraData.Settings.MaxAngle = value
        end
    })

    KillAura:Slider({
        Name = "Delay",
        Flag = "KillAuraDelay",
        Min = 0,
        Max = 3,
        Default = 0,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            KillAuraData.Settings.Delay = value
        end
    })

    local TargetBoxTransparency = KillAura:Slider({
        Name = "Box Transparency",
        Flag = "KillAuraTargetBoxTransparency",
        Min = 0,
        Max = 1,
        Default = 0.5,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            KillAuraData.Settings.BoxTransparency = value
        end
    })

    local ParticleRate = KillAura:Slider({
        Name = "Particle Rate",
        Flag = "KillAuraParticleRate",
        Min = 0,
        Max = 50,
        Default = 40,
        Increment = 1,
        CallingFunction = function(self, value: number)
            KillAuraData.Settings.ParticleRate = value
        end
    })

    local ParticleLifeTime = KillAura:Slider({
        Name = "Particle Time",
        Flag = "KillAuraParticleLifeTime",
        Min = 0,
        Max = 5,
        Default = 2,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            KillAuraData.Settings.ParticleLifeTime = value
        end
    })

    local TargetBoxColor = KillAura:ColorSlider({
        Name = "Box Color",
        Flag = "KillAuraTargetBoxColor",
        Default = Color3.fromRGB(255, 0, 0),
        CallingFunction = function(self, value: Color3)
            KillAuraData.Settings.BoxColor = value
        end
    })

    local ParticleColor = KillAura:ColorSlider({
        Name = "Particle Color",
        Flag = "KillAuraParticleColor",
        Default = Color3.fromRGB(255, 0, 0),
        CallingFunction = function(self, value: Color3)
            KillAuraData.Settings.ParticleColor = value
        end
    })


    local AnimationRestoreTime = KillAura:Slider({
        Name = "Animation Restore",
        Flag = "KillAuraAnimationRestoreTime",
        Min = 0,
        Max = 5,
        Default = 0.1,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            KillAuraData.Settings.AnimationRestoreTime = value
        end
    })


    local AnimationPicker = KillAura:Dropdown({
        Name = "Animation",
        Flag = "KillAuraAnimation",
        Default = "Night",
        Options = {"Night", "Smooth", "Funny", "Stand", "Air", "Hit", "Rise", "Moon", "Lunar"},
        CallingFunction = function(self, value: string)
            KillAuraData.Settings.SelectedAnimation = value
        end
    })

    KillAura:MiniToggle({
        Name = "Infinite Range",
        Flag = "KillAuraInfiniteRange",
        CallingFunction = function(self, value: boolean)
            KillAuraData.Settings.InfRange = value
        end
    })


    KillAura:MiniToggle({
        Name = "Target Box",
        Flag = "KillAuraTargetBox",
        Default = true,
        CallingFunction = function(self, value: boolean)
            KillAuraData.Settings.Boxes = value
            TargetBoxTransparency:SetVisiblity(value)
            TargetBoxColor:SetVisiblity(value)
        end
    })

    KillAura:MiniToggle({
        Name = "Particles",
        Flag = "KillAuraParticles",
        Default = true,
        CallingFunction = function(self, value: boolean)
            KillAuraData.Settings.Particles = value

            ParticleLifeTime:SetVisiblity(value)
            ParticleRate:SetVisiblity(value)
            ParticleColor:SetVisiblity(value)
        end
    })

    KillAura:MiniToggle({
        Name = "Auto Switch",
        Flag = "KillAuraAutoSwitch",
        Default = true,
        CallingFunction = function(self, value: boolean)
            KillAuraData.Settings.AutoSwitch = value
        end
    })

    KillAura:MiniToggle({
        Name = "Hand Check",
        Flag = "KillAuraHandCheck",
        CallingFunction = function(self, value: boolean)
            KillAuraData.Settings.HandCheck = value
        end
    })

    KillAura:MiniToggle({
        Name = "Wall Check",
        Flag = "KillAuraWallCheck",
        CallingFunction = function(self, value: boolean)
            KillAuraData.Settings.WallCheck = value
        end
    })

    KillAura:MiniToggle({
        Name = "No Swing",
        Flag = "KillAuraNoSwing",
        CallingFunction = function(self, value: boolean)
            KillAuraData.Settings.NoSwing = value
        end
    })

    KillAura:MiniToggle({
        Name = "Use Trigger",
        Flag = "KillAuraTriggerEnabled",
        CallingFunction = function(self, value: boolean)
            KillAuraData.Settings.TriggerButton = value
            Trigger:SetVisiblity(value)
        end
    })

    KillAura:MiniToggle({
        Name = "Use Animation",
        Flag = "KillAuraUseAnimation",
        Default = true,
        CallingFunction = function(self, value: boolean)
            KillAuraData.Settings.UseAnimation = value

            AnimationRestoreTime:SetVisiblity(value)
            AnimationPicker:SetVisiblity(value)
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

    local Aimbot = Windows.Combat:CreateModule({
        Name = "Aimbot",
        Flag = "Aimbot",
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

                    local Entities = GetEntities()
                    local AllEntities = {}
                    for i,v in Entities do
                        table.insert(AllEntities, v.Entity)
                    end

                    local NearestToMouse: {DistanceFromMouse: number, DistanceFromPlayer: number, Player: Player?, Character: Model?} = Night:GetNerestPlayerToMouse({
                        TeamCheck = AimbotData.Settings.TeamCheck,
                        Exclude = {LocalPlayer},
                        Extras = AllEntities
                    })

                    if NearestToMouse.Character then
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
                                
                                if AimbotData.Settings.WallCheck then
                                    AimbotData.Data.RayParams.FilterType = Enum.RaycastFilterType.Exclude
                                    AimbotData.Data.RayParams.FilterDescendantsInstances = CollectionService:GetTagged("entity")
                                    if not IsPathClear(Target, TargetPart, AimbotData.Data.RayParams) then 
                                        return 
                                    end
                                end

                                local NewCF = CFrame.new(CurrentCamera.CFrame.Position, TargetPart.Position)
                                CurrentCamera.CFrame = CurrentCamera.CFrame:Lerp(NewCF, AimbotData.Settings.Smoothness * Delta)
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
        Flag = "AimbotTrigger",
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
        Flag = "AimbotUseTriggerButton",
        CallingFunction = function(self, value: boolean)
            AimbotData.Settings.UseTriggerButton = value
            KeyTrigger:SetVisiblity(value)
        end
    })
end)();

(function()
    local TeamCheck = false
    local Distance = 30

    local TargetHud = Windows.Render:CreateModule({
        Name = "Target HUD",
        Flag = "TargetHUD",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                local Health = {
                    Current = math.round(LocalPlayer.Character:GetAttribute("Health")) or 0,
                    Max = math.round(LocalPlayer.Character:GetAttribute("MaxHealth")) or 0
                }

                Night:GetTargetHud(true, {Player = LocalPlayer, Health = Health})
                repeat
                    local Nearest = GetNearestEntity(TeamCheck)
                    if Nearest.Entity and Distance >= Nearest.Distance then
                        Health = {
                            Current = math.round(Nearest.Entity:GetAttribute("Health")) or 0,
                            Max = math.round(Nearest.Entity:GetAttribute("MaxHealth")) or 0
                        }

                        local Display: string = Nearest.Entity.Humanoid.DisplayName
                        if Display == "" then
                            Display = Nearest.Entity.Name
                        end

                        Night:GetTargetHud():Update({
                            Player = Nearest.Data.Player,
                            UserData = {
                                Name = Nearest.Entity.Name, 
                                DisplayName = Display, 
                                ProfilePic = "",
                            },
                            Health = Health,
                            Visible = true
                        })
                    else
                        Health = {
                            Current = math.round(LocalPlayer.Character:GetAttribute("Health")) or 0,
                            Max = math.round(LocalPlayer.Character:GetAttribute("MaxHealth")) or 0
                        }

                        Night:GetTargetHud():Update({
                            Player = LocalPlayer,
                            Health = Health,
                            Visible = Night.UIData.UIOpen
                        })
                    end
                    task.wait(0.5)
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
    local Distance = 28
    local HandCheck = false
    local AutoSwitch = false
    local LastHitNormal = Enum.NormalId.Top

    local Nuker = Windows.Utility:CreateModule({
        Name = "Nuker",
        Flag = "Nuker",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                repeat 
                    if HandCheck then
                        local CurrentHand = GetInventory().hand
                        if CurrentHand and CurrentHand.tool then
                            local Meta = GameData.Utils.ItemMeta[CurrentHand.itemType]
                            if not Meta or not Meta.breakBlock then
                                task.wait()
                                continue
                            end
                        else
                            task.wait()
                            continue
                        end
                    end

                    local Bed = GetNearestBed()
                    if Bed.Bed and Distance >= Bed.Distance then
                        local BestSide = FindWeakestSide(Bed.Bed)
                        local Item = BestSide[#BestSide]
                        local ItemName = Item.Block.Name
                        if Item then
                            if table.find(CollectionService:GetTagged("bed"), Item.Block) then
                                ItemName = "wood"
                                Item.HitNormal = LastHitNormal
                            else
                                LastHitNormal = Item.HitNormal
                            end

                            local BestTool = GetBestItemToBreakBlock(ItemName)
                            if BestTool.Item then
                                SwitchItem(BestTool.Item, not AutoSwitch)
                            else
                                if AutoSwitch then
                                    BestTool = GetBestItemToBreakBlock("stone")
                                    if BestTool.Item then
                                        SwitchItem(BestTool.Item, false)
                                    end
                                end
                            end

                            local Result = DamageBlock(Item.Block, LastHitNormal)
                            if Result == "cancelled" then
                                task.wait(0.5)
                            end
                        end
                    end
                    task.wait()
                until not self.Enabled
            end
        end
    })

    Nuker:Slider({
        Name = "Distance",
        Flag = "NukerDistance",
        Min = 1,
        Max = 28,
        Default = 28,
        CallingFunction = function(self, value: number)
            Distance = value
        end
    })

    Nuker:MiniToggle({
        Name = "Switch Item",
        Flag = "NukerSwitchItem",
        Default = true,
        CallingFunction = function(self, value: boolean)
            AutoSwitch = value
        end
    })

    Nuker:MiniToggle({
        Name = "HandCheck",
        Flag = "NukerHandCheck",
        CallingFunction = function(self, value: boolean)
            HandCheck = value
        end
    })
end)();

(function()
    local Old
    Windows.Movement:CreateModule({
        Name = "Sprint",
        Flag = "Sprint",
        CallingFunction = function(self, enabled: boolean) 
            if enabled then
                Old = GameData.Utils.Sprint.stopSprinting
                GameData.Utils.Sprint.stopSprinting = function()
                    return
                end

                repeat
                    if not GameData.Utils.Sprint:isSprinting() then
                        GameData.Utils.Sprint:startSprinting()
                    end
                    task.wait()
                until not self.Enabled
            else
                GameData.Utils.Sprint.stopSprinting = Old
                GameData.Utils.Sprint:stopSprinting()
            end
        end
    })
end)();

(function()
    local OldApply = nil
    local KnockbackValue = 0

    local Knockback = Windows.Movement:CreateModule({
        Name = "Knockback",
        Flag = "KnockbackChanger",
        CallingFunction = function(self, enabled: boolean) 
            if enabled then
                OldApply = GameData.Utils.Knockback.applyKnockback
                GameData.Utils.Knockback.applyKnockback = function(Part: BasePart, RealKnockback: number, ...)
                    return OldApply(Part, KnockbackValue, ...)
                end
            else
                if OldApply then
                    GameData.Utils.Knockback.applyKnockback = OldApply
                end
            end
        end
    })
    
    Knockback:Slider({
        Name = "Knockback",
        Flag = "KnockbackChangerValue",
        Min = 0,
        Max = 30,
        Default = 0,
        CallingFunction = function(self, value: number)
            KnockbackValue = value
        end
    })
end)();

(function()
    local ScaffoldData = {
        Settings = {
            Extend = 1,
            DownValue = 4,
            Boost = 5
        },
        Data = {
            Blocks = {},
            Placed = {},
            HoldingDown = false,
            HoldingUp = false,
            Pos = Vector3.zero
        }
    }

    local function GetBlockPlace(pos: Vector3)
        local Round = GameData.Utils.BlockEngine:getBlockPosition(pos)
        return GameData.Utils.BlockEngine:getStore():getBlockAt(Round), Round
    end

    local function CheckBlockPos(pos: Vector3)
        for _, Offset in next, ScaffoldData.Data.Blocks do
            return GetBlockPlace(pos + Offset)
        end
        return nil
    end

    local function GetPositions(min: Vector3, max: Vector3)
        local Store, List = GameData.Utils.BlockEngine:getStore(), {}
        for x = min.X, max.X do
            for y = min.Y, max.Y do
                for z = min.Z, max.Z do
                    if Store:getBlockAt(Vector3.new(x, y, z)) then
                        List[#List + 1] = Vector3.new(x * 3, y * 3, z * 3)
                    end
                end
            end
        end
        return List
    end

    local function GetCorner(a: Vector3, b: Vector3)
        local Pos = a + (b - a).Unit * 100
        local Vec = Vector3.new(3, 3, 3)
        return Vector3.new(
            math.clamp(Pos.X, a.X - Vec.X, a.X + Vec.X),
            math.clamp(Pos.Y, a.Y - Vec.Y, a.Y + Vec.Y),
            math.clamp(Pos.Z, a.Z - Vec.Z, a.Z + Vec.Z)
        )
    end

    local function GetBuild(pos: Vector3)
        local Vec = Vector3.new(21, 21, 21)
        local Dist, Point = 60, nil
        for _, v in next, GetPositions(GameData.Utils.BlockEngine:getBlockPosition(pos - Vec), GameData.Utils.BlockEngine:getBlockPosition(pos + Vec)) do
            local Corner = GetCorner(v, pos)
            local Mag = (pos - Corner).Magnitude
            if Mag < Dist then
                Dist, Point = Mag, Corner
            end
        end
        return Point
    end

    local function PlaceBlock(pos: Vector3)
        local Block = GetBlocks()
        if not Block then return end
        if not ScaffoldData.Data.Placed[Block] then
            ScaffoldData.Data.Placed[Block] = GameData.Utils.BlockPlacer.new(GameData.Utils.BlockClient, Block.Type)
        end
        return ScaffoldData.Data.Placed[Block]:placeBlock(GameData.Utils.BlockEngine:getBlockPosition(pos))
    end

    local function IsDiagonal()
        local Move = LocalPlayer.Character.Humanoid.MoveDirection
        local X, Z = math.abs(Move.X), math.abs(Move.Z)
        return X > 0.1 and Z > 0.1 and math.abs(X - Z) < 0.3
    end

    local Scaffold = Windows.Utility:CreateModule({
        Name = "Scaffold",
        Flag = "Scaffold",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                repeat
                    if Night:IsAlive(LocalPlayer) then
                        local Root = LocalPlayer.Character.HumanoidRootPart
                        local Hum = LocalPlayer.Character.Humanoid
                        for i = 1, ScaffoldData.Settings.Extend do
                            local YLevel = Root.Position.Y - Hum.HipHeight - (ScaffoldData.Data.HoldingDown and ScaffoldData.Settings.DownValue or 1.5)
                            local Dir = Hum.MoveDirection * i
                            local CFrame = CFrame.new(Root.Position) * CFrame.new(Dir.X, -Root.Position.Y + YLevel, Dir.Z)
                            local Pos = Vector3.new(math.round(CFrame.X / 3) * 3, math.round(CFrame.Y / 3) * 3, math.round(CFrame.Z / 3) * 3)

                            if IsDiagonal() then
                                local Hor = (ScaffoldData.Data.Pos - Root.Position) * Vector3.new(1, 0, 1)
                                if Hor.X ^ 2 + Hor.Z ^ 2 < 6.25 then
                                    Pos = ScaffoldData.Data.Pos
                                end
                            end

                            local _, res = pcall(function()
                                return GetBlockPlace(Pos)
                            end)

                            if not res then
                                local Place = CheckBlockPos(Pos * 3) or GetBuild(Pos)
                                if Place then
                                    task.spawn(function()
                                        PlaceBlock(Place)
                                    end)
                                end
                            end

                            ScaffoldData.Data.Pos = Pos
                        end

                        if ScaffoldData.Settings.Tower and ScaffoldData.Data.HoldingUp and not UserInputService:GetFocusedTextBox() then
                            local Velo = Root.Velocity
                            Root.Velocity = Vector3.new(Velo.X, ScaffoldData.Settings.Boost * 6 + 3, Velo.Z)
                        end
                    end
                    task.wait()
                until not self.Enabled
            end
        end
    })

    Scaffold:KeyBind({
        Name = "Down",
        MobileText = "Scaffold Down",
        Flag = "ScaffoldDownKeybind",
        DestroyMobileButtonOnDisable = true,
        Default = Enum.KeyCode.LeftShift,
        Events = {
            Began = function()
                ScaffoldData.Data.HoldingDown = true
            end,
            Ended = function()
                ScaffoldData.Data.HoldingDown = false
            end
        }
    })

    Scaffold:KeyBind({
        Name = "Up",
        MobileText = "Scaffold Up",
        Flag = "ScaffoldUpKeybind",
        DestroyMobileButtonOnDisable = true,
        Default = Enum.KeyCode.Space,
        Events = {
            Began = function()
                ScaffoldData.Data.HoldingUp = true
            end,
            Ended = function()
                ScaffoldData.Data.HoldingUp = false
            end
        }
    })

    Scaffold:Slider({
        Name = "Extend",
        Flag = "ScaffoldExtend",
        Min = 1,
        Max = 10,
        Default = 2,
        CallingFunction = function(self, value: number)
            ScaffoldData.Settings.Extend = value
        end
    })

    Scaffold:Slider({
        Name = "Down",
        Flag = "ScaffoldDown",
        Min = 1,
        Max = 10,
        Default = 4,
        CallingFunction = function(self, value: number)
            ScaffoldData.Settings.DownValue = value
        end
    })

    Scaffold:Slider({
        Name = "Up",
        Flag = "ScaffoldUp",
        Min = 1,
        Max = 10,
        Default = 5,
        CallingFunction = function(self, value: number)
            ScaffoldData.Settings.Boost = value
        end
    })
end)();

(function()
    local FallRay: RaycastParams, Power: number = RaycastParams.new(), 0
    local function Physics(Delta: number)
        local Root: BasePart = LocalPlayer.Character.PrimaryPart
        local Velocity: Vector3 = Root.AssemblyLinearVelocity

        Root.AssemblyLinearVelocity = Vector3.new(Velocity.X, -85, Velocity.Z)
        Root.CFrame += Vector3.new(0, Delta * Power, 0)

        Power -= Delta * workspace.Gravity
    end

    local function MakeRay(Char: Model)
        repeat task.wait() until Night:IsAlive(LocalPlayer)

        FallRay.FilterType = Enum.RaycastFilterType.Exclude
        FallRay.CollisionGroup = Char.PrimaryPart.CollisionGroup
        FallRay.FilterDescendantsInstances = {Char, CurrentCamera}
    end

    Windows.Utility:CreateModule({
        Name = "No Fall",
        Flag = "NoFall",
        CallingFunction = function(self, enabled: boolean) 
            if enabled then
                self:Connection(LocalPlayer.CharacterAdded:Connect(MakeRay))
                if Night:IsAlive(LocalPlayer) then
                    MakeRay(LocalPlayer.Character)
                end

                self:Connection(RunService.PreSimulation:Connect(function(Delta)
                    if not Night:IsAlive(LocalPlayer) then return end

                    local Char: Model = LocalPlayer.Character
                    local Root: BasePart = Char.PrimaryPart
                    
                    if Root.AssemblyLinearVelocity.Y >= -80 then
                        Power = 0
                        return
                    end

                    local _, Size: Vector3 = Char:GetBoundingBox()
                    local Raycast: RaycastResult = workspace:Raycast(Root.Position, Vector3.new(0, -(Size.Y / 2), 0), FallRay)
                    if not Raycast then
                        Physics(Delta)
                    else
                        Power = 0
                    end
                end))
            end
        end
    })
end)();

(function()
    local Potions, HealthConsumables = false, false
    local Delay = 0
    local RequiredHealth = 60
    local Whitelisted = {
        "shield",
        "star",
        "apple_juice",
        "pie"
    }

    local AutoConsume = Windows.Utility:CreateModule({
        Name = "Auto Consume",
        Flag = "AutoConsume",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                repeat
                    for i,v in GetInventory().items do
                        local Meta = GameData.Utils.ItemMeta[v.itemType]
                        local IsWhitelisted: boolean = false
                        for i2,v2 in Whitelisted do
                            if v.itemType:lower():find(v2) then
                                IsWhitelisted = true
                                break
                            end
                        end

                        if Meta and Meta.consumable and ((HealthConsumables and Meta.consumable.requiresMissingHealth) or (Potions and Meta.consumable.potion) or IsWhitelisted) then
                            if (v.itemType == "speed_potion" and LocalPlayer.Character:GetAttribute("SpeedBoost")) then
                                continue
                            end

                            if (v.itemType == "pie" and LocalPlayer.Character:GetAttribute("SpeedPieBuff")) then
                                continue
                            end

                            if v.itemType:lower():find("shield") then
                                local Potion: number = LocalPlayer.Character:GetAttribute("Shield_POTION")
                                if Potion >= 200 then
                                    continue
                                end
                            end

                            if LocalPlayer.Character:GetAttribute("StatusEffect_"..v.itemType) then
                                continue
                            end

                            if Meta.consumable.requiresMissingHealth and RequiredHealth < LocalPlayer.Character:GetAttribute("Health") then
                                continue
                            end

                            task.wait(Delay)
                            GameData.Utils.Remotes:Get("ConsumeItem"):CallServerAsync({
                                item = v.tool
                            })
                        end
                    end
                    task.wait()
                until not self.Enabled
            end
        end
    })

    local HealthSlider = AutoConsume:Slider({
        Name = "Health",
        Flag = "AutoConsumeHealthValue",
        Min = 1,
        Max = 100,
        Default = 60,
        CallingFunction = function(self, value: number)
            RequiredHealth = value
        end
    })

    AutoConsume:Slider({
        Name = "Delay",
        Flag = "AutoConsumeDelay",
        Min = 0,
        Max = 10,
        Default = 0,
        CallingFunction = function(self, value: number)
            Delay = value
        end
    })

    AutoConsume:MiniToggle({
        Name = "Potions",
        Flag = "AutoConsumePotions",
        Default = true,
        CallingFunction = function(self, value: boolean)
            Potions = value
        end
    })

    AutoConsume:MiniToggle({
        Name = "Health",
        Flag = "AutoConsumeHealth",
        Default = true,
        CallingFunction = function(self, value: boolean)
            HealthConsumables = value
            HealthSlider:SetVisiblity(value)
        end
    })
end)();

(function()
    local Distance = 23
    local Delay = 0
    local UICheck = false
    local Opened = {}

    local ChestStealer = Windows.Utility:CreateModule({
        Name = "Chest Stealer",
        Flag = "ChestStealer",
        CallingFunction = function(self, enabled: boolean)
            if enabled then 
                repeat
                    local Chest = GetNearestChest(Opened)
                    if Chest.Chest and Distance >= Chest.Distance and not table.find(Opened, Chest.Chest) and #Chest.ChestFolder:GetChildren() > 0 then
                        if UICheck and not GameData.Utils.App:isAppOpen(GameData.Utils.AppIds.CHEST_INVENTORY) then
                            continue
                        end

                        local InsertValue: number = #Opened + 1
                        table.insert(Opened, InsertValue, Chest.Chest)
                        task.delay(0.5, table.remove, Opened, InsertValue)

                        GameData.Utils.Remotes:GetNamespace("Inventory"):Get("SetObservedChest"):SendToServer(Chest.Chest)
                        if not Chest.Chest:GetAttribute("ChestOpened") then
                            coroutine.wrap(function()
                                GameData.Utils.Chest:playChestOpenAnimation(Chest.Chest)
                            end)()
                        end

                        task.delay(0.1, function()
                            for i,v in Chest.ChestFolder:GetChildren() do
                                GameData.Utils.Remotes:GetNamespace("Inventory"):Get("ChestGetItem"):CallServerAsync(Chest.ChestFolder, v)
                                if Delay ~= 0 then
                                    task.wait(Delay)
                                end
                            end

                            GameData.Utils.Remotes:GetNamespace("Inventory"):Get("SetObservedChest"):SendToServer()
                        end)
                    end
                    task.wait(0.1)
                until not self.Enabled
            end
        end
    })
    
    ChestStealer:Slider({
        Name = "Range",
        Flag = "ChestStealerRange",
        Min = 1,
        Max = 20,
        Default = 20,
        CallingFunction = function(self, value: number)
            Distance = value
        end
    })

    ChestStealer:Slider({
        Name = "Delay",
        Flag = "ChestStealerDelay",
        Min = 0,
        Max = 5,
        Default = 0,
        CallingFunction = function(self, value: number)
            Delay = value
        end
    })
end)();

(function()
    local Speed: number, Distance: number = 60, 2

    local Param: RaycastParams = RaycastParams.new()
    Param.FilterType = Enum.RaycastFilterType.Include
    Param.RespectCanCollide = true

    Param.FilterDescendantsInstances = BlockList

    local WallClimb = Windows.Movement:CreateModule({
        Name = "Wall Climb",
        Flag = "WallClimb",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                repeat
                    if Night:IsAlive(LocalPlayer) then
                        local Root: BasePart = LocalPlayer.Character.PrimaryPart
                        local Humanoid: Humanoid = LocalPlayer.Character.Humanoid

                        local Ray: RaycastResult? = workspace:Raycast(
                            Root.Position,
                            Humanoid.MoveDirection * Distance,
                            Param
                        )

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
        Flag = "WallClimbSpeed",
        Min = 1,
        Max = 120,
        Default = 60,
        CallingFunction = function(self, value: number)
            Speed = value
        end
    })

    WallClimb:Slider({
        Name = "Distance",
        Flag = "WallClimbDistance",
        Min = 1,
        Max = 5,
        Default = 2,
        CallingFunction = function(self, value: number)
            Distance = value
        end
    })
end)();

(function()
    local ProjAimbotData = {
        Settings = {
            FOV = false,
            Filled = false,
            Other = false,
            WallCheck = false,
            DistCheck = false,
            Distance = 100,
            Radius = 1000,
            TargetPart = "HumanoidRootPart",
            Color = Color3.fromRGB(255, 0, 0)
        },
        Data = {
            RayParams = RaycastParams.new(),
            Target = nil,
            Circle = nil,
            Old = nil
        }
    }

    ProjAimbotData.Data.RayParams.FilterType = Enum.RaycastFilterType.Include
    ProjAimbotData.Data.RayParams.FilterDescendantsInstances = BlockList
    
    local ProjAimbot = Windows.Combat:CreateModule({
        Name = "Projectile Aimbot",
        Flag = "ProjectileAimbot",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                if not ProjAimbotData.Data.Circle then
                    local Circle = Drawing.new("Circle")
                    Circle.Visible = ProjAimbotData.Settings.FOV
                    Circle.Color = ProjAimbotData.Settings.Color
                    Circle.Radius = ProjAimbotData.Settings.Radius
                    Circle.Thickness = 2
                    Circle.Filled = ProjAimbotData.Settings.Filled
                    Circle.Transparency = 0.8
                    ProjAimbotData.Data.Circle = Circle
                end

                self:Connection(RunService.PreRender:Connect(function()
                    if not Night:IsAlive(LocalPlayer) then return end

                    if ProjAimbotData.Data.Circle then
                        ProjAimbotData.Data.Circle.Position = UserInputService:GetMouseLocation()
                    end

                    local Entities = GetEntities()
                    local AllEntities = {}
                    for _, v in Entities do
                        table.insert(AllEntities, v.Entity)
                    end

                    local NearestToMouse = Night:GetNerestPlayerToMouse({
                        TeamCheck = true,
                        Exclude = {LocalPlayer},
                        Extras = AllEntities
                    })

                    if NearestToMouse.Character then
                        local Target = NearestToMouse.Character
                        local TargetPart = Target:FindFirstChild(ProjAimbotData.Settings.TargetPart) or Target.PrimaryPart
                        if TargetPart then
                            local Pos, OnScreen = CurrentCamera:WorldToViewportPoint(TargetPart.Position)
                            local MousePos = UserInputService:GetMouseLocation()
                            local DistToMouse = (Vector2.new(Pos.X, Pos.Y) - MousePos).Magnitude
                            if OnScreen and DistToMouse <= ProjAimbotData.Settings.Radius then
                                if ProjAimbotData.Settings.DistCheck and NearestToMouse.DistanceFromPlayer >= ProjAimbotData.Settings.Distance then
                                    ProjAimbotData.Data.Target = nil
                                    return
                                end
                                
                                if ProjAimbotData.Settings.WallCheck then
                                    if not IsPathClear(Target, TargetPart, ProjAimbotData.Data.RayParams) then
                                        ProjAimbotData.Data.Target = nil
                                        return 
                                    end
                                end

                                ProjAimbotData.Data.Target = Target
                            else
                                ProjAimbotData.Data.Target = nil
                            end
                        end
                    end
                end))

                ProjAimbotData.Data.Old = GameData.Utils.Projectile.calculateImportantLaunchValues
                GameData.Utils.Projectile.calculateImportantLaunchValues = function(proj, data, line, start, pos)
                    local Launch = pos or proj:getLaunchPosition(start)
                    if not ProjAimbotData.Data.Target or not ProjAimbotData.Data.Target.PrimaryPart or not Launch then
                        return ProjAimbotData.Data.Old(proj, data, line, start, pos)
                    end
                    
                    local PrimaryPart = ProjAimbotData.Data.Target.PrimaryPart
                    local Humanoid = ProjAimbotData.Data.Target:FindFirstChildOfClass("Humanoid")
                    local YLevel = Humanoid and PrimaryPart.Position.Y + Humanoid.HipHeight or PrimaryPart.Position.Y
                    local StartPos = CFrame.new(Launch + (data.fromPositionOffset or Vector3.new()), Vector3.new(PrimaryPart.Position.X, YLevel, PrimaryPart.Position.Z)).Position
                    local Disp = Vector3.new(PrimaryPart.Position.X, YLevel, PrimaryPart.Position.Z) - StartPos
                    local Vel = PrimaryPart.Velocity or Vector3.new(0, 0, 0)
                    local Meta = data:getProjectileMeta()
                    local Gravity = (Meta and Meta.gravitationalAcceleration or 0) * (data.gravityMultiplier or 1)
                
                    local IsArrow = type(data.projectile) == "string" and data.projectile:find("arrow")
                    local IsOtherProj = Meta and (Meta.gravitationalAcceleration or 0) > 0
                    local Calc = nil

                    if (IsArrow or IsOtherProj) and Meta and Meta.launchVelocity and Meta.launchVelocity > 0 then
                        local Time = Disp.Magnitude / Meta.launchVelocity
                        if Time > 0 then
                            Calc = StartPos + Vector3.new(
                                (Disp.X + Vel.X * Time) / Time,
                                (Disp.Y - (-0.5 * Gravity) * Time * Time) / Time,
                                (Disp.Z + Vel.Z * Time) / Time
                            )
                        end
                    end

                    if not Calc then
                        Calc = PrimaryPart.Position
                    end
                
                    return {
                        initialVelocity = CFrame.new(StartPos, Calc).LookVector * ((Meta and Meta.launchVelocity) or 100),
                        positionFrom = StartPos,
                        deltaT = (Meta and (Meta.predictionLifetimeSec or Meta.lifetimeSec)) or 1,
                        gravitationalAcceleration = Gravity
                    }
                end
            else
                GameData.Utils.Projectile.calculateImportantLaunchValues = ProjAimbotData.Data.Old
                ProjAimbotData.Data.Target = nil
                if ProjAimbotData.Data.Circle then
                    ProjAimbotData.Data.Circle:Destroy()
                    ProjAimbotData.Data.Circle = nil
                end
            end
        end
    })

    ProjAimbot:Dropdown({
        Name = "Target Part",
        Flag = "ProjAimbotPart",
        Default = "HumanoidRootPart",
        Options = AimParts,
        CallingFunction = function(self, Value: string)
            ProjAimbotData.Settings.TargetPart = Value
        end
    })

    local FovColor = ProjAimbot:ColorSlider({
        Name = "FOV Color",
        Flag = "ProjAimbotFOVCircleColor",
        Default = Color3.fromRGB(255, 0, 0),
        CallingFunction = function(self, Color: Color3)
            ProjAimbotData.Settings.Color = Color
            if ProjAimbotData.Data.Circle then
                ProjAimbotData.Data.Circle.Color = Color
            end
        end
    })

    local FovSize = ProjAimbot:Slider({
        Name = "FOV Size",
        Flag = "ProjAimbotFOVSize",
        Default = 1000,
        Min = 1,
        Max = 1000,
        CallingFunction = function(self, value: number)
            ProjAimbotData.Settings.Radius = value
            if ProjAimbotData.Data.Circle then
                ProjAimbotData.Data.Circle.Radius = value
            end
        end
    })

    local Distance = ProjAimbot:Slider({
        Name = "Distance",
        Flag = "ProjAimbotDistance",
        Default = 100,
        Min = 1,
        Max = 200,
        CallingFunction = function(self, value: number)
            ProjAimbotData.Settings.Distance = value
        end
    })

    ProjAimbot:MiniToggle({
        Name = "FOV",
        Flag = "ProjAimbotFOV",
        CallingFunction = function(self, value: boolean)
            ProjAimbotData.Settings.FOV = value

            FovColor:SetVisiblity(value)
            FovSize:SetVisiblity(value)

            if not ProjAimbotData.Data.Circle then
                if ProjAimbot.Enabled then
                    local Circle = Drawing.new("Circle")
                    Circle.Visible = true
                    Circle.Color = ProjAimbotData.Settings.Color
                    Circle.Radius = ProjAimbotData.Settings.Radius
                    Circle.Thickness = 2
                    Circle.Filled = false
                    Circle.Transparency = 0.8
                    ProjAimbotData.Data.Circle = Circle
                end
            else
                if not value then
                    ProjAimbotData.Data.Circle:Destroy()
                    ProjAimbotData.Data.Circle = nil
                end
            end
        end
    })

    ProjAimbot:MiniToggle({
        Name = "Distance Check",
        Flag = "ProjAimbotDistanceCheck",
        CallingFunction = function(self, value: number)
            ProjAimbotData.Settings.DistCheck = value
            Distance:SetVisiblity(value)
        end
    })

    ProjAimbot:MiniToggle({
        Name = "Wall Check",
        Flag = "ProjAimbotWallCheck",
        CallingFunction = function(self, value: boolean)
            ProjAimbotData.Settings.WallCheck = value
        end
    })
end)();

(function()
    local ProjectileAura = {
        Settings = {
            Range = 30,
            Speed = 100,
            Power = 50,
            Delay = 0.1,
            TP = false,
            WallCheck = false,
            PlayersOnly = false
        },
        Data = {
            DelayProj = {},
            ProjNames = {arrow = true, snowball = true},
            Params = RaycastParams.new()
        }
    }

    local function GetAmmo(Check)
        if not Check.ammoItemTypes then return nil end

        local Inv = GetInventory().items
        for i = 1, #Check.ammoItemTypes do
            local Type = Check.ammoItemTypes[i]
            for j = 1, #Inv do
                if Inv[j].itemType == Type then
                    return Type
                end
            end
        end
        
        return nil
    end
    
    local function GetTools()
        local Found = {}
        local Inventory = GetInventory().items

        for i = 1, #Inventory do
            local Item = Inventory[i]
            local Data = GameData.Utils.ItemMeta[Item.itemType]
            local Source = Data and Data.projectileSource
            if Source then
                local Ammo = GetAmmo(Source)
                if Ammo and ProjectileAura.Data.ProjNames[Ammo] then
                    Found[#Found + 1] = {
                        Item = Item,
                        Ammo = Ammo,
                        Proj = Source.projectileType(Ammo),
                        Meta = Source
                    }
                end
            end
        end

        return next(Found) and Found or {}
    end

    local function CheckProj(Fired, Obj)
        if not Fired then
            ProjectileAura.Data.DelayProj[Obj.Item.itemType] = os.clock()
        else
            local Sounds = Obj.Meta.launchSound
            if Sounds and Sounds[1] then
                GameData.Utils.Sound:playSound(Sounds[1])
            end
        end
    end    

    local function Aim(Start: Vector3, Launch: number, Gravity: number?, TargetPos: Vector3, Velocity: Vector3, HipHeight: number?): Vector3?
        if not (Start and TargetPos and Launch and Launch > 1) then return end
        Gravity = Gravity or workspace.Gravity
        local ping: number = (Stats and (Stats.Ping:GetValue() / 1000)) or 0.1
    
        TargetPos = TargetPos + Vector3.new(0, HipHeight or 0, 0)
    
        local rel: Vector3 = TargetPos - Start
        local dist: number = rel.Magnitude
        local t: number = dist / Launch + ping
    
        local horizLead: Vector3 = Vector3.new(Velocity.X, 0, Velocity.Z) * t
        local pred: Vector3 = TargetPos + horizLead
    
        rel = pred - Start
        dist = rel.Magnitude
        t = dist / Launch
    
        pred = pred + Vector3.new(0, 0.5 * Gravity * t * t, 0)
        return pred
    end

    local ProjAura = Windows.Combat:CreateModule({
        Name = "Projectile Aura",
        Flag = "ProjectileAura",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                repeat
                    if Night:IsAlive(LocalPlayer) then
                        local Target = GetNearestEntity(true)
                        if Target.Entity and Target.Distance <= ProjectileAura.Settings.Range and Night:IsAlive(Target.Entity, true) and (ProjectileAura.Settings.PlayersOnly and Target.Data.Player or not ProjectileAura.Settings.PlayersOnly) then
                            local Pos = LocalPlayer.Character.PrimaryPart.Position
                            local Tools = GetTools()

                            if ProjectileAura.Settings.WallCheck then
                                ProjectileAura.Data.Params.FilterType = Enum.RaycastFilterType.Exclude
                                ProjectileAura.Data.Params.FilterDescendantsInstances = CollectionService:GetTagged("entity")

                                if not IsPathClear(Target.Entity, Target.Entity.PrimaryPart, ProjectileAura.Data.Params) then
                                    task.wait()
                                    continue
                                end
                            end

                            if GameData.Data.KillAuraTarget then
                                task.wait()
                                continue
                            end

                            if Windows.Movement.Modules.LongJump.Enabled then
                                task.wait()
                                continue
                            end

                            for i = 1, #Tools do
                                local Obj = Tools[i]
                                local ItemType = Obj.Item.itemType

                                if (ProjectileAura.Data.DelayProj[ItemType] or 0) < os.clock() then
                                    local ProjData = GameData.Utils.ProjMeta[Obj.Proj]
                                    local LaunchVel = ProjData.launchVelocity
                                    local AimPos = Aim(Pos, LaunchVel, ProjData.gravitationalAcceleration or 196.2, Target.Entity.PrimaryPart.Position, Target.Entity.PrimaryPart.Velocity, Target.Entity.Humanoid.HipHeight)
                                    
                                    if AimPos then
                                        SwitchItem(Obj.Item.tool, true)
                                        coroutine.wrap(function()
                                            local LookVec = (CFrame.new(Pos, AimPos)).LookVector * LaunchVel

                                            if not ProjectileAura.Settings.TP then
                                                GameData.Utils.Projectile:createLocalProjectile(ProjData, Obj.Ammo, Obj.Proj, CFrame.new(Pos, AimPos).Position, HttpService:GenerateGUID(true), LookVec, {drawDurationSeconds = 1})
                                            end

                                            GameData.Utils.Remotes:Get("ProjectileFire"):CallServerAsync(
                                                Obj.Item.tool, Obj.Ammo, Obj.Proj,
                                                CFrame.new(Pos, AimPos).Position,
                                                Pos, LookVec,
                                                HttpService:GenerateGUID(true),
                                                {drawDurationSec = ProjectileAura.Settings.Speed / 100, shotId = HttpService:GenerateGUID(false)},
                                                workspace:GetServerTimeNow() - 0.01 * ((ProjectileAura.Settings.Power - 5) / 2)
                                            ):andThen(function(Ammo: Instance)
                                                CheckProj(Ammo, Obj)
                                            end)
                                        end)()
                                        
                                        ProjectileAura.Data.DelayProj[ItemType] = os.clock() + Obj.Meta.fireDelaySec
                                        task.wait(ProjectileAura.Settings.Delay)
                                    end
                                end
                            end
                        end
                        task.wait(ProjectileAura.Settings.Delay)
                    end
                    task.wait()
                until not self.Enabled
            end
        end
    })

    ProjAura:Slider({
        Name = "Range",
        Flag = "ProjectileAuraRange",
        Min = 1,
        Max = 200,
        Default = 140,
        CallingFunction = function(self, value: number)
            ProjectileAura.Settings.Range = value
        end
    })

    ProjAura:Slider({
        Name = "Speed",
        Flag = "ProjectileAuraSpeed",
        Min = 1,
        Max = 200,
        Default = 100,
        CallingFunction = function(self, value: number)
            ProjectileAura.Settings.Speed = value
        end
    })

    ProjAura:Slider({
        Name = "Power",
        Flag = "ProjectileAuraPower",
        Min = 1,
        Max = 70,
        Default = 50,
        CallingFunction = function(self, value: number)
            ProjectileAura.Settings.Power = value
        end
    })

    ProjAura:Slider({
        Name = "Delay",
        Flag = "ProjectileAuraDelay",
        Min = 0.3,
        Max = 5,
        Default = 0.1,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            ProjectileAura.Settings.Delay = value
        end
    })

    ProjAura:MiniToggle({
        Name = "Players Only",
        Flag = "ProjectileAuraPlayersOnly",
        Default = true,
        CallingFunction = function(self, value: boolean)
            ProjectileAura.Settings.PlayersOnly = value
        end
    })

    ProjAura:MiniToggle({
        Name = "Wall Check",
        Flag = "ProjectileAuraWallCheck",
        Default = true,
        CallingFunction = function(self, value: boolean)
            ProjectileAura.Settings.WallCheck = value
        end
    })

    ProjAura:MiniToggle({
        Name = "Teleport",
        Flag = "ProjectileAuraTeleport",
        CallingFunction = function(self, value: boolean)
            ProjectileAura.Settings.TP = value
        end
    })
end)();

(function()
    local Speed: number = 80
    local Time: number = 1.5
    local StartTime: number = 0
    local Height: number = 12
    local UseBoost: boolean = false

    local LongJump = Windows.Movement:CreateModule({
        Name = "Long Jump",
        Flag = "LongJump",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                if not Night:IsAlive(LocalPlayer) then
                    task.delay(0.1, self.SetValue, self, false)
                    return
                end

                local Fly = Windows.Movement.Modules.Fly
                if Fly.Enabled then
                    Fly:SetValue(false)
                end

                local FireBall = GetItem("fireball")
                local CanLongJump: boolean = false
                local PrimaryPart: BasePart = LocalPlayer.Character.PrimaryPart
                local Humanoid: Humanoid = LocalPlayer.Character.Humanoid

                PrimaryPart.Anchored = true
                if FireBall then
                    local TempCon
                    TempCon = self:Connection(GameData.Events.Damage.Event:Connect(function(Values)
                        if Values.Type.Value == "TNT" and Values.DamagedPlayer == LocalPlayer then
                            CanLongJump = true
                            PrimaryPart.Anchored = false

                            StartTime = os.clock()
                            TempCon:Disconnect()                            
                        end
                    end))

                    SwitchItem(FireBall.tool, true)
                    GameData.Utils.Remotes:Get("ProjectileFire"):CallServerAsync(
                        FireBall.tool, FireBall.itemType, FireBall.itemType,
                        PrimaryPart.Position, PrimaryPart.Position, Vector3.new(0, -30, 0),
                        HttpService:GenerateGUID(false),
                        {
                            drawDurationSec = 0,
                            shotId = HttpService:GenerateGUID(false)
                        },
                        workspace:GetServerTimeNow() - 0.325
                    )
                end

                repeat task.wait() until CanLongJump

                local Boosted: boolean = false
                repeat
                    if not Boosted then
                        local RealSpeed: number = Speed
                        if UseBoost then
                            local Multiplier: number = GetSpeedMultiplier()
                            if Multiplier ~= 0 then
                                RealSpeed *= Multiplier
                            end
                        end

                        PrimaryPart.AssemblyLinearVelocity = Vector3.new(Humanoid.MoveDirection.X * RealSpeed, Height, Humanoid.MoveDirection.Z * RealSpeed)      
                    end
                    
                    Boosted = not Boosted
                    task.wait()
                until not self.Enabled or (os.clock() - StartTime) >= Time

                self:SetValue(false)
            else
                if Night:IsAlive(LocalPlayer) then
                    LocalPlayer.Character.PrimaryPart.Anchored = false
                end
            end
        end
    })

    LongJump:Slider({
        Name = "Speed",
        Flag = "LongJumpSpeed",
        Min = 40,
        Max = 120,
        Default = 100,
        CallingFunction = function(self, value: number)
            Speed = value
        end
    })

    LongJump:Slider({
        Name = "Time",
        Flag = "LongJumpTime",
        Min = 0.1,
        Max = 2,
        Default = 1.5,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            Time = value
        end
    })

    LongJump:Slider({
        Name = "Height",
        Flag = "LongJumpHeight",
        Min = 5,
        Max = 20,
        Default = 15,
        CallingFunction = function(self, value: number)
            Height = value
        end
    })

    LongJump:MiniToggle({
        Name = "Consumable Boost",
        Flag = "LongJumpConsumableBoost",
        Default = true,
        CallingFunction = function(self, value: boolean)
            UseBoost = value
        end
    })
end)();

(function()
    local Studs = 5
    local HoldingKeybind = false

    local Param = RaycastParams.new()
    Param.FilterType = Enum.RaycastFilterType.Exclude

    local Phase = Windows.Movement:CreateModule({
        Name = "Phase",
        Flag = "Phase",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                self:Connection(RunService.PreSimulation:Connect(function()
                    if Night:IsAlive(LocalPlayer) and isnetworkowner(LocalPlayer.Character.PrimaryPart) and HoldingKeybind then
                        local PrimaryPart: BasePart = LocalPlayer.Character.PrimaryPart
                        local Humanoid: Humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")

                        Param.FilterDescendantsInstances = CollectionService:GetTagged("entity")
                        local Ray: RaycastResult? = workspace:Raycast(PrimaryPart.Position, Humanoid.MoveDirection * 3, Param)
                        if Ray then
                            PrimaryPart.CFrame = CFrame.new(PrimaryPart.Position + (Humanoid.MoveDirection * Studs))
                        end
                    end
                end))
            end
        end
    })

    Phase:KeyBind({
        Name = "Phase Bind",
        MobileText = "Use Phase",
        Flag = "PhaseActualBind",
        DestroyMobileButtonOnDisable = true,
        Default = Enum.KeyCode.LeftAlt,
        Events = {
            Began = function()
                HoldingKeybind = true
            end,
            Ended = function()
                HoldingKeybind = false
            end
        }
    })

    Phase:Slider({
        Name = "TP Studs",
        Flag = "PhaseStuds",
        Min = 1,
        Max = 10,
        Default = 3,
        CallingFunction = function(self, value: number)
            Studs = value
        end
    })
end)();

(function()
    local Distance: number = 18
    local Delay: number = 0
    local SelectedUpgrades = {}
    local UICheck: boolean = false

    local AutoUpgrade = Windows.Utility:CreateModule({
        Name = "Auto Upgrade",
        Flag = "AutoUpgrade",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                repeat
                    if UICheck and not GameData.Utils.App:isAppOpen(GameData.Utils.AppIds.TEAM_UPGRADE) then
                        task.wait()
                        continue
                    end

                    local Diamonds = GetItem("diamond")
                    local TeamUpgradeShop = GetNearestTeamUpgradeShop()

                    if Diamonds and TeamUpgradeShop.Shop and Distance >= TeamUpgradeShop.Distance then
                        for i,v in SelectedUpgrades do
                            local Id: string, Item = GetUpgradeFromName(v)
                            if Id and Item then
                                local Current = GameData.Utils.TeamUpgradesController.currentUpgrades[Id]
                                local NextUpgrade = 1

                                if Current then
                                    NextUpgrade = (Current + 1)
                                end

                                local NextTier = Item.tiers[NextUpgrade]
                                if NextTier and Diamonds.amount >= NextTier.cost then
                                    GameData.Utils.TeamUpgradesController:requestPurchaseTeamUpgrade(Id)

                                    if Delay ~= 0 then
                                        task.wait(Delay)
                                    end
                                end
                            end
                        end
                    end
                    task.wait()
                until not self.Enabled
            end
        end
    })

    local Upgrades = {}
    for i,v in GameData.Utils.TeamUpgradeMeta do
        table.insert(Upgrades, v.name)
    end

    AutoUpgrade:Dropdown({
        Name = "Upgrades",
        Flag = "AutoUpgradeUpgrades",
        Default = {"Damage", "Armor"},
        Options = Upgrades,
        MaxLimit = math.huge,
        CallingFunction = function(self, value: {string})
            SelectedUpgrades = value
        end
    })

    AutoUpgrade:Slider({
        Name = "Distance",
        Flag = "AutoUpgradeDistance",
        Min = 1,
        Max = 18,
        Default = 18,
        CallingFunction = function(self, value: number)
            Distance = value
        end
    })

    AutoUpgrade:Slider({
        Name = "Delay",
        Flag = "AutoUpgradeDelay",
        Min = 0,
        Max = 5,
        Default = 0,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            Delay = value
        end
    })

    AutoUpgrade:MiniToggle({
        Name = "UI Check",
        Flag = "AutoUpgradeUICheck",
        CallingFunction = function(self, value: boolean)
            UICheck = value
        end
    })
end)();

(function()
    local Distance: number = 18
    local Delay: number = 0
    local UICheck: boolean = false
    local SelectedItems = {}

    local Purchased = {}
    local AutoBuy = Windows.Utility:CreateModule({
        Name = "Auto Buy",
        Flag = "AutoBuy",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                repeat
                    if UICheck and not GameData.Utils.App:isAppOpen(GameData.Utils.AppIds.BEDWARS_ITEM_SHOP) then
                        task.wait()
                        continue
                    end

                    local ItemShop = GetNearestItemShop()
                    if ItemShop.Shop and Distance >= ItemShop.Distance then
                        if table.find(SelectedItems, "Sword") then
                            local NextSword = GetNextSword()
                            if NextSword then
                                local Currency = GetItem(NextSword.currency)
                                if Currency and Currency.amount >= NextSword.price and (not Purchased[NextSword.itemType] or (os.clock() - Purchased[NextSword.itemType]) > 5) then
                                    Purchased[NextSword.itemType] = os.clock()
                                    GameData.Utils.Remotes:Get("BedwarsPurchaseItem"):CallServerAsync({
                                        shopItem = NextSword,
                                        shopId = ItemShop.Id
                                    })
                                    
                                    task.wait(0.1 + Delay)
                                end
                            end
                        end

                        if table.find(SelectedItems, "Armor") then
                            local NextArmor = GetNextArmor()
                            if NextArmor then
                                local Currency = GetItem(NextArmor.currency)
                                if Currency and Currency.amount >= NextArmor.price and (not Purchased[NextArmor.itemType] or (os.clock() - Purchased[NextArmor.itemType]) > 5) then
                                    Purchased[NextArmor.itemType] = os.clock()
                                    GameData.Utils.Remotes:Get("BedwarsPurchaseItem"):CallServerAsync({
                                        shopItem = NextArmor,
                                        shopId = ItemShop.Id
                                    })

                                    task.wait(0.1 + Delay)
                                end
                            end
                        end

                    end
                    task.wait()
                until not self.Enabled
            end
        end
    })

    AutoBuy:Dropdown({
        Name = "Items",
        Flag = "AutoBuyItems",
        Default = {"Sword", "Armor"},
        Options = {"Sword", "Armor"},
        MaxLimit = math.huge,
        CallingFunction = function(self, value: {string})
            SelectedItems = value
        end
    })

    AutoBuy:Slider({
        Name = "Distance",
        Flag = "AutoBuyDistance",
        Min = 1,
        Max = 18,
        Default = 18,
        CallingFunction = function(self, value: number)
            Distance = value
        end
    })

    AutoBuy:Slider({
        Name = "Delay",
        Flag = "AutoBuyDelay",
        Min = 0,
        Max = 5,
        Default = 0,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            Delay = value
        end
    })

    AutoBuy:MiniToggle({
        Name = "UI Check",
        Flag = "AutoBuyUICheck",
        CallingFunction = function(self, value: boolean)
            UICheck = value
        end
    })
end)();

(function()
    local Distance: number = 18
    local Delay: number = 0
    local Collected = {}

    local PickupRange = Windows.Utility:CreateModule({
        Name = "Pickup Range",
        Flag = "PickupRange",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                repeat
                    local ItemDrop = GetNearestItemDrop(Collected)
                    if ItemDrop.Item and Distance >= ItemDrop.Distance then
                        GameData.Utils.Remotes:Get("PickupItemDrop"):CallServerAsync({
                            itemDrop = ItemDrop.Item
                        })

                        local StoreIndex: number = #Collected + 1
                        table.insert(Collected, StoreIndex, ItemDrop.Item)
                        task.delay(1.2, table.remove, Collected, StoreIndex)

                        if Delay ~= 0 then
                            task.wait(Delay)
                        end
                    end
                    task.wait()
                until not self.Enabled
            end
        end
    })

    PickupRange:Slider({
        Name = "Distance",
        Flag = "PickupRangeDistance",
        Min = 1,
        Max = 10,
        Default = 10,
        CallingFunction = function(self, value: number)
            Distance = value
        end
    })

    PickupRange:Slider({
        Name = "Delay",
        Flag = "PickupRangeDelay",
        Min = 0,
        Max = 5,
        Default = 0.1,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            Delay = value
        end
    })
end)();

(function()
    local AntiHitData = {
        Settings = {
            Distance = 20,
            Height = 100,
            StayUp = 0.25,
            PlayersOnly = false,
            WaitUntilDamage = false
        },
        Data = {
            Target = nil,
            OldPos = nil,
            GoUp = true,
            CanTeleport = false,
            Clone = nil
        }
    }

    local AntiHit = Windows.Combat:CreateModule({
        Name = "Anti Hit",
        Flag = "AntiHit",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                self:Connection(GameData.Events.Damage.Event:Connect(function(Data)
                    if AntiHitData.Data.Target and Data.Damaged == AntiHitData.Data.Target then
                        AntiHitData.Data.CanTeleport = true
                        task.delay(0.05, function()
                            AntiHitData.Data.CanTeleport = false
                        end)
                    end
                end))

                self:Connection(RunService.PreRender:Connect(function()
                    if AntiHitData.Data.Clone and Night:IsAlive(LocalPlayer) then
                        local RealClone: BasePart = AntiHitData.Data.Clone.Clone
                        local OldRoot: BasePart = AntiHitData.Data.Clone.PrimaryPart

                        RealClone.CFrame = CFrame.lookAlong(Vector3.new(OldRoot.Position.X, RealClone.Position.Y, OldRoot.Position.Z), OldRoot.CFrame.LookVector)
                        if LocalPlayer.Character.Humanoid:GetState() == Enum.HumanoidStateType.Jumping then
                            RealClone.AssemblyLinearVelocity = Vector3.new(RealClone.AssemblyLinearVelocity.X, OldRoot.AssemblyLinearVelocity.Y, RealClone.AssemblyLinearVelocity.Z)
                        end
                    end
                end))

                repeat
                    local NearestEntity = GetNearestEntity(true)
                    local Fly = Windows.Movement.Modules.Fly
                    local LongJump = Windows.Movement.Modules.LongJump
                    
                    if Fly.Enabled or LongJump.Enabled then
                        task.wait()
                        continue
                    end

                    if Night:IsAlive(LocalPlayer) and NearestEntity.Entity and AntiHitData.Settings.Distance >= NearestEntity.Distance and (AntiHitData.Settings.PlayersOnly and NearestEntity.Data.Player or not AntiHitData.Settings.PlayersOnly) then
                        if not AntiHitData.Data.Clone then
                            AntiHitData.Data.Clone = MakeClone()
                        end

                        local PrimaryPart: BasePart = AntiHitData.Data.Clone.PrimaryPart --LocalPlayer.Character.PrimaryPart
                        AntiHitData.Data.Target = NearestEntity.Entity                        
                        repeat 
                            local NewEntity =  GetNearestEntity(true)
                            if NewEntity.Distance > AntiHitData.Settings.Distance or (AntiHitData.Settings.PlayersOnly and not NearestEntity.Data.Player) then
                                break
                            end
                            task.wait() 
                        until AntiHitData.Data.CanTeleport or not AntiHitData.Settings.WaitUntilDamage
                        
                        if self.Enabled and AntiHitData.Data.Clone and Night:IsAlive(LocalPlayer) and isnetworkowner(LocalPlayer.Character.PrimaryPart) then
                            if AntiHitData.Settings.StayUp then
                                PrimaryPart.CFrame = AntiHitData.Data.Clone.Clone.CFrame + Vector3.new(0, AntiHitData.Settings.Height, 0)
                                task.wait(AntiHitData.Settings.StayUp)
                                PrimaryPart.CFrame = AntiHitData.Data.Clone.Clone.CFrame
                            else
                                PrimaryPart.CFrame = AntiHitData.Data.Clone.Clone.CFrame - Vector3.new(0, AntiHitData.Settings.Height / 2, 0)
                                task.wait(AntiHitData.Settings.StayUp)
                                PrimaryPart.CFrame = AntiHitData.Data.Clone.Clone.CFrame
                            end

                            AntiHitData.Data.GoUp = not AntiHitData.Data.GoUp
                        end
                    else
                        AntiHitData.Data.Target = nil
                        if AntiHitData.Data.Clone then
                            AntiHitData.Data.Clone:Destroy()
                        end

                        AntiHitData.Data.Clone = nil
                    end
                    task.wait()
                until not self.Enabled
            else
                AntiHitData.Data.Target = nil
                local NewCF: CFrame
                if AntiHitData.Data.Clone then
                    NewCF = AntiHitData.Data.Clone.Clone.CFrame
                    AntiHitData.Data.Clone:Destroy()
                end

                AntiHitData.Data.Clone = nil
                if NewCF and Night:IsAlive(LocalPlayer) then
                    LocalPlayer.Character.PrimaryPart.CFrame = NewCF
                end
            end
        end
    })

    AntiHit:Slider({
        Name = "Distance",
        Flag = "AntiHitDistance",
        Min = 1,
        Max = 30,
        Default = 20,
        CallingFunction = function(self, value: number)
            AntiHitData.Settings.Distance = value
        end
    })

    AntiHit:MiniToggle({
        Name = "Players Only",
        Flag = "AntiHitPlayersOnly",
        Default = true,
        CallingFunction = function(self, value: boolean)
            AntiHitData.Settings.PlayersOnly = value
        end
    })

    AntiHit:MiniToggle({
        Name = "Damage Wait",
        Flag = "AntiHitDamageWait",
        Default = true,
        CallingFunction = function(self, value: boolean)
            AntiHitData.Settings.WaitUntilDamage = value
        end
    })

    AntiHit:Slider({
        Name = "Height",
        Flag = "AntiHitHeight",
        Min = 1,
        Max = 200,
        Default = 100,
        CallingFunction = function(self, value: number)
            AntiHitData.Settings.Height = value
        end
    })

    AntiHit:Slider({
        Name = "Stay Up",
        Flag = "AntiHitStayUp",
        Min = 0.1,
        Max = 1,
        Default = 0.25,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            AntiHitData.Settings.StayUp = value
        end
    })
end)();

(function()
    local StaffDetectorData = {
        Settings = {
            Mode = "Uninject",
            Clan = false,
            YouTuber = false,
            Party = false
        },
        Data = {
            Clans = {"VA", "IPS", "TYP", "gg", "Gdoggs", "L8R", "DV"},
            Players = {},
            Friends = {},
            Active = {}
        }
    }
    
    local function CheckGroup(Player, ID)
        return pcall(Player.GetRankInGroup, Player, ID)
    end
    
    local function Notify(Player, Reason)
        local Message = string.format("Staff Detected: %s (%s)", Player.Name, Reason)
        
        if StaffDetectorData.Settings.Mode == "Notify" and Night then
            Night:CreateNotification({
                Title = "Staff Detector",
                Description = Message,
                Duration = 60
            })
        else
            StarterGui:SetCore("SendNotification", {
                Title = "Staff Detector",
                Text = string.format("%s\nUser: %s (ID: %d)", Reason, Player.Name, Player.UserId),
                Duration = 60
            })
        end
        
        if StaffDetectorData.Settings.Party and GameData.Utils.Party then
            GameData.Utils.Party:leaveParty()
        end
        
        if StaffDetectorData.Settings.Mode == "Uninject" and Assets.Functions then
            Assets.Functions:Uninject()
        end
    end

    local function GetFriends(ID)
        if StaffDetectorData.Data.Friends[ID] then return StaffDetectorData.Data.Friends[ID] end
        
        local Success, List = pcall(function()
            local Friends = {}
            local Pages = Players:GetFriendsAsync(ID)
            local PageCount = 0
            
            repeat
                local CurrentPage = Pages:GetCurrentPage()
                for _, FriendData in next, CurrentPage do
                    Friends[FriendData.Id] = FriendData.Username
                end
                
                PageCount += 1
                if not Pages.IsFinished and PageCount < 12 then
                    Pages:AdvanceToNextPageAsync()
                end
            until Pages.IsFinished or PageCount >= 12
            
            return Friends
        end)
        
        if Success then
            StaffDetectorData.Data.Friends[ID] = List
            return List
        end

        return {}
    end
    
    local function FindMutual(Friends)
        for ID, Name in next, Friends do
            if StaffDetectorData.Data.Players[ID] then
                return Name
            end
        end
        return nil
    end
    
    local function CheckSpectator(player)
        if not player:GetAttribute("Spectator") or player:GetAttribute("Team") then
            return false
        end
        
        if GameData.Utils.Store and GameData.Utils.Store:getState().Game.customMatch then
            return false
        end
        
        local Friend: string = FindMutual(GetFriends(player.UserId))
        
        if not Friend then
            Notify(player, "Suspicious spectator join pattern")
            return true
        else
            if StaffDetectorData.Settings.Mode == "Notify" and Night then
                Night:CreateNotification({
                    Title = "Spectator Detector",
                    Description = string.format("Player %s connected via %s", player.Name, Friend),
                    Duration = 15
                })
            end
        end

        return false
    end
    
    local function GroupRankCheck(player)
        local Success, Rank = CheckGroup(player, 5774246)
        return Success and Rank >= (StaffDetectorData.Settings.YouTuber and 20 or 100)
    end
    
    local function ClanCheck(player)
        local ClanTag = player:GetAttribute("ClanTag")
        if not ClanTag then return false end
        
        for _, BannedClan in next, StaffDetectorData.Data.Clans do
            if ClanTag == BannedClan then
                return true
            end
        end

        return false
    end
    
    local function CheckPlayer(player)
        if player == LocalPlayer then return end
        
        StaffDetectorData.Data.Players[player.UserId] = player.Name
        StaffDetectorData.Data.Active[player.UserId] = StaffDetectorData.Data.Active[player.UserId] or {}

        if GroupRankCheck(player) then
            Notify(player, "Verified staff member")
            return
        end

        local SpectatorCon
        SpectatorCon = player:GetAttributeChangedSignal("Spectator"):Connect(function()
            if CheckSpectator(player) then
                SpectatorCon:Disconnect()
                return
            end
        end)

        table.insert(StaffDetectorData.Data.Active[player.UserId], SpectatorCon)
        if CheckSpectator(player) or not StaffDetectorData.Settings.Clan then 
            return 
        end

        local function SeeClan()
            if ClanCheck(player) then
                Notify(player, string.format("Affiliated with restricted clan: %s", player:GetAttribute("ClanTag")))
                if SpectatorCon then
                    SpectatorCon:Disconnect()
                end
            end
        end
        
        if player:GetAttribute("ClanTag") then
            SeeClan()
        else
            local ClanCon = player:GetAttributeChangedSignal("ClanTag"):Connect(SeeClan)
            table.insert(StaffDetectorData.Data.Active[player.UserId], ClanCon)
        end
    end
    
    local function CleanConnection(player)
        if StaffDetectorData.Data.Active[player.UserId] then
            for _, v in next, StaffDetectorData.Data.Active[player.UserId] do
                if v.Connected then
                    v:Disconnect()
                end
            end
            StaffDetectorData.Data.Active[player.UserId] = nil
        end
        
        StaffDetectorData.Data.Players[player.UserId] = nil
        StaffDetectorData.Data.Friends[player.UserId] = nil
    end

    local StaffDetector = Windows.Utility:CreateModule({
        Name = "Staff Detector",
        Flag = "StaffDetector",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                for _, player in next, Players:GetPlayers() do
                    task.defer(CheckPlayer, player)
                end
                
                self:Connection(Players.PlayerAdded:Connect(CheckPlayer))
                self:Connection(Players.PlayerRemoving:Connect(CleanConnection))
            else
                for _, v in next, StaffDetectorData.Data.Active do
                    for _, conn in next, v do
                        if conn.Connected then
                            conn:Disconnect()
                        end
                    end
                end
                
                table.clear(StaffDetectorData.Data.Active)
                table.clear(StaffDetectorData.Data.Players)
                table.clear(StaffDetectorData.Data.Friends)
            end
        end
    })

    StaffDetector:Dropdown({
        Name = "Mode",
        Flag = "StaffDetectorMode",
        Default = "Uninject",
        Options = {"Uninject", "Notify"},
        CallingFunction = function(self, value: string)
            StaffDetectorData.Settings.Mode = value
        end
    })

    StaffDetector:MiniToggle({
        Name = "Clans",
        Flag = "StaffDetectorClans",
        Default = true,
        CallingFunction = function(self, value: boolean)
            StaffDetectorData.Settings.Clan = value
        end
    })

    StaffDetector:MiniToggle({
        Name = "YouTubers",
        Flag = "StaffDetectorYouTubers",
        Default = true,
        CallingFunction = function(self, value: boolean)
            StaffDetectorData.Settings.YouTuber = value
        end
    })

    StaffDetector:MiniToggle({
        Name = "Leave Party",
        Flag = "StaffDetectorParty",
        Default = true,
        CallingFunction = function(self, value: boolean)
            StaffDetectorData.Settings.Party = value
        end
    })
end)();

(function()
    local Restore = {}
    Windows.Utility:CreateModule({
        Name = "Anti AFK",
        Flag = "AntiAFK",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                for i,v in getconnections(LocalPlayer.Idled) do
                    if v.Enabled then
                        v:Disable()
                        table.insert(Restore, v)
                    end
                end

                for i,v in getconnections(RunService.Heartbeat) do
                    if v.Function and typeof(v.Function) == "function" and v.Enabled then
                        local Constants = debug.getconstants(v.Function)
                        if #Constants > 0 and table.find(Constants, "AfkInfo") then
                            v:Disable()
                            table.insert(Restore, v)
                        end
                    end
                end

                GameData.Utils.Remotes:Get("AfkInfo"):SendToServer({
                    afk = false
                })
            else
                for i,v in Restore do
                    v:Enable()
                end

                table.clear(Restore)
            end
        end
    })
end)();

(function()
    local Delay: number = 0
    local Sent: boolean = false

    local AutoQueue = Windows.Utility:CreateModule({
        Name = "Auto Queue",
        Flag = "AutoQueue",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                self:Connection(GameData.Events.Death.Event:Connect(function(Values)  
                    if not Sent and Values.Final and Values.KilledPlayer and Values.KilledPlayer == LocalPlayer then
                        Sent = true
                        task.delay(Delay, GameData.Utils.QueueController.joinQueue, GameData.Utils.QueueController, GameData.Utils.Store:getState().Game.queueType)
                    end
                end))

                self:Connection(GameData.Utils.Remotes:Get("MatchEndEvent"):Connect(function()
                    if not Sent then
                        Sent = true
                        task.delay(Delay, GameData.Utils.QueueController.joinQueue, GameData.Utils.QueueController, GameData.Utils.Store:getState().Game.queueType)
                    end
                end))
            end
        end
    })

    AutoQueue:Slider({
        Name = "Delay",
        Flag = "AutoQueueDelay",
        Min = 0,
        Max = 4,
        Default = 0,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            Delay = value
        end
    })
end)();

(function()
    local Part: Part
    local Color = Color3.fromRGB(255, 0, 0)
    local Transparency: number = 0.5
    local Mode: string = "Velocity"
    local Power: number = 200
    local TweenSpeed: number = 0.2
    local DebounceTime: number = 0.2
    local LastCF: CFrame
    local Debounce: number = 0
    local UseDebounce: boolean = false

    local AntiVoid = Windows.Utility:CreateModule({
        Name = "Anti Void",
        Flag = "AntiVoid",
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                local YLevel: number = math.huge
                local BlockStore = GameData.Utils.BlockEngine:getStore()
                for i,v in BlockStore:getAllBlockPositions() do
                    local Block = BlockStore:getBlockAt(v + Vector3.new(0, 3, 0))
                    if Block and YLevel > v.Y then
                        YLevel = v.Y
                    end
                end

                Part = Instance.new("Part", workspace)
                Part.Position = Vector3.new(0, YLevel, 0)
                Part.Size = Vector3.new(100000, 1, 100000)
                Part.Color = Color
                Part.Anchored = true
                Part.Transparency = Transparency
                Part.Material = Enum.Material.Air
                GameData.Utils.GameQuery:setQueryIgnored(Part)

                self:Connection(Part.Touched:Connect(function(Part: Part)
                    if Night:IsAlive(LocalPlayer) and Part.Parent == LocalPlayer.Character and ((os.clock() - Debounce) >= DebounceTime or not UseDebounce) then
                        local PrimaryPart: BasePart = LocalPlayer.Character.PrimaryPart                        
                        if Mode == "Velocity" then
                            local Current: Vector3 = PrimaryPart.AssemblyLinearVelocity
                            PrimaryPart.AssemblyLinearVelocity = Vector3.new(Current.X, Power, Current.Z)
                        elseif Mode == "Tween" then
                            if LastCF then
                                TweenService:Create(PrimaryPart, TweenInfo.new(TweenSpeed), {CFrame = LastCF}):Play()
                            end
                        end
                    end
                end))

                self:Connection(RunService.PreSimulation:Connect(function()
                    if Night:IsAlive(LocalPlayer) then
                        if LocalPlayer.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
                            LastCF = LocalPlayer.Character.PrimaryPart.CFrame
                        end
                    end
                end))
            else
                if Part then
                    Part:Destroy()
                end
            end
        end
    })

    local PowerSlider, TweenSpeedSlider
    AntiVoid:Dropdown({
        Name = "Mode",
        Flag = "AntiVoidMode",
        Options = {"Velocity", "Tween", "Walk"},
        Default = "Velocity",
        CallingFunction = function(self, value: string)
            Mode = value
            PowerSlider:SetVisiblity(value == "Velocity")
            TweenSpeedSlider:SetVisiblity(value == "Tween")
        end
    })

    local DebounceTimeSlider
    AntiVoid:MiniToggle({
        Name = "Debounce",
        Flag = "AntiVoidDebounce",
        Default = true,
        CallingFunction = function(self, value: boolean)
            UseDebounce = value
            DebounceTimeSlider:SetVisiblity(false)
        end
    })

    DebounceTimeSlider = AntiVoid:Slider({
        Name = "Debounce",
        Flag = "AntiVoidDebounceTime",
        Min = 0,
        Max = 1,
        Default = 0.2,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            DebounceTime = value
        end
    })

    PowerSlider = AntiVoid:Slider({
        Name = "Power",
        Flag = "AntiVoidVelocityPower",
        Min = 50,
        Max = 400,
        Default = 200,
        CallingFunction = function(self, value: number)
            Power = value
        end
    })

    TweenSpeedSlider = AntiVoid:Slider({
        Name = "Speed",
        Flag = "AntiVoidTweenSpeed",
        Min = 0.05,
        Max = 0.5,
        Default = 0.2,
        Increment = 0.01,
        CallingFunction = function(self, value: number)
            TweenSpeed = value
        end
    })

    AntiVoid:Slider({
        Name = "Transparency",
        Flag = "AntiVoidPartTransparency",
        Min = 0,
        Max = 1,
        Default = 0.5,
        Increment = 0.1,
        CallingFunction = function(self, value: number)
            Transparency = value
            if Part then
                Part.Transparency = value
            end
        end
    })

    AntiVoid:ColorSlider({
        Name = "Color",
        Flag = "AntiVoidPartColor",
        Default = Color3.fromRGB(255, 0, 0),
        CallingFunction = function(self, value: Color3)
            Color = value
            if Part then
                Part.Color = value
            end
        end
    })
end)();
