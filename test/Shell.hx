import sys.io.Process;

class Shell
{
    private static var process:Process;
    public static function run(url:String)
    {
        switch (Sys.systemName())
        {
            case "Windows": process = new Process('start $url');
            default: process = new Process('sh $url');
        }
    }
    public static function close()
    {
        process.close();
    }
}