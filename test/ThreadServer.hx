import haxe.Exception;
import haxe.Timer;
import sys.thread.Thread;
import sys.net.Socket;
import sys.net.Host;
class ThreadServer
{
    public static function createServer():ThreadServer
    {
        return new ThreadServer(new Socket());
    }
    public static function createSSLServer():ThreadServer
    {
        var socket = new sys.ssl.Socket();
        var cert = sys.ssl.Certificate.loadFile("server/rootcert.pem");
        trace("cert " + cert.commonName);
        socket.setCA(cert);
        socket.setCertificate(cert,sys.ssl.Key.loadFile("server/rootkey.pem"));
        socket.setHostname("example.com");
        socket.verifyCert = false;
        return new ThreadServer(socket);
    }
    private function new(socket:Socket)
    {
        Thread.create(function()
        {
            socket.bind(new Host("0.0.0.0"),8000);
            socket.setTimeout(4);
            socket.listen(1);
            trace("waiting for connection...");
            var client = socket.accept();
            client.setBlocking(false);
            client.setFastSend(true);
            trace("socket accepted");
            Sys.sleep(1); //wait for message
            var message = client.input.readLine();
            trace('server read message |$message|');
            client.output.writeString('$message\r\n');
            trace("server finished");
            Sys.sleep(1);
            socket.close();
        });
    }
}