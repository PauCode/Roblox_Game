object = script.Parent 
if (object ~= nil) and (object ~= game.Workspace) then 
model = object 
messageText = ""

message = Instance.new("Message") 
message.Text = messageText 
backup = model:clone()
waitTime = 5 
wait(math.random(0, waitTime)) 
while true do 
wait(waitTime)

message.Parent = game.Workspace 
model:remove() 

wait(2.5) 

model = backup:clone() 
model.Parent = game.Workspace 
model:makeJoints() 
message.Parent = nil 
end 
end 
