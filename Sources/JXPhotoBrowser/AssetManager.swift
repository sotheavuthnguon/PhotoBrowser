//
//  AssetManager.swift
//  JXPhotoBrowser
//
//  Created by Sotheavuth Nguon on 7/23/21.
//

import UIKit

class AssetManager {

  static func image(_ named: String) -> UIImage? {
    let bundle = Bundle(for: AssetManager.self)
    return UIImage(named: "JXPhotoBrowser.bundle/\(named)", in: bundle, compatibleWith: nil)
  }
}
