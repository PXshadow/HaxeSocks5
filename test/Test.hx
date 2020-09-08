import sys.io.Process;
import sys.net.Host;
class Test
{
    static function main()
    {
        trace("create server");
        var server = new Process("hl server.hl");
        var socket = new socks5.Socket();
        socket.connect(new Host("localhost"),8000);
    }
}