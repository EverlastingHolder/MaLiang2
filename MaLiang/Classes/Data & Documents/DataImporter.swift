//
//  DataImporter.swift
//  Chrysan
//
//  Created by Harley-xk on 2019/4/23.
//

import Foundation

/// class for import existing data from saved data
open class DataImporter {
    
    
    /// import existing data from saved file
    ///
    /// - Parameters:
    ///   - directory: directory for saved data contents
    ///   - canvas: canvas to draw data on
    /// - Attention: make sure that all brushes needed are finished seting up before reloading data
    public static func importData(
        from directory: URL,
        to canvas: MLCanvas,
        progress: ProgressHandler? = nil
    ) async -> Result<Void, Error>  {
        do {
            try await self.importDataSynchronously(from: directory, to: canvas, progress: progress)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    public static func importDataSynchronously(from directory: URL, to canvas: MLCanvas, progress: ProgressHandler? = nil) async throws {
        let decoder = JSONDecoder()
        
        /// check infomations
        let infoData = try Data(contentsOf: directory.appendingPathComponent("info"))
        let info = try decoder.decode(DocumentInfo.self, from: infoData)
        guard info.library != nil else {
            throw MLError.fileDamaged
        }

        /// read contents
        let contentData = try Data(contentsOf: directory.appendingPathComponent("content"))
        let content = try decoder.decode(CanvasContent.self, from: contentData)

        do {
            /// read chartlet textures
            let texturePaths = try FileManager.default.contentsOfDirectory(
                at: directory.appendingPathComponent("textures"),
                includingPropertiesForKeys: [],
                options: []
            )
            for path in texturePaths {
                let data = try Data(contentsOf: path)
                try await canvas.makeTexture(with: data, id: path.lastPathComponent)
            }
        } catch {
            // no textures found
            if info.chartlets > 0 {
                throw MLError.fileDamaged
            }
        }
        
        /// update content size for scrollable canvas
        if let scrollable = canvas as? ScrollableCanvas, let size = content.size {
            Task { @MainActor in
                scrollable.contentSize = size
            }
        }
        
        let defaultBrush = await canvas.defaultBrush
        
        /// import elements to canvas
        for line in content.lineStrips {
            line.brush = await canvas.findBrushBy(name: line.brushName) ?? defaultBrush
        }
        
        content.chartlets.forEach { $0.canvas = canvas }
        
        let sortedElements: [CanvasElement] = (content.lineStrips + content.chartlets).sorted(by: { $0.index < $1.index })
        await canvas.setDataElemnets(sortedElements)
        /// redraw must be call on main thread
        await canvas.redraw(isLoadingFromData: true)
    }
}
