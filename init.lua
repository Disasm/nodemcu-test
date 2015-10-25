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

function sendfile(fileName, conn)
    if file.open(fileName, "r") then
        conn:send("HTTP/1.1 200 OK\r\n\r\n")
        while true do
            data = file.read(256)
            if data == nil then
                break
            end
            conn:send(data)
        end
        file.close()
    else
        conn:send("HTTP/1.1 404 Not Found\r\n\r\nNot Found")
    end
    conn:close()
end

-- a simple http server
if srv then
    srv:close()
end
srv = net.createServer(net.TCP) 
srv:listen(80, function(conn) 
    conn:on("receive",function(conn, payload)

    request = {}
    request.method = string.match(payload, '^([A-Z]+) ')
    request.path = string.match(payload, '[A-Z]+ (/[^ ]*) ')
    
    answer = nil
    if request.path == "/led0_on" then
      answer = "OK"
      set_led(0, true)
    elseif request.path == "/led0_off" then
      answer = "OK"
      set_led(0, false)
    elseif request.path == "/led1_on" then
      answer = "OK"
      set_led(1, true)
    elseif request.path == "/led1_off" then
      answer = "OK"
      set_led(1, false)
    elseif request.path == "/btn_state" then
      answer = "<meta http-equiv='refresh' content='1'>BTN = " .. gpio.read(btn_pin)
    elseif request.path == "/" then
      sendfile("index.html", conn)
      return
    else
      answer = "HELLO"
    end

    conn:send("HTTP/1.1 200 OK\r\nContent-type: text/html;charset=utf8\r\n\r\n")
    if answer ~= nil then
      conn:send(answer .. "\n")
    end
    conn:close()
    end)
end)
