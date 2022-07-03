if shared.acs_ref then return end
shared.acs_ref = true
local Player = game.Players.LocalPlayer
local Storage = game.ReplicatedStorage    
    
-- Find Remotes 
local events, refil; do
    if getsenv and getupvalues then
        local chr = Player.Character or Player.CharacterAdded:wait()
        local env = getsenv(chr:FindFirstChild("ACS_Framework",true)
            or chr:FindFirstChild("ACS_Client",true))
        wait(.1) -- waiting for cli init 
        
        events = getupvalues(env.Shoot)[env.script.Name == "ACS_Client" and 15 or 9]
    else
        events = storage:FindFirstChild("ACS_Engine")
        or storage:FindFirstChild("ACS_Framework")
        
        events = events and events:FindFirstChild("Eventos")
        or events:FindFirstChild("Events")
    end
    
    local rmt = events:FindFirstChild("Refil")
    or events:FindFirstChild("Recarregar")
    
    refil = function(i,v,e)
        pcall(function()
            rmt:InvokeServer(i,v-e)
        end)
        pcall(function()
            rmt:FireServer(v,{ACS_Modulo={Variaveis={StoredAmmo=i}}})
        end)
    end
end

-- UI Lib Fetch
local raw, url 
url = "https://raw.githubusercontent.com/loglizzy/Elerium-lib/main/lib.min.lua"

if isfile and readfile then
    if isfile("log-Elerium.lib") then
        raw = readfile("log-Elerium.lib")
    else
        raw = game:HttpGet(url)
        writefile("log-Elerium.lib", raw)
    end
end

-- Create GUI
local Library = loadstring(raw or game:HttpGet(url))()
local Window = Library:AddWindow("Values Explorer", {
	main_color = nil,
	min_size = Vector2.new(315, 700),
	toggle_key = Enum.KeyCode.RightShift,
	can_resize = true,
})

-- Compiling folders
local Folders = {}
function Compile(plr, pr)
    for i,v in next, pr:GetChildren() do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local box
            box = plr:AddTextBox("", function(val)
                val = tonumber(val)
                if val then v.Value = val refil(v, val, v.Value) end
            end)
            
            box.RichText = true
            box.Text = "<b>"..v.Name..":</b> "..v.Value
            box.FocusLost:Connect(function()
                task.wait()
                box.Text = "<b>"..v.Name..":</b> "..v.Value
            end)
            
            v:GetPropertyChangedSignal("Value"):Connect(function()
                if not box:IsFocused() then
                    box.Text = "<b>"..v.Name..":</b> "..v.Value
                end
            end)
        end
        
        for i,e in next, v:GetDescendants() do
            if e:IsA("NumberValue") or e:IsA("IntValue") then
                Compile(plr:AddFolder(v.Name), v)
                break
            end
        end
    end
end

local tab = Window:AddTab("Players")
tab:Show()

for i,v in next, game.Players:GetPlayers() do
    local folder = tab:AddFolder(v.Name)
    Compile(folder, v)
end

game.Players.PlayerAdded:Connect(function(v)
    local folder = tab:AddFolder(v.Name)
    Compile(folder, v)
end)
