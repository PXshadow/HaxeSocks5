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
	public function new()
	{
		//haxe.Log.trace = function(v, ?infos) { Sys.println(v);}
		#if !(target.threaded) throw "threading required for test"; #end
		test("[haxe] -> proxy[nodejs] -> tcp[haxe]",function()
		{
			ThreadServer.createServer();
			socket(false,true);
		});
		/*test("ssl[haxe] -> ssl[haxe]",function()
		{
			ThreadServer.createSSLServer();
			socket(true,false);
		});*/
		test("ssl[haxe] -> proxy[nodejs] -> ssl[haxe]",function()
		{
			ThreadServer.createSSLServer();
			socket(true,true);
		});
		/*test("http[haxe] -> proxy[nodejs] -> http[external]",function()
		{

		});
		test("https[haxe] -> proxy[nodejs] -> https[external]",function()
		{

		});*/
	}
	private function test(string:String,func:Void->Void)
	{
		var line = [for (i in 0...string.length) "_"].join("");
		trace(line);
		trace(string);
		trace(line);
		try {
			func();
		}catch(e:Exception)
		{
			trace(e.details());
		}
	}
	private function socket(secure:Bool=false,proxy:Bool=true)
	{
		var socket = new socks5.Socket();
		//var socket = new sys.net.Socket();
		socket.setTimeout(6);
		socket.setHostname("example.com");
		socks5.Socket.PROXY = null;
		if (proxy) socks5.Socket.PROXY = {host: "127.0.0.1",port: 1080,auth: null};
		trace("trying to connect");
		socket.connect(new Host("127.0.0.1"),8000);
		if (secure) 
		{
			socket.verifyCert = false;
			socket.upgrade();
		}
		socket.setBlocking(false);
		trace("connected");
		socket.output.writeString("hello world\n");
		trace("sent message");
		Sys.sleep(2); //wait for message
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
