//
//  GalleryCollectionViewCell.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/24.
//

import UIKit

class GalleryCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewWidth: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    
    public func rotateImageView() {
        let imageViewSize = imageView.frame.size
        let transform = imageView.transform.rotated(by: .pi / 2)
        let rotation = atan2(transform.b, transform.a)
        let degree = rotation * 180 / .pi
        
        if abs(round(degree)) == 90 {
            self.imageViewWidth.constant = imageViewSize.height
            self.imageViewHeight.constant = imageViewSize.width
        } else {
            self.imageViewWidth.constant = imageViewSize.width
            self.imageViewHeight.constant = imageViewSize.height
        }

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseInOut,
            animations: {
                self.imageView.transform = transform
                self.layoutIfNeeded()
            }
        )
    }
}
