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


extension String {
    
    /// base加密
    /// - Parameters:
    ///   - space: 分割长度，Base16,Base32,Base64 依次为4、5、6
    ///   - baseCharset: Base16,Base32,Base64的编码表
    /// - Returns: 加密后的字符串
    private func baseEncode(space:Int, baseCharset:String) -> String {
        let data = self.data(using: .ascii)!
        
        //转二进制
        var binaryStr = ""
        for element in data {
            var byte = String(element, radix: 2)
            if byte.count < 8 {
                byte.insert(contentsOf: String(format:"%0\(8-byte.count)d",0), at: byte.startIndex)
            }
            binaryStr.append(byte)
        }
        
        // 未尾补0
        if binaryStr.count % space != 0 {
            let zeroCount = space - binaryStr.count % space
            binaryStr.append(String(format:"%0\(zeroCount)d",0))
        }
        
        var ret = ""
        for i in stride(from: 0, to: binaryStr.count, by: space) {
            let indexStart = binaryStr.index(binaryStr.startIndex, offsetBy: i)
            let indexEnd = binaryStr.index(binaryStr.startIndex, offsetBy: i + space)
            
            let spaceStr = String(binaryStr[indexStart ..< indexEnd])
            let num = Int(spaceStr, radix: 2)!
            
            ret.append(baseCharset[baseCharset.index(baseCharset.startIndex, offsetBy: num)])
        }
        
        // 在末尾补充3个"=".经过Base32编码后最终值应是"JFGFK===".
        if space == 5 && binaryStr.count%40 != 0 {
            for _ in 0 ..< (40 - binaryStr.count%40)/space {
                ret.append("=")
            }
        }
        // 在末尾补充3个"=".经过Base32编码后最终值应是"JFGFK===".
        if space == 6 && binaryStr.count%24 != 0 {
            for _ in 0 ..< (24 - binaryStr.count%24)/space {
                ret.append("=")
            }
        }
        return ret
    }
    
    /// 求最小公倍数
    /// - Parameters:
    ///   - a: 数1
    ///   - b: 数2
    /// - Returns: 最小公倍数
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
    
    /// base加密位运算方法
    /// - Parameters:
    ///   - space: 分割长度，Base16,Base32,Base64 依次为4、5、6
    ///   - baseCharset: Base16,Base32,Base64的编码表
    /// - Returns: 加密后的字符串
    func baseEncodeBit(space:Int, baseCharset:String) -> String {
        let baseCharstData = baseCharset.data(using: .ascii)!
        
        let data = self.data(using: .ascii)!
        let inLength = data.count
        
        var outLength = inLength * 8
        let padLen = lcm(a: 8, b: space)
        if outLength % padLen == 0 {
            outLength = outLength / space
        }else {
            outLength = (outLength + (padLen - (outLength % padLen))) / space
        }
        
        let ret = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
        var outPutIndex = 0
        var bitStartIndex = 0
        
        var bitEndIndex = bitStartIndex + space
        var orgIndex = bitStartIndex / 8
        var orgStartIndex = orgIndex * 8
        var orgEndIndex = orgStartIndex + 8
        
        while outPutIndex < outLength && bitStartIndex < inLength * 8 {
            
            var value = data[orgIndex]
            
            if bitStartIndex >= orgStartIndex && bitEndIndex <= orgEndIndex {
                // 去除尾后的
                let rightPad = orgEndIndex - bitEndIndex
                if rightPad > 0 {
                    value = value >> rightPad
                }
                // 去除前面
                let leftPad = bitStartIndex - orgStartIndex
                if leftPad > 0 {
                    var leftPadValue:UInt8 = 0b0
                    for i in 0 ..< space {
                        leftPadValue = leftPadValue | (1 << i)
                    }
                    value = value & leftPadValue
                }
            }else {
                // 左边的值
                let leftPad = orgEndIndex - bitStartIndex
                var leftPadValue:UInt8 = 0b0
                for i in 0 ..< leftPad {
                    leftPadValue = leftPadValue | (1 << i)
                }
                value = (data[orgIndex] & leftPadValue) << (space - leftPad)
                if orgIndex + 1 < inLength {
                    // 右边的值
                    let rightPad = 8 - (space - leftPad)
                    value = value | (data[orgIndex + 1] >> rightPad)
                }
            }
            ret[outPutIndex] = baseCharstData[Data.Index(value)]
            
            outPutIndex += 1
            bitStartIndex += space
            
            bitEndIndex = bitStartIndex + space
            orgIndex = bitStartIndex / 8
            orgStartIndex = orgIndex * 8
            orgEndIndex = orgStartIndex + 8
        }

        while outPutIndex < outLength {
            ret[outPutIndex] = UInt8(61)
            outPutIndex += 1
        }

        return String(bytesNoCopy: ret, length: outLength, encoding: .ascii, freeWhenDone: true)!;
    }
    
    /// base16加密
    /// - Returns: 加密字符串
    func base16Encode() -> String {
        return baseEncode(space: 4, baseCharset: base16Charset)
    }
    
