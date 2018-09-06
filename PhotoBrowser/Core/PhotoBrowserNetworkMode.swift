//
//  PhotoBrowserNetworkMode.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/8/28.
//

import Foundation

public struct PhotoBrowserNetworkMode {
    
    /// 共有多少项
    var numberOfItemsClosure: () -> Int
    
    /// 网络图片加载完成前的占位图
    var placeholderAtIndexClosure: (Int) -> UIImage?
    
    /// 网络图片url
    var urlAtIndexClosure: (Int) -> URL?
    
    /// 初始化
    /// - parameter numberOfItems: 共有多少项
    /// - parameter imageAtIndex: 每一项的图片对象
    public init(numberOfItems: @escaping () -> Int,
                placeholderAtIndex: @escaping (Int) -> UIImage?,
                urlAtIndex: @escaping (Int) -> URL?) {
        self.numberOfItemsClosure = numberOfItems
        self.placeholderAtIndexClosure = placeholderAtIndex
        self.urlAtIndexClosure = urlAtIndex
    }
}

extension PhotoBrowserNetworkMode {
    
    public func numberOfItems() -> Int {
        return numberOfItemsClosure()
    }
    
    public func configure(cell: PhotoBrowserCell, at index: Int) {
        
    }
}
