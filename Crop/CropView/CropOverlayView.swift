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
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
        
    private func createCornerLineView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        addSubview(view)
        return view
    }

    private func setup() {
        clipsToBounds = false
        layer.borderWidth = 2
        layer.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)

        isUserInteractionEnabled = false
        addCornerView()
    }
    
    private func addCornerView() {
        let borderWidth: CGFloat = 4
        let borderLength: CGFloat = 28
        
        let leftTop = createCornerLineView()
        let leftTopConstraint: [NSLayoutConstraint] = [
            leftTop.bottomAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            leftTop.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: -borderWidth),
            leftTop.widthAnchor.constraint(equalToConstant: borderLength),
            leftTop.heightAnchor.constraint(equalToConstant: borderWidth)
        ]

        let topLeft = createCornerLineView()
        let topLeftConstraint: [NSLayoutConstraint] = [
            topLeft.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            topLeft.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: -borderWidth),
            topLeft.widthAnchor.constraint(equalToConstant: borderWidth),
            topLeft.heightAnchor.constraint(equalToConstant: borderLength)
        ]

        let rightTop = createCornerLineView()
        let rightTopConstraint: [NSLayoutConstraint] = [
            rightTop.bottomAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            rightTop.leadingAnchor.constraint(equalTo: self.trailingAnchor, constant: -borderLength),
            rightTop.widthAnchor.constraint(equalToConstant: borderLength),
            rightTop.heightAnchor.constraint(equalToConstant: borderWidth)
        ]
        
        let topRight = createCornerLineView()
        let topRightConstraint: [NSLayoutConstraint] = [
            topRight.topAnchor.constraint(equalTo: self.topAnchor, constant: -borderWidth),
            topRight.leadingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            topRight.widthAnchor.constraint(equalToConstant: borderWidth),
            topRight.heightAnchor.constraint(equalToConstant: borderLength)
        ]
        
        let bottomRight = createCornerLineView()
        let bottomRightConstraint: [NSLayoutConstraint] = [
            bottomRight.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: borderWidth),
            bottomRight.leadingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            bottomRight.widthAnchor.constraint(equalToConstant: borderWidth),
            bottomRight.heightAnchor.constraint(equalToConstant: borderLength)
        ]
        
        let rightBottom = createCornerLineView()
        let rightBottomConstraint: [NSLayoutConstraint] = [
            rightBottom.topAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
            rightBottom.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: borderWidth),
            rightBottom.widthAnchor.constraint(equalToConstant: borderLength),
            rightBottom.heightAnchor.constraint(equalToConstant: borderWidth)
        ]

        let leftBottom = createCornerLineView()
        let leftBottomConstraint: [NSLayoutConstraint] = [
            leftBottom.topAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
            leftBottom.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: -borderWidth),
            leftBottom.widthAnchor.constraint(equalToConstant: borderLength),
            leftBottom.heightAnchor.constraint(equalToConstant: borderWidth)
        ]
        
        let bottomLeft = createCornerLineView()
        let bottomLeftConstraint: [NSLayoutConstraint] = [
            bottomLeft.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: borderWidth),
            bottomLeft.trailingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            bottomLeft.widthAnchor.constraint(equalToConstant: borderWidth),
            bottomLeft.heightAnchor.constraint(equalToConstant: borderLength)
        ]
        
        let constraints = leftTopConstraint + topLeftConstraint + rightTopConstraint + topRightConstraint + bottomRightConstraint + rightBottomConstraint + leftBottomConstraint + bottomLeftConstraint
        NSLayoutConstraint.activate(constraints)
    }
}
