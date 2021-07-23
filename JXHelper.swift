//
//  JXHelper.swift
//  JXPhotoBrowser
//
//  Created by Sotheavuth Nguon on 7/23/21.
//

import UIKit

final class JXHelper {
    static func getTopSafeAreaHeight() -> CGFloat {
        if #available(iOS 13.0, *) {
            guard UIApplication.shared.windows.count != 0 else { return 0 }
            let window = UIApplication.shared.windows[0]
            return window.safeAreaInsets.top
        } else if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            guard let topPadding = window?.safeAreaInsets.top else { return 0 }
            return topPadding
        }
        return 0
    }

    static func getBottomSafeAreaHeight() -> CGFloat {
        if #available(iOS 13.0, *) {
            guard UIApplication.shared.windows.count != 0 else { return 0 }
            let window = UIApplication.shared.windows[0]
            return window.safeAreaInsets.bottom
        } else if #available(iOS 11.0, *) {
            let window = UIApplication.shared.keyWindow
            guard let bottomPadding = window?.safeAreaInsets.bottom else { return 0 }
            return bottomPadding
        }
        return 0
    }
}

extension UIViewController {
    var topBarHeight: CGFloat {
        var top = self.navigationController?.navigationBar.frame.height ?? 0.0
        if #available(iOS 13.0, *) {
            top += UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            top += UIApplication.shared.statusBarFrame.height
        }
        return top
    }
    var bottomBarHeight: CGFloat {
        var bottom = self.navigationController?.toolbar.frame.size.height ?? 0.0
        bottom += JXHelper.getBottomSafeAreaHeight()
        return bottom
    }
}
