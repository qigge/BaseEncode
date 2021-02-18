# BaseEncode
Swift Base16 Base32 Base64 encode decode

Swift版Base16,Base32,Base64编码解码，BaseEncoding.swift 包含字符串处理和位运算处理两个版本
推荐使用位运算版本
Base16编码
```
"f".baseEncodeBit(space: 4, baseCharset: base16Charset)
```
Base32编码
```
"f".baseEncodeBit(space: 5, baseCharset: base32Charset)
```
Base64编码
```
"f".baseEncodeBit(space: 6, baseCharset: base64Charset)
```

Base16解码
```
"f".baseDecodeBit(space: 4, baseCharset: base16Charset)
```
Base32解码
```
"f".baseDecodeBit(space: 5, baseCharset: base32Charset)
```
Base64解码
```
"f".baseDecodeBit(space: 6, baseCharset: base64Charset)
```
