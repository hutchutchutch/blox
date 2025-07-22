local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local remotes = ReplicatedStorage:WaitForChild("HeatSeekerRemotes")
local Types = require(script.Parent.Parent.Types)

local FADE_TIME = 1.5
local MUSIC_VOLUME = 0.5
local DANGER_THRESHOLD = 50

local musicFolder = Instance.new("Folder")
musicFolder.Name = "GameMusic"
musicFolder.Parent = SoundService

local happyMusic = Instance.new("Sound")
happyMusic.Name = "HappyMusic"
happyMusic.SoundId = "rbxasset://sounds/uuhhh.mp3"
happyMusic.Volume = 0
happyMusic.Looped = true
happyMusic.Parent = musicFolder

local hauntingMusic = Instance.new("Sound")
hauntingMusic.Name = "HauntingMusic"
hauntingMusic.SoundId = "rbxasset://sounds/bass.mp3"
hauntingMusic.Volume = 0
hauntingMusic.Looped = true
hauntingMusic.Parent = musicFolder

local currentMusic = happyMusic
local targetMusic = happyMusic
local isTransitioning = false

ContentProvider:PreloadAsync({happyMusic, hauntingMusic})

local function fadeMusic(sound: Sound, targetVolume: number, fadeTime: number)
	local tween = TweenService:Create(sound, TweenInfo.new(fadeTime, Enum.EasingStyle.Linear), {
		Volume = targetVolume
	})
	tween:Play()
	return tween
end

local function switchMusic(newMusic: Sound)
	if newMusic == currentMusic or isTransitioning then
		return
	end
	
	isTransitioning = true
	targetMusic = newMusic
	
	local fadeOutTween = fadeMusic(currentMusic, 0, FADE_TIME)
	
	fadeOutTween.Completed:Connect(function()
		currentMusic:Stop()
		
		currentMusic = targetMusic
		currentMusic:Play()
		
		fadeMusic(currentMusic, MUSIC_VOLUME, FADE_TIME).Completed:Connect(function()
			isTransitioning = false
		end)
	end)
end

local lastHeatType = nil
local dangerLevel = 0

remotes.TemperatureUpdate.OnClientEvent:Connect(function(temperature: Types.Temperature)
	local heatType = temperature.heatType
	local distance = temperature.distance
	local intensity = temperature.intensity or 0
	
	if heatType == "bad" and distance <= DANGER_THRESHOLD then
		dangerLevel = math.min(dangerLevel + 0.1, 1)
		
		if not hauntingMusic.IsPlaying and currentMusic ~= hauntingMusic then
			switchMusic(hauntingMusic)
		end
		
		local dangerVolume = MUSIC_VOLUME + (intensity * 0.3)
		hauntingMusic.Volume = math.min(dangerVolume, 1)
		
		hauntingMusic.PlaybackSpeed = 1 + (intensity * 0.2)
		
	else
		dangerLevel = math.max(dangerLevel - 0.05, 0)
		
		if dangerLevel <= 0.1 and currentMusic ~= happyMusic then
			switchMusic(happyMusic)
			happyMusic.PlaybackSpeed = 1
		end
	end
	
	lastHeatType = heatType
end)

happyMusic:Play()
fadeMusic(happyMusic, MUSIC_VOLUME, FADE_TIME)

script.Parent:WaitForChild("ClientMain")

return {
	switchMusic = switchMusic,
	fadeMusic = fadeMusic,
	happyMusic = happyMusic,
	hauntingMusic = hauntingMusic,
}