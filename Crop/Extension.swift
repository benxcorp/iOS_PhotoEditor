//
//  Extension.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/12.
//

import UIKit

extension UIView {
    func bindFrameToSuperviewBounds() {
        guard let superview = self.superview else {
            return
        }

        translatesAutoresizingMaskIntoConstraints = false
        topAnchor.constraint(equalTo: superview.topAnchor, constant: 0).isActive = true
        bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: 0).isActive = true
        leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 0).isActive = true
        trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: 0).isActive = true
    }
    
    func addSubViewToFit(_ view: UIView) {
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.topAnchor.constraint(equalTo: self.topAnchor, constant: 0).isActive = true
        view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0).isActive = true
        view.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0).isActive = true
        view.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0).isActive = true
    }
    
    
    func mask(withRect rect: CGRect, inverse: Bool = true) {
        let path = UIBezierPath(rect: rect)
        let maskLayer = CAShapeLayer()

        if inverse {
            path.append(UIBezierPath(rect: self.bounds))
            maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        }

        maskLayer.path = path.cgPath
        let anim = CABasicAnimation(keyPath: "path")
        anim.fromValue = layer.mask?.value(forKey: "path")
        anim.toValue = path.cgPath
        anim.duration = 0.3
        anim.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)

        maskLayer.add(anim, forKey: nil)
        
        self.layer.mask = maskLayer
        
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        maskLayer.path = path.cgPath
        CATransaction.commit()

    }
    
    public func mask(with rect: CGRect?, inverse: Bool = true, animated: Bool = true, duration: TimeInterval = 0.3) {
        guard let rect = rect else {
            layer.mask = nil
            return
        }

        let path = UIBezierPath(rect: rect)
        let maskLayer = CAShapeLayer()

        if inverse {
            path.append(UIBezierPath(rect: self.bounds))
            maskLayer.fillRule = .evenOdd
        }

        if animated {
            let animation = CABasicAnimation(keyPath: "path")
            animation.fromValue = maskLayer.path
            animation.toValue = path.cgPath
            animation.duration = duration
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.isRemovedOnCompletion = false
            maskLayer.add(animation, forKey: "selectAnimation")
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            maskLayer.path = path.cgPath
            self.layer.mask = maskLayer
            CATransaction.commit()
        } else {
            maskLayer.path = path.cgPath
            self.layer.mask = maskLayer
        }
  }

}

extension CGRect{
    var center: CGPoint {
        return CGPoint(x:midX, y: midY)
    }
}

extension UIImage {
    func cropImage(frame: CGRect) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, scale)
        draw(at: CGPoint(x: -frame.origin.x / scale, y: -frame.origin.y / scale))
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return croppedImage
    }
    
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: size)
            .applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        let context = UIGraphicsGetCurrentContext()!
        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: CGFloat(radians))
        draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = max(widthRatio, heightRatio)
        
        var newSize: CGSize
//        if(widthRatio > heightRatio) {
//           newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
//        } else {
//           newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
//        }
        newSize = CGSize(width: size.width * ratio,  height: size.height * ratio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 2.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
   }

}

extension UIImageView {
    func rotate() {
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi/2)
        rotation.duration = 0.3
        rotation.isCumulative = false
//        rotation.repeatCount = Float.greatestFiniteMagnitude
        self.layer.add(rotation, forKey: "rotationAnimation")
    }
}
