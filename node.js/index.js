let RPSGame = require('./RPSGame');
let RPSUDPListener = require('./RPSUDPListener');

let usage = () => {
	console.log("node index.js create [n] | join");
	process.exit(1);
}

(async () => {
	if (process.argv.length < 3) {
		console.log(process.argv);
		usage();
	}
	if (process.argv[2] == "create") {
		let n = 2;
		try {
			if (process.argv.length > 3)
				n = parseInt(process.argv[3]);
		} catch(e) {}
		let rps = new RPSGame();
		console.log('hosting for', n, 'people')
		await rps.host(n);
	} else if (process.argv[2] == "join") {
		let rpsudpl = new RPSUDPListener();
		let host = await rpsudpl.findHost();
		rpsudpl.close();
		host.port = 7853;
		let rps = new RPSGame(host);
		await rps.prepare();
		await rps.play();
	} else {
		usage();
	}
	/*
	  Pour une  raison inconnue, le  fait d'attacher un  listener data
	  sur process.stdin  fait que  le processus  ne peut  plus quitter
	  normalement, meme si le listener est détaché par la suite...
	 */
	process.exit(0);
})();
