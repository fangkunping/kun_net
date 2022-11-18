package kun_net.core;

import haxe.io.Bytes;
import hx.strings.Strings;

class HttpUtils {
	static public function echo(socketHandleImpl:SocketHandleImpl, msg:String = "", header:Map<String, String> = null, code:Int = 200) {
		var res = encodeHeader(header, code);
		var msgBytes = Bytes.ofString(msg);
		res.add('${HeaderConst.CONTENT_LENGTH}: ${msgBytes.length}\r\n');
		res.add('\r\n');
		socketHandleImpl.send(Bytes.ofString(res.toString()));
		socketHandleImpl.send(msgBytes);
		socketHandleImpl.close();
	}

	static function encodeHeader(header:Map<String, String> = null, code:Int = 200) {
		var res = new StringBuf();
		res.add('HTTP/1.1 ${code} OK\r\n');
		if (header != null) {
			for (k => v in header) {
				res.add('${k}: ${v}\r\n');
			}
		}
		return res;
	}

	static public function objectToMap(o:Dynamic) {
		var m:Map<String, String> = new Map();
		for (k in Reflect.fields(o)) {
			m.set(k, Std.string(Reflect.field(o, k)));
		}
		return m;
	}

	static public function queryToMap(queryString:String) {
		var querys:Map<String, String> = new Map();
		if (queryString != null) {
			for (s in queryString.split("&")) {
				var kvt:Array<String> = s.split("=");
				if (kvt.length > 0) {
					querys.set(kvt[0], StringTools.urlDecode(kvt[1]));
				}
			}
		}
		return querys;
	}
}
