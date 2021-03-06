//
//  xxHash32.swift
//  xxHash
//
//  Created by Daisuke T on 2019/02/12.
//  Copyright © 2019 xxHash. All rights reserved.
//

import Foundation

public class xxHash32 {

	// MARK: - Enum, Const
	static let prime1: UInt32 = 2654435761	// 0b10011110001101110111100110110001
	static let prime2: UInt32 = 2246822519	// 0b10000101111010111100101001110111
	static let prime3: UInt32 = 3266489917	// 0b11000010101100101010111000111101
	static let prime4: UInt32 =  668265263	// 0b00100111110101001110101100101111
	static let prime5: UInt32 =  374761393	// 0b00010110010101100110011110110001


	
	// MARK: - Property
	private let endian = Common.endian()
	private var state = Common.State<UInt32>()
	public var seed = UInt32(0) {
		didSet {
			reset()
		}
	}



	// MARK: - Life cycle
	
	/// Creates a new instance with the seed.
	///
	/// - Parameter seed: Seed for generate hash. Default is 0.
	public init(_ seed: UInt32 = 0) {
		self.seed = seed
		reset()
	}

}



// MARK: - Utility
public extension xxHash32 {

	static private func round(_ seed: UInt32, input: UInt32) -> UInt32 {
		var seed2 = seed
		seed2 &+= input &* prime2
		seed2 = Common.rotl(seed2, r: 13)
		seed2 &*= prime1

		return seed2
	}

	static private func avalanche(_ h: UInt32) -> UInt32 {
		var h2 = h
		h2 ^= h2 >> 15
		h2 &*= prime2
		h2 ^= h2 >> 13
		h2 &*= prime3
		h2 ^= h2 >> 16

		return h2
	}

}
	


// MARK: - Finalize
public extension xxHash32 {

	static private func finalize(_ h: UInt32, array: [UInt8], len: Int, endian: Common.Endian) -> UInt32 {
		var index = 0
		var h2 = h

		func process1() {
			h2 &+= UInt32(array[index]) &* prime5
			index += 1
			h2 = Common.rotl(h2, r: 11) &* prime1
		}

		func process4() {
			h2 &+= Common.UInt8ArrayToUInt(array, index: index, type: UInt32(0), endian: endian) &* prime3
			index += 4
			h2 = Common.rotl(h2, r: 17) &* prime4
		}

		
		switch len & 15 {
		case 12:
			process4()
			fallthrough

		case 8:
			process4()
			fallthrough

		case 4:
			process4()
			return avalanche(h2)

			
		case 13:
			process4()
			fallthrough
			
		case 9:
			process4()
			fallthrough
			
		case 5:
			process4()
			process1()
			return avalanche(h2)
			
			
		case 14:
			process4()
			fallthrough
			
		case 10:
			process4()
			fallthrough
			
		case 6:
			process4()
			process1()
			process1()
			return avalanche(h2)

			
		case 15:
			process4()
			fallthrough
			
		case 11:
			process4()
			fallthrough
			
		case 7:
			process4()
			fallthrough

		case 3:
			process1()
			fallthrough

		case 2:
			process1()
			fallthrough

		case 1:
			process1()
			fallthrough
			
		case 0:
			return avalanche(h2)
			
		default:
			break
		}

		return h2	// reaching this point is deemed impossible
	}

}



// MARK: - Digest(One-shot)
public extension xxHash32 {

	static private func digest(_ array: [UInt8], seed: UInt32, endian: Common.Endian) -> UInt32 {

		let len = array.count
		var h = UInt32(0)
		var index = 0

		if len >= 16 {
			let limit = len - 15
			var v1 = seed &+ prime1 &+ prime2
			var v2 = seed &+ prime2
			var v3 = seed + 0
			var v4 = seed &- prime1

			repeat {

				v1 = round(v1, input: Common.UInt8ArrayToUInt(array, index: index, type: UInt32(0)))
				index += 4

				v2 = round(v2, input: Common.UInt8ArrayToUInt(array, index: index, type: UInt32(0)))
				index += 4

				v3 = round(v3, input: Common.UInt8ArrayToUInt(array, index: index, type: UInt32(0)))
				index += 4

				v4 = round(v4, input: Common.UInt8ArrayToUInt(array, index: index, type: UInt32(0)))
				index += 4

			} while(index < limit)
			
			h = Common.rotl(v1, r: 1)  &+
				Common.rotl(v2, r: 7)  &+
				Common.rotl(v3, r: 12) &+
				Common.rotl(v4, r: 18)
		}
		else {
			h = seed &+ prime5
		}
		
		h &+= UInt32(len)

		let array2 = Array(array[index...])
		h = finalize(h, array: array2, len: len & 15, endian: endian)

		return h
	}


	/// Generate hash(One-shot)
	///
	/// - Parameters:
	///   - array: Source data for hashing.
	///   - seed: Seed for generate hash. Default is 0.
	/// - Returns: A generated hash.
	static public func digest(_ array: [UInt8], seed: UInt32 = 0) -> UInt32 {
		return digest(array, seed: seed, endian: Common.endian())
	}
	
	/// Overload func for "digest(_ array: [UInt8], seed: UInt32 = 0)".
	static public func digest(_ string: String, seed: UInt32 = 0) -> UInt32 {
		return digest(Array(string.utf8), seed: seed, endian: Common.endian())
	}
	
