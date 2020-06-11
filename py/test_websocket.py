import websocket
import _thread

# 在接收到服务器发送消息时调用
def on_message(ws, message):
    print('Received: ' + message)

# 在和服务器建立完成连接时调用
def on_open(ws):
    # 线程运行函数
    def gao():
        # 往服务器依次发送0-4，每次发送完休息0.01秒
        for i in range(5):
            time.sleep(0.01)
            msg="{0}".format(i)
            ws.send(msg)
            print('Sent: ' + msg)
        # 休息1秒用于接收服务器回复的消息
        time.sleep(1)

        # 关闭Websocket的连接
        ws.close()
        print("Websocket closed")

    # 在另一个线程运行gao()函数
    thread.start_new_thread(gao, ())


if __name__ == "__main__":
    ws = websocket.WebSocketApp("ws://echo.websocket.org/",
                              on_message = on_message,
                              on_open = on_open)

    ws.run_forever()

# #### 输出 #####
# Sent: 0
# Sent: 1
# Received: 0
# Sent: 2
# Received: 1
# Sent: 3
# Received: 2
# Sent: 4
# Received: 3
# Received: 4
# Websocket closed
