//
//  BaseEncoding.swift
//  SwiftTestMac
//
//  Created by Eric Wang on 2021/2/6.
//
// 参考自 https://blog.csdn.net/lili13897741554/article/details/82177472
//

import Foundation

let base16Charset = "0123456789ABCDEF"
let base32Charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
let base64Charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

struct ZQBaseEncoder {
    
    /// lcm
    /// - Parameters:
    ///   - a: num1
    ///   - b: num2
    /// - Returns: lcm
    private func lcm(a:Int, b:Int) -> Int {
        var aa = a, bb = b
        while true {
            if aa == bb {
                return aa
            }
            else if aa < bb {
                aa += a
            }
            else {
                bb += b
            }
        }
    }

    public func baseEncode(space:Int, baseCharset:String, data:Data) -> Data {
        var encodeData:Data = Data()
        guard data.count > 0 else {
            return encodeData
        }
        
        let baseCharstData = baseCharset.data(using: .ascii)!
        
        var preDataCount:Int = 8
        var preDataValue:UInt16 = UInt16(data[0])
        
        var dataIndex:Int = 1
        
        while dataIndex < data.count || preDataCount > 0 {
            if preDataCount >= space {
                let dataVale = preDataValue >> (preDataCount - space)
                let char = baseCharstData[Int(dataVale)]
                encodeData.append(char)
                
                preDataCount -= space
                preDataValue = preDataValue & (1 << preDataCount - 1)
            }else {
                if dataIndex >= data.count && preDataCount > 0 {
                    let zeroPadding = (space - preDataCount)
                    preDataValue = (preDataValue << zeroPadding)
                    preDataCount += zeroPadding
                }else {
                    preDataValue = ((preDataValue << 8) | UInt16(data[dataIndex]))
                    dataIndex += 1
                    preDataCount = preDataCount + 8
                }
            }
        }
        
        let lcmCount = lcm(a: space, b: 8)
        if encodeData.count * space % lcmCount != 0 {
            let equalPadding = (lcmCount - encodeData.count * space % lcmCount) / space
            for _ in 0 ..< equalPadding {
                encodeData.append(61)
            }
        }
        return encodeData
    }
    
    public func baseDecode(space:Int, baseCharset:String, data:Data) -> Data {
        var decodeData:Data = Data()
        guard data.count > 0 else {
            return decodeData
        }
        
        let baseCharstData:Data = baseCharset.data(using: .ascii)!
        var reverseDic:[Int:UInt8] = [Int:UInt8]()
        for i in 0 ..< baseCharstData.count {
            reverseDic[Int(baseCharstData[i])] = UInt8(i)
        }
        
        var preDatacount:Int = 0
        var preData:UInt16 = 0
        
        var dataIndex:Int = 0
        
        while dataIndex < data.count || preDatacount > 0 {
            if preDatacount < 8 {
                let dataValue = Int(data[dataIndex])
                if dataValue == 61 {
                    break
                }
                
                let reverseValue = UInt16(reverseDic[dataValue]!)
                
                preData = (preData << space) | reverseValue
                preDatacount += space
                dataIndex += 1
            }else if preDatacount >= 8 {
                let endPadding = preDatacount - 8

                let data = UInt8(preData >> endPadding)
                decodeData.append(data)
                
                preDatacount -= 8
                preData = preData & (1 << endPadding - 1)
            }
        }
        return decodeData
    }
}

extension String {
    /// base16 encode
    /// - Returns: encode string
    func zq_base16Encode() -> String {
        let encoder:ZQBaseEncoder = ZQBaseEncoder()
        let encodeData = encoder.baseEncode(space: 4, baseCharset: base16Charset, data: self.data(using: .ascii) ?? Data())
        return String(data: encodeData, encoding: .ascii)!
    }
    
    /// base32 encode
    /// - Returns: encode string
    func zq_base32Encode() -> String {
        let encoder:ZQBaseEncoder = ZQBaseEncoder()
        let encodeData = encoder.baseEncode(space: 5, baseCharset: base32Charset, data: self.data(using: .ascii) ?? Data())
        return String(data: encodeData, encoding: .ascii)!
    }
    
    /// base64 encode
    /// - Returns: encode string
    func zq_base64Encode() -> String {
        let encoder:ZQBaseEncoder = ZQBaseEncoder()
        let encodeData = encoder.baseEncode(space: 6, baseCharset: base64Charset, data: self.data(using: .ascii) ?? Data())
        return String(data: encodeData, encoding: .ascii)!
    }
    
    /// base16 decode
    /// - Returns: decode string
    func zq_base16Decode() -> String {
        let encoder:ZQBaseEncoder = ZQBaseEncoder()
        let encodeData = encoder.baseDecode(space: 4, baseCharset: base16Charset, data: self.data(using: .ascii) ?? Data())
        return String(data: encodeData, encoding: .ascii)!
    }
    
    /// base32 decode
    /// - Returns: decode string
    func zq_base32Decode() -> String {
        let encoder:ZQBaseEncoder = ZQBaseEncoder()
        let encodeData = encoder.baseDecode(space: 5, baseCharset: base32Charset, data: self.data(using: .ascii) ?? Data())
        return String(data: encodeData, encoding: .ascii)!
    }
    
    /// base64 decode
    /// - Returns: decode string
    func zq_base64Decode() -> String {
        let encoder:ZQBaseEncoder = ZQBaseEncoder()
        let encodeData = encoder.baseDecode(space: 6, baseCharset: base64Charset, data: self.data(using: .ascii) ?? Data())
        return String(data: encodeData, encoding: .ascii)!
    }
}
