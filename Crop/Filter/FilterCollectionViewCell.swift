//
//  FilterCollectionViewCell.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/30.
//

import UIKit

class FilterCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var filterLabel: UILabel!
    @IBOutlet weak var dimView: UIView!
    
    override var isSelected: Bool {
        didSet {
            UIView.animate(withDuration: 0.25) {
                self.dimView.alpha = self.isSelected ? 1: 0
            }
        }
    }
    
    var imageConfigure: (thumb: UIImage?, filter: Lookup)? {
        didSet {
            applyFilter()
        }
    }
    
    private func applyFilter() {
        guard let imageConfigure = imageConfigure else {
            return
        }
        guard let thumbImage = imageConfigure.thumb else {
            return
        }
        let lookupFilter = ColorLookupFilter(image: thumbImage)
        imageView.image = lookupFilter.applyFiler(with: imageConfigure.filter)
        filterLabel.text = imageConfigure.filter.rawValue
    }
    
}
