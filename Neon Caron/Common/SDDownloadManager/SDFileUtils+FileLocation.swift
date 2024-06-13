//
//  SDFileUtils+FileLocation.swift
//  Neon Caron
//
//  Created by Pablo Ruiz on 3/16/21.
//

import Foundation

extension SDFileUtils {
  public static func getCacheFileURL(fineName: String, directory: String) -> URL? {
    let localURL = cacheDirectoryPath().appendingPathComponent(directory).appendingPathComponent(fineName)
    if FileManager.default.fileExists(atPath: localURL.path) {
      return localURL
    }
    return nil
  }
}
