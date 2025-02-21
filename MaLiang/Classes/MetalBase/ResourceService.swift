import MetalKit

public final class ResourceService {
    public private(set) var textures: [String: MLTexture] = [:]
    
    private lazy var textureLoader = MTKTextureLoader(device: sharedDevice!)
    
    @discardableResult
    public func makeTexture(_ data: Data, id: String, isForce: Bool = false) throws -> MLTexture {
        if let texture = textures[id], !isForce {
            return texture
        }
        let texture = try textureLoader.newTexture(data: data, options: [.SRGB: false])
        let mlTexture = MLTexture(id: id, texture: texture)
        textures[id] = mlTexture
        return mlTexture
    }
    
    public func removeTexture(_ id: String) {
        textures[id] = nil
    }
}

extension ResourceService: ServiceType {
    public static var service: ResourceService {
        if let service: ResourceService = ServiceLocator.service() {
            return service
        }
        
        let service = ResourceService()
        ServiceLocator.addService(service)
        return service
    }
    
    public func clear() {
        textures.removeAll()
    }
    
    public func remove() {
        ServiceLocator.removeService(self)
    }
}
