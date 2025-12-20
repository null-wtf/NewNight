local Night = getgenv().Night
local Windows = Night.UIData

--// Services (CACHED)
local Players = Night.cloneref(game:GetService("Players"))
local Lighting = Night.cloneref(game:GetService("Lighting"))
local Workspace = Night.cloneref(game:GetService("Workspace"))
local RunService = game:GetService("RunService")

local attacking = false

local LocalPlayer = Players.LocalPlayer
local PlayerGui = Night.cloneref(LocalPlayer:WaitForChild("PlayerGui"))
local character = LocalPlayer.Character
local hrp = character:WaitForChild("HumanoidRootPart")

--------------------------------------------------
-- Utility
--------------------------------------------------

local function Warning(Title: string, Description: string, Duration: number)
	pcall(function()
		setthreadidentity(8)
	end)

	Night:CreateNotification({
		Title = Title,
		Description = Description,
		Duration = Duration
	})
end

local function IsPartOfAnyCharacter(part: Instance): boolean
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and part:IsDescendantOf(char) then
			return true
		end
	end
	return false
end

function GetNearestPlayer()
	local character = LocalPlayer.Character
	if not character then return nil end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local nearestPlayer = nil
	local nearestDistance = math.huge
	local nearestHRP = nil

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			if char then
				local targetHRP = char:FindFirstChild("HumanoidRootPart")
				local humanoid = char:FindFirstChildOfClass("Humanoid")

				if targetHRP and humanoid and humanoid.Health > 0 then
					local distance = (targetHRP.Position - hrp.Position).Magnitude
					if distance < nearestDistance then
						nearestDistance = distance
						nearestPlayer = player
						nearestHRP = targetHRP
					end
				end
			end
		end
	end

	return nearestPlayer
end


--------------------------------------------------
-- Load on execute
--------------------------------------------------
Warning("AntiCheat", "Rival's anticheat is currently active, don't use blatant configurations until an bypass is created!", 4)

--------------------------------------------------
-- XRay
--------------------------------------------------

local XRayData = {
	Enabled = false,
	Value = 0.7,
	Original = {}
}

local function ApplyXRay(part)
	if not part:IsA("BasePart") then return end
	if IsPartOfAnyCharacter(part) then return end

	if XRayData.Original[part] == nil then
		XRayData.Original[part] = part.Transparency
	end

	part.Transparency = XRayData.Value
end

local function RestoreXRay()
	for part, trans in pairs(XRayData.Original) do
		if part and part.Parent then
			part.Transparency = trans
		end
	end
	table.clear(XRayData.Original)
end

local XRay = Windows.Utility:CreateModule({
	Name = "XRay",
	Flag = "",
	CallingFunction = function(self, enabled)
		XRayData.Enabled = enabled

		if enabled then
			for _, v in ipairs(Workspace:GetDescendants()) do
				ApplyXRay(v)
			end
		else
			RestoreXRay()
		end
	end,
})

XRay:Slider({
	Name = "Transparency",
	Flag = "",
	Default = 0,
	Max = 1,
	CallingFunction = function(self, value)
		XRayData.Value = value
		if not XRayData.Enabled then return end
		for part in pairs(XRayData.Original) do
			if part and part.Parent then
				part.Transparency = value
			end
		end
	end,
})

Workspace.DescendantAdded:Connect(function(v)
	if XRayData.Enabled then
		ApplyXRay(v)
	end
end)

--------------------------------------------------
-- Hitbox Alterator
--------------------------------------------------

local Hitbox = {
	Enabled = false,
	Size = Vector3.new(6,6,6),
	Original = {}
}

local function ApplyHitbox(part)
	if not part:IsA("BasePart") then return end
	if not string.find(part.Name:lower(), "hitbox") then return end

	if Hitbox.Original[part] == nil then
		Hitbox.Original[part] = part.Size
	end

	part.Size = Hitbox.Size
end

local function RestoreHitboxes()
	for part, size in pairs(Hitbox.Original) do
		if part and part.Parent then
			part.Size = size
		end
	end
	table.clear(Hitbox.Original)
end

local HitboxAlterator = Windows.Combat:CreateModule({
	Name = "Hitbox Alterator",
	Flag = "",
	CallingFunction = function(self, enabled)
		Hitbox.Enabled = enabled

		if enabled then
			for _, v in ipairs(Workspace:GetDescendants()) do
				ApplyHitbox(v)
			end
		else
			RestoreHitboxes()
		end
	end,
})

HitboxAlterator:Slider({
	Name = "Hitbox Size",
	Flag = "",
	Default = 6,
	Max = 50,
	CallingFunction = function(self, value)
		Hitbox.Size = Vector3.new(value, value, value)
		if not Hitbox.Enabled then return end
		for part in pairs(Hitbox.Original) do
			if part and part.Parent then
				part.Size = Hitbox.Size
			end
		end
	end,
})

