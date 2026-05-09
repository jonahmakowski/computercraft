-- rednet setup
rednet.open("back")
rednet.host("megablimp", "altitude_control")


local redstone_control_1 = peripheral.wrap("left")
local redstone_control_2 = peripheral.wrap("right")
local redstone_control_3 = peripheral.wrap("top")

local total_segments = 10

local redstone_controls = {
    {relay = redstone_control_1, sides = {"top", "right", "front", "back"}},
    {relay = redstone_control_2, sides = {"left", "top", "front", "back"}},
    {relay = redstone_control_3, sides = {"top", "back"}},
}

-- if value is -1, it'll only return the current value
local function set_segment(segment, value)
    local current_segment = 1

    for _, entry in ipairs(redstone_controls) do
        for _, side in ipairs(entry.sides) do
            if current_segment == segment then
                if value ~= -1 then
                    entry.relay.setAnalogOutput(side, value)
                end
                return entry.relay.getAnalogOutput(side)
            end
            current_segment = current_segment + 1
        end
    end
end

local function split(str, sep)
    local result = {}
    for part in str:gmatch("([^" .. sep .. "]+)") do
        table.insert(result, part)
    end
    return result
end

local target_percentage = 55

parallel.waitForAny(
    -- Control power
    function()
        while true do
            -- Setting values
            local segments_full_power = math.floor(target_percentage / 10)
            local next_segment_power = (target_percentage - (segments_full_power * 10)) / 10

            for i = 1, segments_full_power do
                set_segment(i, 15)
            end

            for i = segments_full_power+1, total_segments do
                set_segment(i, 0)
            end

            set_segment(segments_full_power+1, 15 * next_segment_power)

            -- Displaying values
            term.clear()
            for i = 1, total_segments do
                term.setCursorPos(1, i)
                print("Segment "..i.. ": "..set_segment(i, -1))
            end

            term.setCursorPos(1, total_segments+3)
            print("Current Throttle: "..target_percentage.."%")

            sleep(1)
        end
    end,
    -- Transmit current throttle
    function()
        while true do
            rednet.broadcast("height_throttle:"..target_percentage, "megablimp_information")
            sleep(1)
        end
    end,
    -- Update current throttle
    function()
        while true do
            local id, data = rednet.receive("megablimp_command")
            print("Recived"..data)
            if id == rednet.lookup("megablimp", "control") and string.find(data, "height_throttle") then
                target_percentage = tonumber(split(data, ":")[2])
            end
        end
    end
)



set_segment(1, 0)
