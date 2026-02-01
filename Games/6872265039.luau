local Night = getgenv().Night
local Windows = Night.UIData

local Players: Players = Night.cloneref(game:GetService("Players"))
local ReplicatedStorage: ReplicatedStorage = Night.cloneref(game:GetService("ReplicatedStorage"))
local LocalPlayer: Player = Players.LocalPlayer

local Knit = require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"].knit.src).KnitClient
local Flamework = require(ReplicatedStorage.rbxts_include.node_modules["@flamework"].core.out).Flamework

repeat task.wait() until Knit and Knit.Controllers and debug.getupvalue(Knit.Start, 1)

local GameData = {
    Utils = {
        App = Flamework.resolveDependency("@easy-games/game-core:client/controllers/app-controller@AppController"),
        MatchHistroyApp = require(LocalPlayer.PlayerScripts.TS.controllers.global["match-history"].ui["match-history-moderation-app"]).MatchHistoryModerationApp,
        MatchHistroyController = Knit.Controllers.MatchHistoryController
    }
}

(function()
    -- pls stop skidding ts :rage:
    Windows.Utility:CreateModule({
        Name = "Match History",
        Flag = "MatchHistroy",
        Button = true,
        CallingFunction = function(self, enabled: boolean)
            if enabled then
                GameData.Utils.MatchHistroyController:requestMatchHistory(LocalPlayer.Name):andThen(function(Data)
                    if Data then
                        GameData.Utils.App:openApp({
                            app = GameData.Utils.MatchHistroyApp,
                            appId = "MatchHistoryApp",
                        }, Data)
                    end
                end)
            end
        end
    })
end)();