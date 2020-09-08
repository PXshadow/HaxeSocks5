import sys.io.Process;
import sys.net.Host;
class Test
{
    static function main()
    {
        //var server = new Process("hl server.hl");
        socks5.Socket.PROXY = {host: "localhost",port: 1080,auth: null};
        var socket = new socks5.Socket();//sys.net.Socket();
        socket.connect(new Host("duckduckgo.com"),80);
        socket.setBlocking(true);
        socket.auth();
        trace("line " + socket.input.readLine());
        /*while (true)
        {
            trace("auth!");
            if (!socket.auth()) continue;
            try {
                trace("line " + socket.input.readLine());
            }catch(e:Dynamic)
            {
                if (e != haxe.io.Error.Blocked)
                {
                    trace("e " + e);
                }
            }
        }*/
    }
}