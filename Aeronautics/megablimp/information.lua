rednet.open("back")
rednet.host("megablimp", "information")

local altitude_sensor = peripheral.wrap("top")
local gimbal_sensor = peripheral.wrap("right")
local speed_sensor = peripheral.wrap("left")
local optical_sensor = peripheral.wrap("bottom")

local function get_height()
    return altitude_sensor.getHeight()
end

local function get_gimbal()
    return gimbal_sensor.getAngles()
end

local function get_speed()
    return speed_sensor.getVelocity()
end

local function get_ground_distance()
    if optical_sensor.getBlock() ~= "minecraft:air" then
        return optical_sensor.getDistance()
    else
        return -1
    end
end

while true do
    -- Get Data
    local altitude = get_height()
    local gimbal_data = get_gimbal()
    local speed = get_speed()
    local ground_distance = get_ground_distance()

    -- Rednet broadcast
    rednet.broadcast("altitude:"..altitude, "megablimp_information")
    sleep(0.1)
    rednet.broadcast("gimbal:"..gimbal_data[1]..","..gimbal_data[2], "megablimp_information")
    sleep(0.1)
    rednet.broadcast("speed:"..speed, "megablimp_information")
    sleep(0.1)
    rednet.broadcast("ground_distance:"..ground_distance, "megablimp_information")


    -- Update display
    term.clear()
    term.setCursorPos(1,1)
    print("Altitude: "..altitude)
    print("Gimbal Data: "..gimbal_data[1]..", "..gimbal_data[2])
    print("Speed: "..speed)
    print("Ground Distance: "..ground_distance)
    sleep(0.5)
end

