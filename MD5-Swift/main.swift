//
//  main.swift
//  MD5-Swift
//
//  Created by Veight Zhou on 5/12/15.
//  Copyright (c) 2015 Veight Zhou. All rights reserved.
//

import Foundation

// 定义类型
typealias Byte  = UInt8
typealias Word  = UInt32
typealias Block = [Word]

/**
We define a rotate left operator <<<
*/
infix operator <<< {
    associativity none
    precedence  140
}

func <<< (x: Word, n: Word) -> Word {
    let result: Word = (x << n) | (x >> (32 - n))
    return result
}

struct MD5 {
    var rawString: String = "" {
        didSet {
            buffer = [
                0x67452301,
                0xEFCDAB89,
                0x98BADCFE,
                0x10325476
            ]

            transform(string: rawString)
        }
    }
    var buffer: [Word] = [
        0x67452301,
        0xEFCDAB89,
        0x98BADCFE,
        0x10325476
    ]
    var checksum: String {
        get {
            return decode(words: buffer)
        }
    }
    
    func log(word: Word) -> () {
        var binaryString = ""
        for index in 0...31 {
            binaryString = String(word >> Word(index) & 0x1) + binaryString
            if index % 8 == 7 {
                binaryString = " " + binaryString
            }
        }
        binaryString += " -> \(word)"
    }
    
