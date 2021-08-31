//
//  CropViewModel.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/12.
//

import UIKit

class CropViewModel {
    let hotAreaUnit: CGFloat = 32
//    var boxFrame = CGRect.zero
    var cropBoxFrame: Box<CGRect> = Box(.zero)
    
    var beginCropBoxFrame = CGRect.zero
    var beginPanPoint = CGPoint.zero
    var tapEdge = CropViewOverlayEdge.none
    
    func prepareCrop(with point: CGPoint) {
        beginPanPoint = point
        beginCropBoxFrame = cropBoxFrame.value
        
        let touchRect = cropBoxFrame.value.insetBy(dx: -hotAreaUnit / 2, dy: -hotAreaUnit / 2)
        tapEdge = getCropEdge(forPoint: point, byTouchRect: touchRect)
    }

    func updateCropBoxFrame(with point: CGPoint, touchRect: CGRect, imageFrame: CGRect, containerFrame: CGRect) {
//        var point = point
//        point.x = max(beginCropBoxFrame.origin.x, point.x)
//        point.y = max(beginCropBoxFrame.origin.y, point.y)
        
        print("imageFrame \(imageFrame) point \(point) isContains \(imageFrame.contains(point))")
        guard imageFrame.contains(point) else {
            return
        }
        
        let delta = CGPoint(x: point.x - beginPanPoint.x, y: point.y - beginPanPoint.y)
        var beforeCropBoxFrame = self.cropBoxFrame.value
        var newCropBoxFrame = self.cropBoxFrame.value

        func handleTop() {
//            newCropBoxFrame.origin.y = beginCropBoxFrame.origin.y + delta.y
//            newCropBoxFrame.size.height = beginCropBoxFrame.height - delta.y
//
            var updateCropBoxFrame = newCropBoxFrame
            updateCropBoxFrame.origin.y = beginCropBoxFrame.origin.y + delta.y
            updateCropBoxFrame.size.height = beginCropBoxFrame.height - delta.y

            guard updateCropBoxFrame.size.width / updateCropBoxFrame.size.height >= minCropBoxRatio,
                  updateCropBoxFrame.size.width / updateCropBoxFrame.size.height <= maxCropBoxRatio,
                  updateCropBoxFrame.origin.x >= cropViewPadding else {
                return
            }
            newCropBoxFrame = updateCropBoxFrame

        }
        
        func handleBottom() {
            var updateCropBoxFrame = newCropBoxFrame
            updateCropBoxFrame.size.height = beginCropBoxFrame.height + delta.y
            
            guard updateCropBoxFrame.size.width / updateCropBoxFrame.size.height >= minCropBoxRatio,
                  updateCropBoxFrame.size.width / updateCropBoxFrame.size.height <= maxCropBoxRatio,
                  updateCropBoxFrame.size.height <= containerFrame.size.height - (cropViewPadding * 2) else {
                return
            }
            newCropBoxFrame = updateCropBoxFrame
        }
        
        func handleLeft() {
            var updateCropBoxFrame = newCropBoxFrame
            updateCropBoxFrame.origin.x = beginCropBoxFrame.origin.x + delta.x
            updateCropBoxFrame.size.width = beginCropBoxFrame.width - delta.x
            
            guard updateCropBoxFrame.size.width / updateCropBoxFrame.size.height >= minCropBoxRatio,
                  updateCropBoxFrame.size.width / updateCropBoxFrame.size.height <= maxCropBoxRatio,
                  updateCropBoxFrame.origin.x >= cropViewPadding else {
                return
            }
            newCropBoxFrame = updateCropBoxFrame
        }
        
        func handleRight() {
            var updateCropBoxFrame = newCropBoxFrame
            updateCropBoxFrame.size.width = beginCropBoxFrame.width + delta.x
            guard updateCropBoxFrame.size.width / updateCropBoxFrame.size.height >= minCropBoxRatio,
                  updateCropBoxFrame.size.width / updateCropBoxFrame.size.height <= maxCropBoxRatio,
                  updateCropBoxFrame.size.width <= containerFrame.size.width - (cropViewPadding * 2) else {
                return
            }
            newCropBoxFrame = updateCropBoxFrame
        }
        
        switch tapEdge {
        case .top:
            handleTop()
        case .topRight:
            handleTop()
            handleRight()
        case .right:
            handleRight()
        case .bottomRight:
            handleBottom()
            handleRight()
        case .bottom:
            handleBottom()
        case .bottomLeft:
            handleBottom()
            handleLeft()
        case .left:
            handleLeft()
        case .topLeft:
            handleTop()
            handleLeft()
        case .none:
            break
        }
        
//        if newCropBoxFrame.size.width / newCropBoxFrame.size.height < minCropBoxRatio {
//            newCropBoxFrame = beforeCropBoxFrame
//        }
        
//        if cropBoxFrame.origin.x >= cropViewPadding,
//           cropBoxFrame.maxX <= containerFrame.maxX - cropViewPadding,
//           cropBoxFrame.origin.y >= 0,
//           cropBoxFrame.maxY <= containerFrame.maxY {
//            self.cropBoxFrame.value = cropBoxFrame
//        }
//        if cropBoxFrame.size.width / cropBoxFrame.size.height < minCropBoxRatio {
//
//        }
        
        
        self.cropBoxFrame.value = newCropBoxFrame

//        if cropBoxFrame.origin.x >= max(imageFrame.origin.x, cropViewPadding),
//           cropBoxFrame.maxX <= min(imageFrame.maxX, containerFrame.maxX - cropViewPadding),
//           cropBoxFrame.origin.y >= max(imageFrame.origin.y, cropViewPadding),
//           cropBoxFrame.maxY <= min(imageFrame.maxY,containerFrame.maxY - cropViewPadding)  {
//            self.cropBoxFrame.value = cropBoxFrame
//        }
    }

