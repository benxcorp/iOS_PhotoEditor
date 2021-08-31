//
//  CropView.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/12.
//

import UIKit

enum RatioPreset {
    case free
    case scale1to1
    case scale3to4
    case scale4to3
    
    var size: CGSize {
        switch self {
        case .free:
            return .zero
        case .scale1to1:
            return CGSize(width: 1, height: 1)
        case .scale3to4:
            return CGSize(width: 3, height: 4)
        case .scale4to3:
            return CGSize(width: 4, height: 3)
        }
    }
}

let cropViewPadding: CGFloat = 20
let minCropBoxRatio: CGFloat = 9/32
let maxCropBoxRatio: CGFloat = 32/9

public struct CropInfo {
    let minimumZoomScale: CGFloat
    let zoomScale: CGFloat
    let contentOffset: CGPoint
//    let contentInset: UIEdgeInsets
    let cropBoxFrame: CGRect
    let rotation: CGFloat
}

class CropView: UIView {
    let image: UIImage
    let imageContainerView = ImageContainerView()
    let cropOverlayView = CropOverlayView(frame: .zero)
    let cropMaskView = UIView()
    var viewModel = CropViewModel()
    var cropInfoList: [CropInfo]

    lazy private var scrollView: CropScrollView = {
        let scrollView = CropScrollView(frame: bounds)
        scrollView.delegate = self
        addSubViewToFit(scrollView)
        return scrollView
    }()
    
    
    lazy private var dimView: UIView = {
        let dimView = UIView()
        dimView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.8)
        return dimView
    }()
    
    private var imageSize: CGSize {
        return image.size
    }
    
    func pushCropInfo() {
        let cropInfo = CropInfo(
            minimumZoomScale: scrollView.minimumZoomScale,
            zoomScale: scrollView.zoomScale,
            contentOffset: scrollView.contentOffset,
            cropBoxFrame: viewModel.cropBoxFrame.value,
            rotation: 0
        )
        cropInfoList.append(cropInfo)
    }
    
    private var contentBounds: CGRect {
        let padding: CGFloat = 20
        let rect = bounds
        var contentRect = CGRect.zero
        contentRect.origin.x = rect.origin.x + padding
        contentRect.origin.y = rect.origin.y + padding
        contentRect.size.width = rect.width - (2 * padding)
        contentRect.size.height = rect.height - (2 * padding)
        return contentRect
    }

    var imageCropFrame: CGRect {
        let contentSize = scrollView.contentSize
        let cropBoxFrame = viewModel.cropBoxFrame.value
        let contentOffset = scrollView.contentOffset
        let edgeInset = scrollView.contentInset
        let scale = min(imageSize.width / contentSize.width, imageSize.height / contentSize.height)
        
        var cropFrame = CGRect.zero
        let originX = (contentOffset.x + edgeInset.left) * (imageSize.width / contentSize.width)
        let originY = (contentOffset.y + edgeInset.top) * (imageSize.height / contentSize.height)
        let width =  min(cropBoxFrame.size.width * scale, imageSize.width)
        let height =  min(cropBoxFrame.size.height * scale, imageSize.height)

        cropFrame.origin.x = (originX > 0) ? originX: 0
        cropFrame.origin.y = (originY > 0) ? originY: 0
        cropFrame.size.width = width
        cropFrame.size.height = height
        return cropFrame
    }
    
    var croppedImage: UIImage? {
        image.cropImage(frame: imageCropFrame)
    }
    
    init(image: UIImage, cropInfoList: [CropInfo]) {
        self.image = image
        self.cropInfoList = cropInfoList
        super.init(frame: .zero)
        setNeedsLayout()
        layoutIfNeeded()

        imageContainerView.image = image
        imageContainerView.frame = CGRect(origin: .zero, size: imageSize)
        imageContainerView.imageView.frame = imageContainerView.frame
        imageContainerView.backgroundColor = .green
        imageContainerView.isUserInteractionEnabled = false
        
        scrollView.clipsToBounds = true
        scrollView.addSubview(imageContainerView)
        addSubview(cropOverlayView)
        bindViewModel()
        layoutInitialImage()
        
        addSubViewToFit(dimView)
        
        applyLastCropInfo()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func applyLastCropInfo() {
        guard let cropInfo = cropInfoList.last else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.scrollView.minimumZoomScale = cropInfo.zoomScale
            self.scrollView.zoomScale = cropInfo.zoomScale
            self.scrollView.contentOffset = cropInfo.contentOffset
            
            self.viewModel.cropBoxFrame.value = cropInfo.cropBoxFrame

        }
        
//        let cropBoxFrame: CGRect
//        let rotation: CGFloat

    }
    
    private func bindViewModel() {
        viewModel.cropBoxFrame.bind { [weak self] frame in
            print("frameframe \(frame)")
            guard let self = self else { return }
            self.cropOverlayView.frame = frame
            self.scrollView.contentInset = UIEdgeInsets(
                top: frame.minY,
                left: frame.minX,
                bottom: self.bounds.maxY - frame.maxY,
                right: self.bounds.maxX - frame.maxX
            )
            
            self.dimView.mask(withRect: frame, inverse: true)
            self.updateZoomScaleForFitImage(to: frame)
        }
    }

    private func updateScale(with boxFrame: CGRect) {
        let scale = max(
            boxFrame.size.width / imageSize.width,
            boxFrame.size.height / imageSize.height
        )
        scrollView.zoomScale = scale
    }
    
    public func layoutInitialImage() {
        scrollView.contentSize = imageSize

        let ratio = imageSize.height / imageSize.width
        let width = UIScreen.main.bounds.size.width - (cropViewPadding * 2)
        let height = width * ratio
        let orginY = (bounds.height - height) / 2
        viewModel.cropBoxFrame.value = CGRect(
            x: cropViewPadding,
            y: orginY,
            width: width,
            height: height
        )
        updateZoomScaleToFitCropBox()
    }
    
    private func updateZoomScaleToFitCropBox() {
        let cropBoxFrame = viewModel.cropBoxFrame.value
        let scale = max(
            cropBoxFrame.size.width / imageSize.width,
            cropBoxFrame.size.height / imageSize.height
        )
        scrollView.minimumZoomScale = scale
        scrollView.zoomScale = scale
//        pushCropInfo()
    }
    
    public func updateRatio(ratio: RatioPreset) {
        guard ratio != .free else {
            return
        }
        var cropBoxFrame = viewModel.cropBoxFrame.value
        let center = cropBoxFrame.center
        
//        if (aspectRatio > CGFloat(imageRationH)) {
//            cropBoxFrame.size.height = cropBoxFrame.width / aspectRatio
//        } else {
//            cropBoxFrame.size.width = cropBoxFrame.height * aspectRatio

//        bounds.size.width
//        cropBoxFrame.size.width = 0
        let aspectRatio = ratio.size.width / ratio.size.height
        cropBoxFrame.size.height = cropBoxFrame.width / aspectRatio
        cropBoxFrame.origin.x = center.x - cropBoxFrame.width / 2
        cropBoxFrame.origin.y = center.y - cropBoxFrame.height / 2


        UIView.animate(withDuration: 0.3) {
            self.viewModel.cropBoxFrame.value = cropBoxFrame
        }
        
        
        
//        let scale = max(
//            cropBoxFrame.size.width / imageSize.width,
//            cropBoxFrame.size.height / imageSize.height
//        )
//
//        UIView.animate(withDuration: 0.3) {
//            self.scrollView.zoomScale = scale
//        }

    }
    
    private func updateZoomScaleForFitImage(to cropBoxFrame: CGRect) {
//        let scale = max(
//            cropBoxFrame.size.width / imageSize.width,
//            cropBoxFrame.size.height / imageSize.height
//        )
//
//        scrollView.minimumZoomScale = scale
        
        let transform = imageContainerView.imageView.transform
        let rotation = atan2(transform.b, transform.a)
        let degree = rotation * 180 / .pi
        
//        let scale: CGFloat
//        if abs(round(degree)) == 90 {
//            scale = max(
//                cropBoxFrame.size.width / imageSize.height,
//                cropBoxFrame.size.height / imageSize.width
//            )
//        } else {
//            scale = max(
//                cropBoxFrame.size.width / imageSize.width,
//                cropBoxFrame.size.height / imageSize.height
//            )
//        }
        
        let tempBoxFrameSize: CGSize
        if abs(round(degree)) == 90 {
            tempBoxFrameSize = CGSize(width: cropBoxFrame.size.height, height: cropBoxFrame.size.width)
        } else {
            tempBoxFrameSize = CGSize(width: cropBoxFrame.size.width, height: cropBoxFrame.size.height)
        }

        let scale = max(
            tempBoxFrameSize.width / imageSize.width,
            tempBoxFrameSize.height / imageSize.height
        )

        scrollView.minimumZoomScale = scale

        guard tempBoxFrameSize.width > imageContainerView.frame.size.width ||
                tempBoxFrameSize.height > imageContainerView.frame.size.height else {
            return
        }
        
//        let scale = max(
//            cropBoxFrame.size.width / imageSize.width,
//            cropBoxFrame.size.height / imageSize.height
//        )
//
//        scrollView.minimumZoomScale = scale

//        UIView.animate(withDuration: 0.3) {
//            self.scrollView.zoomScale = scale
//        }
        
        print("CC minimumZoomScale \(scrollView.minimumZoomScale) zoomScale \(scrollView.zoomScale)")

        
    }
    
    
    public func rotation() {
        let imageViewSize = imageContainerView.frame.size
        let transform = imageContainerView.imageView.transform.rotated(by: .pi / 2)
//        let transform = CGAffineTransform(rotationAngle: .pi / 2)
        
        let rotation = atan2(transform.b, transform.a)
        let degree = rotation * 180 / .pi

        let beforeImageContainerFrame = imageContainerView.frame
        
        var newImageContainerFrame = beforeImageContainerFrame
        newImageContainerFrame.size.width = beforeImageContainerFrame.height
        newImageContainerFrame.size.height = beforeImageContainerFrame.width
        
        var rotatedScrollViewContentSize = scrollView.contentSize
        rotatedScrollViewContentSize.width = scrollView.contentSize.height
        rotatedScrollViewContentSize.height = scrollView.contentSize.width

//        self.imageContainerView.imageView.transform = transform
//        self.imageContainerView.imageView.frame.origin.x = 0
//        self.imageContainerView.imageView.frame.origin.y = 0
//        self.imageContainerView.frame = newImageContainerFrame
//
//        self.updateScrollViewContentSize(rotatedScrollViewContentSize)
//        self.updateCropBox(90)
        
        
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .curveEaseInOut,
            animations: {
                self.imageContainerView.imageView.transform = transform
                self.imageContainerView.imageView.frame.origin.x = 0
                self.imageContainerView.imageView.frame.origin.y = 0
                self.imageContainerView.frame = newImageContainerFrame

                self.updateScrollViewContentSize(rotatedScrollViewContentSize)
                self.updateCropBox(90)

//                self.imageContainerView.transform = transform
//                self.imageContainerView.imageView.transform = transform
                
//                self.imageContainerView.imageView.frame = newImageContainerFrame

//                self.updateScrollViewContentSize(rotatedScrollViewContentSize)
            },
            completion: { _ in

            }
        )
    }
    
    public func updateScrollViewContentSize(_ size: CGSize) {
//        let contentOffset = CGPoint(
//            x: scrollView.contentOffset.x + scrollView.contentInset.left,
//            y: scrollView.contentOffset.y + scrollView.contentInset.top
//        )
//
//        let newContentOffest = CGPoint(
//            x: scrollView.contentSize.height - (cropBoxFrame.size.height + contentOffset.y) - scrollView.contentInset.left,
//            y: contentOffset.x - scrollView.contentInset.top
//        )
        let cropBoxFrame = viewModel.cropBoxFrame.value
        
        let focusPoint = CGPoint(x: cropBoxFrame.midX, y: cropBoxFrame.midY)
        let midPoint = CGPoint(x: self.contentBounds.midX, y: self.contentBounds.midY)
//
//        let targetPoint = CGPoint(
//            x: (focusPoint.x + self.scrollView.contentOffset.x) * zoomScale,
//            y: (focusPoint.y + self.scrollView.contentOffset.y) * zoomScale
//        )
        
        let beforeTargetPoint = CGPoint(
            x: (focusPoint.x + self.scrollView.contentOffset.x),
            y: (focusPoint.y + self.scrollView.contentOffset.y)
        )
        
        let afterTargetPoint = CGPoint(
            x: scrollView.contentSize.height - (beforeTargetPoint.y),
            y: beforeTargetPoint.x
        )
        
        scrollView.contentSize = size
        scrollView.contentOffset = CGPoint(
            x: afterTargetPoint.x - midPoint.x,
            y: afterTargetPoint.y - midPoint.y
        )
        
        
        
//        let beforeTargetView = UIView(frame: CGRect.init(origin: afterTargetPoint, size: CGSize(width: 10, height: 10)))
//        beforeTargetView.backgroundColor = .blue
//        imageContainerView.addSubview(beforeTargetView)
//
//        let targetView = UIView(frame: CGRect.init(origin: scrollView.contentOffset, size: CGSize(width: 10, height: 10)))
//        targetView.backgroundColor = .red
//        imageContainerView.imageView.addSubview(targetView)

        print("BE scrollViewContentOffset \(scrollView.contentOffset)")

        
//        self.scrollView.contentInset = UIEdgeInsets(
//            top: viewModel.cropBoxFrame.value.minY,
//            left: viewModel.cropBoxFrame.value.minX,
//            bottom: self.bounds.maxY - viewModel.cropBoxFrame.value.maxY,
//            right: self.bounds.maxX - viewModel.cropBoxFrame.value.maxX
//        )
    }
    
    private func updateCropBox(_ rotation: CGFloat) {
        var cropBoxFrame = viewModel.cropBoxFrame.value
        cropBoxFrame.size = CGSize(width: viewModel.cropBoxFrame.value.height, height: viewModel.cropBoxFrame.value.width)
        
        var cropBoxRatio = cropBoxFrame.size.height / cropBoxFrame.size.width
        cropBoxRatio = max(min(cropBoxRatio, maxCropBoxRatio), minCropBoxRatio)
        
        let contentAreaRatio = bounds.size.height / bounds.size.width
        let width: CGFloat
        let height: CGFloat
        let originX: CGFloat
        let originY: CGFloat

        if cropBoxRatio > contentAreaRatio {
            height = bounds.size.height - (cropViewPadding * 2)
            width = height / cropBoxRatio
            originX = (bounds.width - width) / 2
            originY = cropViewPadding
        } else {
            width = bounds.size.width - (cropViewPadding * 2)
            height = width * cropBoxRatio
            originX = cropViewPadding
            originY = (bounds.height - height) / 2
        }
        
        let newCropBoxFrame = CGRect(
            x: originX,
            y: originY,
            width: width,
            height: height
        )
        
        let zoomScale = max(
            newCropBoxFrame.size.width / viewModel.cropBoxFrame.value.height,
            newCropBoxFrame.size.height / viewModel.cropBoxFrame.value.width
        )
        let result = scrollView.zoomScale * zoomScale

        print("AAA minimumZoomScale \(scrollView.minimumZoomScale) zoomScale \(scrollView.zoomScale)")

        UIView.animate(withDuration: 0.3) {
            self.viewModel.cropBoxFrame.value = newCropBoxFrame
            self.scrollView.zoomScale = result

        }
        
//        let transform = imageContainerView.imageView.transform
//        let rotation = atan2(transform.b, transform.a)
//        let degree = rotation * 180 / .pi
//        let scale: CGFloat
//        if abs(round(degree)) == 90 {
//            scale = max(
//                newCropBoxFrame.size.width / imageSize.height,
//                newCropBoxFrame.size.height / imageSize.width
//            )
//        } else {
//            scale = max(
//                newCropBoxFrame.size.width / imageSize.width,
//                newCropBoxFrame.size.height / imageSize.height
//            )
//        }
//
//
//        scrollView.minimumZoomScale = scale
        
        
//        let result = scrollView.zoomScale * zoomScale

        print("BBB minimumZoomScale \(scrollView.minimumZoomScale) zoomScale \(scrollView.zoomScale)")

    }
}
// MARK: Private
extension CropView {
    private func resetUI() {
//        viewModel.resetFrame(getInitialCropBoxRect())
        
    }
    
