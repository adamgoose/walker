package;

import haxe.ds.Vector;
import haxe.Int64;
import haxe.io.Bytes;
import haxe.crypto.Md5;
import haxe.crypto.Sha1;

class Uuid {
	public inline static var DNS = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';
	public inline static var URL = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';
	public inline static var ISO_OID = '6ba7b812-9dad-11d1-80b4-00c04fd430c8';
	public inline static var X500_DN = '6ba7b814-9dad-11d1-80b4-00c04fd430c8';
	public inline static var NIL = '00000000-0000-0000-0000-000000000000';

	public inline static var LOWERCASE_BASE26 = "abcdefghijklmnopqrstuvwxyz";
	public inline static var UPPERCASE_BASE26 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	public inline static var NO_LOOK_ALIKES_BASE51 = "2346789ABCDEFGHJKLMNPQRTUVWXYZabcdefghijkmnpqrtwxyz"; // without 1, l, I, 0, O, o, u, v, 5, S, s
	public inline static var FLICKR_BASE58 = "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ"; // without similar characters 0/O, 1/I/l
	public inline static var BASE_70 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-+!@#$^";
	public inline static var COOKIE_BASE90 = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!#$%&'()*+-./:<=>?@[]^_`{|}~";
	public inline static var NANO_ID_ALPHABET = "_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

	public inline static var NUMBERS_BIN = "01";
	public inline static var NUMBERS_OCT = "01234567";
	public inline static var NUMBERS_DEC = "0123456789";
	public inline static var NUMBERS_HEX = "0123456789abcdef";

	static var lastMSecs:Float = 0;
	static var lastNSecs = 0;
	static var clockSequenceBuffer:Int = -1;
	static var regexp:EReg = ~/^(?:[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}|00000000-0000-0000-0000-000000000000)$/i;

	// static var rndSeed:Int = Std.int(Timer.stamp() * 1000);
	static var rndSeed:Int = Std.int(lua.Os.time() * 1000);
	static var state0 = splitmix64_seed(rndSeed);
	static var state1 = splitmix64_seed(rndSeed + 1);

	private static function splitmix64_seed(index:Int):Int64 {
		var result:Int64 = (index + Int64.make(0x9E3779B9, 0x7F4A7C15));
		result = (result ^ (result >> 30)) * Int64.make(0xBF58476D, 0x1CE4E5B9);
		result = (result ^ (result >> 27)) * Int64.make(0x94D049BB, 0x133111EB);
		return result ^ (result >> 31);
	}

	public static function randomFromRange(min:Int, max:Int):Int {
		var s1:Int64 = state0;
		var s0:Int64 = state1;
		state0 = s0;
		s1 ^= s1 << 23;
		state1 = s1 ^ s0 ^ (s1 >>> 18) ^ (s0 >>> 5);
		var result:Int = ((state1 + s0) % (max - min + 1)).low;
		result = (result < 0) ? -result : result;
		return result + min;
	}

	public static function randomByte():Int {
		return randomFromRange(0, 255);
	}

	public static function fromShort(shortUuid:String, separator:String = '-', fromAlphabet:String = FLICKR_BASE58):String {
		var uuid = Uuid.convert(shortUuid, fromAlphabet, NUMBERS_HEX);
		return hexToUuid(uuid, separator);
	}

	public static function toShort(uuid:String, separator:String = '-', toAlphabet:String = FLICKR_BASE58):String {
		uuid = StringTools.replace(uuid, separator, '').toLowerCase();
		return Uuid.convert(uuid, NUMBERS_HEX, toAlphabet);
	}

	public static function fromNano(nanoUuid:String, separator:String = '-', fromAlphabet:String = NANO_ID_ALPHABET):String {
		var uuid = Uuid.convert(nanoUuid, fromAlphabet, NUMBERS_HEX);
		return hexToUuid(uuid, separator);
	}

	public static function toNano(uuid:String, separator:String = '-', toAlphabet:String = NANO_ID_ALPHABET):String {
		uuid = StringTools.replace(uuid, separator, '').toLowerCase();
		return Uuid.convert(uuid, NUMBERS_HEX, toAlphabet);
	}

	public static function v3(name:String, namespace:String = "", separator:String = "-", shortUuid:Bool = false, toAlphabet:String = FLICKR_BASE58):String {
		namespace = StringTools.replace(namespace, '-', '');
		var buffer = Md5.make(Bytes.ofHex(namespace + Bytes.ofString(name).toHex()));
		buffer.set(6, (buffer.get(6) & 0x0f) | 0x30);
		buffer.set(8, (buffer.get(8) & 0x3f) | 0x80);
		var uuid = stringify(buffer, separator);
		if (shortUuid)
			uuid = Uuid.toShort(uuid, separator, toAlphabet);
		return uuid;
	}

