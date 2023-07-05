package tdd;

import sys.thread.Mutex;
import sys.thread.FixedThreadPool;
import hx.ws.Log;
import kun_net.client.SocketClient;
import haxe.io.Bytes;

class Client {
	static public function main() {
		final lock = new Mutex();
		Log.mask = Log.INFO | Log.DEBUG | Log.DATA;
		var client:SocketClient = null;
		client = new SocketClient((socketHandle) -> {
			socketHandle.onClose(() -> {
				trace("disconnect!");
			});
			socketHandle.onData(msg -> {
				trace(msg.toString());
			});
			var executor = new FixedThreadPool(10000);

			for (i in 0...10) {
				executor.run(() -> {
					var msg = Bytes.ofString('Hello World ${i}');
					lock.acquire();
					socketHandle.send(msg);
					lock.release();
				});
			}
		});
		trace("Client Start");
	}
}