    private func getInitialCropBoxRect() -> CGRect {
    
        let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        return imageRect
    }

    private func updateCropBox(
        animation: Bool = true,
        zoom: Bool = true,
        completion: @escaping () -> Void) {
        
//        let scale = max(
//            cropBoxFrame.size.width / imageSize.width,
//            cropBoxFrame.size.height / imageSize.height
//        )
        
        let contentRect = bounds
    }

    func resizeCropBox() {
        let cropBoxFrame = viewModel.cropBoxFrame.value
        let zoomScale = min(
            self.contentBounds.width / cropBoxFrame.size.width,
            self.contentBounds.height / cropBoxFrame.size.height
        )
        let focusPoint = CGPoint(x: cropBoxFrame.midX, y: cropBoxFrame.midY)
        let midPoint = CGPoint(x: self.contentBounds.midX, y: self.contentBounds.midY)
        
        let targetPoint = CGPoint(
            x: (focusPoint.x + self.scrollView.contentOffset.x) * zoomScale,
            y: (focusPoint.y + self.scrollView.contentOffset.y) * zoomScale
        )

        
        UIView.animate(withDuration: 0.3) {
            self.scrollView.zoomScale *= zoomScale
            self.scrollView.contentOffset = CGPoint(x: targetPoint.x - midPoint.x, y: targetPoint.y - midPoint.y)
            self.viewModel.cropBoxFrame.value = self.newCropBoxFrame()
        } completion: { _ in

        }

    }
    
