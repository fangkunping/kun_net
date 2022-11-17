package kun_net.core;

import hx.ws.Types.MessageType;
import haxe.io.BytesInput;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;
import hl.uv.Stream;

class SocketHandleImpl {
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

	public function onData(_callbackFn:MessageType->Void = null) {
		wsHandler.onmessage = _callbackFn;
	}

	public function onOpen(_callbackFn:Void->Void):Void {
		wsHandler.onopen = _callbackFn;
	}

	public function onError(_callbackFn:Dynamic->Void):Void {
		wsHandler.onerror = _callbackFn;
	}

	// 发送消息
	public function send(msg:Any) {
		wsHandler.send(msg);
	}

	// 主动关闭连接
	public function close() {
		wsHandler.close();
	}

	// 信息到达
	public function msgIn(packageData:Bytes) {
		wsHandler.handle(packageData);
	}
}
