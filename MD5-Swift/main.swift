//
//  main.swift
//  MD5-Swift
//
//  Created by Veight Zhou on 5/12/15.
//  Copyright (c) 2015 Veight Zhou. All rights reserved.
//

import Foundation

var string = "1112"

// 定义类型
typealias Byte = UInt8
typealias Word = UInt32

func encode(# string: String) -> [[Word]] {
    println("开始对字符串\(string)编码")
    let stringLength:UInt64 = UInt64(count(string))
    println("字符串的个数为\(count(string)), 相当于\(stringLength * 8)位")
    
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
        paddingWords.count
        bytes.count
    }
    
    var words = [Word]()
    
    var i: Int
    for i = 0; i < bytes.count; i = i + 4 {
        let word: Word = (Word(bytes[i]) << 24)
            | (Word(bytes[i + 1]) << 16)
            | (Word(bytes[i + 2]) << 8)
            | (Word(bytes[i + 3]) << 0)
        words.append(word)
    }
    
    //  Mark: 生成长度补位编码
    var lengthPaddingWords = [Word](count: 2, repeatedValue: 0)
    lengthPaddingWords[0] = Word(stringLength >> 32 & 0xFFFFFFFF)
    lengthPaddingWords[1] = Word(stringLength & 0xFFFFFFFF)
    
    words.extend(lengthPaddingWords)
    println(words)
    println(words.count * 32)

    let wordsCollectionCount = words.count/16
    var wordsCollection = [[Word]]()
    for index in 0..<wordsCollectionCount {
        let wordsUnit = Array(words[(index*16)..<(index*16 + 16)])
        wordsCollection.append(wordsUnit)
    }
    println(wordsCollection)
    return wordsCollection
}

encode(string: string)

