'use strict';

const dgram = require('dgram');

// Les générateurs async ne viendrons jamais assez tot...
class RPSUDPListener {
	constructor() {
		this.server = dgram.createSocket({
			type:'udp4',
			reuseAddr: true
		});
		this.server.bind(7854, '0.0.0.0', () => {
			this.server.setBroadcast(true);
		});
	}

	close() {
		this.server.close();
	}

	findHost() {
		const dismsg = Buffer.from('DIS');
		return new Promise((res, rej) => {
			this.server.on('message', (mes, rinfo) => {
				if (mes.compare(dismsg, 0, 3, 0, 3) == 0)
					res(rinfo);
			});
		});
	}
}

module.exports = RPSUDPListener;