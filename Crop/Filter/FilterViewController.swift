//
//  FilterViewController.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/30.
//

import UIKit
protocol FilterViewControllerDelegate {
    func applyFilter(_ filter: Lookup)
}
class FilterViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    var thumbImage: UIImage? {
        didSet {
            collectionView.reloadData()
        }
    }
    private var lookup = Lookup.ab1
    var delegate: FilterViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        collectionView.collectionViewLayout = layout
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    func updateThubmImage(_ image: UIImage) {
//        guard thumbImage == nil else {
//            return
//        }
        let currentImage = image
        thumbImage = currentImage.resizeImage(image: currentImage, targetSize: CGSize(width: 240, height: 240))
    }
    
    func updateFilterList(imageInfo: ImageInfo) {
        if let filter = imageInfo.filter,
           let selectedIndex = Lookup.allCases.indices.filter({ Lookup.allCases[$0] == filter }).first {
            let indexPath = IndexPath(item: selectedIndex, section: 0)
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredVertically)
        }
    }
}

extension FilterViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        Lookup.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCollectionViewCell", for: indexPath) as? FilterCollectionViewCell else {
            fatalError()
        }
        cell.imageConfigure = (thumbImage, Lookup.allCases[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let lookupFilter = Lookup.allCases[indexPath.item]
        delegate?.applyFilter(lookupFilter)
    }
}
