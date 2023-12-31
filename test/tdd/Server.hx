package tdd;

import hx.ws.Log;
import kun_net.server.SocketServer;
import haxe.xml.Access;
import core.tdd.Assert;

class Server {
	static public function main() {
		Log.mask = Log.INFO | Log.DEBUG | Log.DATA;
		// Assert.eq("test", "error");
		trace("Server Start");
		new SocketServer(new sys.net.Host("0.0.0.0"), 4836, 10000, socketHandle -> {
			socketHandle.onClose(() -> {
				trace('ID: ${socketHandle.uuid} , Close!');
			});
			socketHandle.onData(msg -> {
				trace('ID: ${socketHandle.uuid}, MSG: ${msg.toString()}');
			});
		});
	}
}
