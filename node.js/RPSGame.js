'use strict';

//let pserv = require('./promise-server');
let net = require('net');
let pcli = require('./promise-client');
let Hash = require('./hash');
let udpe = require('./RPSUDPEmitter');

class RPS {
	constructor(v) {
		this.v = v;
	}

	beats(other) {
		if (this.v == RPS.Lose.v)
			return false;
		switch (this.v) {
		case 0:
			return other.v == 2;
		case 1:
			return other.v == 0;
		case 2:
			return other.v == 1;
		default:
			return false;
		}
	}

	toString() {
		if (this.v < 0 || this.v > 2)
			return "Lose";
		return ["Rock", "Paper", "Scissors"][this.v];
	}
}

RPS.Lose = new RPS(255);
RPS.Rock = new RPS(0);
RPS.Paper = new RPS(1);
RPS.Scissors = new RPS(2);

let delay = n => {
	return new Promise((res, rej) => {
		setTimeout(() => res(), n)
	});
}

class RPSGame {
	constructor(host) {
		if (host !== undefined)
			this.host = host;
		this.players = [];
		this.pchoices = [];
		this.ppoints = [];
		this.mypoints = 0;
	}

	async host(n) {
		let uc = new udpe();
		let completePlayers = [];
		let hc = net.createServer(async sock => {
			if (n <= 0) {
				sock.end();
				return;
			}
			let newp = new pcli(sock);
			newp.gport = await newp.read(2);
			await newp.write(Buffer.from([0x43, completePlayers.length]));
			let tasks = completePlayers.map(async p => {
				let addr = p.client.remoteAddress.split('.').map(i => parseInt(i));
				let port = p.gport;
				await newp.write([...addr, ...port]);
			});
			await Promise.all(tasks);
			completePlayers.push(newp);
			n--;
		});
		hc.listen({host: '0.0.0.0', port: 7853}, () => {});
		while (n > 0) {
			await uc.write([0x44, 0x49, 0x53, n]);
			await delay(1000);
		}
		await Promise.all(completePlayers.map(async p => {
			p.write(Buffer.from([ 0x4F, 0x4B, completePlayers.length % 255 ]));
			p.close();
		}));
		uc.close();
		hc.close();
	}

	choose() {
		return new Promise((res, rej) => {
			let selected = 1;
			let choices = [ "💎", "📜", "✂️" ];
			let values = [ RPS.Rock, RPS.Paper, RPS.Scissors ];
			let k;

			let printSelection = () => {
				process.stdout.write("\x1b[2K\r");
				for (let i = 0; i < 3; ++i) {
					if (i == selected) {
						process.stdout.write("\x1b[7m");
					}
					process.stdout.write(choices[i] + " ");
					if (i == selected) {
						process.stdout.write("\x1b[0m");
					}
					process.stdout.write(" ");
				}
				process.stdout.write("arrows to select, space to confirm");
			}

			process.stdin.setRawMode(true);
			process.stdin.setEncoding('utf8');

			process.stdout.write('\x1b[?25l');
			printSelection();

			let handleInput = k => {
				if (k == "\u001b[D")
					selected = (selected - 1);
				else if (k == "\u001b[C")
					selected = (selected + 1) % 3;
				if (selected < 0)
					selected = 2;
				printSelection();
				if (k == ' ') {
					process.stdout.write('\x1b[?25h');
					process.stdin.setRawMode(false);
					process.stdin.removeAllListeners('data');
					res(values[selected]);
				}
			}

			process.stdin.on('data', handleInput);
		});
	}

	random(n) {
		return [...Array(n).keys()].map(() => ~~(Math.random() * 255));
	}

