local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local localPlayer = Players.LocalPlayer
local aimbotEnabled = false
local isAimbotActive = false
local aimbotConnection = nil
local aimbotFOV = 100 -- FOV de l'aimbot par défaut
local aimbotDistance = 500 -- Distance maximale de l'aimbot

local fovCircle = Drawing.new("Circle")
fovCircle.Radius = aimbotFOV
fovCircle.Thickness = 2
fovCircle.Color = Color3.new(1, 0, 0)
fovCircle.Transparency = 0.5
fovCircle.Filled = false

RunService.RenderStepped:Connect(function()
    fovCircle.Visible = aimbotEnabled
    fovCircle.Position = UserInputService:GetMouseLocation()
    fovCircle.Radius = aimbotFOV
end)

-- Fonction pour activer/désactiver l'aimbot
function enableAimbot()
    if aimbotConnection then return end

    aimbotConnection = RunService.RenderStepped:Connect(function()
        if not isAimbotActive then return end

        local closestPlayer
        local shortestDistance = math.huge

        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= localPlayer and targetPlayer.Team ~= localPlayer.Team and targetPlayer.Character then
                local targetHead = targetPlayer.Character:FindFirstChild("Head")
                if targetHead then
                    local screenPosition, onScreen = Camera:WorldToScreenPoint(targetHead.Position)
                    local distanceToCenter = (Vector2.new(screenPosition.X, screenPosition.Y) - UserInputService:GetMouseLocation()).Magnitude

                    -- Si le joueur est à l'intérieur du FOV (cercle)
                    if distanceToCenter <= fovCircle.Radius then
                        -- Calculer la distance
                        local distance = (Camera.CFrame.Position - targetHead.Position).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestPlayer = targetPlayer
                        end
                    end
                end
            end
        end

        if closestPlayer and closestPlayer.Character then
            local targetHead = closestPlayer.Character:FindFirstChild("Head")
            if targetHead then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position)
            end
        end
    end)
end

function disableAimbot()
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
end

-- Fonction pour afficher le menu Aimbot
function createAimbotGui()
    local playerGui = localPlayer:WaitForChild("PlayerGui")
    local screenGui = Instance.new("ScreenGui", playerGui)
    screenGui.Name = "AimbotGui"

    -- Cadre principal du menu aimbot
    local frame = Instance.new("Frame", screenGui)
    frame.Name = "MainFrame"
    frame.Size = UDim2.new(0.3, 0, 0.4, 0)
    frame.Position = UDim2.new(0.35, 0, 0.3, 0)
    frame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    frame.BorderSizePixel = 1
    frame.Draggable = true
    frame.Active = true
    frame.Visible = false  -- Par défaut, le menu est caché

    -- Bouton de fermeture
    local closeButton = Instance.new("TextButton", frame)
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0.2, 0, 0.1, 0)
    closeButton.Position = UDim2.new(0.8, 0, 0, 0)
    closeButton.Text = "Close"
    closeButton.TextColor3 = Color3.new(1, 0, 0)
    closeButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.SourceSansBold

    -- Event pour fermer le GUI
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- Activer/désactiver aimbot
    local aimbotToggleButton = Instance.new("TextButton", frame)
    aimbotToggleButton.Name = "AimbotToggleButton"
    aimbotToggleButton.Size = UDim2.new(0.5, 0, 0.1, 0)
    aimbotToggleButton.Position = UDim2.new(0.25, 0, 0.2, 0)
    aimbotToggleButton.Text = aimbotEnabled and "Disable Aimbot" or "Enable Aimbot"
    aimbotToggleButton.TextColor3 = Color3.new(1, 1, 1)
    aimbotToggleButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    aimbotToggleButton.TextScaled = true
    aimbotToggleButton.Font = Enum.Font.SourceSansBold

    -- Activer/Désactiver aimbot
    aimbotToggleButton.MouseButton1Click:Connect(function()
        aimbotEnabled = not aimbotEnabled
        aimbotToggleButton.Text = aimbotEnabled and "Disable Aimbot" or "Enable Aimbot"
        if aimbotEnabled then
            enableAimbot()
        else
            disableAimbot()
        end
    end)

    -- FOV slider
    local fovLabel = Instance.new("TextLabel", frame)
    fovLabel.Name = "FovLabel"
    fovLabel.Size = UDim2.new(1, 0, 0.1, 0)
    fovLabel.Position = UDim2.new(0, 0, 0.3, 0)
    fovLabel.Text = "Aimbot FOV: " .. aimbotFOV
    fovLabel.TextColor3 = Color3.new(1, 1, 1)
    fovLabel.BackgroundTransparency = 1
    fovLabel.TextScaled = true

    -- FOV slider
    local fovSlider = Instance.new("TextBox", frame)
    fovSlider.Name = "FovSlider"
    fovSlider.Size = UDim2.new(1, 0, 0.1, 0)
    fovSlider.Position = UDim2.new(0, 0, 0.4, 0)
    fovSlider.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    fovSlider.TextColor3 = Color3.new(1, 1, 1)
    fovSlider.Font = Enum.Font.SourceSans
    fovSlider.TextScaled = true
    fovSlider.Text = tostring(aimbotFOV)

    fovSlider.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local newFov = tonumber(fovSlider.Text)
            if newFov and newFov > 0 then
                aimbotFOV = newFov
                fovLabel.Text = "Aimbot FOV: " .. tostring(aimbotFOV)
            end
        end
    end)

    return screenGui
end

-- Fonction pour basculer la visibilité du menu avec la touche "P"
local screenGui
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.P then
        if not screenGui then
            -- Créer le GUI si il n'existe pas
            screenGui = createAimbotGui()
        end
        screenGui.MainFrame.Visible = not screenGui.MainFrame.Visible  -- Alterner la visibilité
    end
end)

-- Gestion des touches pour activer/désactiver l'aimbot avec clic droit
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then  -- Clic droit
        if aimbotEnabled then
            isAimbotActive = true
            enableAimbot()
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then  -- Relâchement du clic droit
        isAimbotActive = false
        disableAimbot()
    end
end)
