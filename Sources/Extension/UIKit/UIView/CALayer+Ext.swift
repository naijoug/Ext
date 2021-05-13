//
//  CALayer+Ext.swift
//  Ext
//
//  Created by naijoug on 2021/1/28.
//

import UIKit

public extension ExtWrapper where Base: CALayer {
        
    func bubble(_ arrow: BubbleArrow = BubbleArrow(), cornerRadius: CGFloat = 8, in size: CGSize) {
        let bubbleLayer = CAShapeLayer()
        bubbleLayer.path = bubblePath(size: size, cornerRadius: cornerRadius, arrow: arrow)
        base.mask = bubbleLayer
    }
    
}
private extension ExtWrapper where Base: CALayer {
    
    // Reference : https://github.com/iHandle/BubbleLayer
    
    /// 绘制气泡形状路径
    func bubblePath(size: CGSize, cornerRadius: CGFloat, arrow: BubbleArrow) -> CGPath? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let ctx = UIGraphicsGetCurrentContext()
        
        // 获取绘图所需要的关键点
        let points = keyPoints(size: size, cornerRadius: cornerRadius, arrow: arrow)
        
        // 第一步是要画箭头的“第一个支点”所在的那个角，所以要把“笔”放在这个支点顺时针顺序的上一个点
        // 所以把“笔”放在最后才画的矩形框的角的位置, 准备开始画箭头
        let currentPoint = points[6]
        ctx?.move(to: currentPoint)
        
        // 用于 CGContextAddArcToPoint函数的变量
        var pointA = CGPoint.zero
        var pointB = CGPoint.zero
        var radius: CGFloat = 0
        var count: Int = 0
        
        while count < 7 {
            // 整个过程需要画七个圆角(矩形框的四个角和箭头处的三个角)，所以分为七个步骤
            
            // 箭头处的三个圆角和矩形框的四个圆角不一样
            radius = count < 3 ? arrow.radius : cornerRadius
            
            pointA = points[count]
            pointB = points[(count + 1) % 7]
            // 画矩形框最后一个角的时候，pointB就是points[0]
            
            ctx?.addArc(tangent1End: pointA, tangent2End: pointB, radius: radius)
            
            count += 1
        }
        
        ctx?.closePath()
        UIGraphicsEndImageContext()
        
        return ctx?.path?.copy()
    }
    /// 关键点: 绘制气泡形状前，需要计算箭头的三个点和矩形的四个角的点的坐标
    func keyPoints(size: CGSize, cornerRadius: CGFloat, arrow: BubbleArrow) -> [CGPoint] {
        
        // 先确定箭头的三个点
        var beginPoint = CGPoint.zero // 按顺时针画箭头时的第一个支点，例如箭头向上时的左边的支点
        var topPoint = CGPoint.zero // 顶点
        var endPoint = CGPoint.zero // 另外一个支点
        
        // 箭头顶点topPoint的X坐标(或Y坐标)的范围（用来计算arrowPosition）
        let tpXRange = size.width - 2 * cornerRadius - arrow.width
        let tpYRange = size.height - 2 * cornerRadius - arrow.width
        
        // 用于表示矩形框的位置和大小
        var rX: CGFloat = 0
        var rY: CGFloat = 0
        var rWidth = size.width
        var rHeight = size.height
        
        // 计算箭头的位置，以及调整矩形框的位置和大小
        switch arrow.direction {
        case .right:
            topPoint = CGPoint(x: size.width, y: size.height / 2 + tpYRange * (arrow.position - 0.5))
            beginPoint = CGPoint(x: topPoint.x - arrow.height, y:topPoint.y - arrow.width / 2 )
            endPoint = CGPoint(x: beginPoint.x, y: beginPoint.y + arrow.width)
            
            rWidth -= arrow.height //矩形框右边的位置“腾出”给箭头
        case .bottom:
            topPoint = CGPoint(x: size.width / 2 + tpXRange * (arrow.position - 0.5), y: size.height)
            beginPoint = CGPoint(x: topPoint.x + arrow.width / 2, y:topPoint.y - arrow.height )
            endPoint = CGPoint(x: beginPoint.x - arrow.width, y: beginPoint.y)
            
            rHeight -= arrow.height
        case .left:
            topPoint = CGPoint(x: 0, y: size.height / 2 + tpYRange * (arrow.position - 0.5))
            beginPoint = CGPoint(x: topPoint.x + arrow.height, y: topPoint.y + arrow.width / 2)
            endPoint = CGPoint(x: beginPoint.x, y: beginPoint.y - arrow.width)
            
            rX = arrow.height
            rWidth -= arrow.height
        case .top:
            topPoint = CGPoint(x: size.width / 2 + tpXRange * (arrow.position - 0.5), y: 0)
            beginPoint = CGPoint(x: topPoint.x - arrow.width / 2, y: topPoint.y + arrow.height)
            endPoint = CGPoint(x: beginPoint.x + arrow.width, y: beginPoint.y)
            
            rY = arrow.height
            rHeight -= arrow.height
        }

        // 先把箭头的三个点放进关键点数组中
        var points = [beginPoint, topPoint, endPoint]
        
        //确定圆角矩形的四个点
        let bottomRight = CGPoint(x: rX + rWidth, y: rY + rHeight); //右下角的点
        let bottomLeft = CGPoint(x: rX, y: rY + rHeight);
        let topLeft = CGPoint(x: rX, y: rY);
        let topRight = CGPoint(x: rX + rWidth, y: rY);
        
        //先放在一个临时数组, 放置顺序跟下面紧接着的操作有关
        let rectPoints = [bottomRight, bottomLeft, topLeft, topRight]
        
        // 绘制气泡形状的时候，从箭头开始,顺时针地进行
        // 箭头向右时，画完箭头之后会先画到矩形框的右下角
        // 所以此时先把矩形框右下角的点放进关键点数组,其他三个点按顺时针方向添加
        // 箭头在其他方向时，以此类推
        
        var rectPointIndex: Int = arrow.direction.rawValue
        for _ in 0...3 {
            points.append(rectPoints[rectPointIndex])
            rectPointIndex = (rectPointIndex + 1) % 4
        }
        return points
    }
}





// 一些在注释中使用的叫法
// 箭头: 气泡形状突出那个三角形把它叫做【箭头】
// 箭头的顶点和底点: 将箭头指向的那个点叫为【顶点】，其余两个点叫为【底点】
// 箭头的高度和宽度: 箭头顶点到底点连线的距离叫为【箭头的高度】，两底点的距离叫为【箭头的宽度】
// 矩形框: 气泡形状除了箭头，剩下的部分叫为【矩形框】
// 箭头的相对位置: 如果箭头的方向是向右或者向左，0表达箭头在最上方，1表示箭头在最下方
//              如果箭头的方向是向上或者向下，0表达箭头在最左边，1表示箭头在最右边
//              默认是 0.5，即在中间


/// 气泡箭头
public struct BubbleArrow {
    /// 气泡箭头方向
    public enum ArrowDirection: Int {
        case right  = 0
        case bottom = 1
        case left   = 2
        case top    = 3
    }
    
    /// 箭头方向
    public var direction: ArrowDirection = .top
    /// 箭头位置的圆角半径
    public var radius: CGFloat = 4
    /// 箭头的宽度
    public var width: CGFloat = 20
    /// 箭头的高度
    public var height: CGFloat = 10
    /// 箭头的相对位置 (0 ~ 1.0)
    public var position: CGFloat = 0.5 {
        didSet {
            position = max(0, min(1.0, position))
        }
    }
    
    public init() {}
}
