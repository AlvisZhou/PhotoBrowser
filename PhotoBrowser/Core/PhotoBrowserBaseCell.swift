//
//  PhotoBrowserBaseCell.swift
//  JXPhotoBrowser
//
//  Created by JiongXing on 2018/9/5.
//

import Foundation

open class PhotoBrowserBaseCell: UICollectionViewCell {
    
    /// ImageView
    public let imageView = UIImageView()
    
    /// 图片缩放容器
    public let imageContainer = UIScrollView()
    
    /// 图片允许的最大放大倍率
    public var imageMaximumZoomScale: CGFloat = 2.0
    
    /// 单击时回调
    public var clickCallback: ((UITapGestureRecognizer) -> Void)?
    
    /// 长按时回调
    public var longPressedCallback: ((UILongPressGestureRecognizer) -> Void)?
    
    /// 图片拖动时回调
    public var panChangedCallback: ((_ scale: CGFloat) -> Void)?
    
    /// 图片下拉松手回调
    public var panReleasedCallback: (() -> Void)?
    
    /// 记录pan手势开始时imageView的位置
    private var beganFrame = CGRect.zero
    
    /// 记录pan手势开始时，手势位置
    private var beganTouch = CGPoint.zero
    
    /// 初始化
    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageContainer)
        imageContainer.maximumZoomScale = imageMaximumZoomScale
        imageContainer.delegate = self
        imageContainer.showsVerticalScrollIndicator = false
        imageContainer.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            imageContainer.contentInsetAdjustmentBehavior = .never
        }
        
        imageContainer.addSubview(imageView)
        imageView.clipsToBounds = true
        
        // 长按手势
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(_:)))
        contentView.addGestureRecognizer(longPress)
        
        // 双击手势
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(onDoubleClick(_:)))
        doubleTap.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTap)
        
        // 单击手势
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(onClick(_:)))
        contentView.addGestureRecognizer(singleTap)
        singleTap.require(toFail: doubleTap)
        
        // 拖动手势
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        pan.delegate = self
        // 必须加在scrollView上。不能加在contentView上，否则长图下拉不能触发
        imageContainer.addGestureRecognizer(pan)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
    
    /// 布局
    open func layout() {
        imageContainer.frame = contentView.bounds
        imageContainer.setZoomScale(1.0, animated: false)
        imageView.frame = fitFrame
        imageContainer.setZoomScale(1.0, animated: false)
    }
}

//
// MARK: - Events
//

extension PhotoBrowserBaseCell {
    /// 响应拖动
    @objc open func onPan(_ pan: UIPanGestureRecognizer) {
        guard imageView.image != nil else {
            return
        }
        switch pan.state {
        case .began:
            beganFrame = imageView.frame
            beganTouch = pan.location(in: imageContainer)
        case .changed:
            let result = panResult(pan)
            imageView.frame = result.0
            panChangedCallback?(result.1)
        case .ended, .cancelled:
            imageView.frame = panResult(pan).0
            if pan.velocity(in: self).y > 0 {
                panReleasedCallback?()
            } else {
                resetImageView()
            }
        default:
            resetImageView()
        }
    }
    
    /// 计算拖动时图片应调整的frame和scale值
    private func panResult(_ pan: UIPanGestureRecognizer) -> (CGRect, CGFloat) {
        // 拖动偏移量
        let translation = pan.translation(in: imageContainer)
        let currentTouch = pan.location(in: imageContainer)
        
        // 由下拉的偏移值决定缩放比例，越往下偏移，缩得越小。scale值区间[0.3, 1.0]
        let scale = min(1.0, max(0.3, 1 - translation.y / bounds.height))
        
        let width = beganFrame.size.width * scale
        let height = beganFrame.size.height * scale
        
        // 计算x和y。保持手指在图片上的相对位置不变。
        // 即如果手势开始时，手指在图片X轴三分之一处，那么在移动图片时，保持手指始终位于图片X轴的三分之一处
        let xRate = (beganTouch.x - beganFrame.origin.x) / beganFrame.size.width
        let currentTouchDeltaX = xRate * width
        let x = currentTouch.x - currentTouchDeltaX
        
        let yRate = (beganTouch.y - beganFrame.origin.y) / beganFrame.size.height
        let currentTouchDeltaY = yRate * height
        let y = currentTouch.y - currentTouchDeltaY
        
        return (CGRect(x: x.isNaN ? 0 : x, y: y.isNaN ? 0 : y, width: width, height: height), scale)
    }
    