	/// Overload func for "digest(_ array: [UInt8], seed: UInt32 = 0)".
	static public func digest(_ data: Data, seed: UInt32 = 0) -> UInt32 {
		return digest([UInt8](data), seed: seed, endian: Common.endian())
	}

}



// MARK: - Digest(Streaming)
public extension xxHash32 {
	
	/// Reset current streaming state to initial.
	public func reset() {
		state = Common.State()
		
		state.v1 = seed &+ xxHash32.prime1 &+ xxHash32.prime2
		state.v2 = seed &+ xxHash32.prime2
		state.v3 = seed + 0
		state.v4 = seed &- xxHash32.prime1
	}


	/// Update streaming state.
	///
	/// - Parameter array: Source data for hashing.
	public func update(_ array: [UInt8]) {
		let len = array.count
		var index = 0

		state.totalLen += UInt32(len)
		state.largeLen = (len >= 16) || (state.totalLen >= 16)
		
		if state.memsize + len < 16 {

			// fill in tmp buffer
			state.mem.replaceSubrange(state.memsize..<state.memsize+len, with: array)			
			state.memsize += len

			return
		}

		
		if state.memsize > 0 {
			// some data left from previous update
			for i in 0..<16 - state.memsize {
				state.mem[state.memsize + i] = array[i]
			}

			state.v1 = xxHash32.round(state.v1, input: Common.UInt8ArrayToUInt(state.mem, index: 0, type: UInt32(0), endian: endian))
			state.v2 = xxHash32.round(state.v2, input: Common.UInt8ArrayToUInt(state.mem, index: 4, type: UInt32(0), endian: endian))
			state.v3 = xxHash32.round(state.v3, input: Common.UInt8ArrayToUInt(state.mem, index: 8, type: UInt32(0), endian: endian))
			state.v4 = xxHash32.round(state.v4, input: Common.UInt8ArrayToUInt(state.mem, index: 12, type: UInt32(0), endian: endian))
			
			index += 16 - state.memsize
			state.memsize = 0
		}
		
		if index <= len - 16 {
			
			let limit = len - 16
			var v1 = state.v1
			var v2 = state.v2
			var v3 = state.v3
			var v4 = state.v4

			repeat {

				v1 = xxHash32.round(v1, input: Common.UInt8ArrayToUInt(array, index: index, type: UInt32(0), endian: endian))
				index += 4

				v2 = xxHash32.round(v2, input: Common.UInt8ArrayToUInt(array, index: index, type: UInt32(0), endian: endian))
				index += 4

				v3 = xxHash32.round(v3, input: Common.UInt8ArrayToUInt(array, index: index, type: UInt32(0), endian: endian))
				index += 4

				v4 = xxHash32.round(v4, input: Common.UInt8ArrayToUInt(array, index: index, type: UInt32(0), endian: endian))
				index += 4

			} while (index <= limit)

			state.v1 = v1
			state.v2 = v2
			state.v3 = v3
			state.v4 = v4
		
		}
		
		
		if index < len {
			for i in 0..<len - index {
				state.mem[i] = array[index + i]
			}

			state.memsize = len - index
		}

	}

	/// Overload func for "update(_ array: [UInt8])".
	public func update(_ string: String) {
		return update(Array(string.utf8))
	}

	/// Overload func for "update(_ array: [UInt8])".
	public func update(_ data: Data) {
		return update([UInt8](data))
	}
	
	
	/// Generate hash(Streaming)
	///
	/// - Returns: A generated hash from current streaming state.
	public func digest() -> UInt32 {
		var h = UInt32(0)

		if state.largeLen {
			h = Common.rotl(state.v1, r: 1)  &+
				Common.rotl(state.v2, r: 7)  &+
				Common.rotl(state.v3, r: 12) &+
				Common.rotl(state.v4, r: 18)

		}
		else {
			h = state.v3 /* == seed */ &+ xxHash32.prime5
		}
		
		h &+= state.totalLen

		h = xxHash32.finalize(h, array: state.mem, len: state.memsize, endian: endian)
		
		return h
	}

}



// MARK: - Canonical
public extension xxHash32 {

	static private func canonicalFromHash(_ hash: UInt32, endian: Common.Endian) -> [UInt8] {
		var hash2 = hash
		if endian == Common.Endian.Little {
			hash2 = Common.swap(hash2)
		}

		return Common.UIntToUInt8Array(hash2, endian: endian)
	}

	/// Get canonical from hash.
	///
	/// - Parameter hash: A target hash.
	/// - Returns: An array of canonical.
	static public func canonicalFromHash(_ hash: UInt32) -> [UInt8] {
		return canonicalFromHash(hash, endian: Common.endian())
	}


	static private func hashFromCanonical(_ canonical: [UInt8], endian: Common.Endian) -> UInt32 {
		var hash = Common.UInt8ArrayToUInt(canonical, index: 0, type: UInt32(0), endian: endian)		
		if endian == Common.Endian.Little {
			hash = Common.swap(hash)
		}
		
		return hash
	}
	
	/// Get hash from canonical.
	///
	/// - Parameter canonical: A target canonical.
	/// - Returns: A hash.
	static public func hashFromCanonical(_ canonical: [UInt8]) -> UInt32 {
		return hashFromCanonical(canonical, endian: Common.endian())
	}
	
}
