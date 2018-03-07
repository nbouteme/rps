'use strict';

const dgram = require('dgram');

// Les générateurs async ne viendrons jamais assez tot...
class RPSUDPEmitter {
	constructor() {
		this.server = dgram.createSocket({
			type:'udp4',
			reuseAddr: true
		});
		this.server.bind(7854, '255.255.255.255', () => {
			this.server.setBroadcast(true);
		});
	}

	close() {
		this.server.close();
	}

	write(bytes) {
		return new Promise((res, rej) => {
			this.server.send(Buffer.from(bytes),
							 0,
							 bytes.length,
							 7854,
							 '255.255.255.255',
							 (e) => {
								 if (e)
									 rej(e);
								 res();
							 })
		});
	}
}

module.exports = RPSUDPEmitter;