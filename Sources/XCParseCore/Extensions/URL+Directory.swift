//
//  URL+Directory.swift
//  
//
//  Created by Alexander Botkin on 7/5/20.
//

import Foundation

public extension Foundation.URL {
    func fileExistsAsDirectory() -> Bool {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: self.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                return true // Exists as a directory
            } else {
                return false // Exists as a file
            }
        } else {
            return false // Does not exist
        }
    }

    func createDirectoryIfNecessary(createIntermediates: Bool = false, console: Console = Console()) -> Bool {
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: self.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                // Directory already exists, do nothing
                return true
            } else {
                console.writeMessage("\(self) is not a directory", to: .error)
                return false
            }
        } else {
            do {
                try FileManager.default.createDirectory(at: self, withIntermediateDirectories: createIntermediates, attributes: nil)
            } catch {
                console.writeMessage("Failed to create directory at \(self.path): \(error)", to: .error)
                return false
            }
        }

        return self.fileExistsAsDirectory()
    }
}
