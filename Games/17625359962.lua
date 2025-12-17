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
local TextChatService: TextChatService = Night.cloneref(game:GetService("TextChatService"))

local LocalPlayer: Player = Players.LocalPlayer
local PlayerGui: PlayerGui = Night.cloneref(LocalPlayer:WaitForChild("PlayerGui"))
local CurrentCamera: Camera = workspace.CurrentCamera

local XRayTable = {
	SliderValue = 0.7,
}

local XRay = Windows.Utility:CreateModule({
	Name = "XRay",
	Flag = "rbxassetid://10734975692",
	CallingFunction = function(self, enabled: boolean)
		if enabled then
			local character = LocalPlayer.Character
			for _, v in pairs(workspace:GetDescendants()) do
				if v:IsA("BasePart")
					and (not character or not v:IsDescendantOf(character)) then
					v.Transparency = XRayTable.SliderValue
				end
			end
		else
			print("disabled")
		end
	end,
})

XRay:Slider({
	Name = "Transparency",
	Flag = "",
	Default = 0,
	Max = 1,
	CallingFunction = function(self, value: number)
		XRayTable.SliderValue = value
		local character = LocalPlayer.Character

		for _, v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart")
				and (not character or not v:IsDescendantOf(character)) then
				v.Transparency = XRayTable.SliderValue
			end
		end
	end,
})
