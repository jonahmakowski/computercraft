rednet.open("back")
rednet.host("megablimp", "engine_control")


local function split(str, sep)
    local result = {}
    for part in str:gmatch("([^" .. sep .. "]+)") do
        table.insert(result, part)
    end
    return result
end

local right_engine_relay = peripheral.wrap("redstone_relay_1")
local left_engine_relay = peripheral.wrap("redstone_relay_0")

while true do
    local id, data = rednet.receive("megablimp_command")

    if id == rednet.lookup("megablimp", "control") then
        left_engine_relay.setAnalogOutput("front", tonumber(split(data, ",")[1]))
        right_engine_relay.setAnalogOutput("front", tonumber(split(data, ",")[2]))
        print("Updated redstone status")
    end
end