    mutating func transform(var # string: String) -> () {

        let S11: Word = 7
        let S12: Word = 12
        let S13: Word = 17
        let S14: Word = 22
        let S21: Word = 5
        let S22: Word = 9
        let S23: Word = 14
        let S24: Word = 20
        let S31: Word = 4
        let S32: Word = 11
        let S33: Word = 16
        let S34: Word = 23
        let S41: Word = 6
        let S42: Word = 10
        let S43: Word = 15
        let S44: Word = 21
        
        /**
        对输入的文本进行编码， 返回一个编码后的数组。数据中的每个元素都是容量为16的Word数组， 即16*32位的子分组。
        
        :param: string 需要编码的文本
        
        :returns: 每个元素都是容量为16的Word数组
        */
        func encode(# string: String) -> [[Word]] {
            let stringLength:UInt64 = UInt64(count(string))
            
            var bytes = [Byte]()
            for character in string.utf8 {
                let byte = Byte(character)
                bytes.append(byte)
            }
            
            let charactersPaddingLength = 512 - ((stringLength * 8) + 64) % 512
            if charactersPaddingLength > 0 {
                var paddingWords = [Byte](count: Int(charactersPaddingLength / 8), repeatedValue: 0)
                paddingWords[0] = 0x80
                bytes.extend(paddingWords)
            }
            
            var words = [Word]()
            for var i = 0; i < bytes.count; i = i + 4 {
                let word: Word = (Word(bytes[i]) << 0)
                    | (Word(bytes[i + 1]) << 8)
                    | (Word(bytes[i + 2]) << 16)
                    | (Word(bytes[i + 3]) << 24)
                words.append(word)
            }
            
            //  Mark: 生成长度补位编码
            var lengthPaddingWords = [Word](count: 2, repeatedValue: 0)
            let bitsCount: UInt64 = stringLength << 3
            lengthPaddingWords[1] = Word(bitsCount >> 32 & 0xFFFFFFFF)
            lengthPaddingWords[0] = Word(bitsCount & 0xFFFFFFFF)
            
            words.extend(lengthPaddingWords)
            
            let wordsCollectionCount = words.count/16
            var wordsCollection = [[Word]]()
            for index in 0..<wordsCollectionCount {
                let wordsUnit = Array(words[(index*16)..<(index*16 + 16)])
                wordsCollection.append(wordsUnit)
            }
            return wordsCollection
        }
        
        
        func roundProcess(var a: Word, var b: Word, var c: Word, var d: Word,wordsArray x:[Word]) -> (Word, Word, Word, Word) {
            
            func FF(var a: Word, var b: Word, var c: Word, var d: Word, # x: Word, # s: Word, # ac:Word) -> (Word, Word, Word, Word) {
                func F(# x: Word, # y: Word, # z: Word) -> Word {
                    let result = (x & y) | ((~x) & z)
                    return result
                }
                
                /*
                #define FF(a, b, c, d, x, s, ac) { \
                (a) += F ((b), (c), (d)) + (x) + (UINT4)(ac); \
                (a) = ROTATE_LEFT ((a), (s)); \
                (a) += (b); \
                }
                */
                
                a = Word((UInt64(a) + UInt64(F(x: b, y: c, z: d))) & 0xFFFFFFFF)
                a = Word((UInt64(a) + UInt64(x)) & 0xFFFFFFFF)
                a = Word((UInt64(a) + UInt64(ac)) & 0xFFFFFFFF)
                a = a <<< s
                a = Word((UInt64(a) + UInt64(b)) & 0xFFFFFFFF)

                return (a, b, c, d)
            }
            
            func GG(var a: Word, var b: Word, var c: Word, var d: Word, # x: Word, # s: Word, # ac:Word) -> (Word, Word, Word, Word) {
                func G(# x: Word, # y: Word, # z: Word) -> Word {
                    let result = (x & z) | (y & (~z))
                    return result
                }
                
                /*
                #define GG(a, b, c, d, x, s, ac) { \
                (a) += G ((b), (c), (d)) + (x) + (UINT4)(ac); \
                (a) = ROTATE_LEFT ((a), (s)); \
                (a) += (b); \
                }
                */
                a = Word((UInt64(a) + UInt64(G(x: b, y: c, z: d)) + UInt64(x) + UInt64(ac)) & 0xFFFFFFFF)
                a = a <<< s
                a = Word((UInt64(a) + UInt64(b)) & 0xFFFFFFFF)
                return (a, b, c, d)
            }
            
            func HH(var a: Word, var b: Word, var c: Word, var d: Word, # x: Word, # s: Word, # ac:Word) -> (Word, Word, Word, Word) {
                func H(# x: Word, # y: Word, # z: Word) -> Word {
                    let result = x ^ y ^ z
                    return result
                }
                
                /*
                #define HH(a, b, c, d, x, s, ac) { \
                (a) += H ((b), (c), (d)) + (x) + (UINT4)(ac); \
                (a) = ROTATE_LEFT ((a), (s)); \
                (a) += (b); \
                }
                */
                a = Word((UInt64(a) + UInt64(H(x: b, y: c, z: d)) + UInt64(x) + UInt64(ac)) & 0xFFFFFFFF)
                a = a <<< s
                a = Word((UInt64(a) + UInt64(b)) & 0xFFFFFFFF)
                return (a, b, c, d)
            }
            
            func II(var a: Word, var b: Word, var c: Word, var d: Word, # x: Word, # s: Word, # ac:Word) -> (Word, Word, Word, Word) {
                func I(# x: Word, # y: Word, # z: Word) -> Word {
                    let result = y ^ (x | (~z))
                    return result
                }
                
                /*
                #define II(a, b, c, d, x, s, ac) { \
                (a) += I ((b), (c), (d)) + (x) + (UINT4)(ac); \
                (a) = ROTATE_LEFT ((a), (s)); \
                (a) += (b); \
                }
                */
                a = Word((UInt64(a) + UInt64(I(x: b, y: c, z: d)) + UInt64(x) + UInt64(ac)) & 0xFFFFFFFF)
                a = a <<< s
                a = Word((UInt64(a) + UInt64(b)) & 0xFFFFFFFF)
                return (a, b, c, d)
            }
            
            let aa = a
            let bb = b
            let cc = c
            let dd = d

            /* Round 1. */
            /* Let [abcd k s i] denote the operation
            a = b + ((a + F(b,c,d) + X[k] + T[i]) <<< s). */
            /* Do the following 16 operations. */
            /*
            [ABCD  0  7  1]  [DABC  1 12  2]  [CDAB  2 17  3]  [BCDA  3 22  4]
            [ABCD  4  7  5]  [DABC  5 12  6]  [CDAB  6 17  7]  [BCDA  7 22  8]
            [ABCD  8  7  9]  [DABC  9 12 10]  [CDAB 10 17 11]  [BCDA 11 22 12]
            [ABCD 12  7 13]  [DABC 13 12 14]  [CDAB 14 17 15]  [BCDA 15 22 16]
            */
            (a, b, c, d) = FF(a, b, c, d, x: x[ 0], s: S11, ac: 0xd76aa478); /* 1 */
            (d, a, b, c) = FF(d, a, b, c, x: x[ 1], s: S12, ac: 0xe8c7b756); /* 2 */
            (c, d, a, b) = FF(c, d, a, b, x: x[ 2], s: S13, ac: 0x242070db); /* 3 */
            (b, c, d, a) = FF(b, c, d, a, x: x[ 3], s: S14, ac: 0xc1bdceee); /* 4 */
            (a, b, c, d) = FF(a, b, c, d, x: x[ 4], s: S11, ac: 0xf57c0faf); /* 5 */
            (d, a, b, c) = FF(d, a, b, c, x: x[ 5], s: S12, ac: 0x4787c62a); /* 6 */
            (c, d, a, b) = FF(c, d, a, b, x: x[ 6], s: S13, ac: 0xa8304613); /* 7 */
            (b, c, d, a) = FF(b, c, d, a, x: x[ 7], s: S14, ac: 0xfd469501); /* 8 */
            (a, b, c, d) = FF(a, b, c, d, x: x[ 8], s: S11, ac: 0x698098d8); /* 9 */
            (d, a, b, c) = FF(d, a, b, c, x: x[ 9], s: S12, ac: 0x8b44f7af); /* 10 */
            (c, d, a, b) = FF(c, d, a, b, x: x[10], s: S13, ac: 0xffff5bb1); /* 11 */
            (b, c, d, a) = FF(b, c, d, a, x: x[11], s: S14, ac: 0x895cd7be); /* 12 */
            (a, b, c, d) = FF(a, b, c, d, x: x[12], s: S11, ac: 0x6b901122); /* 13 */
            (d, a, b, c) = FF(d, a, b, c, x: x[13], s: S12, ac: 0xfd987193); /* 14 */
            (c, d, a, b) = FF(c, d, a, b, x: x[14], s: S13, ac: 0xa679438e); /* 15 */
            (b, c, d, a) = FF(b, c, d, a, x: x[15], s: S14, ac: 0x49b40821); /* 16 */
            
            /* Round 2. */
            /* Let [abcd k s i] denote the operation
            a = b + ((a + G(b,c,d) + X[k] + T[i]) <<< s). */
            /* Do the following 16 operations. */
            /*
            [ABCD  1  5 17]  [DABC  6  9 18]  [CDAB 11 14 19]  [BCDA  0 20 20]
            [ABCD  5  5 21]  [DABC 10  9 22]  [CDAB 15 14 23]  [BCDA  4 20 24]
            [ABCD  9  5 25]  [DABC 14  9 26]  [CDAB  3 14 27]  [BCDA  8 20 28]
            [ABCD 13  5 29]  [DABC  2  9 30]  [CDAB  7 14 31]  [BCDA 12 20 32]
            */
            (a, b, c, d) = GG(a, b, c, d, x: x[ 1], s: S21, ac: 0xf61e2562); /* 17 */
            (d, a, b, c) = GG(d, a, b, c, x: x[ 6], s: S22, ac: 0xc040b340); /* 18 */
            (c, d, a, b) = GG(c, d, a, b, x: x[11], s: S23, ac: 0x265e5a51); /* 19 */
            (b, c, d, a) = GG(b, c, d, a, x: x[ 0], s: S24, ac: 0xe9b6c7aa); /* 20 */
            (a, b, c, d) = GG(a, b, c, d, x: x[ 5], s: S21, ac: 0xd62f105d); /* 21 */
            (d, a, b, c) = GG(d, a, b, c, x: x[10], s: S22, ac:  0x2441453); /* 22 */
            (c, d, a, b) = GG(c, d, a, b, x: x[15], s: S23, ac: 0xd8a1e681); /* 23 */
            (b, c, d, a) = GG(b, c, d, a, x: x[ 4], s: S24, ac: 0xe7d3fbc8); /* 24 */
            (a, b, c, d) = GG(a, b, c, d, x: x[ 9], s: S21, ac: 0x21e1cde6); /* 25 */
            (d, a, b, c) = GG(d, a, b, c, x: x[14], s: S22, ac: 0xc33707d6); /* 26 */
            (c, d, a, b) = GG(c, d, a, b, x: x[ 3], s: S23, ac: 0xf4d50d87); /* 27 */
            (b, c, d, a) = GG(b, c, d, a, x: x[ 8], s: S24, ac: 0x455a14ed); /* 28 */
            (a, b, c, d) = GG(a, b, c, d, x: x[13], s: S21, ac: 0xa9e3e905); /* 29 */
            (d, a, b, c) = GG(d, a, b, c, x: x[ 2], s: S22, ac: 0xfcefa3f8); /* 30 */
            (c, d, a, b) = GG(c, d, a, b, x: x[ 7], s: S23, ac: 0x676f02d9); /* 31 */
            (b, c, d, a) = GG(b, c, d, a, x: x[12], s: S24, ac: 0x8d2a4c8a); /* 32 */
            
            /* Round 3. */
            /* Let [abcd k s t] denote the operation
            a = b + ((a + H(b,c,d) + X[k] + T[i]) <<< s). */
            /* Do the following 16 operations. */
            /*
            [ABCD  5  4 33]  [DABC  8 11 34]  [CDAB 11 16 35]  [BCDA 14 23 36]
            [ABCD  1  4 37]  [DABC  4 11 38]  [CDAB  7 16 39]  [BCDA 10 23 40]
            [ABCD 13  4 41]  [DABC  0 11 42]  [CDAB  3 16 43]  [BCDA  6 23 44]
            [ABCD  9  4 45]  [DABC 12 11 46]  [CDAB 15 16 47]  [BCDA  2 23 48]
            */
            (a, b, c, d) = HH(a, b, c, d, x: x[ 5], s: S31, ac: 0xfffa3942); /* 33 */
            (d, a, b, c) = HH(d, a, b, c, x: x[ 8], s: S32, ac: 0x8771f681); /* 34 */
            (c, d, a, b) = HH(c, d, a, b, x: x[11], s: S33, ac: 0x6d9d6122); /* 35 */
            (b, c, d, a) = HH(b, c, d, a, x: x[14], s: S34, ac: 0xfde5380c); /* 36 */
            (a, b, c, d) = HH(a, b, c, d, x: x[ 1], s: S31, ac: 0xa4beea44); /* 37 */
            (d, a, b, c) = HH(d, a, b, c, x: x[ 4], s: S32, ac: 0x4bdecfa9); /* 38 */
            (c, d, a, b) = HH(c, d, a, b, x: x[ 7], s: S33, ac: 0xf6bb4b60); /* 39 */
            (b, c, d, a) = HH(b, c, d, a, x: x[10], s: S34, ac: 0xbebfbc70); /* 40 */
            (a, b, c, d) = HH(a, b, c, d, x: x[13], s: S31, ac: 0x289b7ec6); /* 41 */
            (d, a, b, c) = HH(d, a, b, c, x: x[ 0], s: S32, ac: 0xeaa127fa); /* 42 */
            (c, d, a, b) = HH(c, d, a, b, x: x[ 3], s: S33, ac: 0xd4ef3085); /* 43 */
            (b, c, d, a) = HH(b, c, d, a, x: x[ 6], s: S34, ac:  0x4881d05); /* 44 */
            (a, b, c, d) = HH(a, b, c, d, x: x[ 9], s: S31, ac: 0xd9d4d039); /* 45 */
            (d, a, b, c) = HH(d, a, b, c, x: x[12], s: S32, ac: 0xe6db99e5); /* 46 */
            (c, d, a, b) = HH(c, d, a, b, x: x[15], s: S33, ac: 0x1fa27cf8); /* 47 */
            (b, c, d, a) = HH(b, c, d, a, x: x[ 2], s: S34, ac: 0xc4ac5665); /* 48 */
            
            /* Round 4. */
            /* Let [abcd k s t] denote the operation
            a = b + ((a + I(b,c,d) + X[k] + T[i]) <<< s). */
            /* Do the following 16 operations. */
            /*
            [ABCD  0  6 49]  [DABC  7 10 50]  [CDAB 14 15 51]  [BCDA  5 21 52]
            [ABCD 12  6 53]  [DABC  3 10 54]  [CDAB 10 15 55]  [BCDA  1 21 56]
            [ABCD  8  6 57]  [DABC 15 10 58]  [CDAB  6 15 59]  [BCDA 13 21 60]
            [ABCD  4  6 61]  [DABC 11 10 62]  [CDAB  2 15 63]  [BCDA  9 21 64]
            */
            (a, b, c, d) = II(a, b, c, d, x: x[ 0], s: S41, ac: 0xf4292244); /* 49 */
            (d, a, b, c) = II(d, a, b, c, x: x[ 7], s: S42, ac: 0x432aff97); /* 50 */
            (c, d, a, b) = II(c, d, a, b, x: x[14], s: S43, ac: 0xab9423a7); /* 51 */
            (b, c, d, a) = II(b, c, d, a, x: x[ 5], s: S44, ac: 0xfc93a039); /* 52 */
            (a, b, c, d) = II(a, b, c, d, x: x[12], s: S41, ac: 0x655b59c3); /* 53 */
            (d, a, b, c) = II(d, a, b, c, x: x[ 3], s: S42, ac: 0x8f0ccc92); /* 54 */
            (c, d, a, b) = II(c, d, a, b, x: x[10], s: S43, ac: 0xffeff47d); /* 55 */
            (b, c, d, a) = II(b, c, d, a, x: x[ 1], s: S44, ac: 0x85845dd1); /* 56 */
            (a, b, c, d) = II(a, b, c, d, x: x[ 8], s: S41, ac: 0x6fa87e4f); /* 57 */
            (d, a, b, c) = II(d, a, b, c, x: x[15], s: S42, ac: 0xfe2ce6e0); /* 58 */
            (c, d, a, b) = II(c, d, a, b, x: x[ 6], s: S43, ac: 0xa3014314); /* 59 */
            (b, c, d, a) = II(b, c, d, a, x: x[13], s: S44, ac: 0x4e0811a1); /* 60 */
            (a, b, c, d) = II(a, b, c, d, x: x[ 4], s: S41, ac: 0xf7537e82); /* 61 */
            (d, a, b, c) = II(d, a, b, c, x: x[11], s: S42, ac: 0xbd3af235); /* 62 */
            (c, d, a, b) = II(c, d, a, b, x: x[ 2], s: S43, ac: 0x2ad7d2bb); /* 63 */
            (b, c, d, a) = II(b, c, d, a, x: x[ 9], s: S44, ac: 0xeb86d391); /* 64 */
            
            /* Then perform the following additions. (That is increment each
            of the four registers by the value it had before this block
            was started.) */
            /*
            A = A + AA
            B = B + BB
            C = C + CC
            D = D + DD
            */
            
            a = Word((UInt64(a) + UInt64(aa)) & 0xFFFFFFFF)
            b = Word((UInt64(b) + UInt64(bb)) & 0xFFFFFFFF)
            c = Word((UInt64(c) + UInt64(cc)) & 0xFFFFFFFF)
            d = Word((UInt64(d) + UInt64(dd)) & 0xFFFFFFFF)
            
            return (a, b, c, d)
        }
        
        let wordsArray = encode(string: rawString)
        var tempBuffer = (a: buffer[0], b: buffer[1], c: buffer[2], d: buffer[3])
        for words in wordsArray {
            tempBuffer = roundProcess(tempBuffer.a, tempBuffer.b, tempBuffer.c, tempBuffer.d, wordsArray: words)
        }
        buffer = [tempBuffer.a, tempBuffer.b, tempBuffer.c, tempBuffer.d]
        let string = decode(words: buffer)
    }
    
    private func decode(# words: [Word]) -> String {
        let easyMap: [UInt32: Character] = [
            0x00: "0", 0x01: "1", 0x02: "2", 0x03: "3", 0x04: "4", 0x05: "5", 0x06: "6", 0x07: "7",
            0x08: "8", 0x09: "9", 0x0A: "a", 0x0B: "b", 0x0C: "c", 0x0D: "d", 0x0E: "e", 0x0F: "f"
        ]
        
        var string = ""
        for i in 0..<(words.count) {
            let word = words[i]
            for j in 0...3 {
                let s0 = easyMap[(UInt32(word) >> UInt32(j * 8 + 4)) & 0xF]!
                let s1 = easyMap[(UInt32(word) >> UInt32(j * 8)) & 0xF]!
                string.append(s0)
                string.append(s1)
            }
        }
        return string
    }
}










var md5 = MD5()
md5.rawString = "abc"
println("\(md5.rawString) ==> \(md5.checksum)")

md5.rawString = "a"
println("\(md5.rawString) ==> \(md5.checksum)")

md5.rawString = "message digest"
println("\(md5.rawString) ==> \(md5.checksum)")

