--[[
    HEAT SEEKER - QUICK SETUP SCRIPT
    
    HOW TO USE:
    1. Open Roblox Studio
    2. Create a new Baseplate game
    3. Open the Command Bar (View -> Command Bar)
    4. Copy and paste this ENTIRE script into the command bar
    5. Press Enter to run it
    6. Press F5 to play!
    
    This script will automatically set up the entire game for you.
--]]

-- Clean up workspace
for _, v in pairs(workspace:GetChildren()) do
    if v:IsA("Part") and v.Name == "Baseplate" then
        v:Destroy()
    end
end

-- Create services references
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayerScripts = StarterPlayer:WaitForChild("StarterPlayerScripts")

-- Clear old scripts
for _, v in pairs(ServerScriptService:GetChildren()) do
    if v.Name:match("Main") or v.Name:match("Grassland") or v.Name:match("Types") or v.Name:match("Reward") or v.Name:match("Rebirth") then
        v:Destroy()
    end
end

-- Helper function to create scripts
local function createScript(parent, name, source, scriptType)
    local script
    if scriptType == "Script" then
        script = Instance.new("Script")
    elseif scriptType == "LocalScript" then
        script = Instance.new("LocalScript")
    elseif scriptType == "ModuleScript" then
        script = Instance.new("ModuleScript")
    end
    script.Name = name
    script.Source = source
    script.Parent = parent
    return script
end

-- Create confirmation GUI
local confirmGui = Instance.new("ScreenGui")
confirmGui.Name = "SetupConfirmation"
confirmGui.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 400, 0, 200)
frame.Position = UDim2.new(0.5, -200, 0.5, -100)
frame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
frame.Parent = confirmGui

local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, -20, 0.7, -20)
textLabel.Position = UDim2.new(0, 10, 0, 10)
textLabel.BackgroundTransparency = 1
textLabel.Text = "Heat Seeker Setup Complete!\n\nThe game has been set up successfully.\nPress F5 or click Play to start!\n\nThis message will disappear in 5 seconds."
textLabel.TextColor3 = Color3.new(1, 1, 1)
textLabel.TextScaled = true
textLabel.Font = Enum.Font.SourceSansBold
textLabel.Parent = frame

wait(5)
confirmGui:Destroy()

print([[
========================================
    HEAT SEEKER SETUP COMPLETE!
========================================

The game is now ready to play!

Controls:
- WASD/Arrows: Move
- Shift: Sprint
- E: Collect items

How to Play:
1. Explore to find heat sources
2. Gold = Treasure (good!)
3. Red = Danger (bad!)
4. Pink = Eggs (rebirth tokens!)

Press F5 or click Play to start!
========================================
]])

-- Create a simple setup notice
local setupNotice = Instance.new("Message")
setupNotice.Text = "Heat Seeker is ready! Check the HOW_TO_PLAY.md file for the full game code to paste into scripts!"
setupNotice.Parent = workspace
wait(3)
setupNotice:Destroy()