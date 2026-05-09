rednet.open("back")
rednet.host("megablimp", "control")

local mon = peripheral.wrap("monitor_0")
local altitude_sensor = peripheral.wrap("top")

local gimbal_data = {0, 0}
local speed = 0
local ground_distance = 0
local height_throttle = 0
local height = 0

local height_change = 0
local target_height = 100

local left_throttle = 0
local right_throttle = 0

local function split(str, sep)
    local result = {}
    for part in str:gmatch("([^" .. sep .. "]+)") do
        table.insert(result, part)
    end
    return result
end

local function send_command(id, value, command)
    rednet.send(id, string.format("%s:%f", command,  value), "megablimp_command")
end

parallel.waitForAny(
    -- Get Data
    function()
        while true do
            local id, data = rednet.receive("megablimp_information")
            if id == rednet.lookup("megablimp", "information") or id == rednet.lookup("megablimp", "altitude_control") then
                if string.find(data, "speed") then
                    speed = tonumber(split(data, ":")[2])
                elseif string.find(data, "gimbal") then
                    local raw_data = split(data, ":")[2]

                    gimbal_data[1] = tonumber(split(raw_data, ",")[1])
                    gimbal_data[2] = tonumber(split(raw_data, ",")[2])
                elseif string.find(data, "ground_distance") then
                    ground_distance = tonumber(split(data, ":")[2])
                elseif string.find(data, "height_throttle") then
                    height_throttle = tonumber(split(data, ":")[2])
                end
            end
        end
    end,
    -- Display data on monitor
    function()
        while true do
            height = altitude_sensor.getHeight()

            mon.clear()
            mon.setCursorPos(1,1)
            mon.write(string.format("Height: %.2f blocks", height))
            mon.setCursorPos(1,2)
            mon.write(string.format("Gimbal Data: %.2f, %.2f", gimbal_data[1], gimbal_data[2]))
            mon.setCursorPos(1,3)
            mon.write(string.format("Speed: %.2f", speed))
            mon.setCursorPos(1,4)
            mon.write(string.format("Distance from Ground: %.2f", ground_distance))
            mon.setCursorPos(1,5)
            mon.write(string.format("Height Throttle: %.2f%%", height_throttle))
            mon.setCursorPos(1,6)
            mon.write(string.format("Height Change: %.2f", height_change))
            sleep(0.5)
        end
    end,
    -- Internal UI
    function()
        while true do
            term.clear()
            term.setCursorPos(1,1)
            print("Current target height: "..target_height)
            write("New target height: ")
            target_height = tonumber(read())
        end
    end,
    -- Get height change
    function()
        sleep(1)
        local prev_height = height
        while true do
            height_change = height - prev_height
            prev_height = height
            sleep(1)
        end
    end,
    -- Control height
    function()
        local altitude_control_id = rednet.lookup("megablimp", "altitude_control")

        local kP = 0.001
        local kI = 0
        local kD = 0

        local integral = 0
        local last_error = 0

        sleep(5)

        local local_height_throttle = height_throttle

        while true do
            local height_accurate = altitude_sensor.getHeight()

            local error = target_height - height_accurate

            if math.abs(error) > 10 then
                integral = integral + error
                local derivative = error - last_error

                local output = (kP * error) + (kI * integral) + (kD * derivative)

                local_height_throttle = math.min(math.max(local_height_throttle + output, 3), 100)

                send_command(altitude_control_id, local_height_throttle, "height_throttle")

                last_error = error
            else
                integral = 0
            end

            sleep(0.5)
        end
    end,
    -- Control Throttle
    function()
        while true do
            os.pullEvent("redstone")

            left_throttle = redstone.getAnalogInput("left")
            right_throttle = redstone.getAnalogInput("right")

            rednet.send(rednet.lookup("megablimp", "engine_control"), string.format("%f,%f", left_throttle, right_throttle), "megablimp_command")
        end
    end
)
