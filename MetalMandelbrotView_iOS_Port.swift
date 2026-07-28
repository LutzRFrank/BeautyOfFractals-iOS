//
//  MetalMandelbrotView_iOS_Port.swift
//  BeautOfFractals
//
//  Created by Lutz-R. Frank on 16.06.2026.
//

import SwiftUI
import Metal
import MetalKit

#if os(macOS)
typealias PlatformViewRepresentable = NSViewRepresentable
#else
typealias PlatformViewRepresentable = UIViewRepresentable
#endif

struct MetalMandelbrotView: PlatformViewRepresentable {
    let fractalMode: FractalMode
    let fractalPalette: FractalPalette
    let centerX: Double
    let centerY: Double
    let scale: Double
    let maxIterations: Int
    let colorNormalizationIterations: Int? = nil
    let plateauTiltDegrees: Double
    let doodadsStructure: Double
    let doodadsComplexity: Double
    let doodadsCurl: Double
    let viewportAspectRatio: Double?
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    #if os(macOS)
    func makeNSView(context: Context) -> MTKView {
        makeMetalView(context: context)
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        updateMetalView(nsView, context: context)
    }
#else
    func makeUIView(context: Context) -> MTKView {
        makeMetalView(context: context)
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        updateMetalView(uiView, context: context)
    }
#endif
    
    private func makeMetalView(context: Context) -> MTKView {
        let mtkView = MTKView()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            return mtkView
        }
        
        mtkView.device = device
        mtkView.delegate = context.coordinator
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.framebufferOnly = true
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = true
        mtkView.preferredFramesPerSecond = 60
        
        context.coordinator.setup(
            device: device,
            pixelFormat: mtkView.colorPixelFormat
        )
        
