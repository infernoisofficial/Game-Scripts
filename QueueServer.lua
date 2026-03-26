--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Modules
local ZoneModule = require(ReplicatedStorage.Modules.Zone)

--// Objects
local TeleportZones = game.Workspace:WaitForChild("TeleportZones")
local Configuration = TeleportZones.Configuration
local QueueRemote = ReplicatedStorage.Remotes.QueueRemote

--// Modules
local ZoneData = {}

function JoinParty(Plr,ZoneContainer,TpZones)
	-- Add player to the lists
	table.insert(ZoneData[TpZones]["Players"],Plr)
	QueueRemote:FireClient(Plr,"JoinParty")
	-- Tp Character into box
	local Char = Plr.Character or Plr.CharacterAdded:Wait()
	local RootPart = Char:WaitForChild("HumanoidRootPart")
	RootPart.CFrame = ZoneContainer.CFrame
end

function LeaveParty(Plr,LobbyPos,TpZones)
	-- Remove player from the lists
	table.remove(ZoneData[TpZones]["Players"],table.find(ZoneData[TpZones]["Players"],Plr)
		-- Tp Character out of box
		local Char = Plr.Character or Plr.CharacterAdded:Wait()
		local RootPart = Char:WaitForChild("HumanoidRootPart")
		RootPart.CFrame = TeleportZones.LobbyPos.CFrame
end

for _, TpZones in pairs(TeleportZones:GetChildren()) do
	if TpZones:IsA("Model") then

		ZoneData[TpZones] = {
			["IsReady"] = false,
			["MaxPlayers"] = 0,
			["Players"] = {},
		}

		local ZoneContainer = TpZones:FindFirstChild("ZoneContainer")
		if not ZoneContainer or not ZoneContainer:IsA("BasePart") then
			continue
		end

		local Zone = ZoneModule.new(ZoneContainer)

		Zone.playerEntered:Connect(function(Plr)
			JoinParty(Plr,ZoneContainer,TpZones)
		end)
	end
end