Workspace.DescendantAdded:Connect(function(v)
	if Hitbox.Enabled then
		ApplyHitbox(v)
	end
end)

--------------------------------------------------
-- AntiParticle 
--------------------------------------------------

local AntiParticle = {
	Enabled = false,
	Smoke = true,
	Flash = true
}

local function HandleParticle(v)
	if not AntiParticle.Enabled then return end

	if AntiParticle.Flash and string.find(v.Name, "Flash") then
		pcall(function() v:Destroy() end)
	end

	if AntiParticle.Smoke and string.find(v.Name, "Smoke") then
		pcall(function() v:Destroy() end)
	end
end

local AntiParticleModule = Windows.Render:CreateModule({
	Name = "AntiParticle",
	Flag = "",
	CallingFunction = function(self, enabled)
		AntiParticle.Enabled = enabled

		if enabled then
			for _, v in ipairs(Lighting:GetDescendants()) do
				HandleParticle(v)
			end
			for _, v in ipairs(Workspace:GetDescendants()) do
				HandleParticle(v)
			end
			for _, v in ipairs(PlayerGui:GetDescendants()) do
				HandleParticle(v)
			end
		end
	end,
})

AntiParticleModule:MiniToggle({
	Name = "Smoke",
	Default = true,
	Flag = "",
	CallingFunction = function(self, value)
		AntiParticle.Smoke = value
	end,
})

AntiParticleModule:MiniToggle({
	Name = "Flashbang",
	Flag = "",
	Default = true,
	CallingFunction = function(self, value)
		AntiParticle.Flash = value
	end,
})

Lighting.DescendantAdded:Connect(HandleParticle)
Workspace.DescendantAdded:Connect(HandleParticle)
PlayerGui.DescendantAdded:Connect(HandleParticle)

--------------------------------------------------
-- Staff Detector
--------------------------------------------------

local StaffDetectorTable = {
	Enabled = false,
	Options = {
		Kick = function()
			LocalPlayer:Kick("Staff detector went off!")
		end,
	},
	GroupID = 3461453,
	SelectedRank = "Community Staff",
	SelectedOption = "Kick"
}

local StaffDetector = Windows.Utility:CreateModule({
	Name = "Staff Detector",
	Flag = "",
	CallingFunction = function(self, enabled: boolean)
		StaffDetectorTable.Enabled = enabled
	end,
})

StaffDetector:Dropdown({
	Name = "Respond Option",
	Flag = "",
	Default = {"Kick"},
	Options = {"Kick"},
	MaxLimit = 1,
	MinLimit = 1,
	CallingFunction = function(self, value)
		StaffDetectorTable.SelectedOption = value[1]
	end,
})

StaffDetector:Dropdown({
	Name = "Rank",
	Flag = "",
	Default = {"Community Staff"},
	Options = {"Community Staff", "Tester", "Moderator", "Contributor", "Scripter", "Builder"},
	MaxLimit = 1,
	MinLimit = 1,
	CallingFunction = function(self, value)
		StaffDetectorTable.SelectedRank = value[1]
	end,
})

Players.PlayerAdded:Connect(function(plr)
	if not StaffDetectorTable.Enabled then return end
	if not StaffDetectorTable.GroupID then return end

	print("Qualified for staff detection")

	if plr:GetRoleInGroup(StaffDetectorTable.GroupID) == StaffDetectorTable.SelectedRank then
		local action = StaffDetectorTable.Options[StaffDetectorTable.SelectedOption]
		if action then
			action()
		end
	end
end)

--------------------------------------------------
-- Anticheat Bypass
--------------------------------------------------
local anticheatSignals = {
	hrp.Changed,
	hrp:GetPropertyChangedSignal("CFrame"),
	hrp:GetPropertyChangedSignal("Position"),
	hrp:GetPropertyChangedSignal("Velocity"),
	hrp:GetPropertyChangedSignal("Anchored"),
}

local ACBypassTable = {
	Enabled = false,
	BypassMethod = "",
}

-- STORAGE
local DisabledConnections = {}
local HookedFunctions = {}

local anticheatSignals = {
	hrp.Changed,
	hrp:GetPropertyChangedSignal("CFrame"),
	hrp:GetPropertyChangedSignal("Position"),
	hrp:GetPropertyChangedSignal("Velocity"),
	hrp:GetPropertyChangedSignal("Anchored"),
}

