//
//  PriceAndAmountCell.swift
//  Presentation
//
//  Created by choijunios on 8/30/24.
//

import UIKit
import Domain

// MARK: Cell
public class PriceAndAmountCell: UITableViewCell {
    
    public static let identifier = String(describing: PriceAndAmountCell.self)
    
    // View
    let firstLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        return label
    }()
    let secondLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        return label
    }()
    let percentageBackground = UIView()
    
    var ro: PriceAndAmountCellRO?
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setLayout()
        self.backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    public required init?(coder: NSCoder) { return nil }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let ro else { return }
        
        if ro.type == .buy {
            let width = self.contentView.frame.width
            let halfWidth = (width) / 2
            let x = halfWidth + halfWidth * (1 - ro.percentage)
            let bgWidth = width - x
            
            self.percentageBackground.frame = .init(
                origin: .init(x: x, y: 0),
                size: .init(width: bgWidth, height: self.contentView.frame.height)
            )
            
        } else {
            
            let width = self.contentView.frame.width
            let halfWidth = (width) / 2
            let bgWidth = halfWidth * ro.percentage
            
            self.percentageBackground.frame = .init(
                origin: .init(x: 0, y: 0),
                size: .init(width: bgWidth, height: self.contentView.frame.height)
            )
        }
    }
    
    private func setLayout() {
        
        let stack = UIStackView(arrangedSubviews: [firstLabel, UIView(), secondLabel])
        firstLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        secondLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        stack.distribution = .fill
        stack.alignment = .center
        stack.axis = .horizontal
        
        [
            percentageBackground,
            stack
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            stack.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    public func render(_ ro: PriceAndAmountCellRO) {
        
        self.ro = ro
        
        let accentColor: UIColor = ro.type == .buy ? .green : .red
        
        if ro.type == .buy {
            setLabel(label1: firstLabel, label2: secondLabel, accentColor: accentColor, ro: ro)
        } else {
            setLabel(label1: secondLabel, label2: firstLabel, accentColor: accentColor, ro: ro)
        }
        
        // background
        percentageBackground.backgroundColor = accentColor.withAlphaComponent(0.3)
    }
    
    private func setLabel(label1: UILabel, label2: UILabel, accentColor: UIColor, ro: PriceAndAmountCellRO) {
        
        label1.text = String(ro.amount)
        label1.font = UIFont.systemFont(ofSize: 12)
        label2.text = String(ro.price)
        label2.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label2.textColor = accentColor
    }
}
