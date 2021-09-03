//
//  ImageContainerView.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/17.
//

import UIKit

class ImageContainerView: UIView {
    lazy public var imageView: UIImageView = {
        let imageView = UIImageView(frame: bounds)
        imageView.layer.minificationFilter = .trilinear
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        
        return imageView
    }()
    
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
}
