gpio.mode(1, gpio.OUTPUT)

pwm.setup(1, 100, 512)
local i = 0
local d = 1

tmr.alarm(0,1,1,function()
    pwm.setduty(1, i)
    i = i + d
    if (i == 512 and d == 1) or (i == 64 and d == -1) then
        d = d * -1
    end
end)
