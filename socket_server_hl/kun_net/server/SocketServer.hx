package kun_net.server;

import haxe.crypto.Md5;
import kun_net.core.SocketHandleImpl;
import hl.uv.Tcp;

class SocketServer {
	var server:Tcp;
	var connectCallback:SocketHandleImpl->Void;

	public function new(_connectCallback:SocketHandleImpl->Void = null) {
		connectCallback = _connectCallback;
		server = new Tcp();
		server.bind(Config.host, Config.port);
		server.listen(Config.connectPool, onConnect);
	}

	function onConnect() {
		var socket = server.accept();
		if (socket != null) {
			var socketHandle = new SocketHandleImpl(socket);
			socketHandle.uuid = SocketManager.instance().createUUID();
			socketHandle.nickName = Md5.encode(Std.string(socketHandle.uuid));
			SocketManager.instance().addHandle(socketHandle);
			socket.readStart(data -> {
				socketHandle.msgIn(data);
				if (data == null) {
					SocketManager.instance().removeHandle(socketHandle);
				}
			});
			if (connectCallback != null) {
				connectCallback(socketHandle);
			}
		}
	}
}
