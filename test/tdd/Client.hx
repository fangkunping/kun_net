package tdd;

import hx.ws.Log;
import hx.concurrent.lock.RLock;
import hx.concurrent.executor.Executor;
import kun_net.client.SocketClient;
import haxe.io.Bytes;

class Client {
	static public function main() {
		final lock = new RLock();
		Log.mask = Log.INFO | Log.DEBUG | Log.DATA;
		var client:SocketClient = null;
		client = new SocketClient((socketHandle) -> {
			socketHandle.onClose(() -> {
				trace("disconnect!");
			});
			socketHandle.onData(msg -> {
				trace(msg.toString());
			});
			var executor = Executor.create(10);

			for (i in 0...10) {
				executor.submit(() -> {
					var msg = Bytes.ofString('Hello World ${i}');
					lock.execute(() -> {
						socketHandle.send(msg);
						return true;
					});
				});
			}
		});
		trace("Client Start");
	}
}
