import socks5.Socket;
import sys.thread.Thread;
import sys.net.Host;
class Test
{
    static function main()
    {
        trace("create server");
        Thread.create(function()
        {
            var server_tcp = new sys.net.Socket();
            server_tcp.bind(new Host("0.0.0.0"),8000);
            server_tcp.listen(1);
            var client = server_tcp.accept();
            client.output.writeString("hey");
        });
        Thread.create(function()
        {
            var server_tcp = new sys.ssl.Socket();
            server_tcp.bind(new Host("0.0.0.0"),8005);
            server_tcp.listen(1);
            var client = server_tcp.accept();
            client.output.writeString("hey");
        });
        trace("start socket");
        var socket = new Socket();
        socket.connect(new Host("localhost"),8000);
        trace("connected!");
        trace("read: " + socket.input.readString(3));
    }
}