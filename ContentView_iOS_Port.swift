//
//  ContentView_iOS_Port.swift
//  BeautOfFractals
//
//  Created by Lutz-R. Frank on 16.06.2026.
//

import SwiftUI
import CoreGraphics
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#else
import UIKit
#endif
import simd

private let highPrecisionScaleLimit: Double = 0.006
private let highPrecisionPreviewMaxPixelWidth: Int = 1800
private let highPrecisionPreviewMaxPixelHeight: Int = 1200

enum FractalMode: Int, CaseIterable, Identifiable {
    case mandelbrot = 0
    case julia = 1
    case burningShip = 2
    case tricorn = 3
    case kleinian = 4
    case mandelbulb3D = 5
    case mandelbrotRelief = 6
    case mandelbox3D = 7
    case newton = 8
    
    var id: Int {
        rawValue
    }
    
    var displayName: String {
        switch self {
        case .mandelbrot:
            return "Mandelbrot"
        case .julia:
            return "Julia"
        case .burningShip:
            return "Burning Ship"
        case .tricorn:
            return "Tricorn"
        case .kleinian:
            return "Kleinian Relief"
        case .mandelbulb3D:
            return "Mandelbulb 3D"
        case .mandelbrotRelief:
            return "Mandelbrot Relief"
        case .mandelbox3D:
            return "Mandelbox 3D"
        case .newton:
            return "Newton Fractal"
        }
    }
    
    var shortName: String {
        switch self {
        case .mandelbrot:
            return "Mandelbrot"
        case .julia:
            return "Julia"
        case .burningShip:
            return "Burning"
        case .tricorn:
            return "Tricorn"
        case .kleinian:
            return "Kleinian"
        case .mandelbulb3D:
            return "Mandelbulb"
        case .mandelbrotRelief:
            return "Relief"
        case .mandelbox3D:
            return "Mandelbox"
        case .newton:
            return "Newton"
        }
    }
    
    var fileName: String {
        switch self {
        case .mandelbrot:
            return "Mandelbrot"
        case .julia:
            return "Julia"
        case .burningShip:
            return "BurningShip"
        case .tricorn:
            return "Tricorn"
        case .kleinian:
            return "KleinianRelief"
        case .mandelbulb3D:
            return "Mandelbulb3D"
        case .mandelbrotRelief:
            return "MandelbrotRelief"
        case .mandelbox3D:
            return "Mandelbox3D"
        case .newton:
            return "Newton"
        }
    }
    
    var defaultCenterX: Double {
        switch self {
        case .mandelbrot:
            return -0.5
        case .julia:
            return 0.0
        case .burningShip:
            return -0.5
        case .tricorn:
            return 0.0
        case .kleinian:
            return 0.0
        case .mandelbulb3D:
            return 0.0
        case .mandelbrotRelief:
            return -0.5
        case .mandelbox3D:
            return 0.0
        case .newton:
            return 0.0
        }
    }
    
    var defaultCenterY: Double {
        switch self {
        case .mandelbrot:
            return 0.0
        case .julia:
            return 0.0
        case .burningShip:
            return -0.5
        case .tricorn:
            return 0.0
        case .kleinian:
            return 0.0
        case .mandelbulb3D:
            return 0.0
        case .mandelbrotRelief:
            return 0.0
        case .mandelbox3D:
            return 0.0
        case .newton:
            return 0.0
        }
    }
    
    var defaultScale: Double {
        switch self {
        case .mandelbrot:
            return 3.0
        case .julia:
            return 3.0
        case .burningShip:
            return 3.2
        case .tricorn:
            return 3.2
        case .kleinian:
            return 3.0
        case .mandelbulb3D:
            return 2.8
        case .mandelbrotRelief:
            return 3.0
        case .mandelbox3D:
            return 2.8
        case .newton:
            return 3.2
        }
    }
    
    var supportsHighPrecisionPreview: Bool {
        switch self {
        case .mandelbrot, .mandelbrotRelief, .julia, .burningShip, .tricorn, .kleinian, .newton:
            return true
        case .mandelbulb3D, .mandelbox3D:
            return false
        }
    }
}

enum FractalPalette: Int, CaseIterable, Identifiable {
    case ocean = 0
    case electric = 1
    case fire = 2
    case ice = 3
    case gold = 4
    case violet = 5
    case deepBlue = 6
    case solarCoral = 7
    case infernoCoral = 8
    case solarPop = 9
    
    var id: Int {
        rawValue
    }
    
    var displayName: String {
        switch self {
        case .ocean:
            return "Ocean"
        case .electric:
            return "Electric"
        case .fire:
            return "Fire"
        case .ice:
            return "Ice"
        case .gold:
            return "Gold"
        case .violet:
            return "Violet"
        case .deepBlue:
            return "Deep Blue"
        case .solarCoral:
            return "Solar Coral"
        case .infernoCoral:
            return "Inferno Coral"
        case .solarPop:
            return "Solar Pop"
        }
    }
    
    var fileName: String {
        switch self {
        case .ocean:
            return "Ocean"
        case .electric:
            return "Electric"
        case .fire:
            return "Fire"
        case .ice:
            return "Ice"
        case .gold:
            return "Gold"
        case .violet:
            return "Violet"
        case .deepBlue:
            return "DeepBlue"
        case .solarCoral:
            return "SolarCoral"
        case .infernoCoral:
            return "InfernoCoral"
        case .solarPop:
            return "SolarPop"
        }
    }
}

enum RenderQuality: String, CaseIterable, Identifiable {
    case fast = "Fast"
    case high = "High"
    case deep = "Deep"
    
    var id: String { rawValue }
    
    var iterationMultiplier: Double {
        switch self {
        case .fast:
            return 1.0
        case .high:
            return 1.6
        case .deep:
            return 2.5
        }
    }
}

private func effectiveIterationCount(
    baseIterations: Int,
    renderQuality: RenderQuality,
    scale: Double,
    defaultScale: Double,
    cap: Int = 80_000
) -> Int {
    let zoomLevel = defaultScale / max(scale, 0.000000000000000001)
    let zoomBoost: Double
    
    if zoomLevel > 100_000_000 {
        zoomBoost = 1.6
    } else if zoomLevel > 10_000_000 {
        zoomBoost = 1.35
    } else if zoomLevel > 1_000_000 {
        zoomBoost = 1.2
    } else {
        zoomBoost = 1.0
    }
    
    let value = Double(baseIterations) * renderQuality.iterationMultiplier * zoomBoost
    return min(max(Int(value.rounded()), 300), cap)
}

struct ContentView: View {
    @State private var fractalMode: FractalMode = .mandelbrot
    @State private var fractalPalette: FractalPalette = .ocean
    @State private var renderQuality: RenderQuality = .high
    
    @State private var centerX: Double = FractalMode.mandelbrot.defaultCenterX
    @State private var centerY: Double = FractalMode.mandelbrot.defaultCenterY
    @State private var scale: Double = FractalMode.mandelbrot.defaultScale
    
    @State private var maxIterations: Int = 300
    @State private var isSavingSnapshot: Bool = false
    @State private var showHelp: Bool = false
    #if os(iOS)
    @State private var exportURL: URL?
    #endif
    
    private var effectiveIterations: Int {
        effectiveIterationCount(
            baseIterations: maxIterations,
            renderQuality: renderQuality,
            scale: scale,
            defaultScale: fractalMode.defaultScale,
            cap: 80_000
        )
    }
    
    private var exportIterationCap: Int {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone ? 32_000 : 60_000
        #else
        80_000
        #endif
    }
    
    private var ultraExportIterationCap: Int {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone ? 48_000 : 90_000
        #else
        120_000
        #endif
    }
    
    private var isPhoneDevice: Bool {
        #if os(iOS)
        UIDevice.current.userInterfaceIdiom == .phone
        #else
        false
        #endif
    }
    
    private var exportEffectiveIterations: Int {
        effectiveIterationCount(
            baseIterations: maxIterations,
            renderQuality: renderQuality,
            scale: scale,
            defaultScale: fractalMode.defaultScale,
            cap: exportIterationCap
        )
    }
    
