--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Variables
local ZoneModule = require(ReplicatedStorage.Modules.Zone)

--// Objects
local TeleportZones = game.Workspace:WaitForChild("TeleportZones")
local Configuration = TeleportZones.Configuration

function JoinParty(Plr,ZoneContainer)
	local Char = Plr.Character or Plr.CharacterAdded:Wait()
	local RootPart = Char:WaitForChild("HumanoidRootPart")
	RootPart.CFrame = ZoneContainer.CFrame
end

function LeaveParty()
	
end

for _, TpZones in pairs(TeleportZones:GetChildren()) do
	if TpZones:IsA("Model") then

		local ZoneContainer = TpZones:FindFirstChild("ZoneContainer")
		if not ZoneContainer or not ZoneContainer:IsA("BasePart") then
			continue
		end

		local Zone = ZoneModule.new(ZoneContainer)

		Zone.playerEntered:Connect(function(Plr)
			JoinParty(Plr,ZoneContainer)
		end)
	end
end