	public static function v4(randBytes:Bytes = null, ?randomFunc:Void->Int, separator:String = "-", shortUuid:Bool = false,
			toAlphabet:String = FLICKR_BASE58):String {
		if (randomFunc == null)
			randomFunc = randomByte;
		var buffer:Bytes = randBytes;
		if (buffer == null) {
			buffer = Bytes.alloc(16);
			for (i in 0...16) {
				buffer.set(i, randomFunc());
			}
		} else {
			if (buffer.length < 16)
				throw "Random bytes should be at least 16 bytes";
		}
		buffer.set(6, (buffer.get(6) & 0x0f) | 0x40);
		buffer.set(8, (buffer.get(8) & 0x3f) | 0x80);
		var uuid = stringify(buffer, separator);
		if (shortUuid)
			uuid = Uuid.toShort(uuid, separator, toAlphabet);
		return uuid;
	}

	public static function v5(name:String, namespace:String = "", separator:String = "-", shortUuid:Bool = false, toAlphabet:String = FLICKR_BASE58):String {
		namespace = StringTools.replace(namespace, '-', '');
		var buffer = Sha1.make(Bytes.ofHex(namespace + Bytes.ofString(name).toHex()));
		buffer.set(6, (buffer.get(6) & 0x0f) | 0x50);
		buffer.set(8, (buffer.get(8) & 0x3f) | 0x80);
		var uuid = stringify(buffer, separator);
		if (shortUuid)
			uuid = Uuid.toShort(uuid, separator, toAlphabet);
		return uuid;
	}

	public static function stringify(data:Bytes, separator:String = "-"):String {
		return hexToUuid(data.toHex(), separator);
	}

	public static function parse(uuid:String, separator:String = "-"):Bytes {
		return Bytes.ofHex(StringTools.replace(uuid, separator, ''));
	}

	public static function validate(uuid:String, separator:String = "-"):Bool {
		if (separator == "") {
			uuid = uuid.substr(0, 8)
				+ "-"
				+ uuid.substr(8, 4)
				+ "-"
				+ uuid.substr(12, 4)
				+ "-"
				+ uuid.substr(16, 4)
				+ "-"
				+ uuid.substr(20, 12);
		} else if (separator != "-") {
			uuid = StringTools.replace(uuid, separator, '-');
		}
		return regexp.match(uuid);
	}

	public static function version(uuid:String, separator:String = "-"):Int {
		uuid = StringTools.replace(uuid, separator, '');
		return Std.parseInt("0x" + uuid.substr(12, 1));
	}

	private static function hexToUuid(hex:String, separator:String):String {
		return (hex.substr(0, 8) + separator + hex.substr(8, 4) + separator + hex.substr(12, 4) + separator + hex.substr(16, 4) + separator
			+ hex.substr(20, 12));
	}

	public static function convert(number:String, fromAlphabet:String, toAlphabet:String):String {
		var fromBase:Int = fromAlphabet.length;
		var toBase:Int = toAlphabet.length;
		var len = number.length;
		var buf:String = "";
		var numberMap:Vector<Int> = new Vector<Int>(len);
		var divide:Int = 0, newlen:Int = 0;
		for (i in 0...len) {
			numberMap[i] = fromAlphabet.indexOf(number.charAt(i));
		}
		do {
			divide = 0;
			newlen = 0;
			for (i in 0...len) {
				divide = divide * fromBase + numberMap[i];
				if (divide >= toBase) {
					numberMap[newlen++] = Math.floor(divide / toBase);
					divide = divide % toBase;
				} else if (newlen > 0) {
					numberMap[newlen++] = 0;
				}
			}
			len = newlen;
			buf = toAlphabet.charAt(divide) + buf;
		} while (newlen != 0);

		return buf;
	}

	public static function nanoId(len:Int = 21, alphabet:String = NANO_ID_ALPHABET, ?randomFunc:Void->Int):String {
		if (randomFunc == null)
			randomFunc = randomByte;
		if (alphabet == null)
			throw "Alphabet cannot be null";
		if (alphabet.length == 0 || alphabet.length >= 256)
			throw "Alphabet must contain between 1 and 255 symbols";
		if (len <= 0)
			throw "Length must be greater than zero";
		var mask:Int = (2 << Math.floor(Math.log(alphabet.length - 1) / Math.log(2))) - 1;
		var step:Int = Math.ceil(1.6 * mask * len / alphabet.length);
		var sb = new StringBuf();
		while (sb.length != len) {
			for (i in 0...step) {
				var rnd = randomFunc();
				var aIndex:Int = rnd & mask;
				if (aIndex < alphabet.length) {
					sb.add(alphabet.charAt(aIndex));
					if (sb.length == len)
						break;
				}
			}
		}
		return sb.toString();
	}

	public static function short(toAlphabet:String = FLICKR_BASE58, ?randomFunc:Void->Int):String {
		return Uuid.v4(randomFunc, true, toAlphabet);
	}
}