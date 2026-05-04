local front_relay = peripheral.wrap("left")
local rear_relay = peripheral.wrap("right")
local INPUT_SIDE = "back"
local OUTPUT_SIDE = "front"
local KP = 0.6
local KD = 0.05
local KI = 0.05
local TARGET_ANGLE = 0

local function process_frame(relay, other_relay, prev_error, integral)
    error = (relay.getAnalogInput(INPUT_SIDE) - other_relay.getAnalogInput(INPUT_SIDE)) - TARGET_ANGLE
    integral = math.min(math.max(integral, 15), 0) + error
    output_data = KP * error + KD*(error-prev_error) + KI * integral
    print("Output Data: "..tostring(output_data))
    output_data = math.min(math.max(output_data, 0), 12)
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
    front_error, front_integral = process_frame(front_relay, rear_relay, front_error, front_integral)
    rear_error, rear_integral = process_frame(rear_relay, front_relay, rear_error, rear_integral)
    print("End Cycle\n")
    sleep(0.05)
end
