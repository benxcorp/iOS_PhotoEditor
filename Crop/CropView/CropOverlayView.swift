//
//  CropOverlayView.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/18.
//

import UIKit

enum CropViewOverlayEdge {
    case none
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft
    case left
}


class CropOverlayView: UIView {
    private var borderLine: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func createLineView() -> UIView {
        let view = UIView()
        view.frame = CGRect.zero
        view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        addSubview(view)
        return view
    }

    private func setup() {
//        backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        clipsToBounds = false
        layer.borderWidth = 2
        layer.borderColor = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
        
        layer.shadowColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        layer.shadowRadius = 3

        isUserInteractionEnabled = false
    }
}
