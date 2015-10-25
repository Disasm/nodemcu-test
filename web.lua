if web then
    if web.srv then
        web.srv:close()
    end
end

web = {}
web.listen = function(port)
    web.subscribers = {}
    web.subscriberList = {}

    if web.srv then
        web.srv:close()
    end
    web.srv = net.createServer(net.TCP)
    web.srv:listen(port, function(conn)
        conn:on("receive",function(conn, payload)
            local request = {}
            request.payload = payload
            request.method = string.match(payload, '^([A-Z]+) ')
            request.path = string.match(payload, '[A-Z]+ (/[^ ]*) ')
            request.conn = conn
            request.answered = false
            request.answer = web.answer
            request.sendFile = web.sendFile

            --print("Request: "..request.path)

            local i
            for i=1,#web.subscriberList do
                m = string.match(request.path, '^'..web.subscriberList[i]..'$')
                if m then
                    local func = web.subscribers[web.subscriberList[i] ] 
                    if func ~= nil then
                        --print("before function call")
                        func(request)
                        break
                    end
                end
            end

            if request.answered == false then
                web.answer(request, 501)
            end
        end)
    end)
end

web.on = function(path, func)
    web.subscribers[path] = func
    web.subscriberList[#web.subscriberList + 1] = path
end

web.codeName = function(code)
    if code == 200 then
        return "OK"
    elseif code == 404 then
        return "Not Found"
    elseif code == 500 then
        return "Internal Server Error"
    elseif code == 501 then
        return "Not Implemented"
    else
        return "UnknownCode"
    end
end

web.answer = function(request, code, data, headers)
    local conn = request.conn
    conn:send("HTTP/1.1 "..code.." "..web.codeName(code).."\r\n")
    if headers ~= nil then
        conn:send(headers)
    else
        conn:send("Content-type: text/html;charset=utf8\r\n\r\n")
    end

    if data ~= nil then
        conn:send(data)
    else
        conn:send(code.." "..web.codeName(code))
    end
    conn:close()

    request.answered = true
end

web.sendFile = function(request, fileName)
    local conn = request.conn
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
        conn:close()

        request.answered = true
    else
        web.answer(request, 404, "Not Found")
    end
end