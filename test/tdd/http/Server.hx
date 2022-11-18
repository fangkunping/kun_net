package tdd.http;

import kun_net.core.HttpUtils;
import hx.ws.Log;
import kun_net.server.SocketServer;
import haxe.xml.Access;
import core.tdd.Assert;

class Server {
	static public function main() {
		Log.mask = Log.INFO | Log.DEBUG | Log.DATA;
		// Assert.eq("test", "error");
		new SocketServer(socketHandle -> {
			socketHandle.onClose(() -> {
				Log.debug('ID: ${socketHandle.uuid} , Close!');
			});
			socketHandle.onData(msg -> {
				Log.debug('ID: ${socketHandle.uuid}');
				Log.debug('FULL_PATH: ${socketHandle.fullPath}');
				Log.debug('METHOD: ${socketHandle.method}');
				Log.debug('PATH: ${socketHandle.path}');
				Log.debug('QUERY_STRING: ${socketHandle.queryString}');
				Log.debug('QUERYS: ${socketHandle.querys}');
				Log.debug('HEADER: ${socketHandle.header}');
				Log.debug('BODY: ${socketHandle.body}');
				HttpUtils.echo(socketHandle, "hello world!你好世界！", HttpUtils.objectToMap({
					"Content-Type": "text/html; charset=utf-8"
				}));
			});
		});
		trace("Server Start");
	}
}
