//
//  ViewController.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/12.
//

import UIKit
import PhotosUI
import MobileCoreServices

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBAction func tapGallery(_ sender: Any) {
//        let vc = UIImagePickerController()
//        vc.sourceType = .photoLibrary
//        vc.delegate = self
//        present(vc, animated: true, completion: nil)
        showPHPPicker()
    }
    
    @IBAction func tapRotation(_ sender: Any) {
        let rotatedImage = imageView.image?.rotate(radians: .pi/2)
        imageView.image = rotatedImage
//        imageView.rotate()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    private func presentCropVC(with image: UIImage) {
        let vc = CropViewController.makeCropViewContorller(with: image)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    private func showPHPPicker() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 10
//        configuration.filter = .any(of: [.images])
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
//    private func presentCropVC(results: [PHPickerResult]) {
//        let vc = CropViewController.makeCropViewContorller(with: image)
//        vc.modalPresentationStyle = .fullScreen
//        vc.delegate = self
//        present(vc, animated: true, completion: nil)
//    }
    private func presentGalleryVC(with images: [UIImage]) {
        let vc = GalleryViewController.makeGalleryViewContorller(with: images)
        vc.modalPresentationStyle = .fullScreen
        
        let navi = UINavigationController(rootViewController: vc)
        navi.modalPresentationStyle = .fullScreen
        present(navi, animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true) {
            if let image = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerOriginalImage")] as? UIImage {
                self.presentCropVC(with: image)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        var images: [UIImage] = []
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                guard let image = object as? UIImage else { return }
//                guard let resizedImage: UIImage = UIGraphicsImageRenderer(size: CGSize(width: 2_000, height: 2_000)).image { (context) in
//                    image.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
//                } else { return }
//
//                images.append(resizedImage)
                images.append(image)
            }
        }

        
        picker.dismiss(animated: true) {
            self.presentGalleryVC(with: images)
        }
    }
}
