'use strict';

let net = require('net');

class PromiseClient {

	constructor(addr, port) {
		this.cache = [];
		if (port == undefined) {
			this.client = addr;
		} else {
			this.client = new net.Socket();
			this.client.connect(port, addr);
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