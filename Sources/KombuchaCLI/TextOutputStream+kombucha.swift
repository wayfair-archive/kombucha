//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Foundation

/// see https://nshipster.com/textoutputstream/
struct FileHandleOutputStream: TextOutputStream {
    fileprivate let encoding: String.Encoding
    fileprivate let fileHandle: FileHandle

    mutating func write(_ string: String) {
        if let data = string.data(using: encoding) {
            fileHandle.write(data)
        }
    }
}

extension FileHandle {
    var outputStream: FileHandleOutputStream {
        return FileHandleOutputStream(encoding: .utf8, fileHandle: self)
    }
}
