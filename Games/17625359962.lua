local Night = getgenv().Night
local Windows = Night.UIData

--// Services (CACHED)
local Players = Night.cloneref(game:GetService("Players"))
local Lighting = Night.cloneref(game:GetService("Lighting"))
local Workspace = Night.cloneref(game:GetService("Workspace"))

local LocalPlayer = Players.LocalPlayer
local PlayerGui = Night.cloneref(LocalPlayer:WaitForChild("PlayerGui"))

--------------------------------------------------
-- Load on execute
--------------------------------------------------
Night:CreateNotification({
	Title = "Anticheat",
	Description = "Do not use blatant configs due to Rival's anticheat. An bypass will be dropped soon.",
	Duration = 5
})



--------------------------------------------------
-- Utility
--------------------------------------------------

local function IsPartOfAnyCharacter(part: Instance): boolean
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and part:IsDescendantOf(char) then
			return true
		end
	end
	return false
end

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
