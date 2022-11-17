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
	var RPC_SENTINEL:EReg = ~/(?<=\/\().*(?=\))/; // ~/(?<=\().*(?=\))/; /* match () */
	var URL_PARSE:EReg = ~/(?:(?P<protocol>[a-z]*(?=[:]\/\/))[:]\/\/(?P<credentials>[^@]*(?=@))?@?(?P<host>[^\/:]*(?=[:\/]|$))?[:]?(?P<port>(?<=[:])[0-9]*)?|)(?P<path>[^?]+)?(?:[?](?P<query>[^#]+))?(?:[#](?P<anchor>.*))?/g;

	public var header:Map<String, String> = new Map();
	public var body:Bytes = null;

	var statusline:Array<String>;

	public var fullPath:String = "";
	public var method:String = ""; // GET POST PUT
	public var path:String = "";
	public var queryString:String = "";
	public var querys:Map<String, String> = new Map();

	var decodeStatus = HttpDecodeSTATUS.HEAD;

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

	function onOpen(_callbackFn:Void->Void):Void {}

	function onError(_callbackFn:Dynamic->Void):Void {}

	// 发送消息
	public function send(msg:Bytes) {
		Log.debug('Send Message Len: ${msg.length}');
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
		// body 解析
		if (decodeStatus == HttpDecodeSTATUS.BODY) {
			var bodyLen = Std.parseInt(header.get(HeaderConst.CONTENT_LENGTH));
			if (bodyLen != null && packageDataCache.length < bodyLen) {
				return;
			}
			body = bodyLen == null ? packageDataCache.getBytes() : null;
			if (msgInCallback != null) {
				msgInCallback(null);
			}
			return;
		}

		// header 解析
		var tmpByteInput:BytesInput = new BytesInput(packageDataCache.getBytes());

		var tmpHeaderStr:StringBuf = new StringBuf();
		var isFirstLine = true;
		while (tmpByteInput.length > tmpByteInput.position) {
			var s = tmpByteInput.readString(1);
			if (s == "\r") {
				// 跳过 \n
				tmpByteInput.readString(1);
				if (isFirstLine) {
					decodeFirstLine(tmpHeaderStr.toString());
					isFirstLine = false;
				} else {
					if (tmpHeaderStr.length == 0) {
						decodeStatus = HttpDecodeSTATUS.BODY;
						packageDataCache = new BytesBuffer();
						packageDataCache.add(tmpByteInput.readAll());
						decodePackage();
						return;
					} else {
						decodeHead(tmpHeaderStr.toString());
					}
				}
				tmpHeaderStr = new StringBuf();
				continue;
			}
			tmpHeaderStr.add(s);
		}
		packageDataCache = new BytesBuffer();
		if (tmpHeaderStr.length > 0) {
			packageDataCache.add(Bytes.ofString(tmpHeaderStr.toString()));
		};
	}

	function decodeHead(tmpHeaderStr:String) {
		var strArr = tmpHeaderStr.split(": ");
		header.set(strArr[0].toLowerCase(), strArr[1]);
	}

	function decodeFirstLine(line:String) {
		statusline = line.split(" ");
		method = statusline[0];
		fullPath = statusline[1];
		URL_PARSE.match(statusline[1]); // parse full path
		path = URL_PARSE.matched(5); // result.path
		queryString = URL_PARSE.matched(6); // result.query
		querys = HttpUtils.queryToMap(queryString);
	}
}

enum HttpDecodeSTATUS {
	HEAD;
	BODY;
}
