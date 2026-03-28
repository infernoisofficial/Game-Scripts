--// Services
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Modules
local ZoneModule = require(ReplicatedStorage.Modules.Zone)
local SafeTeleport = require(ReplicatedStorage.Modules.SafeTeleport)

--// Objects
local TeleportZones = game.Workspace:WaitForChild("TeleportZones")
local Configuration = TeleportZones.Configuration
local QueueRemote = ReplicatedStorage.Remotes.QueueRemote

--// Variables
local ZoneData = {}
local PlrConnections = {}
local PlaceId = 117497893009667

function SafeDisconnect(conn)
	if conn and conn.Connected then
		conn:Disconnect()
	end
end

function CreateParty(Plr, TpZones, MaxPlayer)
	SafeDisconnect(PlrConnections[Plr]["Create"])
	SafeDisconnect(PlrConnections[Plr]["IncreasePlayer"])
	SafeDisconnect(PlrConnections[Plr]["DecreasePlayer"])
	ZoneData[TpZones]["IsReady"] = true
	ZoneData[TpZones]["MaxPlayers"] = MaxPlayer
	TpZones.BillboardGui.PlayerCount.Text = #ZoneData[TpZones]["Players"].."/"..ZoneData[TpZones]["MaxPlayers"]
	spawn(function()
		for i = 1, Configuration.Countdown.Value do 
			if ZoneData[TpZones]["IsReady"] == false then return end
			TpZones.BillboardGui.StateLabel.Text = "Starting in "..(Configuration.Countdown.Value-i)
			task.wait(1)
		end

		if ZoneData[TpZones]["IsReady"] == false then return end 

		local TeleportOptions = Instance.new("TeleportOptions")
		TeleportOptions.ShouldReserveServer = false

		-- 🔥 THIS IS THE IMPORTANT PART
		local PlayersToTeleport = table.clone(ZoneData[TpZones]["Players"])

		if #PlayersToTeleport == 0 then
			warn("No players to teleport!")
			return
		end

		local success, err = pcall(function()
			TeleportService:TeleportAsync(PlaceId, PlayersToTeleport, TeleportOptions)
		end)

		if not success then
			warn("Teleport failed:", err)
		end
	end)
end
--// Functions
function JoinParty(Plr, ZoneContainer, TpZones, IsHost)
	-- Add player to the list
	table.insert(ZoneData[TpZones]["Players"], Plr)
	TpZones.BillboardGui.PlayerCount.Text = #ZoneData[TpZones]["Players"].."/"..ZoneData[TpZones]["MaxPlayers"]
	PlrConnections[Plr] = {}
	local PartyUi = Plr.PlayerGui:WaitForChild("PartyUi")
	if IsHost == true then
		PlrConnections[Plr]["Create"] = PartyUi.Create.Background.CreateButton.MouseButton1Down:Connect(function()
			local MaxPlayer = tonumber(PartyUi.Create.Background.PlayerCount.Frame.TextLabel.Text)
			CreateParty(Plr, TpZones, MaxPlayer)
		end)
		PlrConnections[Plr]["IncreasePlayer"] = PartyUi.Create.Background.PlayerCount.Frame.Add.MouseButton1Down:Connect(function()
			local PlayerText = PartyUi.Create.Background.PlayerCount.Frame.TextLabel
			PlayerText.Text = math.clamp(tonumber(PlayerText.Text)+1, 1, Configuration.HighestPlayer.Value)
		end)
		PlrConnections[Plr]["DecreasePlayer"] = PartyUi.Create.Background.PlayerCount.Frame.Subtract.MouseButton1Down:Connect(function()
			local PlayerText = PartyUi.Create.Background.PlayerCount.Frame.TextLabel
			PlayerText.Text = math.clamp(tonumber(PlayerText.Text)-1, 1, Configuration.HighestPlayer.Value)
		end)
		QueueRemote:FireClient(Plr, "CreateParty")

		-- Kick if not create the room in time ⌛
		spawn(function()
			task.wait(Configuration.TimeBeforeExpires.Value)
			if table.find(ZoneData[TpZones]["Players"], Plr) and ZoneData[TpZones]["IsReady"] == false then
				LeaveParty(Plr, TpZones) -- force leave ❌
			end
		end)
	else
		QueueRemote:FireClient(Plr, "JoinParty")
	end

	-- Button function
	PlrConnections[Plr]["Leave"] = PartyUi.InParty.LeaveButton.MouseButton1Down:Connect(function()
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
	-- disonnect all connections
	if PlrConnections[Plr] then
		SafeDisconnect(PlrConnections[Plr]["Leave"])
		SafeDisconnect(PlrConnections[Plr]["Create"])
		SafeDisconnect(PlrConnections[Plr]["IncreasePlayer"])
		SafeDisconnect(PlrConnections[Plr]["DecreasePlayer"])
	end
	-- remove player from the lists
	local index = table.find(ZoneData[TpZones]["Players"], Plr)
	if ZoneData[TpZones] and index then
		table.remove(ZoneData[TpZones]["Players"], index)
	end
	TpZones.BillboardGui.PlayerCount.Text = #ZoneData[TpZones]["Players"].."/"..ZoneData[TpZones]["MaxPlayers"]
	QueueRemote:FireClient(Plr, "LeaveParty")
	if #ZoneData[TpZones]["Players"] == 0 then --last player leave
		ZoneData[TpZones] = {
			["IsReady"] = false,
			["MaxPlayers"] = 0,
			["Players"] = {},
		}
		TpZones.BillboardGui.PlayerCount.Text = "0/4"
		TpZones.BillboardGui.StateLabel.Text = "Waiting for players..."
	end

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
			if #ZoneData[TpZones]["Players"] == 0 then
				JoinParty(Plr, ZoneContainer, TpZones, true) -- Join as a host
			end
			if #ZoneData[TpZones]["Players"] > 0 
				and ZoneData[TpZones]["IsReady"] == true 
				and #ZoneData[TpZones]["Players"] < ZoneData[TpZones]["MaxPlayers"] 
			then -- if the room had been created andnot max yet
				JoinParty(Plr, ZoneContainer, TpZones, false) -- Join as a members
			end
		end)

		Zone.playerExited:Connect(function(Plr)
			local index = table.find(ZoneData[TpZones]["Players"],Plr)
			if index then
				LeaveParty(Plr, TpZones)
			end
		end)
	end
end

game:GetService("Players").PlayerRemoving:Connect(function(Plr)
	for _, TpZones in pairs(TeleportZones:GetChildren()) do
		local index = table.find(ZoneData[TpZones]["Players"],Plr)
		if ZoneData[TpZones] and index then
			LeaveParty(Plr, TpZones)
		end
	end
end)