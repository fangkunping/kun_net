package kun_net.core;

import hx.ws.Log;
import haxe.io.BytesInput;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;
import hl.uv.Stream;

class SocketHandleImpl {
	public var uuid:Int = -1;
	public var nickName:String = null;

	var stream:hl.uv.Stream;
	var packageDataCache:BytesBuffer;

	var closeCallback:Void->Void;
	var msgInCallback:Bytes->Void;

	public function new(_stream:Stream) {
		stream = _stream;
		packageDataCache = new BytesBuffer();
	}

	public function onClose(_callbackFn:Void->Void = null) {
		closeCallback = _callbackFn;
	}

	public function onData(_callbackFn:Bytes->Void = null) {
		msgInCallback = _callbackFn;
	}

	function onOpen(_callbackFn:Void->Void):Void{}
	function onError(_callbackFn:Dynamic->Void):Void{}

	// 发送消息
	public function send(msg:Bytes) {
		var msgLen = msg.length;
		var headData = Bytes.alloc(CommonConst.HEAD_LEN);
		Log.debug('Message Len: ${msgLen}');
		headData.setInt32(0, msgLen);
		stream.write(headData);
		stream.write(msg);
	}

	// 主动关闭连接
	public function close(?callb:Null<() -> Void>) {
		stream.close(callb);
	}

	// 信息到达
	public function msgIn(packageData:Bytes) {
		if (packageData == null) {
			Log.debug("Socket Disconnect!");
			if (closeCallback != null) {
				closeCallback();
			}
			return;
		}
		Log.debug('Packege Hex: ${packageData.toHex()}');
		packageDataCache.add(packageData);
		decodePackage();
	}



	// 解包
	function decodePackage() {
		/**
			packageData 加入 packageDataCache
			packageDataCache 取出头部（1位，2位，4位） 长度 headLen
				packageDataCache 剩下长度 < headLen
					等待
				packageDataCache 剩下长度 >= headLen
					截取 数据 发送到回调函数
		 */
		if (packageDataCache.length <= CommonConst.HEAD_LEN) {
			return;
		}
		var tmpByteInput:BytesInput = new BytesInput(packageDataCache.getBytes());
		var headLen = tmpByteInput.readInt32();
		var tmpByteLen = tmpByteInput.length;
		if (tmpByteLen < headLen) {
			packageDataCache = new BytesBuffer();
			packageDataCache.addInt32(headLen);
			packageDataCache.add(tmpByteInput.readAll());
			return;
		}
		var actualData:Bytes = tmpByteInput.read(headLen);
		if (msgInCallback != null) {
			msgInCallback(actualData);
		}
		packageDataCache = new BytesBuffer();
		packageDataCache.add(tmpByteInput.readAll());
		decodePackage();
	}
}