    func getCropEdge(forPoint point: CGPoint, byTouchRect touchRect: CGRect) -> CropViewOverlayEdge {
        let touchSize = CGSize(width: hotAreaUnit, height: hotAreaUnit)
        
        let topLeftRect = CGRect(origin: touchRect.origin, size: touchSize)
        if topLeftRect.contains(point) {
            return .topLeft
        }
        
        let topRightRect = topLeftRect.offsetBy(dx: touchRect.width - hotAreaUnit, dy: 0)
        if topRightRect.contains(point) {
            return .topRight
        }
        
        let bottomLeftRect = topLeftRect.offsetBy(dx: 0, dy: touchRect.height - hotAreaUnit)
        if bottomLeftRect.contains(point) {
            return .bottomLeft
        }
        
        let bottomRightRect = bottomLeftRect.offsetBy(dx: touchRect.width - hotAreaUnit, dy: 0)
        if bottomRightRect.contains(point) {
            return .bottomRight
        }
        
        //Check for edges
        let topRect = CGRect(origin: touchRect.origin, size: CGSize(width: touchRect.width, height: hotAreaUnit))
        if topRect.contains(point) {
            return .top
        }
        
        let leftRect = CGRect(origin: touchRect.origin, size: CGSize(width: hotAreaUnit, height: touchRect.height))
        if leftRect.contains(point) {
            return .left
        }
        
        let rightRect = CGRect(origin: CGPoint(x: touchRect.maxX - hotAreaUnit, y: touchRect.origin.y), size: CGSize(width: hotAreaUnit, height: touchRect.height))
        if rightRect.contains(point) {
            return .right
        }
        
        let bottomRect = CGRect(origin: CGPoint(x: touchRect.origin.x, y: touchRect.maxY - hotAreaUnit), size: CGSize(width: touchRect.width, height: hotAreaUnit))
        if bottomRect.contains(point) {
            return .bottom
        }
        
        return .none
    }
}
