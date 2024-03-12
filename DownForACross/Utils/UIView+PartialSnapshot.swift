//
//  UIView+PartialSnapshot.swift
//  DownForACross
//
//  Created by Justin Hill on 3/11/24.
//  Adapted from: https://stackoverflow.com/questions/39283807/how-to-take-screenshot-of-portion-of-uiview
//

import UIKit

extension UIView {

    /// Create snapshot
    ///
    /// - Parameters:
    ///   - rect: The coordinates (in the view's own coordinate space) to be captured. If omitted, the entire `bounds` will be captured.
    ///   - afterScreenUpdates: A Boolean value that indicates whether the snapshot should be rendered after recent changes have been incorporated. Specify the value false if you want to render a snapshot in the view hierarchy’s current state, which might not include recent changes. Defaults to `true`.
    ///
    /// - Returns: Returns `UIImage` of the specified portion of the view.

    func snapshot(of rect: CGRect, afterScreenUpdates: Bool = true) -> UIImage? {
        var format = UIGraphicsImageRendererFormat()
        format.opaque = false
        
        let canvasSize: CGSize
        if let scrollView = self as? UIScrollView {
            canvasSize = scrollView.contentSize
        } else {
            canvasSize = self.bounds.size
        }
        
        let image = UIGraphicsImageRenderer(size: canvasSize).image { _ in
            drawHierarchy(in: self.bounds, afterScreenUpdates: afterScreenUpdates)
        }
        
        let scaledRect = rect.scaled(by: image.scale)
        guard let cgImage = image.cgImage?.cropping(to: scaledRect) else { return nil }
        let uiImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
        
        return UIGraphicsImageRenderer(bounds: CGRect(origin: .zero, size: rect.size)).image { context in
            let origin = CGPoint(x: rect.origin.x < 0 ? abs(rect.origin.x) : 0,
                                 y: rect.origin.y < 0 ? abs(rect.origin.y) : 0)
            uiImage.draw(at: origin)
        }
    }

}

extension CGRect {
    
    func scaled(by scale: CGFloat) -> CGRect {
        return CGRect(x: self.minX * scale,
                      y: self.minY * scale,
                      width: self.width * scale,
                      height: self.height * scale)
    }
    
}
