package tdd.http;

import haxe.macro.Expr.Catch;
import haxe.io.Bytes;
import kun_net.core.SocketHandleImpl;
import sys.thread.Deque;
import hl.uv.Loop;
import hl.uv.Tcp;
import hl.Api;
import haxe.MainLoop;
import sys.thread.FixedThreadPool;
import sys.thread.Thread;
import hl.Gc;
import kun_net.core.HttpUtils;
import hx.ws.Log;
import kun_net.server.SocketServer;
import haxe.xml.Access;
import core.tdd.Assert;

class Server {
	static var qs:Deque<{
		socketHandle:SocketHandleImpl,
		msg:Bytes
	}> = new Deque();

	static public function test_run() {
		trace("runing from c");
	}

	static var count = 0;
	static final threadPoolNum = 10000; // 固定线程池数量，越大占用内存越多
	static final tcpConcurrencyNum = 10000;

	static public function main() {
		// 线程池
		var executor = new FixedThreadPool(threadPoolNum);
		// Log.mask = Log.INFO | Log.DEBUG | Log.DATA;
		// Assert.eq("test", "error");
		Thread.create(() -> {
			var callbackDone = true;
			var timeOut = 0.0;
			var socketHandle:SocketHandleImpl = null;
			while (true) {
				var now = Date.now().getTime();
				if (callbackDone) {
					var data = qs.pop(true);
					if (data != null) {
						callbackDone = false;
						socketHandle = data.socketHandle;
						timeOut = now + 5000;
						Tcp.tcp_asyn_event_call(Loop.getDefaultLoop(), () -> {
							try {
								data.socketHandle.send(data.msg);
								data.socketHandle.close();
							} catch (e) {
								trace(e);
							}
							callbackDone = true;
							socketHandle = null;
						});
					}
				}
			}
		});
		trace("Server Start");
		new SocketServer(new sys.net.Host("0.0.0.0"), 4836, tcpConcurrencyNum, socketHandle -> {
			socketHandle.onClose(() -> {
				Log.debug('ID: ${socketHandle.uuid} , Close!');
			});
			socketHandle.onData(msg -> {
				count++;
				if (socketHandle.queryString == "check") {
					trace(count);
				}
				Log.debug('ID: ${socketHandle.uuid}');
				Log.debug('FULL_PATH: ${socketHandle.fullPath}');
				Log.debug('METHOD: ${socketHandle.method}');
				Log.debug('PATH: ${socketHandle.path}');
				Log.debug('QUERY_STRING: ${socketHandle.queryString}');
				Log.debug('QUERYS: ${socketHandle.querys}');
				Log.debug('HEADER: ${socketHandle.header}');
				Log.debug('BODY: ${socketHandle.body}');
				executor.run(() -> {
					qs.add({
						socketHandle: socketHandle,
						msg: HttpUtils.echo2("hello world!你好世界！", HttpUtils.objectToMap({
							"Content-Type": "text/html; charset=utf-8"
						}))
					});
				});

				// socketHandle.getLock().execute(() -> {
			});
		});
	}
}