    private var ultraExportEffectiveIterations: Int {
        min(
            Int(Double(exportEffectiveIterations) * (isPhoneDevice ? 1.25 : 1.5)),
            ultraExportIterationCap
        )
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            MandelbrotView(
                fractalMode: fractalMode,
                fractalPalette: fractalPalette,
                centerX: $centerX,
                centerY: $centerY,
                scale: $scale,
                maxIterations: $maxIterations,
                renderQuality: renderQuality
            )
            #if os(macOS)
            .frame(minWidth: 900, minHeight: 650)
            #endif
            .ignoresSafeArea()
            
            GeometryReader { proxy in
                controlsOverlay(isCompact: proxy.size.width < 600)
                    .padding(.horizontal, proxy.size.width < 600 ? 10 : 40)
                    .padding(.bottom, proxy.safeAreaInsets.bottom + (proxy.size.width < 600 ? 10 : 18))
                    .frame(maxWidth: proxy.size.width < 600 ? 360 : 980)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .bottom
                    )
            }
            .allowsHitTesting(true)
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        #if os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: .exportDefaultFractal)) { _ in
            saveSnapshot(width: 2560, height: 1600)
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomInFractal)) { _ in
            zoomIn()
        }
        .onReceive(NotificationCenter.default.publisher(for: .zoomOutFractal)) { _ in
            zoomOut()
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetFractal)) { _ in
            resetView()
        }
        .focusedValue(\.fractalActions, FractalActions(
            snap: {
                saveSnapshot(width: 2560, height: 1600)
            },
            zoomIn: zoomIn,
            zoomOut: zoomOut,
            reset: resetView
        ))
        #endif
        .alert("Controls", isPresented: $showHelp) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("""
Choose a fractal mode from the Mode menu:
Mandelbrot, Mandelbrot Relief, Julia, Burning Ship, Tricorn, Kleinian Relief, Mandelbulb 3D, Mandelbox 3D or Newton Fractal.

Choose a color palette from the Palette menu:
Ocean, Electric, Fire, Ice, Gold, Violet or Deep Blue.

Choose render quality from the Quality menu:
Fast, High or Deep. Deep renders more detail at high zooms.

Drag: select an area and zoom in

2-finger drag: move the view on iPhone and iPad

Pinch: zoom in and out

Double tap: zoom in at tap position

⌥ Option + Drag: move the view on Mac

+ / -: zoom in and out

⌘R: reset view

⌘S: export 2560 × 1600 PNG

Deep 2D zooms automatically use High Precision Preview.
At very deep zooms the app shows Near Limit or Extreme Zoom so precision artifacts are easier to recognize.

Export menu:
On iPhone the export choices are mobile optimized so deep zooms do not render forever.
Fast Export uses 1440 × 900. Quality Export uses 1920 × 1200. Ultra Mobile renders 1440 × 900 internally at 2× and downsamples.
On iPad and Mac the larger export sizes remain available.
Live preview is capped dynamically; iPhone export caps are lower than Mac export caps.

The zoom factor overlay is only visible in the app and is not included in exports.
3D exports are CPU raymarched and may take longer.
""")
        }
    }
    
    private func controlsOverlay(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 8 : 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: isCompact ? 6 : 8) {
                    Menu {
                        ForEach(FractalMode.allCases) { mode in
                            Button {
                                setMode(mode)
                            } label: {
                                Text("\(fractalMode == mode ? "✓ " : "   ")\(mode.displayName)")
                            }
                        }
                    } label: {
                        Text(fractalMode.shortName)
                            .lineLimit(1)
                    }
                    
                    Menu {
                        ForEach(FractalPalette.allCases) { palette in
                            Button {
                                fractalPalette = palette
                            } label: {
                                Text("\(fractalPalette == palette ? "✓ " : "   ")\(palette.displayName)")
                            }
                        }
                    } label: {
                        Text(fractalPalette.displayName)
                            .lineLimit(1)
                    }
                    
                    Menu {
                        ForEach(RenderQuality.allCases) { quality in
                            Button {
                                renderQuality = quality
                            } label: {
                                Text("\(renderQuality == quality ? "✓ " : "   ")\(quality.rawValue)")
                            }
                        }
                    } label: {
                        Text(renderQuality.rawValue)
                            .lineLimit(1)
                    }
                    
                    Button {
                        showHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityLabel("Help")
                    
                    Button {
                        zoomOut()
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    
                    Button {
                        zoomIn()
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    
                    Button {
                        resetView()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    
                    Menu {
                        #if os(iOS)
                        if isPhoneDevice {
                            Button("Fast Export 1440 × 900 PNG") {
                                saveSnapshot(width: 1440, height: 900)
                            }
                            
                            Button("Quality Export 1920 × 1200 PNG") {
                                saveSnapshot(width: 1920, height: 1200)
                            }
                            
                            Button("Max Export 2560 × 1600 PNG") {
                                saveSnapshot(width: 2560, height: 1600)
                            }
                            
                            Divider()
                            
                            Button("Ultra Mobile 1440 × 900 PNG · 2×") {
                                saveSnapshot(width: 1440, height: 900, supersampling: 2)
                            }
                        } else {
                            Button("Export 1440 × 900 PNG") {
                                saveSnapshot(width: 1440, height: 900)
                            }
                            
                            Button("Export 2560 × 1600 PNG") {
                                saveSnapshot(width: 2560, height: 1600)
                            }
                            
                            Button("Export 2880 × 1800 PNG") {
                                saveSnapshot(width: 2880, height: 1800)
                            }
                            
                            Divider()
                            
                            Button("Ultra Export 1440 × 900 PNG · 2×") {
                                saveSnapshot(width: 1440, height: 900, supersampling: 2)
                            }
                            
                            Button("Ultra Export 2560 × 1600 PNG · 2×") {
                                saveSnapshot(width: 2560, height: 1600, supersampling: 2)
                            }
                        }
                        #else
                        Button("Export 1440 × 900 PNG") {
                            saveSnapshot(width: 1440, height: 900)
                        }
                        
                        Button("Export 2560 × 1600 PNG") {
                            saveSnapshot(width: 2560, height: 1600)
                        }
                        
                        Button("Export 2880 × 1800 PNG") {
                            saveSnapshot(width: 2880, height: 1800)
                        }
                        
                        Divider()
                        
                        Button("Ultra Export 1440 × 900 PNG · 2×") {
                            saveSnapshot(width: 1440, height: 900, supersampling: 2)
                        }
                        
                        Button("Ultra Export 2560 × 1600 PNG · 2×") {
                            saveSnapshot(width: 2560, height: 1600, supersampling: 2)
                        }
                        #endif
                    } label: {
                        if isSavingSnapshot {
                            Text("Rendering…")
                                .lineLimit(1)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .disabled(isSavingSnapshot)
                    
                    #if os(iOS)
                    if let exportURL {
                        ShareLink(item: exportURL) {
                            Image(systemName: "paperplane")
                        }
                    }
                    #endif
                    
                }
                .padding(.horizontal, isCompact ? 8 : 10)
                .padding(.vertical, isCompact ? 6 : 8)
            }
            
            HStack(spacing: isCompact ? 8 : 10) {
                Text("\(effectiveIterations.formatted())")
                    .font(.system(isCompact ? .caption : .footnote, design: .rounded))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .frame(width: isCompact ? 58 : 70, alignment: .trailing)
                
                Slider(
                    value: Binding(
                        get: {
                            Double(maxIterations)
                        },
                        set: {
                            maxIterations = Int(($0 / 100).rounded()) * 100
                        }
                    ),
                    in: 300...24000
                )
                .frame(minWidth: 80)
                
                Stepper(
                    "",
                    value: $maxIterations,
                    in: 300...24000,
                    step: 100
                )
                .labelsHidden()
                .frame(width: isCompact ? 92 : 110)
            }
            .padding(.horizontal, isCompact ? 10 : 12)
            .padding(.vertical, isCompact ? 7 : 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
        }
        .buttonStyle(.bordered)
        .controlSize(isCompact ? .small : .regular)
        .padding(isCompact ? 8 : 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: isCompact ? 20 : 24, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 8)
        .frame(maxWidth: isCompact ? 360 : 980)
    }
    
    private func setMode(_ mode: FractalMode) {
        fractalMode = mode
        centerX = mode.defaultCenterX
        centerY = mode.defaultCenterY
        scale = mode.defaultScale
        maxIterations = 300
    }
    
    private func zoomIn() {
        scale *= 0.5
        increaseIterationsForZoom()
    }
    
    private func zoomOut() {
        scale *= 2.0
        decreaseIterationsForZoom()
    }
    
    private func resetView() {
        centerX = fractalMode.defaultCenterX
        centerY = fractalMode.defaultCenterY
        scale = fractalMode.defaultScale
        maxIterations = 300
    }
    
    private func increaseIterationsForZoom() {
        if maxIterations < 500 {
            maxIterations += 400
        } else if maxIterations < 1000 {
            maxIterations += 700
        } else if maxIterations < 2500 {
            maxIterations += 1200
        } else if maxIterations < 5000 {
            maxIterations += 1500
        } else if maxIterations < 8000 {
            maxIterations += 2000
        } else if maxIterations < 12000 {
            maxIterations += 3000
        } else if maxIterations < 18000 {
            maxIterations += 4000
        } else {
            maxIterations += 6000
        }
        
        maxIterations = min(maxIterations, 24000)
    }
    
    private func decreaseIterationsForZoom() {
        if maxIterations > 20000 {
            maxIterations -= 6000
        } else if maxIterations > 16000 {
            maxIterations -= 4000
        } else if maxIterations > 10000 {
            maxIterations -= 3000
        } else if maxIterations > 7000 {
            maxIterations -= 2000
        } else if maxIterations > 3500 {
            maxIterations -= 1500
        } else if maxIterations > 2500 {
            maxIterations -= 1200
        } else if maxIterations > 1000 {
            maxIterations -= 700
        } else {
            maxIterations -= 400
        }
        
        maxIterations = max(maxIterations, 300)
    }
    
    
    private func saveSnapshot(width exportWidth: Int = 2560, height exportHeight: Int = 1600, supersampling: Int = 1) {
        if isSavingSnapshot {
            return
        }
        
        let snapshotMode = fractalMode
        let snapshotPalette = fractalPalette
        let snapshotCenterX = centerX
        let snapshotCenterY = centerY
        let snapshotScale = scale
        #if os(iOS)
        let snapshotSupersampling = isPhoneDevice && exportWidth > 1440 ? 1 : max(1, min(supersampling, 2))
        #else
        let snapshotSupersampling = max(1, min(supersampling, 2))
        #endif
        let snapshotIterations = snapshotSupersampling > 1 ? ultraExportEffectiveIterations : exportEffectiveIterations
        let snapshotExportSuffix = snapshotSupersampling > 1 ? "-Ultra\(snapshotSupersampling)x" : ""
        let fileName = "BeautyOfFractals-\(snapshotMode.fileName)-\(snapshotPalette.fileName)-\(snapshotIterations)-iterations\(snapshotExportSuffix)-\(exportWidth)x\(exportHeight).png"
        
        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = fileName
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                return
            }
            renderSnapshot(
                url: url,
                width: exportWidth,
                height: exportHeight,
                mode: snapshotMode,
                palette: snapshotPalette,
                centerX: snapshotCenterX,
                centerY: snapshotCenterY,
                scale: snapshotScale,
                supersampling: snapshotSupersampling,
                iterations: snapshotIterations
            )
        }
        #else
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        renderSnapshot(
            url: url,
            width: exportWidth,
            height: exportHeight,
            mode: snapshotMode,
            palette: snapshotPalette,
            centerX: snapshotCenterX,
            centerY: snapshotCenterY,
            scale: snapshotScale,
            supersampling: snapshotSupersampling,
            iterations: snapshotIterations
        )
        #endif
    }
    
    private func renderSnapshot(
        url: URL,
        width exportWidth: Int,
        height exportHeight: Int,
        mode snapshotMode: FractalMode,
        palette snapshotPalette: FractalPalette,
        centerX snapshotCenterX: Double,
        centerY snapshotCenterY: Double,
        scale snapshotScale: Double,
        supersampling snapshotSupersampling: Int,
        iterations snapshotIterations: Int
    ) {
        isSavingSnapshot = true
        
        Task.detached(priority: .userInitiated) {
            let cgImage: CGImage?
            
            if snapshotMode == .mandelbulb3D {
                cgImage = renderMandelbulb3DImage(
                    width: exportWidth,
                    height: exportHeight,
                    palette: snapshotPalette,
                    centerX: snapshotCenterX,
                    centerY: snapshotCenterY,
                    scale: snapshotScale
                )
            } else if snapshotMode == .mandelbox3D {
                cgImage = renderMandelbox3DImage(
                    width: exportWidth,
                    height: exportHeight,
                    palette: snapshotPalette,
                    centerX: snapshotCenterX,
                    centerY: snapshotCenterY,
                    scale: snapshotScale
                )
            } else {
                cgImage = renderFractalSupersampled(
                    width: exportWidth,
                    height: exportHeight,
                    supersampling: snapshotSupersampling,
                    mode: snapshotMode,
                    palette: snapshotPalette,
                    centerX: snapshotCenterX,
                    centerY: snapshotCenterY,
                    scale: snapshotScale,
                    maxIterations: snapshotIterations
                )
            }
            
            guard let finalImage = cgImage else {
                await MainActor.run { isSavingSnapshot = false }
                return
            }
            
            #if os(macOS)
            let pngData = NSBitmapImageRep(cgImage: finalImage).representation(using: .png, properties: [:])
            #else
            let pngData = UIImage(cgImage: finalImage).pngData()
            #endif
            
            guard let pngData else {
                await MainActor.run { isSavingSnapshot = false }
                return
            }
            
            do {
                try pngData.write(to: url, options: [.atomic])
            } catch {
                print("Snapshot konnte nicht gespeichert werden:", error)
            }
            
            await MainActor.run {
                #if os(iOS)
                exportURL = url
                #endif
                isSavingSnapshot = false
            }
        }
    }
}

struct MandelbrotView: View {
    let fractalMode: FractalMode
    let fractalPalette: FractalPalette
    
    @Binding var centerX: Double
    @Binding var centerY: Double
    @Binding var scale: Double
    @Binding var maxIterations: Int
    let renderQuality: RenderQuality
    
    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var pinchStartScale: Double?
    
    @State private var isOptionPressed: Bool = false
    @State private var isPanning: Bool = false
    @State private var panStartCenterX: Double = -0.5
    @State private var panStartCenterY: Double = 0.0
    
    #if os(macOS)
    @State private var keyMonitor: Any?
    #endif
    
    private var useHighPrecisionPreview: Bool {
        fractalMode.supportsHighPrecisionPreview && scale < highPrecisionScaleLimit
    }
    
    private var magnificationFactor: Double {
        fractalMode.defaultScale / max(scale, 0.000000000000000001)
    }
    
    private var magnificationText: String {
        formatMagnification(magnificationFactor)
    }
    
    private var precisionStatusText: String? {
        if !fractalMode.supportsHighPrecisionPreview {
            return nil
        }
        
        if magnificationFactor >= 50_000_000_000 {
            return "High Precision · Extreme Zoom"
        }
        
        if magnificationFactor >= 10_000_000_000 {
            return "High Precision · Near Limit"
        }
        
        if useHighPrecisionPreview {
            return "High Precision"
        }
        
        return nil
    }
    
    private var effectiveIterations: Int {
        effectiveIterationCount(
            baseIterations: maxIterations,
            renderQuality: renderQuality,
            scale: scale,
            defaultScale: fractalMode.defaultScale,
            cap: 50_000
        )
    }
    
    private func topInfoPadding(viewWidth: CGFloat, safeTop: CGFloat) -> CGFloat {
        #if os(iOS)
        return viewWidth < 600 ? 96 : 36
        #else
        return safeTop + 12
        #endif
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                ZStack {
                    if useHighPrecisionPreview {
                        HighPrecisionFractalPreview(
                            fractalMode: fractalMode,
                            fractalPalette: fractalPalette,
                            centerX: centerX,
                            centerY: centerY,
                            scale: scale,
                            maxIterations: effectiveIterations,
                            viewSize: geometry.size
                        )
                    } else {
                        MetalMandelbrotView(
                            fractalMode: fractalMode,
                            fractalPalette: fractalPalette,
                            centerX: centerX,
                            centerY: centerY,
                            scale: scale,
                            maxIterations: effectiveIterations
                        )
                    }
                    
                    if let rect = selectionRect, !isPanning {
                        Rectangle()
                            .stroke(Color.white, lineWidth: 2)
                            .background(
                                Rectangle()
                                    .fill(Color.white.opacity(0.15))
                            )
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                    }
                    
                    #if os(iOS)
                    MultiTouchGestureOverlay(
                        onSelectionChanged: { start, current in
                            pinchStartScale = nil
                            isPanning = false
                            dragStart = start
                            dragCurrent = current
                        },
                        onSelectionEnded: { start, end in
                            defer { resetDragState() }
                            let rect = makeRect(from: start, to: end)
                            if rect.width > 10 && rect.height > 10 {
                                zoomToSelection(
                                    rect: rect,
                                    viewSize: geometry.size
                                )
                            }
                        },
                        onTwoFingerPan: { delta in
                            resetDragState()
                            pinchStartScale = nil
                            panBy(delta: delta, viewSize: geometry.size)
                        },
                        onPinchChanged: { rawFactor in
                            resetDragState()
                            if pinchStartScale == nil {
                                pinchStartScale = scale
                            }
                            guard let pinchStartScale else {
                                return
                            }
                            let dampening = 0.42
                            let factor = max(0.05, 1.0 + (rawFactor - 1.0) * dampening)
                            scale = max(pinchStartScale / factor, 1.0e-15)
                        },
                        onPinchEnded: { rawFactor in
                            pinchStartScale = nil
                            let dampening = 0.42
                            let factor = max(0.05, 1.0 + (rawFactor - 1.0) * dampening)
                            if factor > 1.05 {
                                increaseIterationsForZoom()
                            } else if factor < 0.95 {
                                decreaseIterationsForZoom()
                            }
                        },
                        onDoubleTap: { location in
                            zoomAt(
                                location: location,
                                factor: 2.0,
                                viewSize: geometry.size
                            )
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    #endif
                }
                
                HStack(alignment: .top) {
                    Text("Zoom \(magnificationText)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                        .monospacedDigit()
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    
                    Spacer(minLength: 12)
                    
                    if let precisionStatusText {
                        Text(precisionStatusText)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, topInfoPadding(viewWidth: geometry.size.width, safeTop: geometry.safeAreaInsets.top))
                .padding(.horizontal, 18)
            }
            .contentShape(Rectangle())
            #if os(macOS)
            .onAppear {
                keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { event in
                    isOptionPressed = event.modifierFlags.contains(.option)
                    
                    if isOptionPressed {
                        NSCursor.openHand.set()
                    } else {
                        NSCursor.crosshair.set()
                    }
                    
                    return event
                }
            }
            .onDisappear {
                if let keyMonitor {
                    NSEvent.removeMonitor(keyMonitor)
                    self.keyMonitor = nil
                }
            }
            .onHover { hovering in
                if hovering {
                    if isOptionPressed {
                        NSCursor.openHand.push()
                    } else {
                        NSCursor.crosshair.push()
                    }
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(selectionDragGesture(viewSize: geometry.size))
            #else
            // iOS touch handling is performed by MultiTouchGestureOverlay above.
            // This avoids SwiftUI gesture conflicts between selection drag, pinch and 2-finger pan.
            #endif
        }
    }
    
    private func selectionDragGesture(viewSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if dragStart == nil {
                    dragStart = value.startLocation
                    dragCurrent = value.location
                    isPanning = isOptionPressed
                    panStartCenterX = centerX
                    panStartCenterY = centerY
                }
                
                guard let start = dragStart else {
                    return
                }
                
                if isPanning {
                    #if os(macOS)
                    NSCursor.closedHand.set()
                    #endif
                    panView(
                        from: start,
                        to: value.location,
                        viewSize: viewSize
                    )
                } else {
                    #if os(macOS)
                    NSCursor.crosshair.set()
                    #endif
                    dragCurrent = value.location
                }
            }
            .onEnded { value in
                defer {
                    resetDragState()
                }
                
                guard let start = dragStart else {
                    return
                }
                
                if isPanning {
                    return
                }
                
                let end = value.location
                let rect = makeRect(from: start, to: end)
                
                if rect.width > 10 && rect.height > 10 {
                    zoomToSelection(
                        rect: rect,
                        viewSize: viewSize
                    )
                }
            }
    }
    
    private var selectionRect: CGRect? {
        guard let start = dragStart, let current = dragCurrent else {
            return nil
        }
        
        return makeRect(from: start, to: current)
    }
    
    private func resetDragState() {
        dragStart = nil
        dragCurrent = nil
        isPanning = false
        
        #if os(macOS)
        if isOptionPressed {
            NSCursor.openHand.set()
        } else {
            NSCursor.crosshair.set()
        }
        #endif
    }
    
    private func makeRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }
    
    private func panView(from start: CGPoint, to current: CGPoint, viewSize: CGSize) {
        let viewWidth = Double(viewSize.width)
        let viewHeight = Double(viewSize.height)
        let aspectRatio = viewWidth / viewHeight
        
        let dx = Double(current.x - start.x)
        let dy = Double(current.y - start.y)
        
        centerX = panStartCenterX - (dx / viewWidth) * scale * aspectRatio
        centerY = panStartCenterY - (dy / viewHeight) * scale
        
        dragCurrent = current
    }
    
    private func panBy(delta: CGSize, viewSize: CGSize) {
        guard viewSize.width > 0, viewSize.height > 0 else {
            return
        }
        
        let viewWidth = Double(viewSize.width)
        let viewHeight = Double(viewSize.height)
        let aspectRatio = viewWidth / viewHeight
        
        centerX -= (Double(delta.width) / viewWidth) * scale * aspectRatio
        centerY -= (Double(delta.height) / viewHeight) * scale
    }
    
    private func zoomToSelection(rect: CGRect, viewSize: CGSize) {
        let viewWidth = Double(viewSize.width)
        let viewHeight = Double(viewSize.height)
        let aspectRatio = viewWidth / viewHeight
        
        let oldScale = scale
        
        let selectedCenterX = Double(rect.midX)
        let selectedCenterY = Double(rect.midY)
        
        let newCenterX =
            centerX + (selectedCenterX / viewWidth - 0.5) * oldScale * aspectRatio
        
        let newCenterY =
            centerY + (selectedCenterY / viewHeight - 0.5) * oldScale
        
        let zoomFactorX = Double(rect.width) / viewWidth
        let zoomFactorY = Double(rect.height) / viewHeight
        
        let zoomFactor = max(zoomFactorX, zoomFactorY)
        
        centerX = newCenterX
        centerY = newCenterY
        scale = oldScale * zoomFactor
        increaseIterationsForZoom()
    }
    
    private func increaseIterationsForZoom() {
        if maxIterations < 500 {
            maxIterations += 400
        } else if maxIterations < 1000 {
            maxIterations += 700
        } else if maxIterations < 2500 {
            maxIterations += 1200
        } else if maxIterations < 5000 {
            maxIterations += 1500
        } else if maxIterations < 8000 {
            maxIterations += 2000
        } else {
            maxIterations += 3000
        }
        
        maxIterations = min(maxIterations, 24000)
    }
    
    private func decreaseIterationsForZoom() {
        if maxIterations > 20000 {
            maxIterations -= 6000
        } else if maxIterations > 16000 {
            maxIterations -= 4000
        } else if maxIterations > 10000 {
            maxIterations -= 3000
        } else if maxIterations > 7000 {
            maxIterations -= 2000
        } else if maxIterations > 3500 {
            maxIterations -= 1500
        } else if maxIterations > 2500 {
            maxIterations -= 1200
        } else if maxIterations > 1000 {
            maxIterations -= 700
        } else {
            maxIterations -= 400
        }
        
        maxIterations = max(maxIterations, 300)
    }
    
    private func zoomAt(location: CGPoint, factor: Double, viewSize: CGSize) {
        guard viewSize.width > 0, viewSize.height > 0 else {
            scale /= factor
            return
        }
        
        let viewWidth = Double(viewSize.width)
        let viewHeight = Double(viewSize.height)
        let aspectRatio = viewWidth / viewHeight
        let oldScale = scale
        let newScale = oldScale / factor
        
        let normalizedX = Double(location.x / viewSize.width - 0.5)
        let normalizedY = Double(location.y / viewSize.height - 0.5)
        
        let oldWorldX = centerX + normalizedX * oldScale * aspectRatio
        let oldWorldY = centerY + normalizedY * oldScale
        
        centerX = oldWorldX - normalizedX * newScale * aspectRatio
        centerY = oldWorldY - normalizedY * newScale
        scale = newScale
        
        if factor > 1.0 {
            increaseIterationsForZoom()
        } else if factor < 1.0 {
            decreaseIterationsForZoom()
        }
    }
}

#if os(iOS)
private struct MultiTouchGestureOverlay: UIViewRepresentable {
    let onSelectionChanged: (CGPoint, CGPoint) -> Void
    let onSelectionEnded: (CGPoint, CGPoint) -> Void
    let onTwoFingerPan: (CGSize) -> Void
    let onPinchChanged: (Double) -> Void
    let onPinchEnded: (Double) -> Void
    let onDoubleTap: (CGPoint) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onSelectionChanged: onSelectionChanged,
            onSelectionEnded: onSelectionEnded,
            onTwoFingerPan: onTwoFingerPan,
            onPinchChanged: onPinchChanged,
            onPinchEnded: onPinchEnded,
            onDoubleTap: onDoubleTap
        )
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isOpaque = false
        view.isUserInteractionEnabled = true
        view.isMultipleTouchEnabled = true

        let selection = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSelection(_:))
        )
        selection.minimumNumberOfTouches = 1
        selection.maximumNumberOfTouches = 1
        selection.cancelsTouchesInView = false
        selection.delaysTouchesBegan = false
        selection.delaysTouchesEnded = false
        selection.delegate = context.coordinator

        let twoFingerPan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTwoFingerPan(_:))
        )
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        twoFingerPan.cancelsTouchesInView = false
        twoFingerPan.delaysTouchesBegan = false
        twoFingerPan.delaysTouchesEnded = false
        twoFingerPan.delegate = context.coordinator

        let pinch = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        pinch.cancelsTouchesInView = false
        pinch.delaysTouchesBegan = false
        pinch.delaysTouchesEnded = false
        pinch.delegate = context.coordinator

        let doubleTap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        doubleTap.cancelsTouchesInView = false
        doubleTap.delegate = context.coordinator

        selection.require(toFail: doubleTap)

        view.addGestureRecognizer(selection)
        view.addGestureRecognizer(twoFingerPan)
        view.addGestureRecognizer(pinch)
        view.addGestureRecognizer(doubleTap)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onSelectionChanged = onSelectionChanged
        context.coordinator.onSelectionEnded = onSelectionEnded
        context.coordinator.onTwoFingerPan = onTwoFingerPan
        context.coordinator.onPinchChanged = onPinchChanged
        context.coordinator.onPinchEnded = onPinchEnded
        context.coordinator.onDoubleTap = onDoubleTap
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onSelectionChanged: (CGPoint, CGPoint) -> Void
        var onSelectionEnded: (CGPoint, CGPoint) -> Void
        var onTwoFingerPan: (CGSize) -> Void
        var onPinchChanged: (Double) -> Void
        var onPinchEnded: (Double) -> Void
        var onDoubleTap: (CGPoint) -> Void

        private var selectionStart: CGPoint?

        init(
            onSelectionChanged: @escaping (CGPoint, CGPoint) -> Void,
            onSelectionEnded: @escaping (CGPoint, CGPoint) -> Void,
            onTwoFingerPan: @escaping (CGSize) -> Void,
            onPinchChanged: @escaping (Double) -> Void,
            onPinchEnded: @escaping (Double) -> Void,
            onDoubleTap: @escaping (CGPoint) -> Void
        ) {
            self.onSelectionChanged = onSelectionChanged
            self.onSelectionEnded = onSelectionEnded
            self.onTwoFingerPan = onTwoFingerPan
            self.onPinchChanged = onPinchChanged
            self.onPinchEnded = onPinchEnded
            self.onDoubleTap = onDoubleTap
        }

        @objc func handleSelection(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view else {
                return
            }

            let location = recognizer.location(in: view)

            switch recognizer.state {
            case .began:
                selectionStart = location
                onSelectionChanged(location, location)

            case .changed:
                if let selectionStart {
                    onSelectionChanged(selectionStart, location)
                }

            case .ended:
                if let selectionStart {
                    onSelectionEnded(selectionStart, location)
                }
                selectionStart = nil

            case .cancelled, .failed:
                selectionStart = nil

            default:
                break
            }
        }

        @objc func handleTwoFingerPan(_ recognizer: UIPanGestureRecognizer) {
            guard let view = recognizer.view else {
                return
            }

            switch recognizer.state {
            case .began, .changed:
                let translation = recognizer.translation(in: view)
                if abs(translation.x) > 0.2 || abs(translation.y) > 0.2 {
                    onTwoFingerPan(CGSize(width: translation.x, height: translation.y))
                    recognizer.setTranslation(.zero, in: view)
                }

            default:
                recognizer.setTranslation(.zero, in: view)
            }
        }

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            switch recognizer.state {
            case .began, .changed:
                onPinchChanged(Double(recognizer.scale))

            case .ended:
                onPinchEnded(Double(recognizer.scale))
                recognizer.scale = 1.0

            case .cancelled, .failed:
                onPinchEnded(1.0)
                recognizer.scale = 1.0

            default:
                break
            }
        }

        @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view else {
                return
            }
            onDoubleTap(recognizer.location(in: view))
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if let pan = gestureRecognizer as? UIPanGestureRecognizer {
                if pan.minimumNumberOfTouches == 1 {
                    return pan.numberOfTouches <= 1
                }
                if pan.minimumNumberOfTouches == 2 {
                    return pan.numberOfTouches >= 2
                }
            }
            return true
        }
    }
}
#endif

