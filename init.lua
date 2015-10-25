--uart.setup(0,115200,8,0,1)

local wifiParams = {}
if file.open("wifi.cfg", "r") then
    local s = file.read()
    wifiParams = cjson.decode(s)
    file.close()
end
if wifiParams.ssid == nil then
    wifiParams.ssid = "AccessPointName"
    wifiParams.password = "password1234"

    file.open("wifi.cfg", "w+")
    file.write(cjson.encode(wifiParams))
    file.close()
end
wifi.setmode(wifi.STATION)
wifi.sta.config(wifiParams.ssid, wifiParams.password)
print(wifi.sta.getip())

led_pin0 = 0
led_pin1 = 1
gpio.mode(led_pin0, gpio.OUTPUT)
gpio.mode(led_pin1, gpio.OUTPUT)

btn_pin = 3
gpio.mode(btn_pin, gpio.INPUT)


function set_led(num, state)
  if num == 0 then
      if state then 
        gpio.write(led_pin0, gpio.LOW)
      else
        gpio.write(led_pin0, gpio.HIGH)
      end
  else
      if state then 
        gpio.write(led_pin1, gpio.HIGH)
      else
        gpio.write(led_pin1, gpio.LOW)
      end
  end
end

set_led(0, false)
set_led(1, false)

-- a simple http server
dofile("web.lua")
web.listen(80)
web.on("/test", function(request)
    print("/test!!!")
    request:answer(200, "Hello!")
end)
web.on("/led0_on", function(request)
    set_led(0, true)
    request:answer(200, "OK")
end)
web.on("/led0_off", function(request)
    set_led(0, false)
    request:answer(200, "OK")
end)
web.on("/led1_on", function(request)
    set_led(1, true)
    request:answer(200, "OK")
end)
web.on("/led1_off", function(request)
    set_led(1, false)
    request:answer(200, "OK")
end)
web.on("/btn_state", function(request)
    request:answer(200, "<meta http-equiv='refresh' content='1'>BTN = " .. gpio.read(btn_pin))
end)
web.on("/", function(request)
    request:sendFile("index.html")
end)
web.on(".*", function(request)
    request:answer(200, "HELLO")
end)
