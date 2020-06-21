import sys.net.Host;
import sys.io.File;
import sys.FileSystem;

class Test {
	static function main() 
	{
		new Test();
	}
	var proxies:Array<String> = [];
	public function new()
	{
		Sys.println("start test");
		//test upgrade socket
		trace("data " + socks5.Http.requestUrl("https://duckduckgo.com"));
		var update:Bool = true;
		if (FileSystem.exists("proxies.txt"))
		{
			proxies = File.getContent("proxies.txt").split("\n");
			update = Std.parseInt(proxies[0]) == Date.now().getDate();
			proxies = proxies.splice(1,proxies.length);
		}
		if (update)
		{ 
			File.saveContent("proxies.txt",'${Date.now().getDate()}\n${haxe.Http.requestUrl("https://raw.githubusercontent.com/hookzof/socks5_list/master/proxy.txt")}');
			proxies = File.getContent("proxies.txt").split("\n");
			proxies = proxies.splice(1,proxies.length);
		}
		trace('proxy count ${proxies.length}');
		/*var response = socks5.Http.requestUrl("https://api.ipify.org/");
		var response2 = haxe.Http.requestUrl("https://api.ipify.org/");
		Sys.println('test proxy: $response normal: $response2');*/
		var data:Array<String> = [];
		for (proxy in proxies.splice(0,100))
		{
			data = proxy.split(":");
			socks5.Http.PROXY = {host: data[0],port: Std.parseInt(data[1]),auth: null};
			trace('attempt ${data[0]}:${data[1]}');
			trace("url " + socks5.Http.requestUrl("https://api.ipify.org/"));
		}
	}
}
