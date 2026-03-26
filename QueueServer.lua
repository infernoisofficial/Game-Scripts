--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Variables
local ZoneModule = require(ReplicatedStorage.Modules.Zone)

--// Objects
local TeleportZones = game.Workspace:WaitForChild("TeleportZones")
local Configuration = TeleportZones.Configuration

for _, TpZones in pairs(TeleportZones:GetChildren()) do
	if TpZones:IsA("Model") then

		local ZoneContainer = TpZones:FindFirstChild("ZoneContainer")
		if not ZoneContainer or not ZoneContainer:IsA("BasePart") then
			continue
		end

		local Zone = ZoneModule.new(ZoneContainer)

		Zone.playerEntered:Connect(function(Plr)
			local Char = Plr.Character or Plr.CharacterAdded:Wait()
			local RootPart = Char:WaitForChild("HumanoidRootPart")

			RootPart.CFrame = ZoneContainer.CFrame
		end)

		Zone.playerExited:Connect(function(Plr)
			-- optional (kept empty like your working version)
		end)
	end
end