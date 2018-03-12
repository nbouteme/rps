'use strict';

let net = require('net');

class PromiseClient {

	constructor(addr, port) {
		this.cache = [];
		this.connected = false;
		if (port == undefined) {
			this.client = addr;
			this.connected = true;
		} else {
			this.client = new net.Socket();
			console.log('Connecting to ', addr, port);
			this.port = port;
			this.addr = addr;
		}
		this.readPromises = [];
		let sendData = data => {
			this.cache.push(...data.toJSON().data);
			for (let p of this.readPromises)
				if (this.cache.length >= p[1])
					p[0](this.cache.splice(0, p[1]));
			this.readPromises = [];
		};
		this.client.on('data', sendData);
	}


	connect() {
		if (this.connected)
			return;
		return new Promise(res => this.client.connect(this.port, this.addr, res));
	}


	write(data) {
		return new Promise(res => this.client.write(Buffer.from(data), res));
	}

	close() {
		this.client.removeAllListeners('data');
		this.client.end();
	}

	read(nbytes) {
		if (this.cache.length >= nbytes)
			return this.cache.splice(0, nbytes);
		return new Promise(res => this.readPromises.push([res, nbytes]));
	}
}

module.exports = PromiseClient;