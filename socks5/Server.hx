#if hl
package socks5;
import haxe.io.Bytes;
import hl.uv.Loop;
import hl.uv.Tcp;
import sys.net.Host;

class Server extends Tcp
{
    public static function main()
    {
        var server = new Server();
        server.update(false);
    }
    var loop:Loop;
    public function new(port:Int=1080)
    {
        loop = Loop.getDefault();
        super(loop);
        noDelay(true);
        bind(new Host("0.0.0.0"),port);
        Sys.println('Socks5 proxy server started on $port');
        listen(100,function()
        {
            var stream = accept();
            trace("connected");
            var int:Int = 0;
            stream.readStart(function(data:Bytes)
            {
                if (data == null) return;
                switch (int)
                {
                    case 0: //greeting 
                    var version = data.get(0);
                    var method = 0x00;
                    if (version != 0x05) 
                    {
                        trace('version wrong: $version');
                        method = 0xFF;
                        version = 0x05;
                    }
                    var out = Bytes.alloc(2);
                    out.set(0,version);
                    out.set(1,method);
                    trace("response to greeting sent");
                    stream.write(out);
                    stream.write(Bytes.ofString("hello world\n \n \n \n"));
                    default:
                    trace("more data "  + data);
                    return;
                }
                int++;
            });
        });
    }
    public inline function update(blocking:Bool=true)
    {
        loop.run(blocking ? Default : NoWait);
    }
}
#end