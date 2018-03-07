let {U64, I64} = require('n64');

let hashData = (data) => {
	let ret = [
		new U64(0x6b901122, 0xfd987193),
		new U64(0xf61e2562, 0xc040b340),
		new U64(0xd62f105d, 0x02441453),
		new U64(0x21e1cde6, 0xc33707d6)
	];

	for (let i = new U64(0); i.ltn(data.length); i.iaddn(1)) {
		let v = new U64(data[i]);
		for (let j = new U64(1); j.ltn(64); j.iaddn(5)) {
			let mask = (ret[j.andn(0x3).toNumber()].shr(j)).andn(3);
			ret[mask].iadd(v.not().shl(j));
			ret[mask].isub(i.addn(1).mul(j.mul(v.addn(1))));
			let idx = ret[mask].shr(j).and(mask);
			ret[mask].iadd(ret[idx.toNumber()]);
		}
		ret[0].ixor(ret[1]);
		ret[1].ixor(ret[2]);
		ret[2].ixor(ret[3]);
		ret[3].ixor(ret[0]);
	}
	let rawhash = [0, 0, 0, 0, 0, 0, 0, 0,
				   0, 0, 0, 0, 0, 0, 0, 0,
				   0, 0, 0, 0, 0, 0, 0, 0,
				   0, 0, 0, 0, 0, 0, 0, 0];
	ret[0].writeRaw(rawhash, 0);
	ret[1].writeRaw(rawhash, 8);
	ret[2].writeRaw(rawhash, 16);
	ret[3].writeRaw(rawhash, 24);
	return rawhash;
}

let hashToStr = h => {
	return h.map(v => {
		let str = v.toString(16);
		return (str.length < 2 ? '0' : '') + str;
	}).join('');
}

module.exports.hashData = hashData;
module.exports.hashToStr = hashToStr;
