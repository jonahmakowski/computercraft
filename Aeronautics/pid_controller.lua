local front_relay = peripheral.wrap("left")
local rear_relay = peripheral.wrap("right")
local INPUT_SIDE = "back"
local OUTPUT_SIDE = "front"
local KP = 0.2
local KD = 0
local KI = 0.05

local function round(x)
    x_int = math.floor(x)
    if x - x_int < 0.5 then
        return x_int
    else
        return x_int + 1
    end
end

local function process_frame(relay, other_relay, prev_error, integral, positive)
    error = (relay.getAnalogInput(INPUT_SIDE) - other_relay.getAnalogInput(INPUT_SIDE))
    integral = math.min(math.max(integral, 15), 0) + error
    output_data = KP * error + KD*(error-prev_error) + KI * integral
    print("Output Data: "..tostring(output_data))
    output_data = round(math.min(math.max(output_data, 0), 15))
    print("Controlled output: "..tostring(output_data))
    relay.setAnalogOutput(OUTPUT_SIDE, output_data)
    return error, integral
end

local front_error = 0
local rear_error = 0
local front_integral = 0
local rear_integral = 0

while true do
    print("New Cycle:")
    front_error, front_integral = process_frame(front_relay, rear_relay, front_error, front_integral, true)
    rear_error, rear_integral = process_frame(rear_relay, front_relay, rear_error, rear_integral, false)
    print("End Cycle\n")
    sleep(0.05)
end
