//
//  CropViewController.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/12.
//

import UIKit

public protocol CropViewControllerDelegate: AnyObject {
//    func cropViewControllerDidCrop(_ cropViewController: CropViewController,
//                                   cropped: UIImage, transformation: Transformation)
//    func cropViewControllerDidFailToCrop(_ cropViewController: CropViewController, original: UIImage)
//    func cropViewControllerDidCancel(_ cropViewController: CropViewController, original: UIImage)
//
//    func cropViewControllerDidBeginResize(_ cropViewController: CropViewController)
//    func cropViewControllerDidEndResize(_ cropViewController: CropViewController, original: UIImage, cropInfo: CropInfo)
    func didCrop(croppedImage: UIImage?, cropInfoList: [CropInfo])
}

public class CropViewController: UIViewController {
    public var image: UIImage!
    public var delegate: CropViewControllerDelegate?
    public var cropInfoList: [CropInfo] = []
    private var initialLayout = false

    @IBOutlet weak var cropFreeButton: UIButton!
    @IBOutlet weak var crop1x1Button: UIButton!
    @IBOutlet weak var crop3x4Button: UIButton!
    @IBOutlet weak var crop4x3Button: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    private lazy var cropView: CropView = {
        let cropView = CropView(image: image, cropInfoList: cropInfoList)
        return cropView
    }()
        
    @IBOutlet var cropContainerView: UIView!
    
    
    @IBAction func tapCropButton(_ button: UIButton) {
        if button == crop3x4Button {
            cropView.updateRatio(ratio: .scale3to4)
        } else if button == crop4x3Button {
            cropView.updateRatio(ratio: .scale4to3)
        } else if button == crop1x1Button {
            cropView.updateRatio(ratio: .scale1to1)
        } else {
            cropView.updateRatio(ratio: .free)
        }
        
    }
    
    @IBAction func rotation(_ sender: Any) {
        cropView.rotation()
    }
    
    @IBAction func tapCloseButton(_ button: UIButton) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func tapDoneButton(_ button: UIButton) {
        cropView.pushCropInfo()
        delegate?.didCrop(croppedImage: cropView.croppedImage, cropInfoList: cropView.cropInfoList)
        dismiss(animated: true, completion: nil)
    }
    
    static func makeCropViewContorller(with image: UIImage) -> CropViewController {
        guard let vc = UIStoryboard(name: "Crop", bundle: nil).instantiateViewController(identifier: "CropViewController") as? CropViewController else {
            fatalError()
        }
        vc.image = image
        return vc
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if initialLayout == false {
            initialLayout = true
            view.layoutIfNeeded()
            cropView.layoutInitialImage()
        }
    }

    private func setupUI() {
//        cropContainerView.addSubview(cropView)
//        cropView.bindFrameToSuperviewBounds()
        cropContainerView.addSubViewToFit(cropView)
    }
    
}
