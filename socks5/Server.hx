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
        var args = Sys.args();
        new Server();
    }
    var loop:Loop;
    public function new(port:Int=8000)
    {
        loop = Loop.getDefault();
        super(loop);
        noDelay(true);
        bind(new Host("0.0.0.0"),8000);
        Sys.println('Socks5 proxy server started on $port');
        listen(100,function()
        {
            var stream = accept();
            var int:Int = 0;
            stream.readStart(function(data:Bytes)
            {
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
                    stream.write(out);
                    default:
                    trace("more data "  + data);
                    return;
                }
                int++;
            });
        });
        loop.run(Default);
    }
}
#end