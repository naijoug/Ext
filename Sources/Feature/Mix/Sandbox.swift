//
//  Sandbox.swift
//  Ext
//
//  Created by guojian on 2021/11/30.
//

import Foundation

/// 沙盒
public final class Sandbox {}

public extension Sandbox {
    
    /// 沙盒目录种类
    enum Directory {
        case documents
        case library
        case tmp
    }
    
    /// 沙盒目录 URL
    static func url(_ directory: Directory) -> URL? {
        switch directory {
        case .documents:
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        case .library:
            return FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first
        case .tmp:
            return FileManager.default.temporaryDirectory
        }
    }
    
    /// 沙盒路径
    static var path: String { url(.library)?.deletingLastPathComponent().path ?? "" }
}

public extension Sandbox {
    
    /// 注入沙盒入口
    /// - Parameters:
    ///   - view: 注入视图
    ///   - numberOfTaps: 点击次数 (默认: 5)
    static func inject(_ view: UIView?, numberOfTaps: Int = 5) {
        guard let view = view else { return }
        
        view.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        tapGesture.numberOfTapsRequired = numberOfTaps
        view.addGestureRecognizer(tapGesture)
    }
    @objc
    private static func tap(_ gesture: UITapGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        Router.shared.goto(FileController(), mode: .modal(wrapped: true, fullScreen: false, animated: true))
    }
    
}

// MARK: - File

/**
 Reference:
    - https://github.com/music4kid/AirSandbox
 */

private class FileController: UITableViewController {
    
    /// 根路径
    private static let rootPath = NSHomeDirectory()
    
    /// 路径
    private var path: String = FileController.rootPath
    
    /// item 列表
    private var items = [FileItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeAction))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(closeAction))
        }
        navigationItem.title = (path == FileController.rootPath) ? "Sandbox" : (path as NSString).lastPathComponent
        
        tableView.ext.registerClass(FileCell.self)
        
        loadData(path)
    }
    
    @objc
    private func closeAction() {
        dismiss(animated: true, completion: nil)
    }
}

extension FileController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.ext.dequeueReusableCell(FileCell.self, for: indexPath)
        cell.bind(items[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let item = items[indexPath.row]
        switch item.type {
        case .file:
            self.shareFile(item.path)
        case .folder:
            let vc = FileController()
            vc.path = item.path
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}

private extension FileController {
    
    /// 加载路径数据
    func loadData(_ path: String) {
        let logEnabled = false
        Ext.debug("load path: \(path) | root path: \(FileController.rootPath)", logEnabled: logEnabled)
        
        var items = [FileItem]()
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            Ext.debug(contents, logEnabled: logEnabled)
            for content in contents {
                guard !(content as NSString).lastPathComponent.hasPrefix(".") else { continue }
                
                let url = URL(fileURLWithPath: path).appendingPathComponent(content)
                
                Ext.debug("fullPath: \(url.path)", logEnabled: logEnabled)
                var isFolder: ObjCBool = false
                guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isFolder) else { continue }
                
                Ext.debug("isFolder: \(isFolder)", logEnabled: logEnabled)
                items.append(FileItem(type: isFolder.boolValue ? .folder : .file, name: content, path: url.path))
            }
        } catch {
            Ext.debug("load directory content error.", error: error, logEnabled: logEnabled)
        }
        
        Ext.debug("items: \(items)", logEnabled: logEnabled)
        self.items = items
        self.tableView.reloadData()
    }
    
    /// 分享文件
    func shareFile(_ filePath: String) {
        Router.shared.toSystemShare([URL(fileURLWithPath: filePath)])
    }
}

// MARK: - Cell

private struct FileItem {
    enum ItemType: String {
        case file       = "📃"
        case folder     = "📂"
    }
    
    var type: ItemType
    var name: String
    var path: String
}
private extension FileItem {
    var title: String { "\(type.rawValue) \(name)" }
}

private class FileCell: UITableViewCell {
    
    private var titleLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupUI()
    }
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setupUI() {
        titleLabel  = contentView.ext.addLabel(font: UIFont.boldSystemFont(ofSize: 17), color: .darkGray, multiline: true)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    func bind(_ item: FileItem) {
        titleLabel.text = item.title
        switch item.type {
        case .file:
            titleLabel.font = UIFont.systemFont(ofSize: 17)
        case .folder:
            titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        }
    }
    
}
