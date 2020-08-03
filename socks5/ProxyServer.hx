package socks5;
import sys.net.Socket;
class ProxyServer
{
    var socket:Socket;
    var host:String;
    var port:Int;
    public function new(socket:Socket,host:String,port:Int)
    {
        this.socket = socket;
        this.host = host;
        this.port = port;
    }
    public function listen()
    {

    }
    public function bind()
    {
        listen();
    }
}