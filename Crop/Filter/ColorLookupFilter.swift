//
//  MetalImageFilter.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/26.
//

import UIKit
import Metal
import MetalKit

enum Lookup: String, CaseIterable {
    case ab1
    case ab2
    case ab3
    case ab4
    case ab5
    case ab6
    case ab7
    case ab8
    case ab9
    case ab10
    case ab11
}

class ColorLookupFilter {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let inputImage: UIImage
    
    var commandEncoder: MTLRenderCommandEncoder?
    var pipelineState: MTLRenderPipelineState?
    var commandBuffer: MTLCommandBuffer?
    
    var inputTexture: MTLTexture?
    var outputTexture: MTLTexture?
    var lutTexture: MTLTexture?

    var samplerState: MTLSamplerState?
    var colorSamplerState: MTLSamplerState?

    private var vertexCoordBuffer: MTLBuffer!
    private var textCoordBuffer: MTLBuffer!
    
    let vertexData: [Float] = [
        -1, -1, 0.0, 1.0,
        1, -1, 0.0, 1.0,
        -1, 1, 0.0, 1.0,
        1, 1, 0.0, 1.0
    ]
    
    let textData: [Float] = [
        0.0, 0.0,
        1.0, 0.0,
        0.0, 1.0,
        1.0, 1.0
    ]
    
    init(image: UIImage) {
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()!
        inputImage = image
    }
    
    func prepare(with lookUp: Lookup) {
        self.inputTexture = makeInputTexture()
        self.outputTexture = makeOutputTexture()
        self.lutTexture = makeLUTTexture(lookUp: lookUp)
        self.samplerState = makeSamplerState()
        self.colorSamplerState = makeColorSamplerState()
        
        self.pipelineState = makePipelineState()
        self.commandBuffer = self.commandQueue.makeCommandBuffer()
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = outputTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 0, green: 0, blue: 0, alpha: 1)
        
        self.commandEncoder = self.commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    }
    
    func applyFiler(with lookup: Lookup) -> UIImage? {
        prepare(with: lookup)
        encodeCommand()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        if let outputTexture = outputTexture {
            let image = makeOutputImage(from: outputTexture)
            return image
        } else {
            return nil
        }
    }
    
    private func makePipelineState() -> MTLRenderPipelineState? {
        let defaultLibrary = device.makeDefaultLibrary()
        guard let vertexFunction = defaultLibrary?.makeFunction(name: "vertexPassThrough"),
              let fragmentFunction = defaultLibrary?.makeFunction(name: "colorLookup2DSquare") else {
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
        
        let pipeLineState = try? device.makeRenderPipelineState(descriptor: descriptor)
        return pipeLineState
    }
    
    private func encodeCommand() {
        guard let commandEncoder = commandEncoder,
              let pipelineState = pipelineState else {
            return
        }

        commandEncoder.setRenderPipelineState(pipelineState)
        vertexCoordBuffer = device.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
        textCoordBuffer = device.makeBuffer(bytes: textData, length: textData.count * MemoryLayout<Float>.size, options: [])

        commandEncoder.setVertexBuffer(vertexCoordBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(textCoordBuffer, offset: 0, index: 1)

        commandEncoder.setFragmentTexture(inputTexture, index: 0)
        commandEncoder.setFragmentTexture(lutTexture, index: 1)

        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        commandEncoder.setFragmentSamplerState(colorSamplerState, index: 1)


        var dimension: Int = 64
        var intensity: Float = 1

        commandEncoder.setFragmentBytes(&dimension, length: MemoryLayout<Int>.stride, index: 0)
        commandEncoder.setFragmentBytes(&intensity, length: MemoryLayout<Float>.stride, index: 1)
        commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        commandEncoder.endEncoding()
    }

    private func makeSamplerState() -> MTLSamplerState {
        let descriptor = MTLSamplerDescriptor()
        descriptor.sAddressMode = .clampToEdge
        descriptor.tAddressMode = .clampToEdge
        descriptor.magFilter = .linear
        descriptor.minFilter = .linear
        return device.makeSamplerState(descriptor: descriptor)!
    }
    
    private func makeColorSamplerState() -> MTLSamplerState {
        let descriptor = MTLSamplerDescriptor()
        descriptor.sAddressMode = .clampToZero
        descriptor.tAddressMode = .clampToZero

        descriptor.magFilter = .linear
        descriptor.minFilter = .linear
        
        return device.makeSamplerState(descriptor: descriptor)!
    }


    private func makeLUTTexture(lookUp: Lookup) -> MTLTexture? {
        let lutImage = UIImage(named: lookUp.rawValue)
        guard let cgImage = lutImage?.cgImage else {
            return nil
        }

        let textureLoader = MTKTextureLoader(device: self.device)
        let texture = try? textureLoader.newTexture(cgImage: cgImage, options: nil)
        return texture
    }
    
    private func makeInputTexture() -> MTLTexture? {
        guard let cgImage = inputImage.cgImage else {
            return nil
        }
        
        let textureLoader = MTKTextureLoader(device: self.device)
        let texture = try? textureLoader.newTexture(cgImage: cgImage, options: [.SRGB: false])
        return texture
    }

    private func makeOutputTexture() -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: Int(inputImage.size.width),
            height: Int(inputImage.size.height),
            mipmapped: false
        )
        textureDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
        let texture = device.makeTexture(descriptor: textureDescriptor)
        return texture
    }

    private func makeOutputImage(from texture: MTLTexture) -> UIImage? {
        guard let ciImage = CIImage(mtlTexture: texture, options: nil) else {
            return nil
        }
        return UIImage(ciImage: ciImage)
    }
}
