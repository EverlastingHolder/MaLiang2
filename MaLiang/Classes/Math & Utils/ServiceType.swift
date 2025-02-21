//
//  ServiceType.swift
//  MaLiang
//
//  Created by roman.moshkovcev on 21.02.2025.
//  Copyright © 2025 MoveApp. All rights reserved.
//

import Foundation

protocol ServiceType {
    static var service: Self { get }
    
    func clear()
    func remove()
}

protocol ServiceLocatorType {
    func service<T>() -> T?
}

final class ServiceLocator: ServiceLocatorType {
    private static let instance = ServiceLocator()
    
    private lazy var services: [String: Any] = [:]
    
    static func service<T>() -> T? {
        return instance.service()
    }
    
    static func addService<T>(_ service: T) {
        return instance.addService(service)
    }
    
    static func clear() {
        instance.services.removeAll()
    }
    
    static func removeService<T>(_ service: T) {
        instance.removeService(service)
    }
    
    func service<T>() -> T? {
        let key = typeName(T.self)
        return services[key] as? T
    }
    
    private func addService<T>(_ service: T) {
        let key = typeName(T.self)
        services[key] = service
    }
    
    private func removeService<T>(_ service: T) {
        let key = typeName(T.self)
        services.removeValue(forKey: key)
    }
    
    private func typeName(_ some: Any) -> String {
        return (some is Any.Type) ? "\(some)" : "\(type(of: some))"
    }
}
