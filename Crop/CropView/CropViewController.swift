//
//  CropViewController.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/12.
//

import UIKit

public protocol CropViewControllerDelegate: AnyObject {
    func didCrop(croppedImage: UIImage?, cropInfoList: [CropInfo])
}

public class CropViewController: UIViewController {
    public var image: UIImage!
    public var delegate: CropViewControllerDelegate?
    public var cropInfoList: [CropInfo] = []
    var ratioPreset: RatioPreset = .free {
        didSet {
            updateCropButton(ratioPreset)
            cropView.updateRatio(ratio: ratioPreset)
            cropView.isCropRectInteractionEanbled = ratioPreset == .free
        }
    }
    var rotation: Rotation = .degree0
    
    @IBOutlet weak var cropFreeButton: UIButton!
    @IBOutlet weak var crop1x1Button: UIButton!
    @IBOutlet weak var crop3x4Button: UIButton!
    @IBOutlet weak var crop4x3Button: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var rotationButton: UIButton!
    
    private lazy var cropView: CropView = {
        let cropView = CropView(frame: cropContainerView.bounds, image: image, cropInfoList: cropInfoList, rotation: rotation)
        return cropView
    }()
        
    @IBOutlet var cropContainerView: UIView!

    @IBAction func tapCropButton(_ button: UIButton) {
        if button == crop3x4Button {
            ratioPreset = .scale3to4
        } else if button == crop4x3Button {
            ratioPreset = .scale4to3
        } else if button == crop1x1Button {
            ratioPreset = .scale1to1
        } else {
            ratioPreset = .free
        }
    }
    
    @IBAction func rotation(_ sender: Any) {
        UIView.animate(withDuration: 0.3) {
            self.cropView.rotation90()
        }
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
        view.setNeedsLayout()
        view.layoutIfNeeded()
        setupUI()
    }

    private func setupUI() {
        cropFreeButton.alignTextBelow()
        crop1x1Button.alignTextBelow()
        crop3x4Button.alignTextBelow()
        crop4x3Button.alignTextBelow()
        rotationButton.alignTextBelow()
        cropFreeButton.isSelected = true
        ratioPreset = .free
        
        cropContainerView.addSubview(cropView)
    }
    
    private func updateCropButton(_ ratioPreset: RatioPreset) {
        crop3x4Button.isSelected = false
        crop4x3Button.isSelected = false
        crop1x1Button.isSelected = false
        cropFreeButton.isSelected = false

        switch ratioPreset {
        case .free:
            cropFreeButton.isSelected = true
        case .scale1to1:
            crop1x1Button.isSelected = true
        case .scale3to4:
            crop3x4Button.isSelected = true
        case .scale4to3:
            crop4x3Button.isSelected = true
        }
    }
}
