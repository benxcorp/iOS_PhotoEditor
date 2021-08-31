//
//  ColorMetalRenderer.swift
//  ImageCropSample
//
//  Created by iron on 2021/08/26.
//

import Metal
import CoreMedia
import CoreVideo

class ColorMetalRenderer {
    private let metalDevice = MTLCreateSystemDefaultDevice()
    private var computePipelineState: MTLComputePipelineState?

    private var outputPixelBufferPool: CVPixelBufferPool?
    private var textureCache: CVMetalTextureCache?

    private var inputFormatDescription: CMFormatDescription?
    private var outputFormatDescription: CMFormatDescription?

    var isPrepared = false

    private lazy var commandQueue: MTLCommandQueue? = {
        return metalDevice?.makeCommandQueue()
    }()

    required init() {
        guard let defaultLibrary = metalDevice?.makeDefaultLibrary(),
              let kernelFunction = defaultLibrary.makeFunction(name: "rosyEffect") else {
            return
        }
                
        do {
            computePipelineState = try metalDevice?.makeComputePipelineState(function: kernelFunction)
        } catch {
            print("\(error)")
        }
    }
    
//    func prepare(with formatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) {
//        reset()
//
//        (outputPixelBufferPool, _, outputFormatDescription) = allocateOutputBufferPool(with: formatDescription,
//                                                                                       outputRetainedBufferCountHint: outputRetainedBufferCountHint)
//        if outputPixelBufferPool == nil {
//            return
//        }
//        inputFormatDescription = formatDescription
//
//        var metalTextureCache: CVMetalTextureCache?
//        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice, nil, &metalTextureCache) != kCVReturnSuccess {
//            assertionFailure("Unable to allocate texture cache")
//        } else {
//            textureCache = metalTextureCache
//        }
//
//        isPrepared = true
//    }

    
    func prepare(with formatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) {
        defer {
            isPrepared = true
        }
        reset()
        
        (outputPixelBufferPool, _, outputFormatDescription) = allocateOutputBufferPool(with: formatDescription,
                                                                                       outputRetainedBufferCountHint: outputRetainedBufferCountHint)
        if outputPixelBufferPool == nil {
            return
        }
        inputFormatDescription = formatDescription
        
        var metalTextureCache: CVMetalTextureCache?
        if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, metalDevice!, nil, &metalTextureCache) != kCVReturnSuccess {
            assertionFailure("Unable to allocate texture cache")
        } else {
            textureCache = metalTextureCache
        }
    }
    
    func reset() {
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        textureCache = nil
        isPrepared = false
    }

    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard isPrepared,
              let outputPixelBufferPool = outputPixelBufferPool else {
            return nil
        }
        
        var newPixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool, &newPixelBuffer)
        guard let outputPixelBuffer = newPixelBuffer else {
            print("Fail get pixel buffer from pool")
            return nil
        }
        
        guard let inputTexture = makeTextureFromCVPixelBuffer(pixelBuffer, textureFormat: .bgra8Unorm),
              let outputTexture = makeTextureFromCVPixelBuffer(outputPixelBuffer, textureFormat: .bgra8Unorm) else {
                return nil
        }
        
        // Set up command queue, buffer, and encoder.
        guard let commandQueue = commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            print("Failed to create a Metal command queue.")
            CVMetalTextureCacheFlush(textureCache!, 0)
            return nil
        }
        
        commandEncoder.label = "Rosy Metal"
        commandEncoder.setComputePipelineState(computePipelineState!)
        commandEncoder.setTexture(inputTexture, index: 0)
        commandEncoder.setTexture(outputTexture, index: 1)

        // Set up the thread groups.
        let width = computePipelineState!.threadExecutionWidth
        let height = computePipelineState!.maxTotalThreadsPerThreadgroup / width
        let threadsPerThreadgroup = MTLSizeMake(width, height, 1)
        let threadgroupsPerGrid = MTLSize(width: (inputTexture.width + width - 1) / width,
                                          height: (inputTexture.height + height - 1) / height,
                                          depth: 1)
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        return newPixelBuffer
    }
    
    func makeTextureFromCVPixelBuffer(_ pixelBuffer: CVPixelBuffer, textureFormat: MTLPixelFormat) -> MTLTexture? {
        guard let textureCache = textureCache else {
            return nil
        }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // Create a Metal texture from the image buffer.
        var cvTextureOut: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, nil, textureFormat, width, height, 0, &cvTextureOut)
        
        guard let cvTexture = cvTextureOut, let texture = CVMetalTextureGetTexture(cvTexture) else {
            CVMetalTextureCacheFlush(textureCache, 0)
            return nil
        }
        
        return texture
    }
    
}

