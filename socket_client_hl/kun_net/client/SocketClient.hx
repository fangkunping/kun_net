package kun_net.client;

import sys.net.Host;
import hx.ws.Log;
import haxe.io.Bytes;
import kun_net.core.SocketHandleImpl;
import hl.uv.Tcp;

class SocketClient {
	var client:Tcp;
	var socketHandle:SocketHandleImpl;
	var connectCallback:SocketHandleImpl->Void;

	public function new(_connectCallback:SocketHandleImpl->Void = null) {
		connectCallback = _connectCallback;
		client = new Tcp();
		client.connect(new Host("0.0.0.0"), 4836, onConnected);
	}

	function onConnected(success:Bool) {
		if (success) {
			socketHandle = new SocketHandleImpl(client);
			client.readStart(socketHandle.msgIn);
			if (connectCallback != null) {
				connectCallback(socketHandle);
			}
		} else {
			Log.debug("Connect to server fail!!");
		}
	}
}