	async doTurn() {
		let choice = await this.choose();
		console.log(`\nI chose ${choice}`);
		let packet = this.random(31);
		packet.unshift(choice.v);
		let hash = Hash.hashData(packet);
		hash.unshift(0x4B);

		let choicestasks = this.players.map(async cli => {
			await cli.write(Buffer.from(hash));
			let oh = await cli.read(33);
			// Point de synchro
			if (oh[0] != 0x4B) {
				return RPS.Lose;
			}
			let otherHash = oh.slice(1);
			oh = [0x56, choice.v];
			oh.push(...packet.slice(1));
			await cli.write(Buffer.from(oh));
			oh = await cli.read(33);
			if (oh[0] != 0x56) {
				return RPS.Lose;
			}
			let otherChoice = new RPS(oh[1]);
			console.log("An other player supposedly chose " + otherChoice);
			let otherSecret = oh.slice(2);
			otherSecret.unshift(otherChoice.v);
			let longHash = Hash.hashData(otherSecret);
			if (otherHash.every((v, i) => v === longHash[i]))
				return otherChoice;
			return RPS.Lose;
		});

		choicestasks = await Promise.all(choicestasks);
		this.pchoices = choicestasks;
		let sum = (b, c) => b + c;
		this.ppoints = this.pchoices.map(c => {
			if (c == RPS.Lose)
				return -1;
			let wins = this.pchoices.map(d => c.beats(d)).reduce(sum);
			let losses = this.pchoices.map(d => d.beats(c)).reduce(sum);
			wins += c.beats(choice);
			losses += choice.beats(c);
			return wins - losses;
		});
		let mwins = this.pchoices.map(d => choice.beats(d)).reduce(sum);
		let mlosses = this.pchoices.map(d => d.beats(choice)).reduce(sum);
		this.mypoints = mwins - mlosses;
	}

	async play() {
		while (this.players.length) {
			console.log(`There's ${this.players.length} other players left!`);
			this.ppoints = [];
			await this.doTurn();
			this.players.map((p, idx) => [p, idx])
				.filter(n => this.ppoints[n[1]] < 0)
				.forEach(n => {
					console.log(`Removing a player because of sub ${this.ppoints[n[1]]} points`);
					this.ppoints.splice(n[1], 1);
					this.players[n[1]].close();
					this.players.splice(n[1], 1);
				})
			if (this.mypoints < 0) {
				console.log("I lost to this");
				break;
			}
			var endtasks = this.players.map(async p => {
				let data = [0x43, 0x4F, 0x4E];
				await p.write(data);
				let res = await p.read(3);
				return res.every((v, i) => v === data[i]);
			});
			// TODO: timeout here
			await Promise.all(endtasks);
			let results = endtasks.map(t => {
				if (!t)
					Console.WriteLine("Other player violated protocol");
				return t;
			});
		}
		if (this.players.length == 0)
			console.log(`You won with ${this.mypoints} points!`);
		else
			console.log(`You lost with ${this.mypoints} points!`);
		this.players.forEach(p => p.close());
		this.players = [];
	}

	async prepare() {
		let playersips = [];
		let hostcon = new pcli(this.host.address, this.host.port);
		let serv = net.createServer(sock => this.players.push(new pcli(sock)));
		let port = await new Promise(res => {
			serv.listen({port: 0}, async () => {
				let nport = serv.address().port
				nport = [nport & 0xFF, nport >> 8 & 0xFF];
				res(nport);
			});
		});
		await hostcon.write(port);
		let head = await hostcon.read(2);
		if (head[0] != 0x43)
			throw new Error("Protocol error");
		let i = 0;
		while (i < head[1]) {
			let np = await hostcon.read(6);
			let pip = {
				address: `${np[0]}.${np[1]}.${np[2]}.${np[3]}`,
				port: np[5] << 8 | np[4]
			};
			console.log(JSON.stringify(pip));
			playersips.push(pip);
			++i;
		}
		this.players = playersips.map(ip => new pcli(ip.address, ip.port));
		while (true) {
			let beg = await hostcon.read(1);
			if (beg[0] == 0x4F) {
				let res = await hostcon.read(2);
				console.log(res);
				if (res[0] == 0x4B) {
					console.log(`Starting game with ${res[1]} other players`);
					hostcon.close();
					serv.close();
					break;
				}
			} else {
				console.log("Unknown request", beg);
			}
		}
	}
}

module.exports = RPSGame;