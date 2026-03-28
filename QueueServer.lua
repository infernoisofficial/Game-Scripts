--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Modules
local ZoneModule = require(ReplicatedStorage.Modules.Zone)

--// Objects
local TeleportZones = game.Workspace:WaitForChild("TeleportZones")
local Configuration = TeleportZones.Configuration
local QueueRemote = ReplicatedStorage.Remotes.QueueRemote

--// Data
local ZoneData = {}

--// Functions
function JoinParty(Plr, ZoneContainer, TpZones)
	-- Add player to the list
	table.insert(ZoneData[TpZones]["Players"], Plr)
	QueueRemote:FireClient(Plr, "JoinParty")

	-- Button function
	local PartyUi = Plr.PlayerGui:WaitForChild("PartyUi")
	PartyUi.InParty.LeaveButton.MouseButton1Down:Connect(function()
		LeaveParty(Plr, TpZones)
	end)

	-- Teleport player into zone 🏃‍♂️‍➡️
	local Char = Plr.Character or Plr.CharacterAdded:Wait()
	local RootPart = Char:WaitForChild("HumanoidRootPart")

	if ZoneContainer:IsA("Model") then
		RootPart.CFrame = ZoneContainer:GetPivot()
	else
		RootPart.CFrame = ZoneContainer.CFrame
	end
end

function LeaveParty(Plr, TpZones)
	-- Remove player from the list
	local index = table.find(ZoneData[TpZones]["Players"], Plr)
	if index then
		table.remove(ZoneData[TpZones]["Players"], index)
	end

	QueueRemote:FireClient(Plr, "LeaveParty")

	-- Teleport player out 🏃‍♂️‍➡️
	local Char = Plr.Character or Plr.CharacterAdded:Wait()
	local RootPart = Char:WaitForChild("HumanoidRootPart")
	RootPart.CFrame = TeleportZones.LobbyPos.CFrame
end

--// ➿ Main Loop
for _, TpZones in pairs(TeleportZones:GetChildren()) do
	if TpZones:IsA("Model") then

		ZoneData[TpZones] = {
			["IsReady"] = false,
			["MaxPlayers"] = 0,
			["Players"] = {},
		}

		local ZoneContainer = TpZones:FindFirstChild("ZoneContainer")
		if not ZoneContainer then
			warn("❌ Missing ZoneContainer in:", TpZones.Name)
			continue
		end

		local ZoneParts = {}

		-- 🔹 Case 1: Single Part
		if ZoneContainer:IsA("BasePart") then
			table.insert(ZoneParts, ZoneContainer)

			-- 🔹 Case 2: Model (multi-part zone)
		elseif ZoneContainer:IsA("Model") then
			for _, obj in ipairs(ZoneContainer:GetDescendants()) do
				if obj:IsA("BasePart") then
					table.insert(ZoneParts, obj)
				end
			end
		end

		-- ❌ No valid parts found
		if #ZoneParts == 0 then
			warn("❌ No BaseParts inside ZoneContainer:", TpZones.Name)
			continue
		end

		-- ✅ Create Zone (supports multiple parts)
		local Zone = ZoneModule.new(ZoneParts)

		Zone.playerEntered:Connect(function(Plr)
			JoinParty(Plr, ZoneContainer, TpZones)
		end)
	end
end