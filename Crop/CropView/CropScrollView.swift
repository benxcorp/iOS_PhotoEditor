//
//  CropScrollView.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/17.
//

import UIKit

class CropScrollView: UIScrollView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        alwaysBounceVertical = true
        alwaysBounceHorizontal = true
        
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        
        contentInsetAdjustmentBehavior = .never
        minimumZoomScale = 1.0
        maximumZoomScale = 10.0
        contentSize = bounds.size
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
