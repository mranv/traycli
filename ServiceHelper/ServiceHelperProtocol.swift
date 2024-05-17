// ServiceHelperProtocol.swift
import Foundation

@objc protocol ServiceHelperProtocol {
    func getMenuItemData(with reply: @escaping ([String: Any]) -> Void)
}
