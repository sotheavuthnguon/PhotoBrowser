//
//  LocalImageViewController.swift
//  JXPhotoBrwoser_Example
//
//  Created by JiongXing on 2018/10/14.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import JXPhotoBrowser

class LocalImageViewController: BaseCollectionViewController {
    
    override class func name() -> String { "本地图片" }
    override class func remark() -> String { "最简单的场景，展示本地图片" }
    
    override func makeDataSource() -> [ResourceModel] {
        makeLocalDataSource()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.jx.dequeueReusableCell(BaseCollectionViewCell.self, for: indexPath)
        cell.imageView.image = self.dataSource[indexPath.item].localName.flatMap { UIImage(named: $0) }
        return cell
    }
    
    override func openPhotoBrowser(with collectionView: UICollectionView, indexPath: IndexPath) {
        // 实例化
        let browser = JXPhotoBrowser()
        // 浏览过程中实时获取数据总量
        browser.numberOfItems = {
            self.dataSource.count
        }
        // 刷新Cell数据。本闭包将在Cell完成位置布局后调用。
        browser.reloadCellAtIndex = { context in
            let browserCell = context.cell as? JXPhotoBrowserImageCell
            let indexPath = IndexPath(item: context.index, section: indexPath.section)
            browserCell?.imageView.image = self.dataSource[indexPath.item].localName.flatMap { UIImage(named: $0) }
        }
        // 可指定打开时定位到哪一页
        browser.pageIndex = indexPath.item
        // 展示
        browser.jxPhotoBrowserDelegate = self
        browser.show(method: .presentInNav(fromVC: self, embed: nil))
    }
}

extension LocalImageViewController: JXPhotoBrowserDelegate {
    func onActionTapped(index: Int) {
        
        // set up activity view controller
        let image = self.dataSource[index].localName.flatMap { UIImage(named: $0) }
        let imageToShare = [ image ]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook ]
        
        // present the view controller
        UIApplication.shared.topMostViewController?.present(activityViewController, animated: true, completion: nil)
    }
    
    func onDownloadImageTapped(index: Int) {
        print("*** Download image at index: \(index)")
    }
    
}

extension UIApplication {
    var topMostViewController: UIViewController? {
        var topViewController: UIViewController? = keyWindow?.rootViewController
        
        while topViewController?.presentedViewController != nil {
            topViewController = topViewController?.presentedViewController!
        }
        
        if let topNavigationController = topViewController as? UINavigationController {
            topViewController = topNavigationController.topViewController
        }
        
        return topViewController
    }

}
