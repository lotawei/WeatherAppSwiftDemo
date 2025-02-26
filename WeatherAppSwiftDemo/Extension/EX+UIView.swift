//
//  EX+UIView.swift
//  WeatherAppSwiftDemo
//
//  Created by work on 2025/2/26.
//

import UIKit

// LayoutConfigurable.swift
protocol LayoutConfigurable {
    /// 布局约束配置
     func setupConstraints()

}
extension LayoutConfigurable{
    /// 预处理视图的基础配置
    func preSetup(){
        
    }
    /// 设置视图层级关系
     func setupHierarchy()
    {
        
    }
    /// 样式配置（可选）
    func setupStyle(){
        
    }
}

extension LayoutConfigurable where Self: UIView {
    func setup() {
        preSetup()
        setupHierarchy()
        setupConstraints()
        setupStyle()
    }
}
