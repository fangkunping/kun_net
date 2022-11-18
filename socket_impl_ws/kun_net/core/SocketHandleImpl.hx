package kun_net.core;

import kun_net.protocol.I_SocketHandle;
import hl.uv.Stream;

import hx.ws.Types.MessageType as ON_DATA_T;
import haxe.io.Bytes as MSG_IN_T;
import Any as SEND_T;

class SocketHandleImpl implements I_SocketHandle<ON_DATA_T, MSG_IN_T, SEND_T> {
	public var uuid:Int = -1;
	public var nickName:String = null;

	var stream:hl.uv.Stream;
	var wsHandler:WebSocketHandler;

	public function new(_stream:Stream) {
		stream = _stream;
		wsHandler = new WebSocketHandler(this, _stream);
	}

	public function onClose(_callbackFn:Void->Void = null) {
		wsHandler.onclose = _callbackFn;
	}

	public function onData(_callbackFn:ON_DATA_T->Void = null) {
		wsHandler.onmessage = _callbackFn;
	}

	public function onOpen(_callbackFn:Void->Void):Void {
		wsHandler.onopen = _callbackFn;
	}

	public function onError(_callbackFn:Dynamic->Void):Void {
		wsHandler.onerror = _callbackFn;
	}

	// 发送消息
	public function send(msg:SEND_T) {
		wsHandler.send(msg);
	}

	// 主动关闭连接
	public function close(?callb:Null<() -> Void>) {
		wsHandler.close();
	}

	// 信息到达
	public function msgIn(packageData:MSG_IN_T) {
		wsHandler.handle(packageData);
	}
}
