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
    
    // Float를 추가했는데 이미지 변경??
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
        self.colorSamplerState = makeSamplerState()
        
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
        
//        guard let vertexFunction = defaultLibrary?.makeFunction(name: "vertexPassThroughShader"),
//              let fragmentFunction = defaultLibrary?.makeFunction(name: "fragmentLookupShader") else {
//            return nil
//        }
        
        guard let vertexFunction = defaultLibrary?.makeFunction(name: "vertexPassThrough"),
              let fragmentFunction = defaultLibrary?.makeFunction(name: "colorLookup2DSquare") else {
            return nil
        }

//        guard let vertexFunction = defaultLibrary?.makeFunction(name: "vertexPassThroughShader"),
//              let fragmentFunction = defaultLibrary?.makeFunction(name: "colorLookup2DSquare") else {
//            return nil
//        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .rgba8Unorm
        
        let pipeLineState = try? device.makeRenderPipelineState(descriptor: descriptor)
        return pipeLineState
    }
    
//    private func encodeCommand() {
//        guard let commandEncoder = commandEncoder,
//              let pipelineState = pipelineState else {
//            return
//        }
//
//        commandEncoder.setRenderPipelineState(pipelineState)
//        let vertexDataSize = vertexData.count * MemoryLayout<Float>.size
//        let vertexBuffer = device.makeBuffer(bytes: vertexData,
//                                             length: vertexDataSize,
//                                             options: [])
//
//        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//        commandEncoder.setFragmentTexture(inputTexture, index: 0)
//        commandEncoder.setFragmentTexture(lutTexture, index: 1)
//        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
//        commandEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexData.count / 2)
//        commandEncoder.endEncoding()
//    }

    
    
    private func encodeCommand() {
        guard let commandEncoder = commandEncoder,
              let pipelineState = pipelineState else {
            return
        }

        commandEncoder.setRenderPipelineState(pipelineState)
//        let vertexDataSize = vertexData.count * MemoryLayout<Float>.size
//        let vertexBuffer = device.makeBuffer(bytes: vertexData,
//                                             length: vertexDataSize,
//                                             options: [])
//        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

        
        vertexCoordBuffer = device.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
        textCoordBuffer = device.makeBuffer(bytes: textData, length: textData.count * MemoryLayout<Float>.size, options: [])

        commandEncoder.setVertexBuffer(vertexCoordBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBuffer(textCoordBuffer, offset: 0, index: 1)

        commandEncoder.setFragmentTexture(inputTexture, index: 0)
        commandEncoder.setFragmentTexture(lutTexture, index: 1)

        commandEncoder.setFragmentSamplerState(samplerState, index: 0)
        commandEncoder.setFragmentSamplerState(colorSamplerState, index: 1)


        let dimension: NSNumber = 64
        let intensity: NSNumber = 1
        var dim = dimension.intValue
        var inten = intensity.floatValue

        commandEncoder.setFragmentBytes(&dim, length: MemoryLayout<Int>.stride, index: 0)
        commandEncoder.setFragmentBytes(&inten, length: MemoryLayout<Float>.stride, index: 1)
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
//        descriptor.sAddressMode = .clampToEdge
//        descriptor.tAddressMode = .clampToEdge
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
    
//    - (void)setLutImage:(UIImage *)lutImage{
//    _lutImage = lutImage;
//
//    CGImageRef imageRef = [_lutImage CGImage];
//
//    // Create a suitable bitmap context for extracting the bits of the image
//    NSUInteger width = CGImageGetWidth(imageRef);
//    NSUInteger height = CGImageGetHeight(imageRef);
//    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    uint8_t *rawData = (uint8_t *)calloc(height * width * 4, sizeof(uint8_t));
//    NSUInteger bytesPerPixel = 4;
//    NSUInteger bytesPerRow = bytesPerPixel * width;
//    NSUInteger bitsPerComponent = 8;
//    CGContextRef bitmapContext = CGBitmapContextCreate(rawData, width, height,
//                                                       bitsPerComponent, bytesPerRow, colorSpace,
//                                                       kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
//    CGColorSpaceRelease(colorSpace);
//
//
//    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, width, height), imageRef);
//    CGContextRelease(bitmapContext);
//
//    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
//    [self.lutTexture replaceRegion:region mipmapLevel:0 withBytes:rawData bytesPerRow:bytesPerRow];
//
//    free(rawData);
//    }

//
//    private func setLutImage(_ image: UIImage) {
//        guard let imageRef = image.cgImage else {
//            return
//        }
//        let width = imageRef.width
//        let height = imageRef.height
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let rawData =
//    }
}
