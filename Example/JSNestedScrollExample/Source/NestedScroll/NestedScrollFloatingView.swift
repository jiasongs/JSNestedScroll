//
//  NestedScrollFloatingView.swift
//  JSNestedScrollExample
//
//  Created by jiasong on 2022/11/7.
//

import UIKit
import JSNestedScroll
import QMUIKit
import SnapKit

class NestedScrollFloatingView: UIView {
    
    lazy var label: QMUILabel = {
        return QMUILabel().then {
            $0.text = "floating"
            $0.textAlignment = .center
        }
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.label)
        self.label.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension NestedScrollFloatingView: NestedScrollViewSupplementarySubview {
    
    public func preferredHeight(in nestedScrollView: NestedScrollView) -> CGFloat {
        return 38
    }
    
}
