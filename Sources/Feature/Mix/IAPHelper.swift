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

public class IAPHelper: NSObject, ExtLogable {
    public var logEnabled: Bool = true
    
    public override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
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
            guard let self else { return }
            switch result {
            case .failure(let error): handler(.failure(error))
            case .success(let tx):
                guard tx.payment.productIdentifier == product.productIdentifier else {
                    handler(.failure(IAPError.paymentProductNotMatch))
                    return
                }
                guard let receiptUrl = Bundle.main.appStoreReceiptURL,
                      FileManager.default.fileExists(atPath: receiptUrl.path),
                      let receipt = try? Data(contentsOf: receiptUrl, options: .alwaysMapped).base64EncodedString(options: []) else {
                    self.ext.log("transaction \(product.productIdentifier) no receipt")
                    handler(.failure(IAPError.paymentNoReceipt))
                    return
                }
                self.ext.log("appstore receipt url: \(receiptUrl.path)")
                handler(.success((tx, receipt)))
            }
        }
    }
    /// 恢复产品
    func restore() {
        _resotre()
    }
}

private extension IAPHelper {
    
    /// 请求产品列表
    func _loadProducts(productIdentifiers: Set<String>, handler: @escaping ProductsHandler) {
        guard !productIdentifiers.isEmpty else {
            handleProducts(nil, error: IAPError.productIdEmpty)
            return
        }
        ext.log("load products: \(productIdentifiers)")
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
        ext.log("buy product \(product.productIdentifier) ...")
        paymentHandler = handler
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }
    
    /// 恢复产品
    func _resotre() {
        ext.log("restore product...")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

// MARK: - SKProductsRequestDelegate

extension IAPHelper: SKProductsRequestDelegate {

    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        ext.log("load products success: \(response.products)")
        let products = response.products
        handleProducts(products, error: nil)
    }
    
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        ext.log("load products failed.", error: error)
        handleProducts(nil, error: error)
    }
    
    private func handleProducts(_ products: [SKProduct]?, error: Error?) {
        DispatchQueue.main.async {
            if let error = error  {
                self.productsHandler?(.failure(error))
            } else {
                self.productsHandler?(.success(products ?? []))
            }
            self.productsHandler = nil
            self.productsRequest = nil
        }
    }
}

// MARK: - SKPaymentTransactionObserver

extension IAPHelper: SKPaymentTransactionObserver {
    
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            ext.log("updated transaction: \(transaction)")
            
            switch transaction.transactionState {
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
    public func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            ext.log("removed transaction: \(transaction)")
        }
    }
    

    private func complete(transaction: SKPaymentTransaction) {
        ext.log("complete... \(transaction.payment.productIdentifier)")
        handlePayment(transaction, error: nil)
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func restore(transaction: SKPaymentTransaction) {
        ext.log("restore... \(transaction.payment.productIdentifier)")
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func fail(transaction: SKPaymentTransaction) {
        if let txError = transaction.error as? NSError, txError.code == SKError.paymentCancelled.rawValue {
            ext.log("transaction cancelled.", error: transaction.error)
            handlePayment(transaction, error: IAPError.paymentCancelled)
        } else {
            ext.log("transaction error.", error: transaction.error)
            handlePayment(transaction, error: transaction.error)
        }
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func handlePayment(_ transaction: SKPaymentTransaction, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                self.paymentHandler?(.failure(error))
            } else {
                self.paymentHandler?(.success(transaction))
            }
            self.paymentHandler = nil
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
