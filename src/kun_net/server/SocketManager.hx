package kun_net.server;

import kun_net.core.ErrorCode;
import core.Result;
import haxe.io.Bytes;
import kun_net.core.SocketHandleImpl;

class SocketManager {
	static var inc:SocketManager = null;

	static public function instance():SocketManager {
		if (inc == null) {
			inc = new SocketManager();
		}
		return inc;
	}

	public function new() {
		socketHandleList = new Array();
		socketHandleUUidMap = new Map();
		socketHandleNicknameMap = new Map();
	}

	var uuidSeed:Int = 0;
	var socketHandleList:Array<SocketHandleImpl>;
	var socketHandleUUidMap:Map<Int, SocketHandleImpl>;
	var socketHandleNicknameMap:Map<String, SocketHandleImpl>;

	public function createUUID():Int {
		uuidSeed++;
		return uuidSeed;
	}

	public function addHandle(handle:SocketHandleImpl):Result<Int> {
		if (socketHandleUUidMap.exists(handle.uuid)) {
			return Result.err(ErrorCode.UUID_DUPLICATE);
		}
		if (socketHandleNicknameMap.exists(handle.nickName)) {
			return Result.err(ErrorCode.NICKNAME_DUPLICATE);
		}
		socketHandleList.push(handle);
		socketHandleUUidMap.set(handle.uuid, handle);
		socketHandleNicknameMap.set(handle.nickName, handle);

		return Result.ok(ErrorCode.OK);
	}

	public function removeHandle(handle:SocketHandleImpl) {
		socketHandleList.remove(handle);
		socketHandleUUidMap.remove(handle.uuid);
		socketHandleNicknameMap.remove(handle.nickName);
	}

	public function sendByUUID(uuid:Int, msg:Bytes) {
		var handle = socketHandleUUidMap.get(uuid);
		if (handle == null)
			return;
		handle.send(msg);
	}

	public function sendByNickName(nickName:String, msg:Bytes) {
		var handle = socketHandleNicknameMap.get(nickName);
		if (handle == null)
			return;
		handle.send(msg);
	}

	public function closeByUUID(uuid:Int, msg:Bytes) {
		var handle = socketHandleUUidMap.get(uuid);
		if (handle == null)
			return;
		handle.close();
		removeHandle(handle);
	}

	public function closeByNickName(nickName:String, msg:Bytes) {
		var handle = socketHandleNicknameMap.get(nickName);
		if (handle == null)
			return;
		handle.close();
		removeHandle(handle);
	}

	// 定时发送信息
	// 定时删除socket
}
