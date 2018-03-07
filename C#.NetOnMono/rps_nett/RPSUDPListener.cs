using System.Net.Sockets;
using System.Net;
using System;
using System.Threading.Tasks;
namespace rps_nett {
    public class RPSUDPListener {
        readonly UdpClient uc;
        public delegate void OnHostConnectionDelegate(IPEndPoint host);
        public OnHostConnectionDelegate OnHostConnection;


        public RPSUDPListener() {
            IPEndPoint hostip = new IPEndPoint(IPAddress.Any, 7854);
            uc = new UdpClient(hostip) {
                EnableBroadcast = true,
                DontFragment = true
            };
        }

        public IPEndPoint FindHost() {
            //UdpReceiveResult packet;
            byte[] packet = new byte[4];
            IPEndPoint remote = new IPEndPoint(0, 0);
            while (true) {
                packet = uc.Receive(ref remote);
                uint p = BitConverter.ToUInt32(packet, 0);
                if ((p & 0xFFFFFF) == 0x534944)
                    break;
            }
            return remote;
        }
    }
}
