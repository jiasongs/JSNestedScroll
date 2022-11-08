//
//  NestedScrollListView.swift
//  JSNestedScrollExample
//
//  Created by jiasong on 2022/11/7.
//

import UIKit
import QMUIKit
import JSNestedScroll

class NestedScrollListView: UIView, QMUITableViewDataSource, QMUITableViewDelegate {
    
    lazy var tableView: QMUITableView = {
        return QMUITableView().then {
            $0.backgroundColor = UIColor.clear
        }
    }()
    
    var numberOfRows = 30 {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var textPrefix: String = "" {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.tableView)
        
        self.tableView.register(QMUITableViewCell.self, forCellReuseIdentifier: "\(QMUITableViewCell.self)")
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.tableView.frame = self.bounds
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "\(QMUITableViewCell.self)", for: indexPath)
        cell.textLabel?.text = "\(self.textPrefix) - \(indexPath.row)"
        cell.textLabel?.textColor = .black
        cell.backgroundColor = .clear
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 42
    }
    
}

extension NestedScrollListView: NestedScrollViewScrollSubview, NestedScrollViewSupplementarySubview {
    
    func preferredScrollView(in nestedScrollView: NestedScrollView) -> UIScrollView? {
        return self.tableView
    }
    
}
