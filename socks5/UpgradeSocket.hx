package socks5;
import haxe.Exception;
import sys.net.Host;
import haxe.io.Bytes;
#if cpp
import cpp.NativeSocket;
import cpp.NativeSsl;
import cpp.Lib;
#elseif neko
import neko.Lib;
#end

private class SocketInput extends haxe.io.Input {
	private var socket:UpgradeSocket;

	public function new(s:UpgradeSocket) {
		this.socket = s;
	}

	public override function readByte() {
		return {
			if (socket.upgraded)
			{
				socket.handshake();
				#if (cpp || neko) NativeSsl.ssl_recv_char(@:privateAccess socket.ssl); #end
			}else{
				#if (cpp || neko) NativeSsl.ssl_recv_char(@:privateAccess socket.__s); #end
			}
		};
	}

	public override function readBytes(buf:haxe.io.Bytes, pos:Int, len:Int):Int {
		var r:Int;
		if (socket == null)
			throw "Invalid handle";
		try {
			if (socket.upgraded)
			{
				socket.handshake();
				#if (cpp || neko) r = NativeSsl.ssl_recv(@:privateAccess socket.ssl,buf.getData(),pos,len); #end
			}else{
				#if (cpp || neko) r = NativeSocket.socket_recv(@:privateAccess socket.__s,buf.getData(),pos,len); #end
			}
		} catch (e:Dynamic) {
			if (e == "Blocking")
				throw haxe.io.Error.Blocked;
			else
				throw haxe.io.Error.Custom(e);
		}
		if (r == 0)
			throw new haxe.io.Eof();
		return r;
	}

	public override function close() {
		super.close();
		if (socket != null)
			socket.close();
	}
}

private class SocketOutput extends haxe.io.Output {
	private var socket:UpgradeSocket;

	public function new(s:UpgradeSocket) {
		this.socket = s;
	}

	public override function writeByte(c:Int) {
		try {
			if (socket.upgraded)
			{
				socket.handshake();
				#if (cpp || neko) NativeSsl.ssl_send_char(@:privateAccess socket.ssl, c); #end
			}else{
				#if (cpp || neko) NativeSocket.socket_send_char(@:privateAccess socket.__s,c); #end
			}
		} catch (e:Dynamic) {
			if (e == "Blocking")
				throw haxe.io.Error.Blocked;
			else
				throw haxe.io.Error.Custom(e);
		}
	}

	public override function writeBytes(buf:haxe.io.Bytes, pos:Int, len:Int):Int {
		return try {
			if (socket.upgraded)
			{
				socket.handshake();
				#if (cpp || neko) return NativeSsl.ssl_send(@:privateAccess socket.ssl, buf.getData(), pos, len); #end
			}else{
				#if (cpp || neko) return NativeSocket.socket_send(@:privateAccess socket.__s, buf.getData(), pos, len); #end
			}
		}catch (e:Dynamic) {
			if (e == "Blocking")
				throw haxe.io.Error.Blocked;
			else
				throw haxe.io.Error.Custom(e);
		}
	}