    /// base32加密
    /// - Returns: 加密字符串
    func base32Encode() -> String {
        return baseEncode(space: 5, baseCharset: base32Charset)
    }
    /// base64加密
    /// - Returns: 加密字符串
    func base64Encode() -> String {
        return baseEncode(space: 6, baseCharset: base64Charset)
    }
    
    
    /// base解码
    /// - Parameters:
    ///   - space: 分割长度Base16,Base32,Base64 依次为4、5、6
    ///   - baseCharset: Base16,Base32,Base64的编码表
    /// - Returns: 解码后的字符串
    private func baseDecode(space:Int, baseCharset:String) -> String {
        var binaryStr = ""
        for cha in self {
            if cha == "=" {
                continue
            }
            
            if let index = baseCharset.firstIndex(of: cha) {
                // 从编码表转为10进制
                let indexDis = baseCharset.distance(from: baseCharset.startIndex, to: index)
                // 10进制转二进制
                var binStr = String(indexDis,radix: 2)
                // 补足0
                if binStr.count < space {
                    binStr.insert(contentsOf: String(format:"%0\(space-binStr.count)d",0), at: binStr.startIndex)
                }
                binaryStr.append(binStr)
            }
        }
        
        var ret = ""
        for i in stride(from: 0, to: binaryStr.count, by: 8) {
            if i + 8 > binaryStr.count {
                break
            }
            let indexStart = binaryStr.index(binaryStr.startIndex, offsetBy: i)
            let indexEnd = binaryStr.index(binaryStr.startIndex, offsetBy: i + 8)
            
            let spaceStr = String(binaryStr[indexStart ..< indexEnd])
            let intVale = Int(spaceStr, radix: 2);
            let a = Character(UnicodeScalar(intVale!)!)
            
            ret.append(a)
        }
        return ret
    }
    
    /// base解密位运算方法
    /// - Parameters:
    ///   - space: 分割长度，Base16,Base32,Base64 依次为4、5、6
    ///   - baseCharset: Base16,Base32,Base64的编码表
    /// - Returns: 加密后的字符串
    func baseDecodeBit(space:Int, baseCharset:String) -> String {
        let baseCharstData = baseCharset.data(using: .ascii)!
        let reverseCharMap = UnsafeMutablePointer<UInt8>.allocate(capacity: 128)
        for i in 0 ..< baseCharstData.count {
            reverseCharMap[Int(baseCharstData[i])] = UInt8(i)
        }
        
        let data = self.data(using: .ascii)!
        
        let outLength = (data.count * space + 7)/8
        
        let ret = UnsafeMutablePointer<UInt8>.allocate(capacity: outLength)
        
        var orgIndex = 0
        var outIndex = 0 // 需要填充的序号
        var outPos = 8 // 需要填充的8个bit
        
        // 按base编码的数据转为二进制，然后填充到8位的二进制数据上
        while orgIndex < data.count  {
            let dataInt = Int(data[orgIndex])
            if dataInt == 61 {
                break
            }
            
            let val = reverseCharMap[dataInt]
            
            if outPos < space {
                let rightPad = space - outPos
                
                // 左侧的值
                let lv:UInt8 = val >> rightPad
                ret[outIndex] = ret[outIndex] | lv
                
                // 填充完序号加1
                outPos = 8 - (space - outPos)
                outIndex += 1
                
                // 右侧的值
                var rightPadvalue:UInt8 = 0b0
                for i in 0 ..< rightPad {
                    rightPadvalue = rightPadvalue | (1 << i)
                }
                let rv = (val & rightPadvalue) << outPos
                ret[outIndex] = ret[outIndex] | rv
            }
            else {
                outPos -= space
                let lv:UInt8 = val << outPos
                ret[outIndex] = ret[outIndex] | lv
            }

            orgIndex += 1
        }

        return String(bytesNoCopy: ret, length: outLength, encoding: .ascii, freeWhenDone: true)!;
    }
    
    /// base16 解码
    /// - Returns: 解码后的字符串
    func base16Decode() -> String {
        return baseDecode(space: 4, baseCharset: base16Charset)
    }
    
    /// base32 解码
    /// - Returns: 解码后的字符串
    func base32Decode() -> String {
        return baseDecode(space: 5, baseCharset: base32Charset)
    }
    
    /// base64 解码
    /// - Returns: 解码后的字符串
    func base64Decode() -> String {
        return baseDecode(space: 6, baseCharset: base64Charset)
    }
}


extension StringProtocol {
    func distance(of element: Element) -> Int? { firstIndex(of: element)?.distance(in: self) }
    func distance<S: StringProtocol>(of string: S) -> Int? { range(of: string)?.lowerBound.distance(in: self) }
}

extension Collection {
    func distance(to index: Index) -> Int { distance(from: startIndex, to: index) }
}

extension String.Index {
    func distance<S: StringProtocol>(in string: S) -> Int { string.distance(to: self) }
}