#if os(macOS)
typealias PlatformImage = NSImage
struct PlatformImageView: View {
    let image: PlatformImage
    var body: some View { Image(nsImage: image) }
}
#else
typealias PlatformImage = UIImage
struct PlatformImageView: View {
    let image: PlatformImage
    var body: some View { Image(uiImage: image) }
}
#endif

struct HighPrecisionFractalPreview: View {
    let fractalMode: FractalMode
    let fractalPalette: FractalPalette
    let centerX: Double
    let centerY: Double
    let scale: Double
    let maxIterations: Int
    let viewSize: CGSize
    
    @State private var image: PlatformImage?
    @State private var isRendering: Bool = false
    
    private var renderID: String {
        [
            fractalMode.rawValue.description,
            fractalPalette.rawValue.description,
            String(format: "%.18f", centerX),
            String(format: "%.18f", centerY),
            String(format: "%.18f", scale),
            maxIterations.description,
            Int(viewSize.width).description,
            Int(viewSize.height).description
        ].joined(separator: "|")
    }
    
    var body: some View {
        ZStack {
            if let image {
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill()
                    .frame(width: viewSize.width, height: viewSize.height)
                    .clipped()
                #else
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill()
                    .frame(width: viewSize.width, height: viewSize.height)
                    .clipped()
                #endif
            } else {
                Color.black
            }
            
            if isRendering {
                VStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Rendering high precision…")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .task(id: renderID) {
            await renderPreview()
        }
    }
    
    @MainActor
    private func renderPreview() async {
        let size = cappedRenderSize(for: viewSize)
        
        guard size.width > 8, size.height > 8 else {
            return
        }
        
        isRendering = true
        
        let mode = fractalMode
        let palette = fractalPalette
        let cx = centerX
        let cy = centerY
        let currentScale = scale
        let iterations = maxIterations
        
        let cgImage = await Task.detached(priority: .userInitiated) {
            renderFractal(
                width: size.width,
                height: size.height,
                mode: mode,
                palette: palette,
                centerX: cx,
                centerY: cy,
                scale: currentScale,
                maxIterations: iterations
            )
        }.value
        
        if let cgImage {
            #if os(macOS)
            image = NSImage(cgImage: cgImage, size: NSSize(width: size.width, height: size.height))
            #else
            image = UIImage(cgImage: cgImage)
            #endif
        }
        
        isRendering = false
    }
    
    private func cappedRenderSize(for viewSize: CGSize) -> (width: Int, height: Int) {
        let width = max(1.0, viewSize.width)
        let height = max(1.0, viewSize.height)
        let aspectRatio = width / height
        
        var targetWidth = min(Int(width.rounded()), highPrecisionPreviewMaxPixelWidth)
        var targetHeight = Int(Double(targetWidth) / aspectRatio)
        
        if targetHeight > highPrecisionPreviewMaxPixelHeight {
            targetHeight = highPrecisionPreviewMaxPixelHeight
            targetWidth = Int(Double(targetHeight) * aspectRatio)
        }
        
        return (
            max(16, targetWidth),
            max(16, targetHeight)
        )
    }
}

nonisolated func renderFractalSupersampled(
    width: Int,
    height: Int,
    supersampling: Int,
    mode: FractalMode,
    palette: FractalPalette,
    centerX: Double,
    centerY: Double,
    scale: Double,
    maxIterations: Int
) -> CGImage? {
    let factor = max(1, min(supersampling, 3))
    
    guard factor > 1 else {
        return renderFractal(
            width: width,
            height: height,
            mode: mode,
            palette: palette,
            centerX: centerX,
            centerY: centerY,
            scale: scale,
            maxIterations: maxIterations
        )
    }
    
    guard mode != .mandelbulb3D, mode != .mandelbox3D else {
        return renderFractal(
            width: width,
            height: height,
            mode: mode,
            palette: palette,
            centerX: centerX,
            centerY: centerY,
            scale: scale,
            maxIterations: maxIterations
        )
    }
    
    let sampleWidth = width * factor
    let sampleHeight = height * factor
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let bitsPerComponent = 8
    let aspectRatio = Double(width) / Double(height)
    
    var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
    let samplesPerPixel = Double(factor * factor)
    
    for py in 0..<height {
        for px in 0..<width {
            var r = 0.0
            var g = 0.0
            var b = 0.0
            
            for sy in 0..<factor {
                for sx in 0..<factor {
                    let sampleX = Double(px * factor + sx) + 0.5
                    let sampleY = Double(py * factor + sy) + 0.5
                    
                    let x0 = centerX + (sampleX / Double(sampleWidth) - 0.5) * scale * aspectRatio
                    let y0 = centerY + (sampleY / Double(sampleHeight) - 0.5) * scale
                    
                    let color: (r: Double, g: Double, b: Double)
                    
                    if mode == .newton {
                        color = calculateNewtonColor(
                            x0: x0,
                            y0: y0,
                            palette: palette,
                            maxIterations: maxIterations
                        )
                    } else {
                        let iteration = calculateFractalIteration(
                            mode: mode,
                            x0: x0,
                            y0: y0,
                            maxIterations: maxIterations
                        )
                        
                        if iteration == maxIterations {
                            color = insideColor(mode: mode, palette: palette)
                        } else {
                            let t = Double(iteration) / Double(maxIterations)
                            color = cpuPaletteColor(
                                t: t,
                                mode: mode,
                                palette: palette
                            )
                        }
                    }
                    
                    r += color.r
                    g += color.g
                    b += color.b
                }
            }
            
            let offset = (py * width + px) * bytesPerPixel
            pixels[offset + 0] = UInt8(clamp01(r / samplesPerPixel) * 255.0)
            pixels[offset + 1] = UInt8(clamp01(g / samplesPerPixel) * 255.0)
            pixels[offset + 2] = UInt8(clamp01(b / samplesPerPixel) * 255.0)
            pixels[offset + 3] = 255
        }
    }
    
    return makeCGImage(
        pixels: pixels,
        width: width,
        height: height,
        bytesPerRow: bytesPerRow,
        bitsPerComponent: bitsPerComponent,
        bytesPerPixel: bytesPerPixel
    )
}

nonisolated func renderFractal(
    width: Int,
    height: Int,
    mode: FractalMode,
    palette: FractalPalette,
    centerX: Double,
    centerY: Double,
    scale: Double,
    maxIterations: Int
) -> CGImage? {
    
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let bitsPerComponent = 8
    
    var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
    
    let aspectRatio = Double(width) / Double(height)
    
    for py in 0..<height {
        for px in 0..<width {
            
            let x0 = centerX + (Double(px) / Double(width) - 0.5) * scale * aspectRatio
            let y0 = centerY + (Double(py) / Double(height) - 0.5) * scale
            
            let color: (r: Double, g: Double, b: Double)
            
            if mode == .newton {
                color = calculateNewtonColor(
                    x0: x0,
                    y0: y0,
                    palette: palette,
                    maxIterations: maxIterations
                )
            } else {
                let iteration = calculateFractalIteration(
                    mode: mode,
                    x0: x0,
                    y0: y0,
                    maxIterations: maxIterations
                )
                
                if iteration == maxIterations {
                    color = insideColor(mode: mode, palette: palette)
                } else {
                    let t = Double(iteration) / Double(maxIterations)
                    color = cpuPaletteColor(
                        t: t,
                        mode: mode,
                        palette: palette
                    )
                }
            }
            
            let offset = (py * width + px) * bytesPerPixel
            
            pixels[offset + 0] = UInt8(clamp01(color.r) * 255.0)
            pixels[offset + 1] = UInt8(clamp01(color.g) * 255.0)
            pixels[offset + 2] = UInt8(clamp01(color.b) * 255.0)
            pixels[offset + 3] = 255
        }
    }
    
    return makeCGImage(
        pixels: pixels,
        width: width,
        height: height,
        bytesPerRow: bytesPerRow,
        bitsPerComponent: bitsPerComponent,
        bytesPerPixel: bytesPerPixel
    )
}

nonisolated func renderMandelbulb3DImage(
    width: Int,
    height: Int,
    palette: FractalPalette,
    centerX: Double,
    centerY: Double,
    scale: Double
) -> CGImage? {
    renderRaymarched3DImage(
        width: width,
        height: height,
        palette: palette,
        centerX: centerX,
        centerY: centerY,
        scale: scale,
        mode: .mandelbulb3D
    )
}

nonisolated func renderMandelbox3DImage(
    width: Int,
    height: Int,
    palette: FractalPalette,
    centerX: Double,
    centerY: Double,
    scale: Double
) -> CGImage? {
    renderRaymarched3DImage(
        width: width,
        height: height,
        palette: palette,
        centerX: centerX,
        centerY: centerY,
        scale: scale,
        mode: .mandelbox3D
    )
}

nonisolated private func renderRaymarched3DImage(
    width: Int,
    height: Int,
    palette: FractalPalette,
    centerX: Double,
    centerY: Double,
    scale: Double,
    mode: FractalMode
) -> CGImage? {
    
    let bytesPerPixel = 4
    let bytesPerRow = width * bytesPerPixel
    let bitsPerComponent = 8
    
    var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
    let aspectRatio = Double(width) / Double(height)
    
    for py in 0..<height {
        for px in 0..<width {
            let uvX = Double(px) / Double(width)
            let uvY = 1.0 - Double(py) / Double(height)
            
            let color = renderRaymarched3DPixel(
                uvX: uvX,
                uvY: uvY,
                aspectRatio: aspectRatio,
                palette: palette,
                centerX: centerX,
                centerY: centerY,
                scale: scale,
                mode: mode
            )
            
            let offset = (py * width + px) * bytesPerPixel
            
            pixels[offset + 0] = UInt8(clamp01(color.r) * 255.0)
            pixels[offset + 1] = UInt8(clamp01(color.g) * 255.0)
            pixels[offset + 2] = UInt8(clamp01(color.b) * 255.0)
            pixels[offset + 3] = 255
        }
    }
    
    return makeCGImage(
        pixels: pixels,
        width: width,
        height: height,
        bytesPerRow: bytesPerRow,
        bitsPerComponent: bitsPerComponent,
        bytesPerPixel: bytesPerPixel
    )
}

nonisolated private func renderRaymarched3DPixel(
    uvX: Double,
    uvY: Double,
    aspectRatio: Double,
    palette: FractalPalette,
    centerX: Double,
    centerY: Double,
    scale: Double,
    mode: FractalMode
) -> (r: Double, g: Double, b: Double) {
    
    var px = (uvX - 0.5) * 2.0 * aspectRatio
    var py = (uvY - 0.5) * 2.0
    
    let zoom = scale / 2.8
    px *= zoom
    py *= zoom
    
    px += centerX
    py += centerY
    
    let rayOrigin = SIMD3<Double>(0.0, 0.0, -4.2)
    let rayDirection = simd_normalize(SIMD3<Double>(px, py, 1.65))
    
    var totalDistance = 0.0
    var hit = false
    var hitDistance = 0.0
    var hitPoint = SIMD3<Double>(0.0, 0.0, 0.0)
    
    for _ in 0..<120 {
        let position = rayOrigin + rayDirection * totalDistance
        
        let distance: Double
        if mode == .mandelbox3D {
            distance = mandelboxDistance(position)
        } else {
            distance = mandelbulbDistance(position)
        }
        
        if distance < 0.0012 {
            hit = true
            hitDistance = totalDistance
            hitPoint = position
            break
        }
        
        totalDistance += distance
        
        if totalDistance > 9.0 {
            break
        }
    }
    
    if !hit {
        let vignette = 1.0 - smoothstep(edge0: 0.2, edge1: 1.7, x: sqrt(px * px + py * py))
        let glow = exp(-0.35 * totalDistance)
        
        let background = paletteBaseColor(
            relief: 0.22 + 0.18 * glow,
            ridge: vignette,
            glow: glow,
            palette: palette
        )
        
        return (
            background.r * 0.28,
            background.g * 0.28,
            background.b * 0.28
        )
    }
    
    let normal: SIMD3<Double>
    if mode == .mandelbox3D {
        normal = mandelboxNormal(hitPoint)
    } else {
        normal = mandelbulbNormal(hitPoint)
    }
    
    let lightDir = simd_normalize(SIMD3<Double>(-0.45, 0.65, -0.8))
    let viewDir = simd_normalize(rayOrigin - hitPoint)
    let halfDir = simd_normalize(lightDir + viewDir)
    
    let diffuse = max(simd_dot(normal, lightDir), 0.0)
    let specular = pow(max(simd_dot(normal, halfDir), 0.0), 48.0)
    let rim = pow(1.0 - max(simd_dot(normal, viewDir), 0.0), 2.2)
    
    let depth = clamp01(hitDistance / 6.5)
    let ao = clamp(value: 1.0 - hitDistance * 0.08, minValue: 0.25, maxValue: 1.0)
    
    let stripe = 0.5 + 0.5 * sin(28.0 * hitPoint.y + 18.0 * hitPoint.x)
    
    var color = paletteBaseColor(
        relief: mode == .mandelbox3D ? 0.78 : 0.65,
        ridge: stripe,
        glow: 0.35,
        palette: palette
    )
    
    color.r *= 0.18 + 1.05 * diffuse
    color.g *= 0.18 + 1.05 * diffuse
    color.b *= 0.18 + 1.05 * diffuse
    
    color.r += 1.0 * specular * 0.85
    color.g += 0.75 * specular * 0.85
    color.b += 0.25 * specular * 0.85
    
    let rimColor = paletteBaseColor(
        relief: 0.9,
        ridge: 1.0,
        glow: 0.7,
        palette: palette
    )
    
    color.r += rimColor.r * rim * 0.45
    color.g += rimColor.g * rim * 0.45
    color.b += rimColor.b * rim * 0.45
    
    color.r *= ao
    color.g *= ao
    color.b *= ao
    
    color.r = mix(color.r, 0.01, depth * 0.35)
    color.g = mix(color.g, 0.02, depth * 0.35)
    color.b = mix(color.b, 0.08, depth * 0.35)
    
    return color
}

nonisolated private func mandelbulbDistance(_ point: SIMD3<Double>) -> Double {
    var z = point
    var dr = 1.0
    var r = 0.0
    let power = 8.0
    
    for _ in 0..<9 {
        r = simd_length(z)
        
        if r > 2.0 {
            break
        }
        
        let theta = acos(clamp(value: z.z / max(r, 0.000001), minValue: -1.0, maxValue: 1.0))
        let phi = atan2(z.y, z.x)
        
        dr = pow(r, power - 1.0) * power * dr + 1.0
        
        let zr = pow(r, power)
        let newTheta = theta * power
        let newPhi = phi * power
        
        z = zr * SIMD3<Double>(
            sin(newTheta) * cos(newPhi),
            sin(newPhi) * sin(newTheta),
            cos(newTheta)
        )
        
        z += point
    }
    
    return 0.5 * log(r) * r / dr
}

nonisolated private func mandelboxDistance(_ point: SIMD3<Double>) -> Double {
    var z = point
    let scaleFactor = 2.4
    var dr = 1.0
    
    let minRadius = 0.45
    let fixedRadius = 1.0
    
    for _ in 0..<12 {
        z.x = clamp(value: z.x, minValue: -1.0, maxValue: 1.0) * 2.0 - z.x
        z.y = clamp(value: z.y, minValue: -1.0, maxValue: 1.0) * 2.0 - z.y
        z.z = clamp(value: z.z, minValue: -1.0, maxValue: 1.0) * 2.0 - z.z
        
        let r2 = simd_length_squared(z)
        
        if r2 < minRadius * minRadius {
            let factor = fixedRadius * fixedRadius / (minRadius * minRadius)
            z *= factor
            dr *= factor
        } else if r2 < fixedRadius * fixedRadius {
            let factor = fixedRadius * fixedRadius / r2
            z *= factor
            dr *= factor
        }
        
        z = z * scaleFactor + point
        dr = dr * abs(scaleFactor) + 1.0
    }
    
    return simd_length(z) / abs(dr)
}

nonisolated private func mandelbulbNormal(_ point: SIMD3<Double>) -> SIMD3<Double> {
    estimateNormal(point) { mandelbulbDistance($0) }
}

nonisolated private func mandelboxNormal(_ point: SIMD3<Double>) -> SIMD3<Double> {
    estimateNormal(point) { mandelboxDistance($0) }
}

nonisolated private func estimateNormal(
    _ point: SIMD3<Double>,
    distance: (SIMD3<Double>) -> Double
) -> SIMD3<Double> {
    
    let epsilon = 0.0015
    
    let dx = distance(point + SIMD3<Double>(epsilon, 0.0, 0.0)) -
             distance(point - SIMD3<Double>(epsilon, 0.0, 0.0))
    
    let dy = distance(point + SIMD3<Double>(0.0, epsilon, 0.0)) -
             distance(point - SIMD3<Double>(0.0, epsilon, 0.0))
    
    let dz = distance(point + SIMD3<Double>(0.0, 0.0, epsilon)) -
             distance(point - SIMD3<Double>(0.0, 0.0, epsilon))
    
    return simd_normalize(SIMD3<Double>(dx, dy, dz))
}

nonisolated private func calculateNewtonColor(
    x0: Double,
    y0: Double,
    palette: FractalPalette,
    maxIterations: Int
) -> (r: Double, g: Double, b: Double) {
    
    var z = SIMD2<Double>(x0, y0)
    let roots = [
        SIMD2<Double>(1.0, 0.0),
        SIMD2<Double>(-0.5, 0.8660254037844386),
        SIMD2<Double>(-0.5, -0.8660254037844386)
    ]
    
    var iteration = 0
    
    while iteration < maxIterations {
        let z2 = complexMul(z, z)
        let z3 = complexMul(z2, z)
        
        let numerator = SIMD2<Double>(z3.x - 1.0, z3.y)
        let denominator = complexMul(SIMD2<Double>(3.0, 0.0), z2)
        
        let correction = complexDiv(numerator, denominator)
        z -= correction
        
        if simd_length(correction) < 0.000001 {
            break
        }
        
        if !z.x.isFinite || !z.y.isFinite {
            break
        }
        
        iteration += 1
    }
    
    var nearestRootIndex = 0
    var nearestDistance = Double.greatestFiniteMagnitude
    
    for index in 0..<roots.count {
        let distance = simd_length(z - roots[index])
        if distance < nearestDistance {
            nearestDistance = distance
            nearestRootIndex = index
        }
    }
    
    let t = Double(iteration) / Double(maxIterations)
    let convergence = 1.0 - t
    
    let edge = pow(t, 0.32)
    let glow = pow(max(convergence, 0.0), 0.28)
    let rings = 0.5 + 0.5 * sin(Double(iteration) * 1.45)
    let fine = 0.5 + 0.5 * sin(Double(iteration) * 4.8)
    
    var rootColor: (r: Double, g: Double, b: Double)
    
    switch palette {
    case .ocean:
        if nearestRootIndex == 0 {
            rootColor = (0.02, 0.80, 1.00)
        } else if nearestRootIndex == 1 {
            rootColor = (0.05, 0.32, 1.00)
        } else {
            rootColor = (0.00, 1.00, 0.72)
        }
        
    case .electric:
        if nearestRootIndex == 0 {
            rootColor = (0.00, 1.00, 1.00)
        } else if nearestRootIndex == 1 {
            rootColor = (0.20, 0.35, 1.00)
        } else {
            rootColor = (0.75, 0.00, 1.00)
        }
        
    case .fire:
        if nearestRootIndex == 0 {
            rootColor = (1.00, 0.18, 0.02)
        } else if nearestRootIndex == 1 {
            rootColor = (1.00, 0.72, 0.02)
        } else {
            rootColor = (0.95, 0.05, 0.00)
        }
        
    case .ice:
        if nearestRootIndex == 0 {
            rootColor = (0.70, 1.00, 1.00)
        } else if nearestRootIndex == 1 {
            rootColor = (0.25, 0.65, 1.00)
        } else {
            rootColor = (0.88, 0.92, 1.00)
        }
        
    case .gold:
        if nearestRootIndex == 0 {
            rootColor = (1.00, 0.72, 0.05)
        } else if nearestRootIndex == 1 {
            rootColor = (1.00, 0.38, 0.02)
        } else {
            rootColor = (0.75, 0.95, 0.05)
        }
        
    case .violet:
        if nearestRootIndex == 0 {
            rootColor = (0.95, 0.15, 1.00)
        } else if nearestRootIndex == 1 {
            rootColor = (0.35, 0.15, 1.00)
        } else {
            rootColor = (1.00, 0.35, 0.75)
        }
        
    case .deepBlue:
        if nearestRootIndex == 0 {
            rootColor = (0.00, 0.95, 1.00)
        } else if nearestRootIndex == 1 {
            rootColor = (0.08, 0.38, 1.00)
        } else {
            rootColor = (0.82, 1.00, 0.15)
        }
        
    case .solarCoral:
        if nearestRootIndex == 0 {
            rootColor = (1.00, 0.86, 0.20)
        } else if nearestRootIndex == 1 {
            rootColor = (1.00, 0.32, 0.18)
        } else {
            rootColor = (0.95, 0.92, 0.62)
        }
        
    case .infernoCoral:
        if nearestRootIndex == 0 {
            rootColor = (1.00, 0.20, 0.05)
        } else if nearestRootIndex == 1 {
            rootColor = (1.00, 0.58, 0.04)
        } else {
            rootColor = (0.32, 0.18, 0.08)
        }
        
    case .solarPop:
        if nearestRootIndex == 0 {
            rootColor = (1.00, 0.96, 0.05)
        } else if nearestRootIndex == 1 {
            rootColor = (1.00, 0.08, 0.025)
        } else {
            rootColor = (1.00, 0.94, 0.74)
        }
    }
    
    let background = 0.05 + 0.12 * edge
    let lineBoost = pow(rings, 5.0) * 0.45 + pow(fine, 10.0) * 0.35
    let brightness = 0.22 + 1.25 * glow + lineBoost
    
    return (
        clamp01(background + rootColor.r * brightness),
        clamp01(background + rootColor.g * brightness),
        clamp01(background + rootColor.b * brightness)
    )
}

nonisolated private func calculateFractalIteration(
    mode: FractalMode,
    x0: Double,
    y0: Double,
    maxIterations: Int
) -> Int {
    
    var x: Double
    var y: Double
    var cx: Double
    var cy: Double
    
    switch mode {
    case .mandelbrot, .mandelbrotRelief:
        x = 0.0
        y = 0.0
        cx = x0
        cy = y0
        
    case .julia:
        x = x0
        y = y0
        cx = -0.8
        cy = 0.156
        
    case .burningShip:
        x = 0.0
        y = 0.0
        cx = x0
        cy = y0
        
    case .tricorn:
        x = 0.0
        y = 0.0
        cx = x0
        cy = y0
        
    case .kleinian:
        x = x0
        y = y0
        cx = 0.0
        cy = 0.0
        
    case .mandelbulb3D, .mandelbox3D, .newton:
        x = 0.0
        y = 0.0
        cx = x0
        cy = y0
    }
    
    var iteration = 0
    
    while x * x + y * y <= 4.0 && iteration < maxIterations {
        switch mode {
        case .mandelbrot, .julia, .mandelbulb3D, .mandelbrotRelief, .mandelbox3D, .newton:
            let xtemp = x * x - y * y + cx
            y = 2.0 * x * y + cy
            x = xtemp
            
        case .burningShip:
            let ax = abs(x)
            let ay = abs(y)
            let xtemp = ax * ax - ay * ay + cx
            y = 2.0 * ax * ay + cy
            x = xtemp
            
        case .tricorn:
            let xtemp = x * x - y * y + cx
            y = -2.0 * x * y + cy
            x = xtemp
            
        case .kleinian:
            let r2 = x * x + y * y + 0.000001
            
            x = x / r2
            y = y / r2
            
            x = abs(x)
            y = abs(y)
            
            x = x - 1.0
            y = y - 0.5
            
            let angle = 0.45
            let cosA = cos(angle)
            let sinA = sin(angle)
            
            let rx = x * cosA - y * sinA
            let ry = x * sinA + y * cosA
            
            x = rx
            y = ry
        }
        
        iteration += 1
    }
    
    return iteration
}

nonisolated private func cpuPaletteColor(
    t: Double,
    mode: FractalMode,
    palette: FractalPalette
) -> (r: Double, g: Double, b: Double) {
    
    let k = sqrt(t)
    
    let relief: Double
    let ridge: Double
    let glow: Double
    
    if mode == .kleinian {
        relief = pow(k, 0.38)
        ridge = 0.5 + 0.5 * sin(70.0 * k)
        glow = exp(-8.0 * abs(k - 0.42))
    } else if mode == .mandelbrotRelief {
        relief = pow(k, 0.42)
        ridge = 0.5 + 0.5 * sin(55.0 * k)
        glow = exp(-7.0 * abs(k - 0.48))
    } else {
        relief = t
        ridge = 0.5 + 0.5 * sin(38.0 * k)
        glow = exp(-7.0 * abs(k - 0.45))
    }
    
    let base = paletteBaseColor(
        relief: relief,
        ridge: ridge,
        glow: glow,
        palette: palette
    )
    
    if mode == .kleinian || mode == .mandelbrotRelief {
        return (
            clamp01(base.r * 1.15),
            clamp01(base.g * 1.15),
            clamp01(base.b * 1.15)
        )
    }
    
    return base
}

nonisolated private func paletteBaseColor(
    relief: Double,
    ridge: Double,
    glow: Double,
    palette: FractalPalette
) -> (r: Double, g: Double, b: Double) {
    
    switch palette {
    case .ocean:
        return (
            clamp01(0.02 + 0.18 * relief + 0.18 * glow + 0.10 * ridge),
            clamp01(0.08 + 0.65 * relief + 0.28 * glow + 0.12 * ridge),
            clamp01(0.22 + 1.05 * relief + 0.30 * glow)
        )
        
    case .electric:
        return (
            clamp01(0.01 + 0.08 * relief + 0.16 * glow),
            clamp01(0.10 + 0.95 * relief + 0.40 * glow + 0.10 * ridge),
            clamp01(0.28 + 1.20 * relief + 0.25 * ridge)
        )
        
    case .fire:
        return (
            clamp01(0.20 + 1.20 * relief + 0.35 * glow),
            clamp01(0.04 + 0.45 * relief + 0.28 * glow + 0.18 * ridge),
            clamp01(0.01 + 0.08 * relief + 0.05 * glow)
        )
        
    case .ice:
        return (
            clamp01(0.16 + 0.62 * relief + 0.20 * glow),
            clamp01(0.32 + 0.95 * relief + 0.25 * ridge),
            clamp01(0.55 + 1.10 * relief + 0.20 * glow)
        )
        
    case .gold:
        return (
            clamp01(0.22 + 1.00 * relief + 0.35 * glow),
            clamp01(0.12 + 0.62 * relief + 0.20 * ridge),
            clamp01(0.02 + 0.18 * relief + 0.06 * glow)
        )
        
    case .violet:
        return (
            clamp01(0.12 + 0.75 * relief + 0.25 * glow),
            clamp01(0.02 + 0.18 * relief + 0.08 * ridge),
            clamp01(0.24 + 1.05 * relief + 0.35 * glow)
        )
        
    case .deepBlue:
        let yellowSpark = pow(glow, 1.35)
        let cyanEdge = pow(relief, 0.55)
        
        return (
            clamp01(0.00 + 0.05 * cyanEdge + 0.80 * yellowSpark + 0.10 * ridge),
            clamp01(0.04 + 0.70 * cyanEdge + 0.95 * yellowSpark + 0.20 * ridge),
            clamp01(0.18 + 1.05 * cyanEdge + 0.18 * yellowSpark + 0.18 * ridge)
        )
        
    case .solarCoral:
        let detail = pow(ridge, 0.72)
        let warmBody = pow(relief, 0.58)
        let hotGlow = pow(glow, 0.82)
        let darkFiligree = pow(1.0 - clamp01(relief + glow * 0.35), 2.8) * ridge
        
        return (
            clamp01(0.40 + 0.82 * warmBody + 0.60 * hotGlow + 0.42 * detail - 0.30 * darkFiligree),
            clamp01(0.28 + 0.78 * warmBody + 0.42 * hotGlow + 0.12 * detail - 0.36 * darkFiligree),
            clamp01(0.08 + 0.24 * warmBody + 0.05 * hotGlow + 0.04 * detail - 0.22 * darkFiligree)
        )
        
    case .infernoCoral:
        let detail = pow(ridge, 0.58)
        let warmBody = pow(relief, 0.52)
        let ember = pow(glow, 0.72)
        let darkFiligree = pow(1.0 - clamp01(relief * 0.8 + glow * 0.45), 2.2) * ridge
        
        return (
            clamp01(0.18 + 1.10 * warmBody + 0.92 * ember + 0.58 * detail - 0.40 * darkFiligree),
            clamp01(0.05 + 0.45 * warmBody + 0.36 * ember + 0.16 * detail - 0.32 * darkFiligree),
            clamp01(0.01 + 0.10 * warmBody + 0.04 * ember + 0.04 * detail - 0.20 * darkFiligree)
        )
        
    case .solarPop:
        // Solar Pop:
        // high-contrast lemon, ivory, coral-red and charcoal bands.
        // More colorful and stepped than Solar Coral.
        let detail = pow(ridge, 0.50)
        let body = pow(relief, 0.44)
        let light = pow(glow, 0.60)
        
        let rawPhase = 0.06 + 2.75 * relief + 4.15 * glow + 6.80 * ridge
        let phase = rawPhase - floor(rawPhase)
        let micro = 0.5 + 0.5 * cos(62.0 * ridge + 15.0 * glow - 9.0 * relief)
        
        let redBand = smoothstep(edge0: 0.08, edge1: 0.18, x: phase) * (1.0 - smoothstep(edge0: 0.30, edge1: 0.44, x: phase))
        let lemonBand = smoothstep(edge0: 0.28, edge1: 0.42, x: phase) * (1.0 - smoothstep(edge0: 0.56, edge1: 0.70, x: phase))
        let ivoryBand = smoothstep(edge0: 0.58, edge1: 0.72, x: phase) * (1.0 - smoothstep(edge0: 0.82, edge1: 0.96, x: phase))
        let darkBand = smoothstep(edge0: 0.80, edge1: 0.94, x: phase)
        
        let warmOrange = (1.00, 0.50, 0.02)
        let lemon = (1.00, 0.95, 0.04)
        let coralRed = (1.00, 0.08, 0.025)
        let ivory = (1.00, 0.94, 0.74)
        let charcoal = (0.050, 0.038, 0.030)
        
        var r = warmOrange.0
        var g = warmOrange.1
        var b = warmOrange.2
        
        r = r + (lemon.0 - r) * (0.78 * lemonBand)
        g = g + (lemon.1 - g) * (0.78 * lemonBand)
        b = b + (lemon.2 - b) * (0.78 * lemonBand)
        
        r = r + (coralRed.0 - r) * (0.70 * redBand)
        g = g + (coralRed.1 - g) * (0.70 * redBand)
        b = b + (coralRed.2 - b) * (0.70 * redBand)
        
        r = r + (ivory.0 - r) * (0.58 * ivoryBand * (0.35 + 0.65 * detail))
        g = g + (ivory.1 - g) * (0.58 * ivoryBand * (0.35 + 0.65 * detail))
        b = b + (ivory.2 - b) * (0.58 * ivoryBand * (0.35 + 0.65 * detail))
        
        r = r + (charcoal.0 - r) * (0.36 * darkBand * detail)
        g = g + (charcoal.1 - g) * (0.36 * darkBand * detail)
        b = b + (charcoal.2 - b) * (0.36 * darkBand * detail)
        
        let edgeSpark = pow(detail, 0.68) * (0.50 + 0.50 * micro)
        let lift = 0.56 + 0.72 * body + 0.44 * light
        
        return (
            clamp01(r * lift + 0.48 * edgeSpark + 0.38 * redBand * detail),
            clamp01(g * lift + 0.32 * edgeSpark + 0.04 * redBand * detail),
            clamp01(b * lift + 0.07 * edgeSpark + 0.02 * redBand * detail)
        )
    }
}

nonisolated private func insideColor(
    mode: FractalMode,
    palette: FractalPalette
) -> (r: Double, g: Double, b: Double) {
    
    if mode == .mandelbrot || mode == .mandelbrotRelief {
        return (0.0, 0.0, 0.0)
    }
    
    if mode == .kleinian {
        switch palette {
        case .ocean:
            return (0.02, 0.04, 0.11)
        case .electric:
            return (0.00, 0.03, 0.12)
        case .fire:
            return (0.08, 0.01, 0.00)
        case .ice:
            return (0.04, 0.08, 0.12)
        case .gold:
            return (0.08, 0.04, 0.00)
        case .violet:
            return (0.05, 0.00, 0.10)
        case .deepBlue:
            return (0.00, 0.01, 0.08)
        case .solarCoral:
            return (0.10, 0.055, 0.020)
        case .infernoCoral:
            return (0.075, 0.020, 0.010)
        case .solarPop:
            return (0.090, 0.040, 0.018)
        }
    }
    
    return (0.0, 0.0, 0.0)
}

nonisolated private func complexMul(_ a: SIMD2<Double>, _ b: SIMD2<Double>) -> SIMD2<Double> {
    SIMD2<Double>(
        a.x * b.x - a.y * b.y,
        a.x * b.y + a.y * b.x
    )
}

nonisolated private func complexDiv(_ a: SIMD2<Double>, _ b: SIMD2<Double>) -> SIMD2<Double> {
    let denominator = b.x * b.x + b.y * b.y + 0.000000001
    
    return SIMD2<Double>(
        (a.x * b.x + a.y * b.y) / denominator,
        (a.y * b.x - a.x * b.y) / denominator
    )
}

nonisolated private func formatMagnification(_ value: Double) -> String {
    if value < 1_000 {
        return "×\(String(format: "%.0f", value))"
    }
    
    if value < 1_000_000 {
        return "×\(String(format: "%.1f", value / 1_000.0))K"
    }
    
    if value < 1_000_000_000 {
        return "×\(String(format: "%.1f", value / 1_000_000.0))M"
    }
    
    if value < 1_000_000_000_000 {
        return "×\(String(format: "%.1f", value / 1_000_000_000.0))B"
    }
    
    return "×\(String(format: "%.2e", value))"
}

nonisolated private func makeCGImage(
    pixels: [UInt8],
    width: Int,
    height: Int,
    bytesPerRow: Int,
    bitsPerComponent: Int,
    bytesPerPixel: Int
) -> CGImage? {
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let data = Data(pixels)
    
    guard let provider = CGDataProvider(data: data as CFData) else {
        return nil
    }
    
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
    
    return CGImage(
        width: width,
        height: height,
        bitsPerComponent: bitsPerComponent,
        bitsPerPixel: bitsPerComponent * bytesPerPixel,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo,
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )
}

nonisolated private func smoothstep(edge0: Double, edge1: Double, x: Double) -> Double {
    let t = clamp01((x - edge0) / (edge1 - edge0))
    return t * t * (3.0 - 2.0 * t)
}

nonisolated private func mix(_ a: Double, _ b: Double, _ t: Double) -> Double {
    a * (1.0 - t) + b * t
}

nonisolated private func clamp(value: Double, minValue: Double, maxValue: Double) -> Double {
    min(maxValue, max(minValue, value))
}

nonisolated private func clamp01(_ value: Double) -> Double {
    min(1.0, max(0.0, value))
}