    private func newCropBoxFrame() -> CGRect {
        let cropBoxFrame = viewModel.cropBoxFrame.value
        var cropBoxRatio = cropBoxFrame.size.height / cropBoxFrame.size.width
        cropBoxRatio = max(min(cropBoxRatio, maxCropBoxRatio), minCropBoxRatio)
        
        let contentAreaRatio = bounds.size.height / bounds.size.width
        let width: CGFloat
        let height: CGFloat
        let originX: CGFloat
        let originY: CGFloat

        if cropBoxRatio > contentAreaRatio {
            height = bounds.size.height - (cropViewPadding * 2)
            width = height / cropBoxRatio
            originX = (bounds.width - width) / 2
            originY = cropViewPadding
        } else {
            width = bounds.size.width - (cropViewPadding * 2)
            height = width * cropBoxRatio
            originX = cropViewPadding
            originY = (bounds.height - height) / 2
        }
        
        let newCropBoxFrame = CGRect(
            x: originX,
            y: originY,
            width: width,
            height: height
        )

        return newCropBoxFrame
    }
}

extension CropView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageContainerView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("scrollView \(scrollView.contentOffset) inset \(scrollView.contentInset)")
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
    }
}

// MARK: Touch
extension CropView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let newPoint = self.convert(point, to: self)
        let hitTestView = super.hitTest(point, with: event)

        if cropOverlayView.frame.insetBy(dx: -30/2, dy: -30/2).contains(newPoint) &&
            !cropOverlayView.frame.insetBy(dx: 30/2, dy: 30/2).contains(newPoint) {
            return cropOverlayView
        }
                
        if self.bounds.contains(newPoint) {
            return self.scrollView
        }
        return hitTestView
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard let touche = touches.first,
              touches.count == 1 else {
            return
        }

        let point = touche.location(in: self)
        
        viewModel.prepareCrop(with: point)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        guard let touche = touches.first,
              touches.count == 1 else {
            return
        }
        
        let point = touche.location(in: self)
        let cropBoxFrame = viewModel.cropBoxFrame.value
        let touchRect = CGRect(x: 0, y: 0, width: cropBoxFrame.width, height: cropBoxFrame.height)
        
        viewModel.updateCropBoxFrame(with: point, touchRect: touchRect, imageFrame: scrollView.convert(imageContainerView.frame, to: self), containerFrame: frame)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        resizeCropBox()
    }
}

