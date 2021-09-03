//
//  GalleryViewController.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/24.
//

import UIKit

struct ImageInfo {
    let originalImage: UIImage
    let filter: Lookup?
//    var filterImage: UIImage?
    var cropInfoList: [CropInfo]?
    var cropImage: UIImage?
    var rotation: Rotation = .degree0
}

class GalleryViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    var imageInfoList = [ImageInfo]()
    var currentPage: Int = 0
    var filterVC: FilterViewController?
    @IBOutlet weak var rotationButton: UIButton!
    @IBOutlet weak var cropButton: UIButton!
    
    static func makeGalleryViewContorller(with images: [UIImage]) -> GalleryViewController {
        guard let vc = UIStoryboard(name: "Crop", bundle: nil).instantiateViewController(identifier: "GalleryViewController") as? GalleryViewController else {
            fatalError()
        }
        vc.imageInfoList = images.map { ImageInfo(originalImage: $0, filter: nil, cropInfoList: nil) }
        return vc
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItem()
        setupCollectionView()
        setupButtons()
        updateFilterList()
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FilterList",
           let vc = segue.destination as? FilterViewController {
            filterVC = vc
            filterVC?.delegate = self
        }
    }
    
    private func updateFilterList() {
        guard !imageInfoList.isEmpty else {
            return
        }

        let imageInfo = imageInfoList[currentPage]
        filterVC?.updateThubmImage(imageInfo.originalImage)
        filterVC?.updateFilterList(imageInfo: imageInfo)
    }
        
    private func setupNavigationItem() {
        let leftButton = UIBarButtonItem(image: #imageLiteral(resourceName: "iconTitlebarIconTitlebarClose"), style: .plain, target: self, action: #selector(tapCloseButton))
        leftButton.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        navigationItem.leftBarButtonItem = leftButton
        navigationItem.title = "\(currentPage+1)/\(imageInfoList.count)"
        
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = .black
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]

    }
    
    private func setupCollectionView() {
//        let bottomInset: CGFloat = 30
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: view.bounds.size.width, height: view.bounds.size.height)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
//        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: bottomInset)
        
        collectionView.collectionViewLayout = layout
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    private func setupButtons() {
        rotationButton.alignTextBelow()
        rotationButton.isUserInteractionEnabled = false
        cropButton.alignTextBelow()
    }
    
    @objc private func tapCloseButton() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tapRotateButton(_ sender: Any) {
        guard let cell = collectionView.cellForItem(at: IndexPath(item: currentPage, section: 0)) as? GalleryCollectionViewCell else {
            return
        }
        cell.rotateImageView()
        
        let transform = cell.imageView.transform
        var rotation = atan2(transform.b, transform.a)
        if rotation < 0 {
            rotation += .pi * 2
        }
        let degree = rotation * 180 / .pi

        var imageInfo = imageInfoList[currentPage]
        imageInfo.rotation = Rotation.degree(value: Int(abs(round(degree))))
        imageInfoList[currentPage] = imageInfo
        
    }
    
    @IBAction func tapCropButton(_ sender: Any) {
        let image = imageInfoList[currentPage].originalImage
        let lookupFilter = ColorLookupFilter(image: image)
        
        if let filter = imageInfoList[currentPage].filter,
           let filterImage = lookupFilter.applyFiler(with: filter) {
            presentCropVC(with: filterImage)
        } else {
            presentCropVC(with: image)
        }
    }
        
    private func presentCropVC(with image: UIImage) {
        let vc = CropViewController.makeCropViewContorller(with: image)
        vc.modalPresentationStyle = .fullScreen
        vc.delegate = self

        let cropInfoList = imageInfoList[currentPage].cropInfoList
        vc.cropInfoList = cropInfoList ?? []
        vc.rotation = imageInfoList[currentPage].rotation
        present(vc, animated: true, completion: nil)
    }
    

}

extension GalleryViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageInfoList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GalleryCollectionViewCell", for: indexPath) as? GalleryCollectionViewCell else {
            fatalError()
        }
        let image = imageInfoList[indexPath.item].cropImage ?? imageInfoList[indexPath.item].originalImage
        let lookupFilter = ColorLookupFilter(image: image)
        if let filter = imageInfoList[indexPath.item].filter,
           let filterImage = lookupFilter.applyFiler(with: filter) {
            cell.imageView.image = filterImage
        } else {
            cell.imageView.image = image
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let visibleCell = collectionView.visibleCells.first,
              let index = collectionView.indexPath(for: visibleCell)?.item else {
            return
        }
        currentPage = index
        updateFilterList()
        navigationItem.title = "\(currentPage+1)/\(imageInfoList.count)"
    }
}

extension GalleryViewController: CropViewControllerDelegate {
    func didCrop(croppedImage: UIImage?, cropInfoList: [CropInfo]) {
        guard let cell = collectionView.cellForItem(at: IndexPath(item: currentPage, section: 0)) as? GalleryCollectionViewCell else {
            return
        }
        cell.imageView.transform = .identity
        cell.imageView.image = croppedImage

        var imageInfo = imageInfoList[currentPage]
        imageInfo.cropImage = croppedImage
        imageInfo.cropInfoList = cropInfoList
        imageInfoList[currentPage] = imageInfo
    }
}

extension GalleryViewController: FilterViewControllerDelegate {
    func applyFilter(_ filter: Lookup) {
        guard let cell = collectionView.cellForItem(at: IndexPath(item: currentPage, section: 0)) as? GalleryCollectionViewCell else {
            return
        }
        
        let currentImage = imageInfoList[currentPage].cropImage ?? imageInfoList[currentPage].originalImage
        let currentCropInfoList = imageInfoList[currentPage].cropInfoList
        let lookupFilter = ColorLookupFilter(image: currentImage)
        let filterImage = lookupFilter.applyFiler(with: filter)
        let rotation = imageInfoList[currentPage].rotation
        let imageInfo = ImageInfo(originalImage: imageInfoList[currentPage].originalImage, filter: filter, cropInfoList: currentCropInfoList, cropImage: imageInfoList[currentPage].cropImage, rotation: rotation)
        cell.imageView.image = filterImage
        imageInfoList[currentPage] = imageInfo
    }
}