extension ColorMetalRenderer {
    func allocateOutputBufferPool(with inputFormatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) ->(
        outputBufferPool: CVPixelBufferPool?,
        outputColorSpace: CGColorSpace?,
        outputFormatDescription: CMFormatDescription?) {
            
            let inputMediaSubType = CMFormatDescriptionGetMediaSubType(inputFormatDescription)
            if inputMediaSubType != kCVPixelFormatType_32BGRA {
                assertionFailure("Invalid input pixel buffer type \(inputMediaSubType)")
                return (nil, nil, nil)
            }
            
            let inputDimensions = CMVideoFormatDescriptionGetDimensions(inputFormatDescription)
            var pixelBufferAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: UInt(inputMediaSubType),
                kCVPixelBufferWidthKey as String: Int(inputDimensions.width),
                kCVPixelBufferHeightKey as String: Int(inputDimensions.height),
                kCVPixelBufferIOSurfacePropertiesKey as String: [:]
            ]
            
            // Get pixel buffer attributes and color space from the input format description.
            var cgColorSpace = CGColorSpaceCreateDeviceRGB()
            if let inputFormatDescriptionExtension = CMFormatDescriptionGetExtensions(inputFormatDescription) as Dictionary? {
                let colorPrimaries = inputFormatDescriptionExtension[kCVImageBufferColorPrimariesKey]
                
                if let colorPrimaries = colorPrimaries {
                    var colorSpaceProperties: [String: AnyObject] = [kCVImageBufferColorPrimariesKey as String: colorPrimaries]
                    
                    if let yCbCrMatrix = inputFormatDescriptionExtension[kCVImageBufferYCbCrMatrixKey] {
                        colorSpaceProperties[kCVImageBufferYCbCrMatrixKey as String] = yCbCrMatrix
                    }
                    
                    if let transferFunction = inputFormatDescriptionExtension[kCVImageBufferTransferFunctionKey] {
                        colorSpaceProperties[kCVImageBufferTransferFunctionKey as String] = transferFunction
                    }
                    
                    pixelBufferAttributes[kCVBufferPropagatedAttachmentsKey as String] = colorSpaceProperties
                }
                
                if let cvColorspace = inputFormatDescriptionExtension[kCVImageBufferCGColorSpaceKey] {
                    cgColorSpace = cvColorspace as! CGColorSpace
                } else if (colorPrimaries as? String) == (kCVImageBufferColorPrimaries_P3_D65 as String) {
                    cgColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
                }
            }
            
            // Create a pixel buffer pool with the same pixel attributes as the input format description.
            let poolAttributes = [kCVPixelBufferPoolMinimumBufferCountKey as String: outputRetainedBufferCountHint]
            var cvPixelBufferPool: CVPixelBufferPool?
            CVPixelBufferPoolCreate(kCFAllocatorDefault, poolAttributes as NSDictionary?, pixelBufferAttributes as NSDictionary?, &cvPixelBufferPool)
            guard let pixelBufferPool = cvPixelBufferPool else {
                assertionFailure("Allocation failure: Could not allocate pixel buffer pool.")
                return (nil, nil, nil)
            }
            
            preallocateBuffers(pool: pixelBufferPool, allocationThreshold: outputRetainedBufferCountHint)
            
            // Get the output format description.
            var pixelBuffer: CVPixelBuffer?
            var outputFormatDescription: CMFormatDescription?
            let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: outputRetainedBufferCountHint] as NSDictionary
            CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pixelBufferPool, auxAttributes, &pixelBuffer)
            if let pixelBuffer = pixelBuffer {
                CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault,
                                                             imageBuffer: pixelBuffer,
                                                             formatDescriptionOut: &outputFormatDescription)
            }
            pixelBuffer = nil
            
            return (pixelBufferPool, cgColorSpace, outputFormatDescription)
    }

    /// - Tag: AllocateRenderBuffers
    private func preallocateBuffers(pool: CVPixelBufferPool, allocationThreshold: Int) {
        var pixelBuffers = [CVPixelBuffer]()
        var error: CVReturn = kCVReturnSuccess
        let auxAttributes = [kCVPixelBufferPoolAllocationThresholdKey as String: allocationThreshold] as NSDictionary
        var pixelBuffer: CVPixelBuffer?
        while error == kCVReturnSuccess {
            error = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer)
            if let pixelBuffer = pixelBuffer {
                pixelBuffers.append(pixelBuffer)
            }
            pixelBuffer = nil
        }
        pixelBuffers.removeAll()
    }

}