function anticooker(state, bypassvers)
	-- ENABLE
	if state == true then
		if ACBypassTable.Enabled then return end
		ACBypassTable.Enabled = true
		ACBypassTable.BypassMethod = bypassvers

		-- =====================
		-- UNIVERSAL METHOD
		-- =====================
		if bypassvers == "Universal" then
			for _, signal in ipairs(anticheatSignals) do
				for _, connection in ipairs(getconnections(signal)) do
					if connection.Enabled then
						connection:Disable()
						table.insert(DisabledConnections, connection)
					end
				end
			end

			print("HumanoidRootPart change signals disabled.")

			-- =====================
			-- OLD BYPASS METHOD
			-- =====================
		elseif bypassvers == "old bypass" then
			local function hookSignal(signalName)
				for _, v in ipairs(getconnections(hrp:GetPropertyChangedSignal(signalName))) do
					if v.Function then
						local oldFunc
						oldFunc = hookfunction(v.Function, function(...)
							print("Disabler took actions! (" .. signalName .. " signal)")
							return
						end)

						table.insert(HookedFunctions, {
							Connection = v,
							Original = oldFunc
						})
					end
				end
			end

			hookSignal("CFrame")
			hookSignal("Velocity")
		end

		-- DISABLE / REVERSE
	elseif state == false then
		if not ACBypassTable.Enabled then return end

		-- Re-enable disabled connections
		for _, connection in ipairs(DisabledConnections) do
			if connection.Enable then
				connection:Enable()
			end
		end
		table.clear(DisabledConnections)

		-- Restore hooked functions
		for _, hookData in ipairs(HookedFunctions) do
			if hookData.Connection and hookData.Original then
				hookfunction(hookData.Connection.Function, hookData.Original)
			end
		end
		table.clear(HookedFunctions)

		ACBypassTable.Enabled = false
		ACBypassTable.BypassMethod = ""

		print("HumanoidRootPart change signals restored.")
	end
end


local ACBypass = Windows.Utility:CreateModule({
	Name = "Anticheat Bypass",
	Flag = "",
	CallingFunction = function(self, enabled: boolean)
		ACBypassTable.Enabled = enabled
		if enabled then
			anticooker(true, ACBypassTable.BypassMethod)
		else
			anticooker(false)
		end
	end,
})

ACBypass:Dropdown({
	Name = "Method",
	Flag = "",
	Default = {"Universal"},
	Options = {"Universal", "Old-Bypass"},
	MaxLimit = 1,
	MinLimit = 1,
	CallingFunction = function(self, value)
		ACBypassTable.BypassMethod = value
	end,
})

--------------------------------------------------
-- Auto Win
--------------------------------------------------

local auto_win_table = {
	Enabled = false
}

local lastClick = 0
local clickDelay = 0.15

RunService.Heartbeat:Connect(function()
	if auto_win_table.Enabled then
		local player = GetNearestPlayer()
		if player then
			local character = player.Character
			if character then
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
				local humanoid = character:FindFirstChildOfClass("Humanoid")

				if humanoidRootPart and humanoid and humanoid.Health > 0 then
					hrp.CFrame = humanoidRootPart.CFrame * CFrame.new(0, 0, -2)

					if tick() - lastClick >= clickDelay then
						mouse1click()
						lastClick = tick()
					end
				end
			end
		end
	end
end)


local autowin = Windows.Combat:CreateModule({
	Name = "Auto Win",
	Flag = "",
	CallingFunction = function(self, enabled: boolean)
		auto_win_table.Enabled = enabled
	end,
})

--------------------------------------------------
-- ESP
--------------------------------------------------

Windows.Render.Modules.UniversalESP:Destroy()

local Players = game:GetService("Players")

local ESPTable = {
	enabled = false
}

local function addESP(character)
	if not character:FindFirstChild("NightESP") then
		local highlight = Instance.new("Highlight")
		highlight.Name = "NightESP"
		highlight.Parent = character
	end
end

local function removeESP(character)
	local esp = character:FindFirstChild("NightESP")
	if esp then
		esp:Destroy()
	end
end

local function ESPUpdate()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		if character then
			if ESPTable.enabled then
				addESP(character)
			else
				removeESP(character)
			end
		end
	end
end

local function hookPlayer(player)
	player.CharacterAdded:Connect(function(character)
		if ESPTable.enabled then
			addESP(character)
		end
	end)

	player.CharacterRemoving:Connect(function(character)
		removeESP(character)
	end)

	if player.Character and ESPTable.enabled then
		addESP(player.Character)
	end
end

for _, player in ipairs(Players:GetPlayers()) do
	hookPlayer(player)
end

Players.PlayerAdded:Connect(hookPlayer)

local ESP = Windows.Render:CreateModule({
	Name = "ESP",
	Flag = "",
	CallingFunction = function(self, enabled: boolean)
		ESPTable.enabled = enabled
		ESPUpdate()
	end,
})
