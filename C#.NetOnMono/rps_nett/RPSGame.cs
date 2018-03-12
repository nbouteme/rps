using System;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace rps_nett {
    public class RPSGame {
        public List<TcpClient> players = new List<TcpClient>();
        List<RPS> playersChoices = new List<RPS>();
        List<int> playersPoints = new List<int>();
        int myPoints;
        private IPEndPoint host;

        public RPSGame(IPEndPoint host) {
            this.host = host;
        }

        public RPSGame() {
        }

        public async Task Host(int n) {
            var udpEp = new IPEndPoint(IPAddress.Broadcast, 7854);
            var uc = new UdpClient(udpEp) {
                EnableBroadcast = true
            };
            uc.Connect(udpEp);
            var hc = new TcpListener(new IPEndPoint(IPAddress.Any, 7853));
            hc.Start();
            var acceptTask = hc.AcceptTcpClientAsync();
            var completePlayers = new List<(TcpClient, byte[])>();

            while (n > 0) {
                await uc.SendAsync(new byte[] { 0x44, 0x49, 0x53, (byte)n }, 4);
                var finished = await Task.WhenAny(acceptTask, Task.Delay(1000));
                if (finished == acceptTask) {
                    var newPlayer = acceptTask.Result;
                    var newPlayerCon = new TcpListener(IPAddress.Any, 0);
                    newPlayerCon.Start();
                    var npportb = new byte[2];
                    await newPlayer.GetStream().ReadAsync(npportb, 0, 2);
                    var tuples = completePlayers.ConvertAll(p => {
                        var stream = p.Item1.GetStream();
                        var tuple = new byte[6];
                        var ip = (IPEndPoint)p.Item1.Client.RemoteEndPoint;
                        ip.Address.GetAddressBytes().CopyTo(tuple, 0);
                        p.Item2.CopyTo(tuple, 4);
                        return tuple;
                    });
                    await newPlayer.GetStream().WriteAsync(new byte[] { 0x43, (byte)(tuples.Count) }, 0, 2);
                    tuples.ForEach(t => newPlayer.GetStream().WriteAsync(t, 0, 6));
                    completePlayers.Add((newPlayer, npportb)); // ???
                    --n;
                    acceptTask = hc.AcceptTcpClientAsync();
                }
            }
            uc.Close();
            hc.Stop();
            var endMessage = new byte[3] { 0x4F, 0x4B, (byte)(completePlayers.Count) };
            Task.WaitAll(completePlayers.ConvertAll(async p => {
                await p.Item1.GetStream().WriteAsync(endMessage, 0, 3);
                p.Item1.Close();
            }).ToArray());
        }

        public async Task Prepare() {
            List<IPEndPoint> playersips = new List<IPEndPoint>();
            var listener = new TcpListener(IPAddress.Any, 0);
            listener.Start();

            var hostcon = new TcpClient();
            hostcon.Connect(host);
            var stream = hostcon.GetStream();
            var pport = ((IPEndPoint)listener.Server.LocalEndPoint).Port;
            await stream.WriteAsync(BitConverter.GetBytes(pport), 0, 2);

            byte[] detail = new byte[3];
            await stream.ReadAsync(detail, 0, 2);
            if (detail[0] != 0x43)
                throw new Exception("Badly formatted packet");
            int i = 0;
            while (i < detail[1]) {
                byte[] newPlayer = new byte[6];
                stream.Read(newPlayer, 0, 6);
                int addr = BitConverter.ToInt32(newPlayer, 0);
                ushort port = BitConverter.ToUInt16(newPlayer, 4);
                playersips.Add(new IPEndPoint(addr, port));
                ++i;
            }
            players = playersips.ConvertAll(ip => {
                var r = new TcpClient();
                Console.WriteLine("Connecting to another player...");
                r.Connect(ip);
                return r;
            });
            detail[0] = 0;
            while (true) {
                Console.WriteLine("Waiting for beginning");
                stream.Read(detail, 0, 3);
                if (detail[0] == 0x4F) {
                    if (detail[1] == 0x4B) {
                        while (players.Count() != detail[2] - 1) {
                            players.Add(await listener.AcceptTcpClientAsync());
                        }
                        listener.Stop();
                        Console.WriteLine("Starting game with {0:d} other players", detail[2] - 1);
                        break;
                    }
                }
            }
        }

        RPS Choose() {
            ConsoleKey k;
            int selected = 1;
            string[] choices = { "💎", "📜", "✂️" };
            Console.CursorVisible = false;
            do {
                Console.Write("\x1b[2K\r");
                for (int i = 0; i < 3; ++i) {
                    // bug graphique où noir est différent de la couleur de base
                    // peut etre du au fait que mon terminal supporte 256 couleurs
                    if (i == selected) {
                        var tmp = Console.BackgroundColor;
                        Console.BackgroundColor = Console.ForegroundColor;
                        Console.ForegroundColor = tmp;
                    }
                    Console.Write(choices[i] + " ");
                    if (i == selected) {
                        var tmp = Console.BackgroundColor;
                        Console.BackgroundColor = Console.ForegroundColor;
                        Console.ForegroundColor = tmp;
                    }
                    Console.Write(" ");
                }
                Console.Write("arrows to select, space to confirm");
                k = Console.ReadKey(false).Key;
                if (k == ConsoleKey.LeftArrow)
                    selected = (selected - 1);
                else if (k == ConsoleKey.RightArrow)
                    selected = (selected + 1) % 3;
                if (selected < 0)
                    selected = 2;
            } while (k != ConsoleKey.Spacebar);
            Console.CursorVisible = true;
            byte choice = (byte)(selected);
            Console.WriteLine("\nI chose " + ((RPS)choice));
            return choice;
        }

        void DoTurn() {
            var choice = Choose();
            byte[] packet = new byte[32];
            byte[] secret = new byte[31];
            byte[] full = new byte[33];
            new Random().NextBytes(secret);
            packet[0] = choice;
            Buffer.BlockCopy(secret, 0, packet, 1, 31);
            var hash = MainClass.HashData(packet);
            full[0] = 0x4B;
            Buffer.BlockCopy(hash, 0, full, 1, 32);
            Console.WriteLine("Using secret " + MainClass.BytesToString(secret));
            Console.WriteLine("Sending packet " + MainClass.BytesToString(full));

            var choicestasks = players.ConvertAll(async cli => {
                byte[] oh = new byte[33];
                byte[] otherHash = new byte[32];
                byte[] otherSecret = new byte[32];
                var cs = cli.GetStream();
                await cs.WriteAsync(full, 0, 33);
                await cs.ReadAsync(oh, 0, 33);
                // Point de synchro
                if (oh[0] != 0x4B) {
                    Console.WriteLine("Malformed response...");
                    return RPS.Lose;
                }
                Console.WriteLine("Received packet " + MainClass.BytesToString(oh));
                Buffer.BlockCopy(oh, 1, otherHash, 0, 32);
                oh[0] = 0x56;
                oh[1] = choice;
                Buffer.BlockCopy(secret, 0, oh, 2, 31);
                Console.WriteLine("Sending verification packet " + MainClass.BytesToString(oh));
                await cs.WriteAsync(oh, 0, 33);
                await cs.ReadAsync(oh, 0, 33);
                Console.WriteLine("Received verification packet " + MainClass.BytesToString(oh));
                if (oh[0] != 0x56) {
                    Console.WriteLine("Malformed response...");
                    return RPS.Lose;
                }
                RPS otherChoice = oh[1];
                Console.WriteLine("Other player supposedly chose " + otherChoice);
                Buffer.BlockCopy(oh, 2, otherSecret, 1, 31);
                otherSecret[0] = otherChoice;
                var longHash = MainClass.HashData(otherSecret);
                if (otherHash.SequenceEqual(longHash))
                    return otherChoice;
                Console.WriteLine("Bad hash detected");
                return RPS.Lose;
            });

            Task.WaitAll(choicestasks.ToArray(), 500000);
            playersChoices = choicestasks.ConvertAll(t => {
                if (!t.IsCompleted)
                    Console.WriteLine("Player took too long to answer");
                return t.IsCompleted ? t.Result : RPS.Lose;
            });
            playersPoints = playersChoices.ConvertAll(c => {
                if (c == RPS.Lose)
                    return -1;
                var wins = playersChoices.ConvertAll(d => c.Beats(d) ? 1 : 0).Sum();
                var losses = playersChoices.ConvertAll(d => d.Beats(c) ? 1 : 0).Sum();
                wins += c.Beats(choice) ? 1 : 0;
                losses += choice.Beats(c) ? 1 : 0;
                return wins - losses;
            });
            var mwins = playersChoices.ConvertAll(d => choice.Beats(d) ? 1 : 0).Sum();
            var mlosses = playersChoices.ConvertAll(d => d.Beats(choice) ? 1 : 0).Sum();
            myPoints = mwins - mlosses;
        }

        public void Play() {
            while (players.Count != 0) {
                Console.WriteLine("There's {0:d} other players left!", players.Count);
                playersPoints = new List<int>();
                DoTurn();

                var zipped = players.Zip(playersPoints, (TcpClient other, int points) => new { other, points });
                var removed = zipped.Where(z => z.points < 0);
                var alive = zipped.Where(z => z.points >= 0);
                players = alive.Select(z => z.other).ToList();
                playersPoints = alive.Select(z => z.points).ToList();

                foreach (var z in removed) {
                    z.other.Close();
                }
                if (myPoints < 0) {
                    Console.WriteLine("I lost to this");
                    break;
                }
            }
            if (players.Count == 0)
                Console.WriteLine("You won with {0:d} points!", myPoints);
            else
                Console.WriteLine("You lost with {0:d} points!", myPoints);
            Console.WriteLine("Ended with {0:d} players left!", players.Count);
        }

        private class RPS {
            byte b;

            public static RPS Lose = new RPS { b = 255 };
            public static RPS Rock = new RPS { b = 0 };
            public static RPS Paper = new RPS { b = 1 };
            public static RPS Scissors = new RPS { b = 2 };

            private RPS() { }

            public static implicit operator byte(RPS r) {
                return r.b;
            }

            public override string ToString() {
                if (b >= 3)
                    return "Lose";
                return new string[] { "Rock", "Paper", "Scissors" }[b];
            }

            public bool Beats(RPS o) {
                if (this == Lose)
                    return false;
                switch (b) {
                case 0:
                    return o == Scissors;
                case 1:
                    return o == Rock;
                case 2:
                    return o == Paper;
                default:
                    return false;
                }
            }

            public bool IsBeatenBy(RPS o) {
                if (this == Lose)
                    return true;
                return this != o && !Beats(o);
            }

            public static implicit operator RPS(byte r) {
                switch (r) {
                case 0:
                    return Rock;
                case 1:
                    return Paper;
                case 2:
                    return Scissors;
                default:
                    return Lose;
                }
            }
        }
    }
}