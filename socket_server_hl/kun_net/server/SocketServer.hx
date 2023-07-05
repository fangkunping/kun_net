package kun_net.server;

import hl.uv.Loop;
import sys.net.Host;
import haxe.crypto.Md5;
import kun_net.core.SocketHandleImpl;
import hl.uv.Tcp;

class SocketServer {
	var server:Tcp;
	var connectCallback:SocketHandleImpl->Void;

	public function new(host:Host, port:Int, backlog:Int, _connectCallback:SocketHandleImpl->Void = null, _loopRunMode:LoopRunMode = Default) {
		connectCallback = _connectCallback;
		if (_loopRunMode == Default) {
			var loop = Loop.getDefaultLoop();
			server = new Tcp(loop);
			server.bind(host, port);
			server.listen(backlog, onConnect);
			while (true) {
				loop.run(Default);
			}
		} else {
			server = new Tcp();
			server.bind(host, port);
			server.listen(backlog, onConnect);
		}
	}

	function onConnect() {
		var socket = server.accept();
		if (socket != null) {
			var socketHandle = new SocketHandleImpl(socket);
			socketHandle.uuid = SocketManager.instance().createUUID();
			socketHandle.nickName = Md5.encode(Std.string(socketHandle.uuid));
			// SocketManager.instance().addHandle(socketHandle);
			socket.readStart(data -> {
				socketHandle.msgIn(data);
				// if (data == null) {
				// SocketManager.instance().removeHandle(socketHandle);
				// }
			});
			if (connectCallback != null) {
				connectCallback(socketHandle);
			}
		}
	}
}
