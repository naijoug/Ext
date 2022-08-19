//
//  IAPHelper.swift
//  Ext
//
//  Created by naijoug on 2021/1/4.
//

import Foundation
import StoreKit

/**
 Reference :
    - https://www.raywenderlich.com/5456-in-app-purchase-tutorial-getting-started
    - https://www.appcoda.com/in-app-purchases-guide/
 */

/// IAP 产品列表回调
public typealias ProductsCompletionHandler  = Ext.ResultDataHandler<[SKProduct]>
/// IAP 支付结果回调
public typealias PaymentCompletionHandler   = Ext.ResultDataHandler<SKPaymentTransaction>

public extension ExtWrapper where Base: SKProduct {
    /// 本地化处理价格
    var localizedPrice: String? {
        let formatter = NumberFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .currency
        formatter.locale = base.priceLocale
        return formatter.string(from: base.price)
    }
}

public class IAPHelper: NSObject  {
    public override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    private var productsRequest: SKProductsRequest?
    
    private var productsHandler: ProductsCompletionHandler?
    private var paymentHandler: PaymentCompletionHandler?
}

// MARK: - StoreKit API

extension IAPHelper {
    
    /// 请求产品列表
    public func loadProducts(productIdentifiers: Set<String>, _ handler: @escaping ProductsCompletionHandler) {
        productsRequest?.cancel()
        productsHandler = handler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    /// 是否可以支付
    public var canMakePayments: Bool { return SKPaymentQueue.canMakePayments() }
    /// 购买产品
    public func buyProduct(_ product: SKProduct, handler: @escaping PaymentCompletionHandler) {
        Ext.debug("Buying \(product.productIdentifier)...")
        paymentHandler = handler
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    private func handleProducts(_ products: [SKProduct]?, error: Error?) {
        DispatchQueue.main.async {
            guard let error = error else {
                self.productsHandler?(.success(products ?? []))
                return
            }
            self.productsHandler?(.failure(error))
            
            self.productsRequest = nil
            self.productsHandler = nil
        }
    }
    private func handlePayment(_ transaction: SKPaymentTransaction, error: Error?) {
        DispatchQueue.main.async {
            guard let error = error else {
                self.paymentHandler?(.success(transaction))
                return
            }
            self.paymentHandler?(.failure(error))
        }
    }
    
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {

    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("Loaded list of products...")
        let products = response.products
        handleProducts(products, error: nil)
        
        print(SKProduct.logTitle)
        for product in products {
            print(product.log)
        }
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        Ext.debug("Failed to load list of products.", error: error)
        handleProducts(nil, error: error)
    }
    
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print(SKPaymentTransaction.logTitle)
        for transaction in transactions {
            print(transaction.log)
            
            switch (transaction.transactionState) {
            case .purchased:
                complete(transaction: transaction)
            case .failed:
                fail(transaction: transaction)
            case .restored:
                restore(transaction: transaction)
            case .deferred:   break
            case .purchasing: break
            default:          break
            }
        }
    }

    private func complete(transaction: SKPaymentTransaction) {
        Ext.debug("complete...")
        handlePayment(transaction, error: nil)
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }

        Ext.debug("restore... \(productIdentifier)")
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func fail(transaction: SKPaymentTransaction) {
        print("fail...")
        if let transactionError = transaction.error as NSError?,
        let localizedDescription = transaction.error?.localizedDescription,
            transactionError.code != SKError.paymentCancelled.rawValue {
            Ext.debug("Transaction Error: \(localizedDescription)", error: transaction.error)
        } else {
            Ext.debug("Transaction cancelled.", error: transaction.error)
        }
        handlePayment(transaction, error: transaction.error)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}

// MARK: - Log

private extension SKProduct {
    /// 产品日志标题
    static var logTitle: String {
        var log = "Product: \t"
        log += "ProductIdentifier \t"
        log += "Title \t"
        log += "Description \t"
        log += "Price \t"
        log += "PriceLocaleIdentifier \t"
        log += "CurrencySymbol \t"
        return log
    }
    /// 产品日志
    var log: String {
        var log = "Product: \t"
        log += "\(productIdentifier) \t"
        log += "\(localizedTitle) \t"
        log += "\(localizedDescription) \t"
        log += "\(price) \t"
        log += "\(priceLocale.identifier) \t"
        log += "\(priceLocale.currencySymbol ?? "") \t"
        return log
    }
}
private extension SKPaymentTransaction {
    /// 交易日志标题
    static var logTitle: String {
        var log = "Tx: \t"
        log += "ProductIdentifier \t"
        log += "Identifier \t"
        log += "State \t"
        return log
    }
    /// 交易日志
    var log: String {
        var log = "Tx: \t"
        log += "\(payment.productIdentifier) \t"
        log += "\(transactionIdentifier ?? "") \t"
        log += "\(stateTitle) \t"
        return log
    }
    /// 交易状态标题
    var stateTitle: String {
        switch transactionState {
        case .purchasing:   return "purchasing..."
        case .purchased:    return "purchased."
        case .failed:       return "failed."
        case .restored:     return "restored."
        case .deferred:     return "deferred."
        default:            return "\(String(describing: transactionState)) \(transactionState.rawValue)"
        }
    }
}
