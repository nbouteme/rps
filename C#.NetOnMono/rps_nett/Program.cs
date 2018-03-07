using System;
using System.Linq;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace rps_nett {
    class MainClass {
        public static string BytesToString(byte[] data) {
            List<byte> bytes = new List<byte>(data);
            return bytes.ConvertAll(b => b.ToString("x2")).Aggregate((a, b) => a + b);
        }

        public static byte[] HashData(byte[] data) {
            Console.WriteLine("Hashing " + BytesToString(data));
            byte[] ret = new byte[32];
            ulong[] hash = {
                0x6b901122fd987193,
                0xf61e2562c040b340,
                0xd62f105d02441453,
                0x21e1cde6c33707d6
            };

            for (int i = 0; i < data.Length; ++i) {
                ulong v = data[i];
                for (int j = 1; j < 64; j += 5) {
                    ulong mask = (hash[j & 0x3] >> j) & 3;
                    hash[mask] += ~v << j;
                    hash[mask] -= (ulong)((i + 1) * j) * (v + 1);
                    hash[mask] += hash[(hash[mask] >> j) & mask];
                }
                hash[0] ^= hash[1];
                hash[1] ^= hash[2];
                hash[2] ^= hash[3];
                hash[3] ^= hash[0];
            }
            Buffer.BlockCopy(hash, 0, ret, 0, 32);
            Console.WriteLine("Hashed: " + BytesToString(ret));
            return ret;
        }

        public static void UsageAndDie(string[] args) {
            Console.WriteLine("Usage: mono ./rps create [n_players] | join");
            Environment.Exit(1);
        }

        // status absolutus de mono en 2018
        // https://github.com/mono/mono/issues/6752
        // tl;dr: export TERM=xterm si ncurses > 6.0

        public static void Main(string[] args) {
            if (args.Length < 1) {
                UsageAndDie(args);
            }
            if (args[0] == "create") {
                var n = 2;
                if (args.Length > 1)
                    n = int.Parse(args[1]);
                var rps = new RPSGame();
                Task.WaitAll(rps.Host(n));
            } else if (args[0] == "join") {
                var rpsudpl = new RPSUDPListener();
                var host = rpsudpl.FindHost();
                host.Port = 7853;
                var rps = new RPSGame(host);
                Task.WaitAll(rps.Prepare());
                rps.Play();
            } else
                UsageAndDie(args);

        }
    }
}