        return mtkView
    }
    
    private func updateMetalView(_ nsView: MTKView, context: Context) {
        context.coordinator.fractalMode = UInt32(fractalMode.rawValue)
        context.coordinator.fractalPalette = UInt32(fractalPalette.rawValue)
        context.coordinator.centerX = Float(centerX)
        context.coordinator.centerY = Float(centerY)
        context.coordinator.scale = Float(scale)
        context.coordinator.maxIterations = UInt32(maxIterations)
        context.coordinator.colorNormalizationIterations = colorNormalizationIterations.map {
            UInt32(clamping: $0)
        } ?? 0
        context.coordinator.plateauTiltDegrees = Float(plateauTiltDegrees)
        context.coordinator.doodadsStructure = Float(doodadsStructure)
        context.coordinator.doodadsComplexity = Float(doodadsComplexity)
        context.coordinator.doodadsCurl = Float(doodadsCurl)
        context.coordinator.viewportAspectRatio = viewportAspectRatio.map(Float.init)
        
        nsView.setNeedsDisplay(nsView.bounds)
    }
    
    final class Coordinator: NSObject, MTKViewDelegate {
        var device: MTLDevice?
        var commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?
        var plateauSourcePipelineState: MTLRenderPipelineState?
        var plateauCompositePipelineState: MTLRenderPipelineState?
        var plateauSourceTexture: MTLTexture?
        
        var fractalMode: UInt32 = 0
        var fractalPalette: UInt32 = 0
        var centerX: Float = -0.5
        var centerY: Float = 0.0
        var scale: Float = 3.0
        var maxIterations: UInt32 = 300
        var colorNormalizationIterations: UInt32 = 0
        var viewportAspectRatio: Float?
        var plateauTiltDegrees: Float = 82.0
        var doodadsStructure: Float = 0.33
        var doodadsComplexity: Float = 0.50
        var doodadsCurl: Float = 0.50
        
        struct Uniforms {
            var centerX: Float
            var centerY: Float
            var scale: Float
            var maxIterations: UInt32
            var colorNormalizationIterations: UInt32
            var aspectRatio: Float
            var fractalMode: UInt32
            var fractalPalette: UInt32
            var plateauTiltDegrees: Float
            var doodadsStructure: Float
            var doodadsComplexity: Float
            var doodadsCurl: Float
        }
        
        func setup(device: MTLDevice, pixelFormat: MTLPixelFormat) {
            self.device = device
            self.commandQueue = device.makeCommandQueue()
            
            guard let library = device.makeDefaultLibrary() else {
                print("Metal: Default Library nicht gefunden")
                return
            }
            
            guard let vertexFunction = library.makeFunction(name: "fullscreen_vertex"),
                  let fragmentFunction = library.makeFunction(name: "fractal_fragment"),
                  let plateauSourceFunction = library.makeFunction(name: "plateau_source_fragment"),
                  let plateauCompositeFunction = library.makeFunction(name: "plateau_composite_fragment") else {
                print("Metal: Shader-Funktionen nicht gefunden")
                return
            }
            
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunction
            descriptor.fragmentFunction = fragmentFunction
            descriptor.colorAttachments[0].pixelFormat = pixelFormat
            
            do {
                self.pipelineState = try device.makeRenderPipelineState(descriptor: descriptor)
                descriptor.fragmentFunction = plateauSourceFunction
                self.plateauSourcePipelineState = try device.makeRenderPipelineState(
                    descriptor: descriptor
                )
                descriptor.fragmentFunction = plateauCompositeFunction
                self.plateauCompositePipelineState = try device.makeRenderPipelineState(
                    descriptor: descriptor
                )
            } catch {
                print("Metal Pipeline Fehler:", error)
            }
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            view.setNeedsDisplay(view.bounds)
        }
        
        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let commandQueue = commandQueue,
                  let pipelineState = pipelineState else {
                return
            }
            
            let width = max(Float(view.drawableSize.width), 1.0)
            let height = max(Float(view.drawableSize.height), 1.0)
            let aspectRatio = viewportAspectRatio ?? (width / height)
            
            var uniforms = Uniforms(
                centerX: centerX,
                centerY: centerY,
                scale: scale,
                maxIterations: maxIterations,
                colorNormalizationIterations: colorNormalizationIterations,
                aspectRatio: aspectRatio,
                fractalMode: fractalMode,
                fractalPalette: fractalPalette,
                plateauTiltDegrees: plateauTiltDegrees,
                doodadsStructure: doodadsStructure,
                doodadsComplexity: doodadsComplexity,
                doodadsCurl: doodadsCurl
            )
            
            guard let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
            }

            if fractalMode == UInt32(FractalMode.mandelbrotPlateau.rawValue),
               let sourcePipeline = plateauSourcePipelineState,
               let compositePipeline = plateauCompositePipelineState {
                let textureWidth = max(Int(view.drawableSize.width), 1)
                let textureHeight = max(Int(view.drawableSize.height), 1)
                if plateauSourceTexture?.width != textureWidth
                    || plateauSourceTexture?.height != textureHeight {
                    let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                        pixelFormat: view.colorPixelFormat,
                        width: textureWidth,
                        height: textureHeight,
                        mipmapped: false
                    )
                    textureDescriptor.usage = [.renderTarget, .shaderRead]
                    textureDescriptor.storageMode = .private
                    plateauSourceTexture = device?.makeTexture(
                        descriptor: textureDescriptor
                    )
                }

                if let sourceTexture = plateauSourceTexture {
                    let sourcePass = MTLRenderPassDescriptor()
                    sourcePass.colorAttachments[0].texture = sourceTexture
                    sourcePass.colorAttachments[0].loadAction = .clear
                    sourcePass.colorAttachments[0].storeAction = .store
                    sourcePass.colorAttachments[0].clearColor = MTLClearColorMake(
                        0,
                        0,
                        0,
                        0
                    )

                    if let sourceEncoder = commandBuffer.makeRenderCommandEncoder(
                        descriptor: sourcePass
                    ) {
                        sourceEncoder.setRenderPipelineState(sourcePipeline)
                        sourceEncoder.setFragmentBytes(
                            &uniforms,
                            length: MemoryLayout<Uniforms>.stride,
                            index: 0
                        )
                        sourceEncoder.drawPrimitives(
                            type: .triangle,
                            vertexStart: 0,
                            vertexCount: 3
                        )
                        sourceEncoder.endEncoding()
                    }

                    if let compositeEncoder = commandBuffer.makeRenderCommandEncoder(
                        descriptor: descriptor
                    ) {
                        compositeEncoder.setRenderPipelineState(compositePipeline)
                        compositeEncoder.setFragmentBytes(
                            &uniforms,
                            length: MemoryLayout<Uniforms>.stride,
                            index: 0
                        )
                        compositeEncoder.setFragmentTexture(sourceTexture, index: 0)
                        compositeEncoder.drawPrimitives(
                            type: .triangle,
                            vertexStart: 0,
                            vertexCount: 3
                        )
                        compositeEncoder.endEncoding()
                    }
                }
            } else if let encoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: descriptor
            ) {
                encoder.setRenderPipelineState(pipelineState)
                encoder.setFragmentBytes(
                    &uniforms,
                    length: MemoryLayout<Uniforms>.stride,
                    index: 0
                )
                encoder.drawPrimitives(
                    type: .triangle,
                    vertexStart: 0,
                    vertexCount: 3
                )
                encoder.endEncoding()
            }

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
