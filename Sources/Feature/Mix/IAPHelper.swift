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

/// IAP 内购错误
enum IAPError: Error {
    case productIdEmpty
    case productNotFound
    
    case paymentDisabled
    case paymentCancelled
    case paymentProductNotMatch
    case paymentNoReceipt
}
extension IAPError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .productIdEmpty:           return "product id is empty"
        case .productNotFound:          return "product not found"
            
        case .paymentDisabled:          return "payment disabled"
        case .paymentCancelled:         return "payment cancelled"
        case .paymentProductNotMatch:   return "payment product not match"
        case .paymentNoReceipt:         return "payment no receipt"
        }
    }
}

/// IAP 产品查询回调
public typealias ProductHandler  = Ext.ResultDataHandler<SKProduct>
/// IAP 产品列表回调
public typealias ProductsHandler  = Ext.ResultDataHandler<[SKProduct]>
/// IAP 支付结果回调
public typealias PaymentHandler   = Ext.ResultDataHandler<(tx: SKPaymentTransaction, receipt: String)>

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
    
    public var logEnabled: Bool = true
    
    private var productsRequest: SKProductsRequest?
    
    private var productsHandler: ProductsHandler?
    private var paymentHandler: Ext.ResultDataHandler<SKPaymentTransaction>?
}

// MARK: - StoreKit API

public extension IAPHelper {
    
    /// 是否可以支付
    var canMakePayments: Bool { SKPaymentQueue.canMakePayments() }
    
    /// 根据产品 ID 查询产品信息
    /// - Parameters:
    ///   - productIdentifier: 产品 ID
    func loadProduct(_ productIdentifier: String, handler: @escaping ProductHandler) {
        guard !productIdentifier.isEmpty else {
            handler(.failure(IAPError.productIdEmpty))
            return
        }
        loadProducts(productIdentifiers: [productIdentifier]) { result in
            switch result {
            case .failure(let error): handler(.failure(error))
            case .success(let products):
                guard let product = products.first(where: { $0.productIdentifier == productIdentifier }) else {
                    handler(.failure(IAPError.productNotFound))
                    return
                }
                handler(.success(product))
            }
        }
    }
    
    /// 产品可用产品列表
    func loadProducts(productIdentifiers: Set<String>, handler: @escaping ProductsHandler) {
        _loadProducts(productIdentifiers: productIdentifiers, handler: handler)
    }
    
    /// 根据产品 ID 购买产品
    /// - Parameters:
    ///   - productIdentifier: 产品 ID
    func buy(_ productIdentifier: String, handler: @escaping PaymentHandler) {
        loadProduct(productIdentifier) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .failure(let error): handler(.failure(error))
            case .success(let product):
                self.buyProduct(product, handler: handler)
            }
        }
    }
    
    /// 购买产品
    func buyProduct(_ product: SKProduct, handler: @escaping PaymentHandler) {
        _buyProduct(product) { [weak self] result in
            guard let `self` = self else { return }
            switch result {
            case .failure(let error): handler(.failure(error))
            case .success(let tx):
                guard tx.payment.productIdentifier == product.productIdentifier else {
                    handler(.failure(IAPError.paymentProductNotMatch))
                    return
                }
                guard let receiptUrl = Bundle.main.appStoreReceiptURL,
                      let receipt = try? Data(contentsOf: receiptUrl).base64EncodedString() else {
                    Ext.debug("transaction \(product.productIdentifier) no receipt", logEnabled: self.logEnabled, locationEnabled: false)
                    handler(.failure(IAPError.paymentNoReceipt))
                    return
                }
                handler(.success((tx, receipt)))
            }
        }
    }
}

private extension IAPHelper {
    
    /// 请求产品列表
    func _loadProducts(productIdentifiers: Set<String>, handler: @escaping ProductsHandler) {
        guard !productIdentifiers.isEmpty else {
            handleProducts(nil, error: IAPError.productIdEmpty)
            return
        }
        productsRequest?.cancel()
        productsHandler = handler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    /// 购买产品
    func _buyProduct(_ product: SKProduct, handler: @escaping Ext.ResultDataHandler<SKPaymentTransaction>) {
        guard canMakePayments else {
            handler(.failure(IAPError.paymentDisabled))
            return
        }
        Ext.debug("Buy \(product.productIdentifier) ...", logEnabled: logEnabled, locationEnabled: false)
        paymentHandler = handler
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {

    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        Ext.debug("Loaded list of products...", logEnabled: logEnabled, locationEnabled: false)
        let products = response.products
        handleProducts(products, error: nil)
        
        Ext.debug("products: \(products)", logEnabled: logEnabled, locationEnabled: false)
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        Ext.debug("Failed to load list of products.", error: error, logEnabled: logEnabled, locationEnabled: false)
        handleProducts(nil, error: error)
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
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            Ext.debug("transaction: \(transaction)", logEnabled: logEnabled, locationEnabled: false)
            
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
        Ext.debug("complete...", logEnabled: logEnabled, locationEnabled: false)
        handlePayment(transaction, error: nil)
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }

        Ext.debug("restore... \(productIdentifier)", logEnabled: logEnabled, locationEnabled: false)
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func fail(transaction: SKPaymentTransaction) {
        if let txError = transaction.error as? NSError, txError.code == SKError.paymentCancelled.rawValue {
            Ext.debug("transaction cancelled.", error: transaction.error, logEnabled: logEnabled, locationEnabled: false)
            handlePayment(transaction, error: IAPError.paymentCancelled)
        } else {
            Ext.debug("transaction error.", error: transaction.error, logEnabled: logEnabled, locationEnabled: false)
            handlePayment(transaction, error: transaction.error)
        }
        SKPaymentQueue.default().finishTransaction(transaction)
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

// MARK: - Log

extension SKProduct {
    open override var description: String {
    """
    {
        "productIdentifier": \(productIdentifier),
        "price": \(price),
        "priceLocale": \(priceLocale),
        "localizedTitle": \(localizedTitle),
        "localizedDescription": \(localizedDescription),
        "isDownloadable": \(isDownloadable),
        "contentVersion": \(contentVersion),
        "subscriptionPeriod": \(subscriptionPeriod?.description ?? ""),
        "introductoryPrice": \(introductoryPrice?.description ?? ""),
        "subscriptionGroupIdentifier": \(subscriptionGroupIdentifier ?? "")
    }
    """
    }
}
extension SKProductSubscriptionPeriod {
    open override var description: String {
    """
    {
        "numberOfUnits": \(numberOfUnits),
        "unit": \(unit)
    }
    """
    }
}
extension SKProduct.PeriodUnit: CustomStringConvertible {
    public var description: String {
        switch self {
        case .day:      return "day"
        case .week:     return "week"
        case .month:    return "month"
        case .year:     return "year"
        default:        return "unknown"
        }
    }
}

extension SKPaymentTransaction {
    open override var description: String {
    """
    {
        "productIdentifier": \(payment.productIdentifier),
        "transactionIdentifier": \(transactionIdentifier ?? ""),
        "transactionDate": \(transactionDate?.ext.format(type: .yyyyMMdd_HHmmss_SSS) ?? ""),
        "transactionState": \(transactionState)
    }
    """
    }
}
extension SKPaymentTransactionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .purchasing:   return "purchasing..."
        case .purchased:    return "purchased."
        case .failed:       return "failed."
        case .restored:     return "restored."
        case .deferred:     return "deferred."
        default:            return "\(rawValue)"
        }
    }
}
