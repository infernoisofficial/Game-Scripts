--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

--// Player Stuffs
local Plr = game.Players.LocalPlayer
local PartyUi = Plr.PlayerGui:WaitForChild("PartyUi")

--// Objects
local TeleportZones = game.Workspace.TeleportZones
local Configuration = TeleportZones.Configuration
local QueueRemote = ReplicatedStorage.Remotes.QueueRemote

QueueRemote.OnClientEvent:Connect(function(Action)
	if Action == "JoinParty" then
		PartyUi.Enabled = true
		PartyUi.Create.Background.Visible = false
		PartyUi.Create.ExpireBar.Visible = false
	elseif Action == "CreateParty" then
		PartyUi.Enabled = true
		PartyUi.Create.Background.Visible = true
		PartyUi.Create.ExpireBar.Visible = true
		PartyUi.Create.ExpireBar.Percentage.Size = UDim2.new(1,0,1,0)
		TweenService:Create(PartyUi.Create.ExpireBar.Percentage,TweenInfo.new(Configuration.TimeBeforeExpires.Value,Enum.EasingStyle.Linear,Enum.EasingDirection.In),{
			Size = UDim2.new(0,0,1,0)
		}):Play()
		-- after press create button make the window disappear
		PartyUi.Create.Background.CreateButton.MouseButton1Down:Connect(function()
			PartyUi.Create.Background.Visible = false
			PartyUi.Create.ExpireBar.Visible = false
		end)
	elseif Action == "LeaveParty" then
		PartyUi.Enabled = false
	end
end)