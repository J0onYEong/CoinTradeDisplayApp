//
//  ViewController.swift
//  CoinTradeDisplay
//
//  Created by choijunios on 8/23/24.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
}



// MARK: Cell
public class PriceAndAmountCell: UITableViewCell {
    
    public struct PriceAndAmountCellRO {
        enum OrderType { case buy, sell }
        let type: OrderType
        let price: Double
        let amount: Double
        let percentage: Double
    }
    
    static let identifier = String(describing: PriceAndAmountCell.self)
    
    // View
    let firstLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    let secondLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    let percentageBackground = UIView()
    
    var ro: PriceAndAmountCellRO?
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    public required init?(coder: NSCoder) { return nil }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let ro else { return }
        
        if ro.type == .buy {
            let width = contentView.frame.width
            let halfWidth = (width)/2
            let x = halfWidth + halfWidth * (1-ro.percentage)
            let bgWidth = width-x
            
            percentageBackground.frame = .init(
                origin: .init(x: x, y: 0),
                size: .init(width: bgWidth, height: contentView.frame.height)
            )
            
        } else {
            
            let width = contentView.frame.width
            let halfWidth = (width)/2
            let bgWidth = halfWidth * ro.percentage
            
            percentageBackground.frame = .init(
                origin: .init(x: 0, y: 0),
                size: .init(width: bgWidth, height: contentView.frame.height)
            )
        }
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
        percentageBackground.backgroundColor = accentColor.withAlphaComponent(0.5)
    }
    
    private func setLabel(label1: UILabel, label2: UILabel, accentColor: UIColor, ro: PriceAndAmountCellRO) {
        
        label1.text = String(ro.amount)
        label2.text = String(ro.price)
        label2.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label2.textColor = accentColor
    }
}
