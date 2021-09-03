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

enum Rotation: Int {
    case degree0 = 0
    case degree90 = 90
    case degree180 = 180
    case degree270 = 270
    
    static func degree(value: Int) -> Rotation {
        if value == 0 {
            return .degree0
        } else if value == 90 {
            return .degree90
        } else if value == 180 {
            return .degree180
        } else if value == 270 {
            return .degree270
        } else {
            return .degree0
        }
    }
    
    var radians: Float {
        switch self {
        case .degree0:
            return 0
        case .degree90:
            return .pi/2
        case .degree180:
            return .pi
        case .degree270:
            return .pi*3/2
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
    let contentSize: CGSize
    let cropBoxFrame: CGRect
    let rotation: Rotation
}

class CropView: UIView {
    let image: UIImage
    let imageContainerView = ImageContainerView()
    let cropMaskView = UIView()
    var viewModel = CropViewModel()
    var cropInfoList: [CropInfo]
    var rotation: Rotation
    var isCropRectInteractionEanbled: Bool = false
    
    lazy private var cropOverlayView: CropOverlayView = {
        let view = CropOverlayView(frame: bounds)
        addSubview(view)
        return view
    }()
    
    lazy private var scrollView: CropScrollView = {
        let scrollView = CropScrollView(frame: bounds)
        scrollView.delegate = self
        addSubViewToFit(scrollView)
        return scrollView
    }()
    
    
    lazy private var dimView: UIView = {
        let dimView = UIView(frame: bounds)
        dimView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.8)
        return dimView
    }()
    
    private var imageSize: CGSize {
        return image.size
    }
    
    private var rotatedImageSize: CGSize
    
    func pushCropInfo() {
        let cropInfo = CropInfo(
            minimumZoomScale: scrollView.minimumZoomScale,
            zoomScale: scrollView.zoomScale,
            contentOffset: scrollView.contentOffset,
            contentSize: scrollView.contentSize,
            cropBoxFrame: viewModel.cropBoxFrame.value,
            rotation: rotation
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
        let imageSize: CGSize
        switch rotation {
        case .degree0, .degree180:
            imageSize = self.imageSize
        case .degree90, .degree270:
            imageSize = CGSize(width: self.imageSize.height, height: self.imageSize.width)
        }
        
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
        guard let rotateImage = image.rotate(radians: rotation.radians) else {
            return nil
        }
        return rotateImage.cropImage(frame: imageCropFrame)
    }
    
    init(frame: CGRect, image: UIImage, cropInfoList: [CropInfo], rotation: Rotation) {
        self.image = image
        self.cropInfoList = cropInfoList
        self.rotation = rotation
        self.rotatedImageSize = image.size
        super.init(frame: frame)
        
        setupImageContainerView()
        addSubViewToFit(dimView)

        bindViewModel()
        layoutInitialImage()
        applyLastCropInfo()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    public func updateRatio(ratio: RatioPreset) {
        guard ratio != .free else {
            return
        }
        var cropBoxFrame = viewModel.cropBoxFrame.value
        let center = cropBoxFrame.center

        let aspectRatio = ratio.size.width / ratio.size.height
        cropBoxFrame.size.height = cropBoxFrame.width / aspectRatio
        cropBoxFrame.origin.x = center.x - cropBoxFrame.width / 2
        cropBoxFrame.origin.y = center.y - cropBoxFrame.height / 2
        
        let newCropBoxFrame = newCropBoxFrame(from: cropBoxFrame)
        UIView.animate(withDuration: 0.3) {
            self.viewModel.cropBoxFrame.value = newCropBoxFrame
            self.updateZoomScaleToFitImage(to: newCropBoxFrame)
        }
    }
    
    public func rotation90() {
        var degree = rotation.rawValue + 90
        degree = degree == 360 ? 0: degree
        guard let rotation = Rotation(rawValue: degree) else {
            return
        }
        self.rotation = rotation
        
        //
        imageContainerView.imageView.transform = imageContainerView.imageView.transform.rotated(by: .pi/2)
        
        //
        var newImageContainerFrame = imageContainerView.frame
        newImageContainerFrame.size.width = imageContainerView.frame.height
        newImageContainerFrame.size.height = imageContainerView.frame.width
        imageContainerView.imageView.frame.origin.x = 0
        imageContainerView.imageView.frame.origin.y = 0
        imageContainerView.frame = newImageContainerFrame
        
        //
        var rotatedScrollViewContentSize = scrollView.contentSize

        let cropBoxFrame = viewModel.cropBoxFrame.value
        let focusPoint = CGPoint(x: cropBoxFrame.midX, y: cropBoxFrame.midY)
        let midPoint = CGPoint(x: self.contentBounds.midX, y: self.contentBounds.midY)

        let beforeTargetPoint = CGPoint(
            x: (focusPoint.x + self.scrollView.contentOffset.x),
            y: (focusPoint.y + self.scrollView.contentOffset.y)
        )
        let afterTargetPoint = CGPoint(
            x: scrollView.contentSize.height - beforeTargetPoint.y,
            y: beforeTargetPoint.x
        )
        rotatedScrollViewContentSize.width = scrollView.contentSize.height
        rotatedScrollViewContentSize.height = scrollView.contentSize.width
        
        //
        let imageSize = CGSize(width: rotatedImageSize.height, height: rotatedImageSize.width)
        rotatedImageSize = imageSize
        let newCropBoxFrame = getNewCropBoxFrame(.degree90)
        let scale = max(
            newCropBoxFrame.size.width / imageSize.width,
            newCropBoxFrame.size.height / imageSize.height
        )
        viewModel.cropBoxFrame.value = newCropBoxFrame

        scrollView.contentSize = rotatedScrollViewContentSize
        scrollView.contentOffset = CGPoint(
            x: afterTargetPoint.x - midPoint.x,
            y: afterTargetPoint.y - midPoint.y
        )
        scrollView.minimumZoomScale = scale
        
        //
        let zoomScale = max(
            newCropBoxFrame.size.width / cropBoxFrame.size.height,
            newCropBoxFrame.size.height / cropBoxFrame.size.width
        )

        scrollView.zoomScale *= zoomScale

    }
    
    public func updateScrollViewContentSize(_ degree: Rotation) {
        var rotatedScrollViewContentSize = scrollView.contentSize

        let cropBoxFrame = viewModel.cropBoxFrame.value
        let focusPoint = CGPoint(x: cropBoxFrame.midX, y: cropBoxFrame.midY)
        let midPoint = CGPoint(x: self.contentBounds.midX, y: self.contentBounds.midY)

        let beforeTargetPoint = CGPoint(
            x: (focusPoint.x + self.scrollView.contentOffset.x),
            y: (focusPoint.y + self.scrollView.contentOffset.y)
        )
        
        let afterTargetPoint: CGPoint
        switch degree {
        case .degree0:
            afterTargetPoint = CGPoint(
                x: beforeTargetPoint.x,
                y: beforeTargetPoint.y
            )
        case .degree90:
            afterTargetPoint = CGPoint(
                x: scrollView.contentSize.height - beforeTargetPoint.y,
                y: beforeTargetPoint.x
            )
            rotatedScrollViewContentSize.width = scrollView.contentSize.height
            rotatedScrollViewContentSize.height = scrollView.contentSize.width
        case .degree180:
            afterTargetPoint = CGPoint(
                x: scrollView.contentSize.width - beforeTargetPoint.x,
                y: scrollView.contentSize.height - beforeTargetPoint.y
            )
        case .degree270:
            afterTargetPoint = CGPoint(
                x: beforeTargetPoint.y,
                y: scrollView.contentSize.width - beforeTargetPoint.x
            )
            rotatedScrollViewContentSize.width = scrollView.contentSize.height
            rotatedScrollViewContentSize.height = scrollView.contentSize.width
        }
        
        scrollView.contentSize = rotatedScrollViewContentSize
        scrollView.contentOffset = CGPoint(
            x: afterTargetPoint.x - midPoint.x,
            y: afterTargetPoint.y - midPoint.y
        )
    }
    
    func rotationAngle(_ degree: Rotation) {
        guard degree != .degree0 else {
            return
        }
        
        updateTransform(rotation)
        updateScrollViewContentSize(rotation)
        updateScrollViewMinimumZoomScale(rotation)
        updateCropBox(rotation)
    }
    
    
    
    
}
// MARK: Private
extension CropView {
    private func layoutInitialImage() {
        scrollView.contentSize = imageSize

        let ratio = imageSize.height / imageSize.width
        let width = UIScreen.main.bounds.size.width - (cropViewPadding * 2)
        let height = width * ratio
        let orginY = (bounds.height - height) / 2
        let cropBoxFrame = CGRect(
            x: cropViewPadding,
            y: orginY,
            width: width,
            height: height
        )
        
        viewModel.cropBoxFrame.value = cropBoxFrame
        updateZoomScaleToFitCropBox()
    }
    
    private func setupImageContainerView() {
        imageContainerView.image = image
        imageContainerView.frame = CGRect(origin: .zero, size: imageSize)
        imageContainerView.imageView.frame = imageContainerView.frame
        imageContainerView.backgroundColor = .green
        imageContainerView.isUserInteractionEnabled = false
        scrollView.addSubview(imageContainerView)
    }
    
    private func initiaizeRotateImageSize(_ rotation: Rotation) {
        switch rotation {
        case .degree0, .degree180:
            rotatedImageSize = CGSize(width: imageSize.width, height: imageSize.height)
        case .degree90, .degree270:
            rotatedImageSize = CGSize(width: imageSize.height, height: imageSize.width)
        }
    }
    
    private func applyLastCropInfo() {
        guard let cropInfo = cropInfoList.last else {
            return
        }
        
        viewModel.cropBoxFrame.value = cropInfo.cropBoxFrame
        scrollView.minimumZoomScale = cropInfo.minimumZoomScale
        scrollView.zoomScale = cropInfo.zoomScale
        scrollView.contentSize = cropInfo.contentSize

        rotation = cropInfo.rotation
        updateTransform(cropInfo.rotation)
        imageContainerViewFrame(cropInfo.rotation)
        initiaizeRotateImageSize(cropInfo.rotation)
        
        scrollView.contentOffset = cropInfo.contentOffset
    }
        
    private func bindViewModel() {
        viewModel.cropBoxFrame.bind { [weak self] frame in
            guard let self = self else { return }
            self.cropOverlayView.frame = frame
            self.scrollView.contentInset = UIEdgeInsets(
                top: frame.minY,
                left: frame.minX,
                bottom: self.bounds.maxY - frame.maxY,
                right: self.bounds.maxX - frame.maxX
            )
            print("bounds \(self.bounds) frame \(self.frame)")
            
            self.dimView.mask(withRect: frame, inverse: true)
            self.layoutIfNeeded()
        }
    }
    
    private func updateZoomScaleToFitCropBox() {
        let imageSize: CGSize
        switch rotation {
        case .degree0, .degree180:
            imageSize = self.imageSize
        case .degree90, .degree270:
            imageSize = CGSize(width: self.imageSize.height, height: self.imageSize.width)
        }

        let cropBoxFrame = viewModel.cropBoxFrame.value
        let scale = max(
            cropBoxFrame.size.width / imageSize.width,
            cropBoxFrame.size.height / imageSize.height
        )
        scrollView.minimumZoomScale = scale
        scrollView.zoomScale = scale
    }
    
    private func updateZoomScaleToFitImage(to cropBoxFrame: CGRect) {
        var tempBoxFrameSize: CGSize
        tempBoxFrameSize = CGSize(width: cropBoxFrame.size.width, height: cropBoxFrame.size.height)

        let imageSize: CGSize
        switch rotation {
        case .degree0, .degree180:
            imageSize = self.imageSize
        case .degree90, .degree270:
            imageSize = CGSize(width: self.imageSize.height, height: self.imageSize.width)
        }

        let scale = max(
            tempBoxFrameSize.width / imageSize.width,
            tempBoxFrameSize.height / imageSize.height
        )

        scrollView.minimumZoomScale = scale

        if scrollView.zoomScale < scrollView.minimumZoomScale {
            scrollView.zoomScale = scrollView.minimumZoomScale
        }
        guard tempBoxFrameSize.width > imageContainerView.frame.size.width ||
                tempBoxFrameSize.height > imageContainerView.frame.size.height else {
            return
        }
    }
    
    private func updateCropBox(_ rotation: Rotation) {
        var cropBoxFrame = viewModel.cropBoxFrame.value
        switch rotation {
        case .degree0, .degree180:
            break
        case .degree90, .degree270:
            cropBoxFrame.size = CGSize(width: viewModel.cropBoxFrame.value.height, height: viewModel.cropBoxFrame.value.width)
        }
        
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
            newCropBoxFrame.size.width / cropBoxFrame.size.width,
            newCropBoxFrame.size.height / cropBoxFrame.size.height
        )

        viewModel.cropBoxFrame.value = newCropBoxFrame
        scrollView.zoomScale *= zoomScale
    }
    
    private func getNewCropBoxFrame(_ rotation: Rotation) -> CGRect {
        var cropBoxFrame = viewModel.cropBoxFrame.value
        switch rotation {
        case .degree0, .degree180:
            break
        case .degree90, .degree270:
            cropBoxFrame.size = CGSize(width: viewModel.cropBoxFrame.value.height, height: viewModel.cropBoxFrame.value.width)
        }
        
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
    
    private func updateScrollViewMinimumZoomScale(_ rotation: Rotation) {
        let imageSize: CGSize
        switch rotation {
        case .degree0, .degree180:
            imageSize = self.imageSize
        case .degree90, .degree270:
            imageSize = CGSize(width: self.imageSize.height, height: self.imageSize.width)
        }

        let cropBoxFrame = getNewCropBoxFrame(rotation)
        let scale = max(
            cropBoxFrame.size.width / imageSize.width,
            cropBoxFrame.size.height / imageSize.height
        )
        scrollView.minimumZoomScale = scale
    }

    
    private func updateScrollContentSize() {
        var rotatedContentSize = scrollView.contentSize
        rotatedContentSize.width = scrollView.contentSize.height
        rotatedContentSize.height = scrollView.contentSize.width
        
        scrollView.contentSize = rotatedContentSize
    }
 
    private func updateTransform(_ degree: Rotation) {
        let transform: CGAffineTransform

        switch degree {
        case .degree0:
            transform = CGAffineTransform(rotationAngle: 0)
        case .degree90:
            transform = CGAffineTransform(rotationAngle: .pi/2)
        case .degree180:
            transform = CGAffineTransform(rotationAngle: .pi)
        case .degree270:
            transform = CGAffineTransform(rotationAngle: .pi * 1.5)
        }

        imageContainerView.imageView.transform = transform
    }

    private func imageContainerViewFrame(_ degree: Rotation) {
        var newImageContainerFrame = imageContainerView.frame

        switch degree {
        case .degree0, .degree180:
            break
        case .degree90, .degree270:
            newImageContainerFrame.size.width = imageContainerView.frame.height
            newImageContainerFrame.size.height = imageContainerView.frame.width
        }
        imageContainerView.imageView.frame.origin.x = 0
        imageContainerView.imageView.frame.origin.y = 0
        imageContainerView.frame = newImageContainerFrame
    }

    private func resizeCropBox() {
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
            self.viewModel.cropBoxFrame.value = self.newCropBoxFrame(from: self.viewModel.cropBoxFrame.value)
            self.updateScrollViewMinimumZoomScale(self.rotation)
        } completion: { _ in
            
        }
    }
    
    private func newCropBoxFrame(from cropBoxFrame: CGRect) -> CGRect {
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
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        print("zoomScale \(scrollView.zoomScale)")
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
        let hitTestView = super.hitTest(point, with: event)
        guard isCropRectInteractionEanbled else {
            return scrollView
        }
        
        let newPoint = self.convert(point, to: self)
        if cropOverlayView.frame.insetBy(dx: -30/2, dy: -30/2).contains(newPoint) &&
            !cropOverlayView.frame.insetBy(dx: 30/2, dy: 30/2).contains(newPoint) {
            return cropOverlayView
        }
                
        if bounds.contains(newPoint) {
            return scrollView
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

