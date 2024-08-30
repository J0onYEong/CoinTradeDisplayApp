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
import Presentation

class ViewController: UIViewController {
    
    var viewModel: OrderBookL2ViewModel?
    
    // View
    let startStreamButton: UIButton = {
        let button = UIButton()
        button.setTitle("스트림 시작", for: .normal)
        button.setTitleColor(.green, for: .normal)
        return button
    }()
    
    let connectStreamButton: UIButton = {
        let button = UIButton()
        button.setTitle("스트림 연결", for: .normal)
        button.setTitleColor(.red, for: .normal)
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
        view.backgroundColor = .black
    }
    
    func setAutoLayout() {
        let tableStack = UIStackView(arrangedSubviews: [buyTable, sellTable])
        tableStack.distribution = .fillEqually
        tableStack.alignment = .center
        tableStack.axis = .horizontal
        
        let buttonStack = UIStackView(arrangedSubviews: [startStreamButton, connectStreamButton])
        buttonStack.alignment = .center
        buttonStack.axis = .horizontal
        
        [
            buttonStack,
            tableStack
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            tableStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            tableStack.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            tableStack.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
        ])
    }
    
    func bind(viewModel: OrderBookL2ViewModel) {
        
        self.viewModel = viewModel
        
        // Input
        startStreamButton.rx.tap
            .bind(to: viewModel.startStreamButtonClicked)
            .disposed(by: disposeBag)
        
        connectStreamButton.rx.tap
            .bind(to: viewModel.connectStreamButtonClicked)
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


