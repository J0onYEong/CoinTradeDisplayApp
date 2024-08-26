//
//  ViewController.swift
//  CoinTradeDisplay
//
//  Created by choijunios on 8/23/24.
//

import UIKit
import Domain
import RxCocoa
import RxSwift

class ViewController: UIViewController {
    
    var viewModel: OrderBookL2ViewModel?
    
    // View
    let startStreamButton: UIButton = {
        let button = UIButton()
        button.setTitle("스트림 시작", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
    }()
    
    let sellTable = StaticSizeTableView(cellCount: 20, cellHeight: 30)
    let sellTableDataSource = CoinDataTableDataSource(type: .sell)
    
    let buyTable = StaticSizeTableView(cellCount: 20, cellHeight: 30)
    let buyTableDataSource = CoinDataTableDataSource(type: .buy)

    let disposeBag = DisposeBag()
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { return nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTable()
        setAppearance()
        setAutoLayout()
    }
    
    private func configureTable() {
        sellTable.register(PriceAndAmountCell.self, forCellReuseIdentifier: PriceAndAmountCell.identifier)
        sellTable.dataSource = sellTableDataSource
        sellTable.isScrollEnabled = false
        sellTableDataSource.tableView = sellTable
        
        buyTable.register(PriceAndAmountCell.self, forCellReuseIdentifier: PriceAndAmountCell.identifier)
        buyTable.dataSource = buyTableDataSource
        buyTable.isScrollEnabled = false
        buyTableDataSource.tableView = buyTable
    }
    
    func setAppearance() {
        view.backgroundColor = .white
    }
    
    func setAutoLayout() {
        let stack = UIStackView(arrangedSubviews: [buyTable, sellTable])
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.axis = .horizontal
        
        [
            startStreamButton,
            stack
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            
            startStreamButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startStreamButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            stack.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
        ])
    }
    
    func bind(viewModel: OrderBookL2ViewModel) {
        
        self.viewModel = viewModel
        
        // Input
        startStreamButton.rx.tap
            .bind(to: viewModel.startStreamButtonClicked)
            .disposed(by: disposeBag)
        
        // Output
        viewModel
            .buyListRO?
            .drive(buyTableDataSource.data)
            .disposed(by: disposeBag)
        
        viewModel
            .sellListRO?
            .drive(sellTableDataSource.data)
            .disposed(by: disposeBag)
    }
}

// MARK: ViewModel
public class OrderBookL2ViewModel {
    
    // Init
    let coinStreamUseCase: CoinStreamUseCase
    
    // Input
    let startStreamButtonClicked: PublishRelay<Void> = .init()
    
    // Output
    private(set) var buyListRO: Driver<[PriceAndAmountCellRO]>?
    private(set) var sellListRO: Driver<[PriceAndAmountCellRO]>?
    
    let disposeBag = DisposeBag()
    
    init(coinStreamUseCase: CoinStreamUseCase) {
        self.coinStreamUseCase = coinStreamUseCase
        
        
        let coinStream = coinStreamUseCase
            .coinDataSubject
            
        
        let buyStream = coinStream.map { vo in
            vo.buyList
        }
        let sellStream = coinStream.map { vo in
            vo.sellList
        }
        
        
        // MARK: Buy
        buyListRO = buyStream.map({ buyData in
            
            let maxAmount = buyData.max { lhs, rhs in lhs.accumulatedAmount < rhs.accumulatedAmount }?.accumulatedAmount
            
            var roList = buyData.map { vo in
                
                var percentage: CGFloat = 0.0
                
                if let maxAmount, maxAmount != 0 {
                    percentage = vo.accumulatedAmount / maxAmount
                }
                
                return PriceAndAmountCellRO(
                    type: .buy,
                    price: vo.price,
                    amount: vo.accumulatedAmount,
                    percentage: percentage
                )
            }
            
            if roList.count < 20 {
                let emptySize = 20 - roList.count
                let emptyRoList: [PriceAndAmountCellRO] = (0..<emptySize).map { _ in .emptyObject(.buy) }
                roList.append(contentsOf: emptyRoList)
            }
            
            return roList
        })
        .asDriver(onErrorDriveWith: .never())
        
        // MARK: Sell
        sellListRO = sellStream.map({ sellData in
            
            let maxAmount = sellData.max { lhs, rhs in lhs.accumulatedAmount < rhs.accumulatedAmount }?.accumulatedAmount
            
            var roList = sellData.map { vo in
                
                var percentage: CGFloat = 0.0
                if let maxAmount, maxAmount != 0 {
                    percentage = vo.accumulatedAmount / maxAmount
                }
                
                return PriceAndAmountCellRO(
                    type: .sell,
                    price: vo.price,
                    amount: vo.accumulatedAmount,
                    percentage: percentage
                )
            }
            
            if roList.count < 20 {
                let emptySize = 20 - roList.count
                let emptyRoList: [PriceAndAmountCellRO] = (0..<emptySize).map { _ in .emptyObject(.sell) }
                roList.append(contentsOf: emptyRoList)
            }
            
            return roList
        })
        .asDriver(onErrorDriveWith: .never())
        
        startStreamButtonClicked
            .subscribe(onNext: { [coinStreamUseCase] _ in
                coinStreamUseCase.startStream()
            })
            .disposed(by: disposeBag)
    }
}


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
        data.value.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.identifier) as! Cell
        cell.selectionStyle = .none
        
        let ro = data.value[indexPath.row]
        
        cell.render(ro)

        return cell
    }
    
    
}

public struct PriceAndAmountCellRO {
    let type: OrderType
    let price: Double
    let amount: Double
    let percentage: Double
    
    static func emptyObject(_ type: OrderType) -> PriceAndAmountCellRO {
        .init(
            type: type,
            price: 0.0,
            amount: 0,
            percentage: 0
        )
    }
    
    static func mockObject(_ type: OrderType) -> PriceAndAmountCellRO {
        .init(
            type: type,
            price: 1234.0,
            amount: 23,
            percentage: 0.32
        )
    }
}


// MARK: Cell
public class PriceAndAmountCell: UITableViewCell {
    
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
        setLayout()
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
        percentageBackground.backgroundColor = accentColor.withAlphaComponent(0.2)
    }
    
    private func setLabel(label1: UILabel, label2: UILabel, accentColor: UIColor, ro: PriceAndAmountCellRO) {
        
        label1.text = String(ro.amount)
        label1.font = UIFont.systemFont(ofSize: 12)
        label2.text = String(ro.price)
        label2.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label2.textColor = accentColor
    }
}
