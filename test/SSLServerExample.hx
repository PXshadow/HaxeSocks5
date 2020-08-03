import sys.net.Host;
import sys.net.Socket;
import sys.ssl.Socket as SocketSSL; // aliased to avoid conflict with sys.net.Socket
import sys.ssl.Certificate;
import sys.ssl.Key;
import sys.thread.Thread;

class SSLServerExample {
  public static function main() {
    var listener_socket = new SocketSSL();
    var cert = Certificate.loadFile('server/rootcert.pem');
    listener_socket.setCA(cert);
    listener_socket.setCertificate(cert, Key.loadFile('server/rootkey.pem'));
    listener_socket.setHostname('foo.example.com');

    // e.g. for an application like an HTTPs server, the client
    // doesn't need to provide a certificate. Otherwise we get:
    // Error: SSL - No client certification received from the client, 
    // but required by the authentication mode
    listener_socket.verifyCert = false;

    // Binding 0.0.0.0 means, listen on "any / all IP addresses on this host"
    listener_socket.bind(new Host('0.0.0.0'), 8000);
    listener_socket.listen(9999); // big max connections

    while (true) {
      // Accepting socket
      trace('waiting to accept...');
      var peer_connection:SocketSSL = listener_socket.accept();
      if (peer_connection != null) {
        trace('got connection from : ' + peer_connection.peer());
        peer_connection.handshake(); // This may not be necessary, if !verifyCert

        // Spawn a reader thread for this connection:
        var thrd = Thread.create(reader);
        trace('sending socket...');
        thrd.sendMessage(peer_connection);
        trace('ok...');
      }
    }
  }

  static function reader() {
    var peer_connection:Socket = cast Thread.readMessage(true);
    trace('new reader thread...');

    while (true) {
      try {
        Sys.print(peer_connection.input.readString(1));
      } catch (e:haxe.io.Eof) {
        trace('Eof, reader thread exiting...');
        return;
      } catch (e:Any) {
        trace('Uncaught: ${e}'); // throw e;
      }
    }
  }
}