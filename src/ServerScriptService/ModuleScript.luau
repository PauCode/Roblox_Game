local Lighting = game:GetService("Lighting")

-- Oscuridad general
Lighting.Ambient = Color3.fromRGB(10, 10, 15)
Lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 30)
Lighting.Brightness = 1

-- Niebla densa y oscura
Lighting.FogColor = Color3.fromRGB(20, 20, 30)
Lighting.FogStart = 30
Lighting.FogEnd = 120

-- Noche profunda
Lighting.ClockTime = 2

-- Color frío y desaturado
local cc = Instance.new("ColorCorrectionEffect", Lighting)
cc.TintColor = Color3.fromRGB(180, 220, 255)
cc.Contrast = 0.1
cc.Brightness = -0.05
cc.Saturation = -0.2

-- Bloom sutil para resaltar luces
local bloom = Instance.new("BloomEffect", Lighting)
bloom.Intensity = 0.2
bloom.Size = 24
bloom.Threshold = 1

-- Blur muy leve (opcional)
local blur = Instance.new("BlurEffect", Lighting)
blur.Size = 2