	public override function close() {
		super.close();
		if (socket != null)
			socket.close();
	}
}
/**
    std/eval/_std/sys/ssl/Socket.hx
    std/cpp/_std/sys/ssl/Socket.hx
    std/neko/_std/sys/ssl/Socket.hx
    std/hl/_std/sys/ssl/Socket.hx

    std/java/_std/sys/ssl/Socket.hx
    std/jvm/_std/sys/ssl/Socket.hx

    std/cs/_std/sys/ssl/Socket.hx

    std/lua/_std/sys/ssl/Socket.hx
    std/python/_std/sys/ssl/Socket.hx
**/
class UpgradeSocket extends sys.ssl.Socket
{
	public var upgraded:Bool = false;
	var _host:Host;
    public function new()
    {
        super();
	}
	#if eval
    override function init(socket:eval.vm.NativeSocket) {
        super.init(socket);
        //override
        input = new SocketInput(this);
		output = new SocketOutput(this);
	}
	#end
    public function upgrade()
    {
		handshakeDone = false;
		if (hostname == null)
			hostname = _host.host;
		#if (neko || cpp) NativeSsl.ssl_set_hostname(ssl, hostname); #end
		#if (hl || hashlink) ssl.setHostname(@:privateAccess hostname.toUtf8()); #end
		handshake();
	}
	override function connect(host:Host, port:Int) {
		_host = host;
		try {
			#if cpp conf #else ctx #end = buildSSLConfig(false);
			ssl = NativeSsl.ssl_new(#if cpp conf #else ctx #end);
			handshakeDone = true; //handshake finished in order to allow upgrade
			NativeSsl.ssl_set_socket(ssl, __s);
			NativeSocket.socket_connect(__s, host.ip, port);
			handshake();
		} catch (s:String) {
			if (s == "Invalid socket handle")
				throw "Failed to connect on " + host.host + ":" + port;
			else if (s == "Blocking") {
				// Do nothing, this is not a real error, it simply indicates
				// that a non-blocking connect is in progress
				}else
					Lib.rethrow(s);
		} catch (e:Dynamic) {
			Lib.rethrow(e);
		}
	}
	#if neko
	public function buildSSLConfig(server:Bool)
	{
		return buildSSLContext(server);
	}
	#end
	override function read():String {
		#if neko var b:String; #end
		#if cpp var b:BytesData; #end
		if (upgraded)
		{
			handshake();
			#if (cpp || neko) b = NativeSsl.ssl_read(ssl); #end
		}else{
			#if (cpp || neko) b = NativeSocket.socket_read(__s); #end
		}
		if (b == null)
			return "";
		#if neko return new String(cast b); #end
		#if cpp return haxe.io.Bytes.ofData(b).toString(); #end
	}
}
#if neko
private class NativeSsl
{
    public static var ssl_new = neko.Lib.loadLazy("ssl", "ssl_new", 1);
	public static var ssl_close = neko.Lib.loadLazy("ssl", "ssl_close", 1);
	public static var ssl_handshake = neko.Lib.loadLazy("ssl", "ssl_handshake", 1);
	public static var ssl_set_socket = neko.Lib.loadLazy("ssl", "ssl_set_socket", 2);
	public static var ssl_set_hostname = neko.Lib.loadLazy("ssl", "ssl_set_hostname", 2);
	public static var ssl_get_peer_certificate = neko.Lib.loadLazy("ssl", "ssl_get_peer_certificate", 1);

	public static var ssl_read = neko.Lib.loadLazy("ssl", "ssl_read", 1);
	public static var ssl_write = neko.Lib.loadLazy("ssl", "ssl_write", 2);

	public static var conf_new = neko.Lib.loadLazy("ssl", "conf_new", 1);
	public static var conf_close = neko.Lib.loadLazy("ssl", "conf_close", 1);
	public static var conf_set_ca = neko.Lib.loadLazy("ssl", "conf_set_ca", 2);
	public static var conf_set_verify = neko.Lib.loadLazy("ssl", "conf_set_verify", 2);
	public static var conf_set_cert = neko.Lib.loadLazy("ssl", "conf_set_cert", 3);
    public static var conf_set_servername_callback = neko.Lib.loadLazy("ssl", "conf_set_servername_callback", 2);
    
    public static var ssl_recv = neko.Lib.loadLazy("ssl", "ssl_recv", 4);
    public static var ssl_recv_char = neko.Lib.loadLazy("ssl", "ssl_recv_char", 1);
    
    public static var ssl_send_char = neko.Lib.loadLazy("ssl", "ssl_send_char", 2);
	public static var ssl_send = neko.Lib.loadLazy("ssl", "ssl_send", 4);
}
private class NativeSocket
{
    public static var socket_new = neko.Lib.load("std", "socket_new", 1);
	public static var socket_close = neko.Lib.load("std", "socket_close", 1);
	public static var socket_connect = neko.Lib.load("std", "socket_connect", 3);
	public static var socket_bind = neko.Lib.load("std", "socket_bind", 3);
    public static var socket_accept = neko.Lib.load("std", "socket_accept", 1);

	public static var socket_send_char = neko.Lib.load("std", "socket_send_char", 2);
	public static var socket_send = neko.Lib.load("std", "socket_send", 4);

    public static var socket_read = neko.Lib.load("std", "socket_read", 1);
    public static var socket_write = neko.Lib.load("std", "socket_write", 2);
    
    public static var socket_recv = neko.Lib.load("std", "socket_recv", 4);
	public static var socket_recv_char = neko.Lib.load("std", "socket_recv_char", 1);
}
#end