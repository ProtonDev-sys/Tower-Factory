local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local remotes = replicatedStorage.remotes
local network = {}
network.remotes = {}

function network:registerEvent(type, name, callback)
    if self.remotes[name] then
        error(string.format("Event with this name (%s) already exists.", name))
    end
    if runService:IsServer() then
        if type == "RemoteEvent" then
            local remote = Instance.new("RemoteEvent")
            remote.Parent = remotes
            remote.Name = name
            self.remotes[name] = remote

            remote.OnServerEvent:Connect(callback)
        elseif type == "RemoteFunction" then
            local remote = Instance.new("RemoteFunction")
            remote.Parent = remotes
            remote.Name = name
            self.remotes[name] = remote

            remote.OnServerInvoke = callback
        end
    else
        error("Do not register events on the client! This will be implemented in the future.")
        --[[
        if type == "RemoteEvent" then
            local remote = Instance.new("RemoteEvent")
            remote.Parent = remotes
            self.remotes[name] = remote

            remote.OnClientEvent:Connect(callback)
        elseif type == "RemoteFunction" then
            local remote = Instance.new("RemoteEvent")
            remote.Parent = remotes
            self.remotes[name] = remote

            remote.OnClientInvoke = callback
        end
        ]]
    end
end

function network:getEvent(name)
    if runService:IsServer() then
        if self.remotes[name] then
            return self.remotes[name]
        else -- this should never run, only get events that are valid!
            error("Event invalid.")
            return false
        end
    else
        if not self.remotes[name] then
            local remote = remotes:FindFirstChild(name)
            if remote then
                self.remotes[name] = remote
                return remote
            else
                error("Invalid remote!")
            end
        else
            return self.remotes[name]
        end
    end
end

function network:deleteEvent(name)
    if self.remotes[name] then
        self.remotes[name] = nil
    else
        error("Event invalid.")
        return false
    end
end

return network