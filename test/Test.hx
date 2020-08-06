import socks5.ProxyServer;
import haxe.Exception;
import sys.thread.Thread;
import sys.io.Process;
import sys.net.Host;
import sys.io.File;
import sys.FileSystem;

class Test {
	static function main() 
	{
		new Test();
	}
	var server:ThreadServer;
	var tests:Int = 0;
	var tests_sucessful:Int = 0;
	public function new()
	{
		var clean:Bool = true;
		if (clean) haxe.Log.trace = function(v, ?infos) { Sys.println(v);}
		#if !(target.threaded) throw "threading required for test"; #end
		trace("Starting node proxy server on port 1080");
		test("ssl[haxe] -> ssl[haxe]",function()
		{
			//Thread.create(function() {SSLServerExample.main();});
			ThreadServer.createSSLServer();
			socket(true,false);
		});
		test("socket -> proxy -> tcp",function()
		{
			ThreadServer.createServer();
			ThreadProxyServer.create(false);
			socket(false,true);
		});
		test("ssl_socket -> proxy -> ssl",function()
		{
			ThreadServer.createSSLServer();
			socket(true,true);
		});
		trace('tests: $tests_sucessful/$tests sucessful');
		if (tests != tests_sucessful) throw "a test failed";
	}
	private function test(string:String,func:Void->Void):Bool
	{
		tests++;
		var line = [for (i in 0...string.length) "_"].join("");
		trace(line);
		trace(string);
		trace(line);
		try {
			func();
		}catch(e:Exception)
		{
			throw(e.details());
			return false;
		}
		tests_sucessful++;
		return true;
	}
	private function socket(secure:Bool=false,proxy:Bool=true)
	{
		var socket = new socks5.Socket();
		//var socket = new sys.net.Socket();
		socket.setTimeout(6);
		socket.setHostname("example.com");
		socks5.Socket.PROXY = null;
		if (proxy) socks5.Socket.PROXY = {host: "localhost",port: 8005,auth: null};
		trace("trying to connect");
		socket.connect(new Host("localhost"),8000);
		if (secure) 
		{
			socket.verifyCert = false;
			socket.upgrade();
		}
		//socket.setBlocking(false);
		trace("connected");
		//socket.output.writeString("hello world\r\n");
		socket.write("hello world\r\n");
		trace("sent message");
		Sys.sleep(2.5); //wait for message
		var message = socket.input.readString(11);
		trace('recieved back message |$message|');
		if (message == "hello world")
		{
			trace("proxy sucessful");
		}else{
			throw "proxy relay unsucessful";
		}
		socket.close();
	}
}
