//
//  Box.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/20.
//

final class Box<T> {
    typealias Listener = (T) -> Void

    var listener: Listener?

    var value: T {
        didSet {
            listener?(value)
        }
    }

    init(_ value: T) {
        self.value = value
    }
  
    func bind(listener: Listener?) {
        self.listener = listener
        listener?(value)
    }
}