    /// 响应单击
    @objc open func onClick(_ tap: UITapGestureRecognizer) {
        clickCallback?(tap)
    }
    
    /// 响应双击
    @objc open func onDoubleClick(_ tap: UITapGestureRecognizer) {
        // 如果当前没有任何缩放，则放大到目标比例，否则重置到原比例
        if imageContainer.zoomScale == 1.0 {
            // 以点击的位置为中心，放大
            let pointInView = tap.location(in: imageView)
            let width = imageContainer.bounds.size.width / imageContainer.maximumZoomScale
            let height = imageContainer.bounds.size.height / imageContainer.maximumZoomScale
            let x = pointInView.x - (width / 2.0)
            let y = pointInView.y - (height / 2.0)
            imageContainer.zoom(to: CGRect(x: x, y: y, width: width, height: height), animated: true)
        } else {
            imageContainer.setZoomScale(1.0, animated: true)
        }
    }
    
    /// 响应长按
    @objc open func onLongPress(_ press: UILongPressGestureRecognizer) {
        longPressedCallback?(press)
    }
}

//
// MARK: - UIScrollViewDelegate
//

extension PhotoBrowserBaseCell: UIScrollViewDelegate {
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.center = resettingCenter
    }
}

//
// MARK: - UIGestureRecognizerDelegate
//

extension PhotoBrowserBaseCell: UIGestureRecognizerDelegate {
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // 只响应pan手势
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        let velocity = pan.velocity(in: self)
        // 向上滑动时，不响应手势
        if velocity.y < 0 {
            return false
        }
        // 横向滑动时，不响应pan手势
        if abs(Int(velocity.x)) > Int(velocity.y) {
            return false
        }
        // 向下滑动，如果图片顶部超出可视区域，不响应手势
        if imageContainer.contentOffset.y > 0 {
            return false
        }
        // 响应允许范围内的下滑手势
        return true
    }
}

//
// MARK: - Private
//

extension PhotoBrowserBaseCell {
    
    /// 计算图片复位坐标
    private var resettingCenter: CGPoint {
        let deltaWidth = bounds.width - imageContainer.contentSize.width
        let offsetX = deltaWidth > 0 ? deltaWidth * 0.5 : 0
        let deltaHeight = bounds.height - imageContainer.contentSize.height
        let offsetY = deltaHeight > 0 ? deltaHeight * 0.5 : 0
        return CGPoint(x: imageContainer.contentSize.width * 0.5 + offsetX,
                       y: imageContainer.contentSize.height * 0.5 + offsetY)
    }
    
    /// 计算图片适合的size
    private var fitSize: CGSize {
        guard let image = imageView.image else {
            return CGSize.zero
        }
        let width = imageContainer.bounds.width
        let scale = image.size.height / image.size.width
        return CGSize(width: width, height: scale * width)
    }
    
    /// 计算图片适合的frame
    private var fitFrame: CGRect {
        let size = fitSize
        let y = (imageContainer.bounds.height - size.height) > 0
            ? (imageContainer.bounds.height - size.height) * 0.5
            : 0
        return CGRect(x: 0, y: y, width: size.width, height: size.height)
    }
    
    /// 复位ImageView
    private func resetImageView() {
        // 如果图片当前显示的size小于原size，则重置为原size
        let size = fitSize
        let needResetSize = imageView.bounds.size.width < size.width
            || imageView.bounds.size.height < size.height
        UIView.animate(withDuration: 0.25) {
            self.imageView.center = self.resettingCenter
            if needResetSize {
                self.imageView.bounds.size = size
            }
        }
    }
}
