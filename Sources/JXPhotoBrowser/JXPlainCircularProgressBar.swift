//
//  JXPlainCircularProgressBar.swift
//  JXPhotoBrowser
//
//  Created by Sotheavuth Nguon on 7/23/21.
//

import UIKit

public class JXPlainCircularProgressBar: UIView {
    @IBInspectable public var ringColor: UIColor? = .gray {
        didSet { setNeedsDisplay() }
    }
    @IBInspectable public var ringWidth: CGFloat = 2

    public var progress: CGFloat = 0 {
        didSet { setNeedsDisplay() }
    }

    private var progressLayer = CAShapeLayer()
    private var backgroundMask = CAShapeLayer()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()

    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        backgroundMask.lineWidth = ringWidth
        backgroundMask.fillColor = nil
        backgroundMask.strokeColor = UIColor.black.cgColor
        layer.mask = backgroundMask

        progressLayer.lineWidth = ringWidth
        progressLayer.fillColor = nil
        layer.addSublayer(progressLayer)
        layer.transform = CATransform3DMakeRotation(CGFloat(90 * Double.pi / 180), 0, 0, -1)
    }

    public override func draw(_ rect: CGRect) {
        let circlePath = UIBezierPath(ovalIn: rect.insetBy(dx: ringWidth / 2, dy: ringWidth / 2))
        backgroundMask.path = circlePath.cgPath

        progressLayer.path = circlePath.cgPath
        progressLayer.lineCap = .round
        progressLayer.strokeStart = 0
        progressLayer.strokeEnd = progress
        progressLayer.strokeColor = ringColor?.cgColor
    }
}
