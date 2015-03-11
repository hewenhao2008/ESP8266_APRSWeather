counter = 1
PIN = 3 --  data pin, GPIO0 是3，GPIO02是4

dht22 = require("dht22")


logininfo = "user BG6JJI pass xxxxx vers ESP8266Weather 0.1 filter m/500"     --格式：user 用户名(大写) pass 用户名的验证码 vers 软件名 版本号 服务器命令如过滤条件等
DomainName = "china.aprs2.net"               --APRS服务器
DomainPort = "14580"                              --服务器端口

     --创建一个TCP连接
     socket=net.createConnection(net.TCP, 0)
   --开始连接服务器
    socket:connect(DomainPort , DomainName)
    print("Connecting to:" .. DomainName)

   --处理断线
    socket:on("disconnection", function(sck, c) --print(c)
      tmr.stop(1)
      print("Disconnected:" .. DomainName)
      loginlabel = nil
      loginedlabel = nil
      loginedflag = nil
      tmr.delay(1000000)
      node.restart()
    end)


   --第一步登录信息
   socket:on("receive", function(sck, response)
      print(response)
      if loginlabel == nil then
          loginlabel =string.find(response,"javAPRSSrvr")  --判断服务器是否连接1
      end
      if loginlabel == nil then
          loginlabel=string.find(response,"aprsc")            --判断服务器是否连接2
      end
      if loginedlabel == nil then
          loginedlabel=string.find(response,"verified")     --判断登录成功标志
               if loginedlabel then
                     loginedflag = 1
               end
      end
      if loginlabel~= nil then
            if loginedlabel == nil then
               --print("Login:".. loginlabel)
               socket:send(logininfo .. "\r\n" )                     --发送登录认证信息
               loginlabel = nil
            end
      end
   end)


       posttime = 30 * 1000
       tmr.alarm(1,posttime,1,function()                         --设置定时时间，不要低于10秒，建议1分钟以上
        if loginedflag ~= nil then
          dht22.read(PIN)
          local g_temp = dht22.getTemperature()
          local h = dht22.getHumidity()

           local tempF = (9 * g_temp / 50 + 32)
           local g_hum = ((h - (h % 10)) / 10)
             if tempF < 100 then
                tempF = 0 .. tempF
             end
            socket:send("BG6JJI-6>ES26,qAS,:=3447.29N/11343.15E_045/002g...t".. tempF  .. "r...p...h"..g_hum.."b.....RAM" .. node.heap() .. "C"..counter.."\r\n")
            --格式：呼号>软件名缩写,编码方式,:=经度/纬度_风向/风速g忘了雨量自午夜起t温度r忘了雨量1小时内p忘了雨量24小时内h湿度b气压 紧跟备注
            -- c000s000g000t086r000p000h53b10020
            -- 每秒输出35个字节，包括数据末尾的换行符（OD,OA）

            -- 数据解析：
            -- c000：风向角度，单位：度。
            -- s000：前1分钟风速，单位：英里每小时
            -- g000：前5分钟最高风速，单位：英里每小时
            -- t086：温度（华氏）
            -- r000：前一小时雨量（0.01英寸）
            -- p000：前24小时内的降雨量（0.01英寸）
            -- h53：湿度（00％= 100％）
            -- b10020：气压（0.1 hpa）
            print("APRS POST counter:" ..counter)
            print("湿度"..g_hum.."温度"..(g_temp / 10).."华氏"..tempF.."内存".. node.heap())
            counter=counter + 1                                       --累加计数器，计算发送次数，调试用
        end
        end)


