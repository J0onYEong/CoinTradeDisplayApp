//
//  StaticSizeTableView+DataSource.swift
//  Presentation
//
//  Created by choijunios on 8/30/24.
//

import UIKit
import RxSwift
import RxCocoa
import Domain


// MARK: TableView
public class StaticSizeTableView: UITableView {
    let tableViewHeight: CGFloat
    
    public override var intrinsicContentSize: CGSize {
        .init(width: super.intrinsicContentSize.width, height: tableViewHeight)
    }
    
    public init(cellCount: Int, cellHeight: CGFloat) {
        self.tableViewHeight = CGFloat(cellCount) * cellHeight
        super.init(frame: .zero, style: .plain)
        self.rowHeight = cellHeight
        self.backgroundColor = .clear
    }
    public required init?(coder: NSCoder) { return nil }
}



// MARK: TableViewDataSource
public class CoinDataTableDataSource: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    typealias Cell = PriceAndAmountCell
    
    let type: OrderType
    public weak var tableView: UITableView?
    
    public lazy var data: BehaviorRelay<[PriceAndAmountCellRO]> = .init(value: [])
    
    let disposeBag = DisposeBag()
    
    public init(type: OrderType) {
        self.type = type
        super.init()
        
        data
            .observe(on: MainScheduler.asyncInstance)
            .subscribe (onNext: { [weak self] newData in
                guard let self else { return }
                
                tableView?.beginUpdates()
                
                for (index, item) in newData.enumerated() {
                    if let cell = self.tableView?.cellForRow(at: IndexPath(row: index, section: 0)) as? Cell {
                        cell.render(item)
                    }
                }
                
                tableView?.endUpdates()
            })
            .disposed(by: disposeBag)
    }
    
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.value.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.identifier) as! Cell
        cell.selectionStyle = .none
        
        let ro = data.value[indexPath.row]
        
        cell.render(ro)

        return cell
    }
}
