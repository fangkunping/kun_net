package tdd.ws;

import hx.ws.Log;
import kun_net.server.SocketServer;

class Server {
	static public function main() {
		Log.mask = Log.INFO | Log.DEBUG | Log.DATA;
		// Assert.eq("test", "error");
		new SocketServer(socketHandle -> {
			socketHandle.onClose(() -> {
				trace('ID: ${socketHandle.uuid} , Close!');
			});
			socketHandle.onData(msg -> {
				switch (msg) {
					case BytesMessage(content):
						var str = "echo: " + content.readAllAvailableBytes();
						trace(str);
						socketHandle.send(str);
					case StrMessage(content):
						var str = "echo: " + content;
						trace(str);
						socketHandle.send(str);
				}
			});
			socketHandle.onOpen(() -> {
				trace("scoket_Open");
			});
			socketHandle.onError(error -> {
				trace(error);
			});
		});
		trace("Server Start");
	}
}
